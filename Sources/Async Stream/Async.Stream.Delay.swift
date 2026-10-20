public import Async
internal import Clock_Concurrency
internal import Ownership

extension Async.Stream {

    public func delay(
        _ duration: Duration,
        clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()
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
