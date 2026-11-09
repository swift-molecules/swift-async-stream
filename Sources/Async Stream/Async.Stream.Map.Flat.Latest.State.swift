public import Async
internal import Buffer
import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Memory
import Memory_Allocator
import Memory_Allocator_Pool
import Memory_Pool
import Ownership_Shared_Primitive
internal import Standard_Library_Extensions
import Storage
import Store

extension Async.Stream.Map.Flat {
    public enum Latest {}
}

extension Async.Stream.Map.Flat.Latest {
    @usableFromInline
    actor State<U: Sendable> {
        @usableFromInline
        var innerTask: Task<Void, Never>?

        @usableFromInline
        var generation: Int = 0

        @usableFromInline
        var queue: Queue<U> = .init()

        @usableFromInline
        var continuation: CheckedContinuation<U?, Never>?

        @usableFromInline
        var outerDone: Bool = false

        @usableFromInline
        var innerActive: Bool = false

        @usableFromInline
        var cancelled: Bool = false

        @usableFromInline
        init() {}
    }
}

extension Async.Stream.Map.Flat.Latest.State {
    /// Cancels the current inner stream and starts forwarding `stream` instead.
    @usableFromInline
    func switchInner(to stream: Async.Stream<U>) {
        guard !cancelled else { return }

        innerTask?.cancel()
        generation += 1
        innerActive = true

        let current = generation
        innerTask = Task { [self] in
            for await element in stream {
                receiveInner(element, generation: current)
            }
            finishInner(generation: current)
        }
    }

    @usableFromInline
    func receiveInner(_ element: sending U, generation current: Int) {
        guard !cancelled, current == generation else { return }

        if let cont = continuation {
            continuation = nil
            cont.resume(returning: element)
        } else {
            queue.enqueue(element)
        }
    }

    @usableFromInline
    func finishInner(generation current: Int) {
        guard current == generation else { return }
        innerActive = false
        resumeIfFinished()
    }

    @usableFromInline
    func finishOuter() {
        outerDone = true
        resumeIfFinished()
    }

    @usableFromInline
    func resumeIfFinished() {
        if outerDone && !innerActive, let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }

    @usableFromInline
    func next() async -> U? {
        if !queue.isEmpty {
            guard let element = queue.dequeue() else {
                preconditionFailure("a non-empty queue dequeues an element")
            }
            return element
        }

        if cancelled || (outerDone && !innerActive) {
            return nil
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (cont: CheckedContinuation<U?, Never>) in
                registerContinuation(cont)
            }
        } onCancel: {
            Task { await self.cancel() }
        }
    }

    @usableFromInline
    func registerContinuation(_ cont: CheckedContinuation<U?, Never>) {
        if Task.isCancelled {
            cancel()
            cont.resume(returning: nil)
            return
        }
        continuation = cont
    }

    /// Ends the stream for good: cancels the inner task and resumes a waiting consumer with `nil`.
    @usableFromInline
    func cancel() {
        cancelled = true
        innerTask?.cancel()
        innerTask = nil
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }
}
