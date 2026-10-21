public import Async
internal import Buffer
import Buffer
import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Memory
internal import Memory
import Memory_Allocator
internal import Memory_Allocator
import Memory_Allocator_Pool
import Memory_Pool
import Ownership_Shared_Primitive
import Storage
import Store

extension Async.Stream.Combine {

    @usableFromInline
    actor State<A: Sendable, B: Sendable> {
        @usableFromInline
        var latestA: A?

        @usableFromInline
        var latestB: B?

        @usableFromInline
        var queue: Queue<(A, B)> = .init()

        @usableFromInline
        var continuation: CheckedContinuation<(A, B)?, Never>?

        @usableFromInline
        var aComplete = false

        @usableFromInline
        var bComplete = false

        @usableFromInline
        init() {}
    }
}

extension Async.Stream.Combine.State {
    @usableFromInline
    func updateA(_ value: sending A) {
        latestA = value
        emitIfPossible()
    }

    @usableFromInline
    func updateB(_ value: sending B) {
        latestB = value
        emitIfPossible()
    }

    @usableFromInline
    func emitIfPossible() {
        guard let a = latestA, let b = latestB else { return }

        if let cont = continuation {
            continuation = nil
            cont.resume(returning: (a, b))
        } else {
            queue.enqueue((a, b))
        }
    }

    @usableFromInline
    func completeA() {
        aComplete = true
        checkComplete()
    }

    @usableFromInline
    func completeB() {
        bComplete = true
        checkComplete()
    }

    @usableFromInline
    func checkComplete() {
        if aComplete && bComplete, let cont = continuation {
            continuation = nil
            cont.resume(returning: nil)
        }
    }

    @usableFromInline
    func receive() async -> (A, B)? {
        if !queue.isEmpty {
            guard let element = queue.dequeue() else {
                preconditionFailure("a non-empty queue dequeues an element")
            }
            return element
        }

        if aComplete && bComplete {
            return nil
        }

        return await withCheckedContinuation { cont in
            continuation = cont
        }
    }
}
