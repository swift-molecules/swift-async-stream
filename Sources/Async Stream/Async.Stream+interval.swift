public import Async
internal import Clock_Concurrency

extension Async.Stream where Element == Int {

    public static func interval(_ duration: Duration, clock: some _Concurrency.Clock<Duration> = Swift::ContinuousClock()) -> Self {
        Self {
            let state = Async.Stream<Int>.Interval.State(duration: duration, clock: Clock.`Any`(clock))
            return Iterator {
                await state.next()
            }
        }
    }
}
