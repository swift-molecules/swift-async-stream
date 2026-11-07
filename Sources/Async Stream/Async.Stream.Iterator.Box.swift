public import Async
public import Ownership

extension Async.Stream.Iterator {

    public typealias Box<I: AsyncIteratorProtocol> = Ownership.Mutable<I>.Unchecked
}
