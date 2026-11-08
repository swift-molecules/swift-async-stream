public import Async
public import Clock_Concurrency

extension Async.Stream where Element == Int {

    public static func interval(
        _ duration: Duration,
        clock: some Clock.Nonsending<Duration> = Swift::ContinuousClock()
    ) -> Self {
        Self {
            let state = Async.Stream<Int>.Interval.State(
                duration: duration,
                clock: Clock.`Any`(clock)
            )
            return Iterator {
                await state.next()
            }
        }
    }
}
