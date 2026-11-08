public import Async
import Clock_Concurrency
import Ownership


extension Async.Stream.Pull {
    @usableFromInline
    enum Outcome: Sendable {
        case element(Element)
        case timerExpired
        case upstreamComplete
    }
}
