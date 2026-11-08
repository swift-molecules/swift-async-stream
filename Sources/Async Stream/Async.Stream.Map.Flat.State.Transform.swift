public import Async
public import Ownership


extension Async.Stream.Map.Flat.State {
    @usableFromInline
    enum Transform {
        case sync(@Sendable (Element) -> Async.Stream<U>)
        case async(@Sendable (Element) async -> Async.Stream<U>)
    }
}
