public import Async

extension Async.Stream.Debounce {

    @usableFromInline
    enum Event: Sendable {
        case element(Element)
        case timerExpired
        case upstreamComplete
    }
}
