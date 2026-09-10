public import Async
internal import Buffer
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Column
internal import Memory_Allocator
internal import Memory
import Storage_Memory

extension Async.Stream.Merge {

    @usableFromInline
    actor State {
        @usableFromInline
        var queue: Queue<Element> = .init()

        @usableFromInline
        var continuation: CheckedContinuation<Element?, Never>?

        @usableFromInline
        var completed = 0

        @usableFromInline
        var cancelled = false

        @usableFromInline
        let streamCount = 2

        @usableFromInline
        init() {}
    }
}

extension Async.Stream.Merge.State {
    @usableFromInline
    func send(_ element: sending Element) {
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: element)
        } else {
            queue.enqueue(element)
        }
    }

    @usableFromInline
    func complete() {
        completed += 1
        if completed >= streamCount, let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }

    @usableFromInline
    func receive() async -> Element? {
        if !queue.isEmpty {
            return queue.dequeue()!
        }

        if cancelled || completed >= streamCount {
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
            cancelled = true
            cont.resume(returning: nil)
            return
        }
        continuation = cont
    }

    @usableFromInline
    func cancelPendingReceive() {
        cancelled = true
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }
}
