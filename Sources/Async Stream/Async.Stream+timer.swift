public import Async
internal import Clock_Concurrency

extension Async.Stream {

    public static func timer(
        after delay: Duration,
        clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()
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
        clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()
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
