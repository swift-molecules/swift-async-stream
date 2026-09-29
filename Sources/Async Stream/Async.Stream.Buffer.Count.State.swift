public import Async
public import Buffer
public import Buffer_Ring_Bounded_Primitive
public import Buffer_Ring_Primitive
internal import Buffer_Ring
internal import Cardinal
public import Memory
public import Memory_Allocator
public import Storage

public import Ownership

extension Async.Stream.Buffer.Count {

    @usableFromInline
    actor State {
        @usableFromInline
        let box: Async.Stream<Element>.Iterator.Box<Async.Stream<Element>.Iterator>

        @usableFromInline
        let count: Index<Element>.Count

        @usableFromInline
        var ring: Buffer::Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded

        @usableFromInline
        init(stream: Async.Stream<Element>, count: Int) {

            let typedCount = try! Index<Element>.Count(max(1, count))
            self.box = Async.Stream<Element>.Iterator.Box(stream.makeAsyncIterator())
            self.count = typedCount
            self.ring = Buffer::Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded(minimumCapacity: typedCount)
        }
    }
}

extension Async.Stream.Buffer.Count.State {
    @usableFromInline
    func next() async -> [Element]? {
        while true {
            guard let element = await box.next() else {

                if ring.count > .zero {
                    var result: [Element] = []
                    ring.drain { result.append($0) }
                    return result
                }
                return nil
            }

            ring.push.back(element)

            if ring.count >= count {
                var result: [Element] = []
                ring.drain { result.append($0) }
                return result
            }
        }
    }
}
