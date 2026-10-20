public import Async
public import Clock_Concurrency
public import Clock
public import Ownership

extension Async.Stream.Throttle {

    @usableFromInline
    actor State {
        @usableFromInline
        let box: Async.Stream<Element>.Iterator.Box<Async.Stream<Element>.Iterator>

        @usableFromInline
        let duration: Duration

        @usableFromInline
        var lastEmitTime: Clock.`Any`<Duration>.Instant?

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(stream: Async.Stream<Element>, duration: Duration, clock: Clock.`Any`<Duration>) {
            self.clock = clock
            self.box = Async.Stream<Element>.Iterator.Box(stream.makeAsyncIterator())
            self.duration = duration
        }
    }
}

extension Async.Stream.Throttle.State {
    @usableFromInline
    func next() async -> Element? {
        while true {
            guard let element = await box.next() else { return nil }

            let now = clock.now

            if let lastTime = lastEmitTime {
                let elapsed = lastTime.duration(to: now)
                if elapsed < duration {

                    continue
                }
            }

            lastEmitTime = now
            return element
        }
    }
}
