public import Async
public import Clock_Concurrency
public import Ownership

extension Async.Stream {
    /// Pulls an upstream iterator for an operator that races each pull against a timer.
    ///
    /// One pull task at a time calls `box.next()`. When the timer wins the race, that pull
    /// keeps running and its result is kept for the next call to ``next(until:clock:)``.
    /// So a timer never cancels the upstream, and no element it produces is dropped.
    /// Cancelling the consumer's task cancels the pull and ends the upstream.
    @usableFromInline
    actor Pull {
        @usableFromInline
        let box: Async.Stream<Element>.Iterator.Box<Async.Stream<Element>.Iterator>

        /// The pull in flight, if any.
        var task: Task<Void, Never>?

        /// A pulled result no caller has taken yet. `.some(nil)` means the upstream finished.
        var ready: Element??

        /// The caller suspended in ``next(until:clock:)``, if any.
        var waiter: CheckedContinuation<Outcome, Never>?

        /// The timer for the current waiter, if it has a deadline.
        var timer: Task<Void, Never>?

        /// Identifies the current waiter, so a stale timer or cancellation is ignored.
        var generation: Int = 0

        /// Set once the consumer was cancelled. The upstream is then treated as finished.
        var cancelled: Bool = false

        @usableFromInline
        init(box: Async.Stream<Element>.Iterator.Box<Async.Stream<Element>.Iterator>) {
            self.box = box
        }

        deinit {
            task?.cancel()
            timer?.cancel()
        }
    }
}

extension Async.Stream.Pull {
    @usableFromInline
    enum Outcome: Sendable {
        case element(Element)
        case timerExpired
        case upstreamComplete
    }
}

extension Async.Stream.Pull {
    /// Returns the next upstream result, or `.timerExpired` when `deadline` passes first.
    ///
    /// With no deadline, it waits for the upstream only.
    @usableFromInline
    func next(
        until deadline: Clock.`Any`<Duration>.Instant?,
        clock: Clock.`Any`<Duration>
    ) async -> Outcome {
        if let outcome = takeReady() {
            return outcome
        }
        if cancelled || Task.isCancelled {
            cancel(generation: generation)
            return .upstreamComplete
        }

        startPullIfNeeded()
        generation += 1
        let current = generation

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Outcome, Never>) in
                register(continuation, generation: current, deadline: deadline, clock: clock)
            }
        } onCancel: {
            Task { await self.cancel(generation: current) }
        }
    }

    func takeReady() -> Outcome? {
        guard let result = ready else { return nil }
        ready = nil
        guard let element = result else {
            ready = .some(nil)
            return .upstreamComplete
        }
        return .element(element)
    }

    func startPullIfNeeded() {
        guard task == nil, ready == nil else { return }
        let box = self.box
        task = Task { [weak self] in
            let element = await box.next()
            await self?.deliver(element)
        }
    }

    func register(
        _ continuation: CheckedContinuation<Outcome, Never>,
        generation current: Int,
        deadline: Clock.`Any`<Duration>.Instant?,
        clock: Clock.`Any`<Duration>
    ) {
        if cancelled {
            continuation.resume(returning: .upstreamComplete)
            return
        }
        if let outcome = takeReady() {
            continuation.resume(returning: outcome)
            return
        }
        waiter = continuation
        if let deadline {
            timer = Task { [weak self] in
                try? await clock.sleep(until: deadline)
                await self?.expire(generation: current)
            }
        }
    }

    func deliver(_ element: Element?) {
        task = nil
        ready = .some(element)
        if let continuation = waiter, let outcome = takeReady() {
            waiter = nil
            timer?.cancel()
            timer = nil
            continuation.resume(returning: outcome)
        }
    }

    func expire(generation current: Int) {
        guard current == generation, let continuation = waiter else { return }
        waiter = nil
        timer = nil
        continuation.resume(returning: .timerExpired)
    }

    func cancel(generation current: Int) {
        cancelled = true
        task?.cancel()
        task = nil
        timer?.cancel()
        timer = nil
        guard current == generation, let continuation = waiter else { return }
        waiter = nil
        continuation.resume(returning: .upstreamComplete)
    }
}
