public import Async
internal import Buffer_Primitive
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Column
internal import Memory_Allocator_Primitive
internal import Memory_Heap
import Storage_Contiguous

extension Async.Stream.Replay {

    @usableFromInline
    actor Subscription {
        @usableFromInline
        var queue: Queue<Element>

        @usableFromInline
        var continuation: CheckedContinuation<Element?, Never>?

        @usableFromInline
        var finished: Bool

        @usableFromInline
        init(replay: sending [Element], finished: Bool) {
            self.queue = .init()
            for element in replay { self.queue.enqueue(element) }
            self.finished = finished
        }
    }
}

extension Async.Stream.Replay.Subscription {

    @usableFromInline
    func receive(_ element: sending Element) {
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: element)
        } else {
            queue.enqueue(element)
        }
    }

    @usableFromInline
    func finish() {
        finished = true
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }

    @usableFromInline
    func next() async -> Element? {
        if !queue.isEmpty {
            return queue.dequeue()!
        }

        if finished {
            return nil
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (cont: CheckedContinuation<Element?, Never>) in
                registerContinuation(cont)
            }
        } onCancel: {
            Task { await self.cancelPendingReceive() }
        }
    }

    @usableFromInline
    func registerContinuation(_ cont: CheckedContinuation<Element?, Never>) {
        if Task.isCancelled {
            finished = true
            cont.resume(returning: nil)
            return
        }
        continuation = cont
    }

    @usableFromInline
    func cancelPendingReceive() {
        finished = true
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }
}
