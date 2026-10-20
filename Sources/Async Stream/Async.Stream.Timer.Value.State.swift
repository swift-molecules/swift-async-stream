public import Async
public import Clock_Concurrency

extension Async.Stream.Timer.Value {

    @usableFromInline
    actor State {
        @usableFromInline
        let delay: Duration

        @usableFromInline
        let value: Element

        @usableFromInline
        var fired: Bool = false

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(delay: Duration, value: sending Element, clock: Clock.`Any`<Duration>) {
            self.clock = clock
            self.delay = delay
            self.value = value
        }
    }
}

extension Async.Stream.Timer.Value.State {
    @usableFromInline
    func next() async -> Element? {
        if fired { return nil }
        if Task.isCancelled { return nil }

        try? await clock.sleep(for: delay)
        if Task.isCancelled { return nil }

        fired = true
        return value
    }
}
