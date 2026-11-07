public import Async
internal import Ownership
import _Concurrency
public import Clock_Concurrency

extension Async {

    public struct Stream<Element: Sendable>: AsyncSequence, Sendable {
        public typealias AsyncIterator = Iterator

        @usableFromInline
        let _makeIterator: @Sendable () -> Iterator

        @inlinable
        public init(_ makeIterator: @escaping @Sendable () -> Iterator) {
            self._makeIterator = makeIterator
        }
    }
}

extension Async.Stream {

    public init<S: AsyncSequence & Sendable>(_ sequence: S) where S.Element == Element {
        self.init {

            let box = Async.Stream<Element>.Iterator.Box(sequence.makeAsyncIterator())
            return Iterator {
                await box.next()
            }
        }
    }
}

extension Async.Stream {
    @inlinable
    public func makeAsyncIterator() -> Iterator {
        _makeIterator()
    }
}

extension Async.Stream {

    public static var empty: Self {
        Self { Iterator { nil } }
    }

    public static var never: Self {
        Self {
            Iterator {

                try? await Task.sleep(for: .seconds(Int64.max))
                return nil
            }
        }
    }

    public static func just(_ value: Element) -> Self {
        from([value])
    }

    public static func from<S: Swift::Sequence & Sendable>(_ sequence: S) -> Self
    where S.Element == Element {
        Self {
            let state = State(Array(sequence))
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public func debounce(
        _ duration: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        Self { [self] in
            let state = Async.Stream<Element>.Debounce.State(
                stream: self,
                duration: duration,
                clock: Clock.`Any`(clock)
            )
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public func filter(
        _ predicate: @escaping @Sendable (Element) -> Bool
    ) -> Self {
        Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())
            return Iterator {
                while true {
                    guard let element = await box.next() else { return nil }
                    if predicate(element) {
                        return element
                    }
                }
            }
        }
    }

    public func filter(
        _ predicate: @escaping @Sendable (Element) async -> Bool
    ) -> Self {
        Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())
            return Iterator {
                while true {
                    guard let element = await box.next() else { return nil }
                    if await predicate(element) {
                        return element
                    }
                }
            }
        }
    }
}

extension Async.Stream {

    public func first() -> Self {
        prefix(1)
    }

    public func first(
        where predicate: @escaping @Sendable (Element) -> Bool
    ) -> Self {
        filter(predicate).first()
    }
}

extension Async.Stream {

    public func last() -> Self {
        Self { [self] in
            let state = Async.Stream<Element>.Last.State(stream: self)
            return Iterator {
                await state.next()
            }
        }
    }

    public func last(
        where predicate: @escaping @Sendable (Element) -> Bool
    ) -> Self {
        filter(predicate).last()
    }
}

extension Async.Stream {

    public func reduce<Result: Sendable>(
        _ initial: Result,
        _ accumulator: @escaping @Sendable (Result, Element) -> Result
    ) async -> Result {
        var result = initial
        for await element in self {
            result = accumulator(result, element)
        }
        return result
    }
}

extension Async.Stream {

    public static func repeating(_ value: Element, count: Int? = nil) -> Self {
        Self {
            let state = Async.Stream<Element>.Repeat.State(value: value, count: count)
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public static func repeating(
        _ value: Element,
        every interval: Duration,
        count: Int? = nil,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        Self {
            let state = Async.Stream<Element>.Repeat.Interval.State(
                value: value,
                interval: interval,
                count: count,
                clock: Clock.`Any`(clock)
            )
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public func scan<Result: Sendable>(
        _ initial: sending Result,
        _ accumulator: @escaping @Sendable (Result, Element) -> Result
    ) -> Async.Stream<Result> {
        let captured = initial
        return Async.Stream<Result> { [self] in
            let state = Async.Stream<Element>.Scan.State(
                stream: self,
                initial: captured,
                accumulator: accumulator
            )
            return Async.Stream<Result>.Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public func throttle(
        _ duration: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        Self { [self] in
            let state = Async.Stream<Element>.Throttle.State(
                stream: self,
                duration: duration,
                clock: Clock.`Any`(clock)
            )
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public static func timer(
        after delay: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self where Element == Void {
        Self {
            let state = Async.Stream<Void>.Timer.State(delay: delay, clock: Clock.`Any`(clock))
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public static func timer(
        after delay: Duration,
        value: Element,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        Self {
            let state = Async.Stream<Element>.Timer.Value.State(
                delay: delay,
                value: value,
                clock: Clock.`Any`(clock)
            )
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public static func unfold<State: Sendable>(
        _ initial: sending State,
        _ next: @escaping @Sendable (State) async -> (Element, State)?
    ) -> Self {
        let captured = initial
        return Self {
            let state = Async.Stream<Element>.Unfold.State(initial: captured, next: next)
            return Iterator {
                await state.next()
            }
        }
    }
}

extension Async.Stream {

    public static func generate(
        _ generator: @escaping @Sendable () async -> Element?
    ) -> Self {
        Self {
            Iterator {
                if Task.isCancelled { return nil }
                return await generator()
            }
        }
    }
}

extension Async.Stream {

    public func delay(
        _ duration: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        let clock = Clock.`Any`(clock)
        return Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())
            return Iterator {
                guard let element = await box.next() else { return nil }

                try? await clock.sleep(for: duration)
                if Task.isCancelled { return nil }
                return element
            }
        }
    }
}

extension Async.Stream {

    public func timeout(
        _ duration: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        let clock = Clock.`Any`(clock)
        return Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())

            return Iterator {
                let resolvedClock = clock
                do {
                    return try await withThrowingTaskGroup(of: Element?.self) { group in
                        group.addTask {
                            await box.next()
                        }
                        group.addTask {
                            try await resolvedClock.sleep(
                                until: resolvedClock.now.advanced(by: duration)
                            )
                            throw CancellationError()
                        }

                        if let result = try await group.next() {
                            group.cancelAll()
                            return result
                        }

                        return nil
                    }
                } catch {

                    return nil
                }
            }
        }
    }
}
