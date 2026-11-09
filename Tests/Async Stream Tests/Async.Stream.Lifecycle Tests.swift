import Async
import Async_Stream
import Testing

private actor `Lifecycle Flag` {
    private(set) var isSet = false
}

extension `Lifecycle Flag` {

    func set() {
        isSet = true
    }
}

extension `Lifecycle Flag` {

    func waitUntilSet(attempts: Int = 100_000) async -> Bool {
        for _ in 0..<attempts {
            if isSet { return true }
            await Task.yield()
        }
        return isSet
    }
}

private func withDeadline<T: Sendable>(
    _ deadline: Duration = .seconds(15),
    _ operation: @escaping @Sendable () async -> T
) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await operation() }
        group.addTask {
            try? await Task.sleep(for: deadline)
            return nil
        }
        let first = await group.next()!
        group.cancelAll()
        return first
    }
}

extension `Async.Stream Tests`.`Async streams preserve values across composed operations`
    .`Stream operations preserve boundary behavior`
{

    @Test(.timeLimit(.minutes(2)))
    func `Merge resumes a suspended consumer instead of hanging when its task is cancelled`()
        async throws
    {

        let (rawA, _) = AsyncStream<Int>.makeStream()
        let (rawB, _) = AsyncStream<Int>.makeStream()
        let merged = Async.Stream.merge(Async.Stream(rawA), Async.Stream(rawB))

        let consumer = Task {
            for await _ in merged {}
        }

        for _ in 0..<1_000 { await Task.yield() }
        consumer.cancel()

        let finished: Void? = await withDeadline { await consumer.value }
        #expect(finished != nil)
    }

    @Test(.timeLimit(.minutes(2)))
    func `Replay resumes a suspended consumer instead of hanging when its task is cancelled`()
        async throws
    {

        let (raw, _) = AsyncStream<Int>.makeStream()
        let replayed = Async.Stream(raw).replay(bufferSize: 4)

        let consumer = Task {
            for await _ in replayed {}
        }

        for _ in 0..<1_000 { await Task.yield() }
        consumer.cancel()

        let finished: Void? = await withDeadline { await consumer.value }
        #expect(finished != nil)
    }

    @Test(.timeLimit(.minutes(2)))
    func `Merge cancels both producer tasks when its iterator is dropped without exhausting`()
        async throws
    {
        let flagA = `Lifecycle Flag`()
        let flagB = `Lifecycle Flag`()

        let (rawA, continuationA) = AsyncStream<Int>.makeStream()
        continuationA.onTermination = { _ in Task { await flagA.set() } }
        let (rawB, continuationB) = AsyncStream<Int>.makeStream()
        continuationB.onTermination = { _ in Task { await flagB.set() } }

        do {
            let merged = Async.Stream.merge(Async.Stream(rawA), Async.Stream(rawB))
            continuationA.yield(1)
            let iterator = merged.makeAsyncIterator()
            _ = await iterator.next()

        }

        let sawA = await flagA.waitUntilSet()
        let sawB = await flagB.waitUntilSet()

        #expect(sawA)
        #expect(sawB)
    }

    @Test(.timeLimit(.minutes(2)))
    func `FlatMapLatest switches to the newest inner stream and cancels the previous one`()
        async throws
    {
        let flag = `Lifecycle Flag`()
        let (rawOuter, outer) = AsyncStream<Int>.makeStream()
        let (rawFirst, first) = AsyncStream<Int>.makeStream()
        first.onTermination = { _ in Task { await flag.set() } }
        first.yield(1)

        let stream = Async.Stream(rawOuter).map.flat.latest { n in
            n == 1 ? Async.Stream(rawFirst) : Async.Stream.from([n, n * 10])
        }
        let iterator = stream.makeAsyncIterator()

        outer.yield(1)
        let head = await withDeadline { await iterator.next() }
        outer.yield(2)
        outer.finish()

        let rest: [Int]? = await withDeadline {
            var results: [Int] = []
            while let value = await iterator.next() { results.append(value) }
            return results
        }

        #expect(head == 1)
        #expect(rest == [2, 20])
        #expect(await flag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `FlatMapLatest keeps going when an inner stream ends while the outer stream has more`()
        async throws
    {
        let (rawOuter, outer) = AsyncStream<Int>.makeStream()
        let (rawFirst, first) = AsyncStream<Int>.makeStream()
        first.yield(1)

        let stream = Async.Stream(rawOuter).map.flat.latest { n in
            n == 1 ? Async.Stream(rawFirst) : Async.Stream.from([n])
        }
        let iterator = stream.makeAsyncIterator()

        outer.yield(1)
        let head = await withDeadline { await iterator.next() }

        let waiting = Task { await iterator.next() }
        for _ in 0..<1_000 { await Task.yield() }
        first.finish()
        for _ in 0..<1_000 { await Task.yield() }
        outer.yield(2)
        outer.finish()

        let second = await withDeadline { await waiting.value }
        let end = await withDeadline { await iterator.next() }

        #expect(head == 1)
        #expect(second == 2)
        #expect(end == .some(nil))
    }

    @Test(.timeLimit(.minutes(2)))
    func `FlatMapLatest cancels the outer and inner tasks when its iterator is dropped`()
        async throws
    {
        let outerFlag = `Lifecycle Flag`()
        let innerFlag = `Lifecycle Flag`()
        let (rawOuter, outer) = AsyncStream<Int>.makeStream()
        outer.onTermination = { _ in Task { await outerFlag.set() } }
        let (rawInner, inner) = AsyncStream<Int>.makeStream()
        inner.onTermination = { _ in Task { await innerFlag.set() } }

        do {
            let stream = Async.Stream(rawOuter).map.flat.latest { _ in Async.Stream(rawInner) }
            outer.yield(1)
            inner.yield(1)
            let iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
        }

        #expect(await outerFlag.waitUntilSet())
        #expect(await innerFlag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `CombineLatest resumes a suspended consumer instead of hanging when its task is cancelled`()
        async throws
    {
        let (rawA, _) = AsyncStream<Int>.makeStream()
        let (rawB, _) = AsyncStream<Int>.makeStream()
        let combined = Async.Stream(rawA).combine.latest(Async.Stream(rawB))

        let consumer = Task {
            for await _ in combined {}
        }

        for _ in 0..<1_000 { await Task.yield() }
        consumer.cancel()

        let finished: Void? = await withDeadline { await consumer.value }
        #expect(finished != nil)
    }

    @Test(.timeLimit(.minutes(2)))
    func `CombineLatest cancels both producer tasks when its iterator is dropped without exhausting`()
        async throws
    {
        let flagA = `Lifecycle Flag`()
        let flagB = `Lifecycle Flag`()

        let (rawA, continuationA) = AsyncStream<Int>.makeStream()
        continuationA.onTermination = { _ in Task { await flagA.set() } }
        let (rawB, continuationB) = AsyncStream<Int>.makeStream()
        continuationB.onTermination = { _ in Task { await flagB.set() } }

        do {
            let combined = Async.Stream(rawA).combine.latest(Async.Stream(rawB))
            continuationA.yield(1)
            continuationB.yield(2)
            let iterator = combined.makeAsyncIterator()
            _ = await iterator.next()
        }

        #expect(await flagA.waitUntilSet())
        #expect(await flagB.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `Latest from cancels draining the other stream when its iterator is dropped`()
        async throws
    {
        let flag = `Lifecycle Flag`()
        let (rawSource, _) = AsyncStream<Int>.makeStream()
        let (rawOther, other) = AsyncStream<Int>.makeStream()
        other.onTermination = { _ in Task { await flag.set() } }

        do {
            let stream = Async.Stream(rawSource).latest.from(Async.Stream(rawOther))
            _ = stream.makeAsyncIterator()
        }

        #expect(await flag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `Sample cancels draining the source stream when its iterator is dropped`()
        async throws
    {
        let flag = `Lifecycle Flag`()
        let (rawSource, source) = AsyncStream<Int>.makeStream()
        source.onTermination = { _ in Task { await flag.set() } }
        let (rawTrigger, _) = AsyncStream<Int>.makeStream()

        do {
            let stream = Async.Stream(rawSource).sample.on(Async.Stream(rawTrigger))
            _ = stream.makeAsyncIterator()
        }

        #expect(await flag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `Share cancels upstream forwarding once the shared stream is totally abandoned`()
        async throws
    {
        let flag = `Lifecycle Flag`()
        let (raw, continuation) = AsyncStream<Int>.makeStream()
        continuation.onTermination = { _ in Task { await flag.set() } }

        do {
            let shared = Async.Stream(raw).share()
            continuation.yield(1)
            let iterator = shared.makeAsyncIterator()
            _ = await iterator.next()

        }

        #expect(await flag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `Replay cancels upstream forwarding once the replay stream is totally abandoned`()
        async throws
    {
        let flag = `Lifecycle Flag`()
        let (raw, continuation) = AsyncStream<Int>.makeStream()
        continuation.onTermination = { _ in Task { await flag.set() } }

        do {
            let replayed = Async.Stream(raw).replay(bufferSize: 4)
            continuation.yield(1)
            let iterator = replayed.makeAsyncIterator()
            _ = await iterator.next()

        }

        #expect(await flag.waitUntilSet())
    }

    @Test(.timeLimit(.minutes(2)))
    func `Replay subscription count returns to zero after N consumers churn through`() async throws {
        let (replayed, subscriptionCount) = Async.Stream.from([1, 2, 3, 4, 5]).replayForTesting(
            bufferSize: 4
        )

        for _ in 0..<10 {
            let iterator = replayed.makeAsyncIterator()
            _ = await iterator.next()

        }

        var finalCount = -1
        for _ in 0..<100_000 {
            finalCount = await subscriptionCount()
            if finalCount == 0 { break }
            await Task.yield()
        }

        #expect(finalCount == 0)
    }

    @Test(.timeLimit(.minutes(2)))
    func `Replay preserves per-subscriber delivery order under contention`() async throws {
        let count = 500
        let upstream = Async.Stream.from(Array(0..<count))
        let replayed = upstream.replay(bufferSize: 8)

        var results: [Int] = []
        for await value in replayed {
            results.append(value)
        }

        #expect(results == Array(0..<count))
    }

    @Test(.timeLimit(.minutes(2)))
    func `Replay delivers a fast pre-subscribed burst in strict send order with no drops`()
        async throws
    {
        let elementCount = 2_000
        let trialCount = 5

        for trial in 0..<trialCount {
            let (raw, continuation) = AsyncStream<Int>.makeStream()

            let (replayed, subscriptionCount) = Async.Stream(raw).replayForTesting(
                bufferSize: elementCount
            )

            let consumer = Task<[Int], Never> {
                var results: [Int] = []
                results.reserveCapacity(elementCount)
                for await value in replayed {
                    results.append(value)
                }
                return results
            }

            for _ in 0..<100_000 {
                if await subscriptionCount() >= 1 { break }
                await Task.yield()
            }

            (0..<elementCount).forEach { value in
                continuation.yield(value)
            }
            continuation.finish()

            let results = await withDeadline(.seconds(60)) { await consumer.value }
            let expected = Array(0..<elementCount)

            if let results {
                let firstBad = (0..<Swift::min(results.count, expected.count)).first {
                    results[$0] != expected[$0]
                }
                let detail =
                    firstBad.map {
                        " (first divergence @\($0): \(results[$0]) != \(expected[$0]))"
                    }
                    ?? " (length mismatch)"
                let message =
                    "trial \(trial): got \(results.count)/\(expected.count) elements" + detail
                #expect(results == expected, Comment(rawValue: message))
            } else {
                #expect(
                    Bool(false),
                    Comment(rawValue: "trial \(trial): consumer did not finish within the deadline")
                )
            }
        }
    }
}
