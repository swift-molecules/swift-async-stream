public import Async
public import Clock_Concurrency
public import Ownership


extension Async.Stream.Pull {
    @usableFromInline
    enum Outcome: Sendable {
        case element(Element)
        case timerExpired
        case upstreamComplete
    }
}
