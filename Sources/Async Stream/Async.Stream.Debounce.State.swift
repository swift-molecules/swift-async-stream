public import Async
public import Clock_Concurrency

extension Async.Stream.Debounce {

    @usableFromInline
    actor State {
        @usableFromInline
        let pull: Async.Stream<Element>.Pull

        @usableFromInline
        let duration: Duration

        @usableFromInline
        var pending: Element?

        @usableFromInline
        var upstreamDone: Bool = false

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(stream: Async.Stream<Element>, duration: Duration, clock: Clock.`Any`<Duration>) {
            self.clock = clock
            self.pull = Async.Stream<Element>.Pull(
                box: Async.Stream<Element>.Iterator.Box(stream.makeAsyncIterator())
            )
            self.duration = duration
        }
    }
}

extension Async.Stream.Debounce.State {
    @usableFromInline
    func next() async -> Element? {
        let resolvedClock = clock
        if upstreamDone {

            if let element = pending {
                pending = nil
                return element
            }
            return nil
        }

        while true {

            let deadline = pending == nil ? nil : resolvedClock.now.advanced(by: duration)
            let result = await pull.next(until: deadline, clock: resolvedClock)

            switch result {
            case .element(let element):

                pending = element
                continue

            case .timerExpired:

                if let element = pending {
                    pending = nil
                    return element
                }
                continue

            case .upstreamComplete:
                upstreamDone = true

                if let element = pending {
                    pending = nil
                    return element
                }
                return nil
            }
        }
    }
}
