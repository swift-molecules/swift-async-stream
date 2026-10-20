public import Async
public import Clock_Concurrency

extension Async.Stream.Timer where Element == Void {

    @usableFromInline
    actor State {
        @usableFromInline
        let delay: Duration

        @usableFromInline
        var fired: Bool = false

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(delay: Duration, clock: Clock.`Any`<Duration>) {
            self.clock = clock
            self.delay = delay
        }
    }
}

extension Async.Stream.Timer.State where Element == Void {
    @usableFromInline
    func next() async -> Void? {
        if fired { return nil }
        if Task.isCancelled { return nil }

        try? await clock.sleep(for: delay)
        if Task.isCancelled { return nil }

        fired = true
        return ()
    }
}
