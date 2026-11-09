public import Async
public import Ownership
internal import Standard_Library_Extensions

extension Async.Stream.Latest {

    @usableFromInline
    actor State<Other: Sendable> {
        @usableFromInline
        var latestOther: Other?

        @usableFromInline
        var sourceBox: Async.Stream<Element>.Iterator.Box<Async.Stream<Element>.Iterator>

        @usableFromInline
        init(source: Async.Stream<Element>) {
            self.sourceBox = Async.Stream<Element>.Iterator.Box(source.makeAsyncIterator())
        }
    }
}

extension Async.Stream.Latest.State {
    @usableFromInline
    func updateLatestOther(_ element: sending Other) {
        latestOther = element
    }

    @usableFromInline
    func next() async -> (Element, Other)? {
        while true {
            guard let element = await sourceBox.next() else {
                return nil
            }

            if let other = latestOther {
                return (element, other)
            }
        }
    }
}
