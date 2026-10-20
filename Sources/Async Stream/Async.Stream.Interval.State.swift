public import Async
public import Clock_Concurrency

extension Async.Stream.Interval where Element == Int {

    @usableFromInline
    actor State {
        @usableFromInline
        let duration: Duration

        @usableFromInline
        var count: Int = 0

        @usableFromInline
        var started: Bool = false

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(duration: Duration, clock: Clock.`Any`<Duration>) {
            self.clock = clock
            self.duration = duration
        }
    }
}

extension Async.Stream.Interval.State {
    @usableFromInline
    func next() async -> Int? {
        if Task.isCancelled { return nil }

        if started {

            try? await clock.sleep(for: duration)
            if Task.isCancelled { return nil }
        }
        started = true

        defer { count += 1 }
        return count
    }
}
