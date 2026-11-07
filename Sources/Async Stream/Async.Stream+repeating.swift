public import Async
public import Clock_Concurrency

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
