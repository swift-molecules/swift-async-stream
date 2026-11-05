public import Async
internal import Buffer
internal import Buffer_Linear_Bounded_Primitive
internal import Buffer_Linear_Primitive
internal import Buffer_Ring_Bounded_Primitive
internal import Buffer_Ring_Primitive
public import Clock_Concurrency
internal import Memory
internal import Memory_Allocator
internal import Memory_Allocator_Pool
internal import Memory_Pool
internal import Ownership_Shared_Primitive
internal import Storage
internal import Store

extension Async.Stream.Buffer.Time {

    @usableFromInline
    actor State {
        @usableFromInline
        let pull: Async.Stream<Element>.Pull

        @usableFromInline
        let duration: Duration

        @usableFromInline
        var queue: Queue<Element> = .init()

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

extension Async.Stream.Buffer.Time.State {
    @usableFromInline
    func next() async -> [Element]? {
        let resolvedClock = clock
        if upstreamDone {
            return nil
        }

        let deadline = resolvedClock.now.advanced(by: duration)

        while true {
            let now = resolvedClock.now
            let remaining = now.duration(to: deadline)
            if remaining <= .zero {

                var result: [Element] = []
                queue.drain { result.append($0) }
                if result.isEmpty && upstreamDone {
                    return nil
                }
                return result
            }

            let result = await pull.next(until: deadline, clock: resolvedClock)

            switch result {
            case .element(let element):
                queue.enqueue(element)

            case .timerExpired:
                var result: [Element] = []
                queue.drain { result.append($0) }
                return result

            case .upstreamComplete:
                upstreamDone = true
                if !queue.isEmpty {
                    var result: [Element] = []
                    queue.drain { result.append($0) }
                    return result
                }
                return nil
            }
        }
    }
}
