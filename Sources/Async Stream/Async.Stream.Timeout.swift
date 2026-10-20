public import Async
internal import Clock_Concurrency
internal import Ownership

extension Async.Stream {

    public func timeout(_ duration: Duration, clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()) -> Self {
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
