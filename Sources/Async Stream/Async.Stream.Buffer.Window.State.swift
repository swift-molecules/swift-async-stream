public import Async
internal import Buffer
import Buffer
import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
public import Clock_Concurrency
import Memory
internal import Memory
import Memory_Allocator
internal import Memory_Allocator
import Memory_Allocator_Pool
import Memory_Pool
import Ownership_Shared_Primitive
import Storage
import Store

extension Async.Stream.Buffer.Window {

    @usableFromInline
    actor State {
        @usableFromInline
        let pull: Async.Stream<Element>.Pull

        @usableFromInline
        let count: Int

        @usableFromInline
        let duration: Duration

        @usableFromInline
        var queue: Queue<Element> = .init()

        @usableFromInline
        var elementCount: Int = 0

        @usableFromInline
        var upstreamDone: Bool = false

        @usableFromInline
        let clock: Clock.`Any`<Duration>

        @usableFromInline
        init(
            stream: Async.Stream<Element>,
            count: Int,
            duration: Duration,
            clock: Clock.`Any`<Duration>
        ) {
            self.clock = clock
            self.pull = Async.Stream<Element>.Pull(
                box: Async.Stream<Element>.Iterator.Box(stream.makeAsyncIterator())
            )
            self.count = max(1, count)
            self.duration = duration
        }
    }
}

extension Async.Stream.Buffer.Window.State {
    @usableFromInline
    func next() async -> [Element]? {
        let resolvedClock = clock
        if upstreamDone && queue.isEmpty {
            return nil
        }

        var deadline = resolvedClock.now.advanced(by: duration)

        while true {

            if elementCount >= count {
                var result: [Element] = []
                for _ in 0..<count {
                    guard let element = queue.dequeue() else { break }
                    result.append(element)
                }
                elementCount -= result.count
                return result
            }

            if upstreamDone {
                if !queue.isEmpty {
                    var result: [Element] = []
                    queue.drain { result.append($0) }
                    elementCount = 0
                    return result
                }
                return nil
            }

            let now = resolvedClock.now
            let remaining = now.duration(to: deadline)
            if remaining <= .zero {

                var result: [Element] = []
                queue.drain { result.append($0) }
                elementCount = 0
                if result.isEmpty {
                    // A window passed with no element. Start a fresh window
                    // instead of looping on the expired deadline without
                    // ever awaiting the upstream again.
                    deadline = now.advanced(by: duration)
                    continue
                }
                return result
            }

            let result = await pull.next(until: deadline, clock: resolvedClock)

            switch result {
            case .element(let element):
                queue.enqueue(element)
                elementCount += 1

            case .timerExpired:
                if !queue.isEmpty {
                    var result: [Element] = []
                    queue.drain { result.append($0) }
                    elementCount = 0
                    return result
                }

            case .upstreamComplete:
                upstreamDone = true
            }
        }
    }
}
