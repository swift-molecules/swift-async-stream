public import Async
public import Ownership
internal import Standard_Library_Extensions

extension Async.Stream.Sample {

    @usableFromInline
    actor State<Trigger: Sendable> {
        @usableFromInline
        var latest: Element?

        @usableFromInline
        var triggerBox: Async.Stream<Element>.Iterator.Box<Async.Stream<Trigger>.Iterator>

        @usableFromInline
        var sourceDone: Bool = false

        @usableFromInline
        init(trigger: Async.Stream<Trigger>) {
            self.triggerBox = Async.Stream<Element>.Iterator.Box(trigger.makeAsyncIterator())
        }
    }
}

extension Async.Stream.Sample.State {
    @usableFromInline
    func updateLatest(_ element: sending Element) {
        latest = element
    }

    @usableFromInline
    func markSourceDone() {
        sourceDone = true
    }

    @usableFromInline
    func next() async -> Element? {
        while true {
            guard await triggerBox.next() != nil else {
                return nil
            }

            if let value = latest {
                return value
            }

            if sourceDone {
                return nil
            }
        }
    }
}
