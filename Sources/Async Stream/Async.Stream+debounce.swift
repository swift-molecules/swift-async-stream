public import Async
internal import Clock_Concurrency

extension Async.Stream {

    public func debounce(_ duration: Duration, clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()) -> Self {
        Self { [self] in
            let state = Async.Stream<Element>.Debounce.State(stream: self, duration: duration, clock: Clock.`Any`(clock))
            return Iterator {
                await state.next()
            }
        }
    }
}
