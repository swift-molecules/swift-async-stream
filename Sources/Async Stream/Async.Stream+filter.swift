public import Async
internal import Ownership

extension Async.Stream {

    public func filter(
        _ predicate: @escaping @Sendable (Element) -> Bool
    ) -> Self {
        Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())
            return Iterator {
                while true {
                    guard let element = await box.next() else { return nil }
                    if predicate(element) {
                        return element
                    }
                }
            }
        }
    }

    public func filter(
        _ predicate: @escaping @Sendable (Element) async -> Bool
    ) -> Self {
        Self { [self] in
            let box = Async.Stream<Element>.Iterator.Box(makeAsyncIterator())
            return Iterator {
                while true {
                    guard let element = await box.next() else { return nil }
                    if await predicate(element) {
                        return element
                    }
                }
            }
        }
    }
}
