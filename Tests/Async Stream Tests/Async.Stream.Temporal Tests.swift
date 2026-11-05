import Async
import Async_Stream
import Clock_Concurrency
import Testing

extension `Async streams preserve values across composed operations`
    .`Stream operations preserve their basic behavior`
{

    @Test
    func `Delay preserves all elements`() async {
        do {
            let stream = Async.Stream.from([1, 2, 3]).delay(.seconds(1), clock: Clock.Immediate())
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [1, 2, 3])
        }
    }

    @Test
    func `Delay preserves element order`() async {
        do {
            let stream = Async.Stream.from([5, 4, 3, 2, 1]).delay(
                .milliseconds(100),
                clock: Clock.Immediate()
            )
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [5, 4, 3, 2, 1])
        }
    }

    @Test
    func `Delay on empty stream completes immediately`() async {
        do {
            let stream = Async.Stream<Int>.empty.delay(.seconds(1), clock: Clock.Immediate())
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 0)
        }
    }

    @Test
    func `Interval emits sequential integers`() async {
        do {
            let stream = Async.Stream<Int>.interval(.seconds(1), clock: Clock.Immediate()).prefix(5)
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [0, 1, 2, 3, 4])
        }
    }

    @Test
    func `Interval starts at zero`() async {
        do {
            let stream = Async.Stream<Int>.interval(.milliseconds(100), clock: Clock.Immediate())
                .prefix(1)
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [0])
        }
    }

    @Test
    func `Timer emits once then completes`() async {
        do {
            let stream = Async.Stream<Void>.timer(after: .seconds(5), clock: Clock.Immediate())
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 1)
        }
    }

    @Test
    func `Timer with value emits value once`() async {
        do {
            let stream = Async.Stream<Swift::String>.timer(
                after: .seconds(1),
                value: "hello",
                clock: Clock.Immediate()
            )
            var results: [Swift::String] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == ["hello"])
        }
    }

    @Test
    func `Throttle emits first and suppresses rapid followers`() async {
        do {

            let stream = Async.Stream.from([1, 2, 3, 4, 5]).throttle(
                .seconds(1),
                clock: Clock.Immediate()
            )
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [1])
        }
    }

    @Test
    func `Throttle on single element emits it`() async {
        do {
            let stream = Async.Stream.from([42]).throttle(.seconds(1), clock: Clock.Immediate())
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [42])
        }
    }

    @Test
    func `Throttle on empty stream completes`() async {
        do {
            let stream = Async.Stream<Int>.empty.throttle(.seconds(1), clock: Clock.Immediate())
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 0)
        }
    }

    @Test
    func `Repeating with interval emits value N times`() async {
        do {
            let stream = Async.Stream<Swift::String>.repeating(
                "ping",
                every: .seconds(1),
                count: 3,
                clock: Clock.Immediate()
            )
            var results: [Swift::String] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == ["ping", "ping", "ping"])
        }
    }

    @Test
    func `Repeating with interval and zero count emits nothing`() async {
        do {
            let stream = Async.Stream<Swift::String>.repeating(
                "ping",
                every: .seconds(1),
                count: 0,
                clock: Clock.Immediate()
            )
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 0)
        }
    }

    @Test
    func `Repeating emits value N times`() async {
        let stream = Async.Stream.repeating(42, count: 4)
        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }
        #expect(results == [42, 42, 42, 42])
    }

    @Test
    func `Repeating with zero count emits nothing`() async {
        let stream = Async.Stream.repeating(42, count: 0)
        var count = 0
        for await _ in stream {
            count += 1
        }
        #expect(count == 0)
    }
}

/// Runs `operation` in an unstructured task and returns its result, or nil
/// when `limit` passes first. The operation is not awaited after the limit,
/// so a stream that spins or hangs fails the test instead of hanging it.
private func temporalResult<T: Sendable>(
    within limit: Duration = .seconds(10),
    _ operation: @escaping @Sendable () async -> T
) async -> T? {
    let (results, continuation) = AsyncStream<T?>.makeStream()
    let worker = Task {
        continuation.yield(await operation())
    }
    let timer = Task {
        try? await Task.sleep(for: limit)
        continuation.yield(nil)
    }
    var iterator = results.makeAsyncIterator()
    let first = await iterator.next() ?? nil
    worker.cancel()
    timer.cancel()
    continuation.finish()
    return first
}

extension `Async streams preserve values across composed operations`
    .`Stream operations preserve boundary behavior`
{

    @Test(.timeLimit(.minutes(1)))
    func `Buffer window keeps pulling after a window passes with no element`() async {
        let batches = await temporalResult {
            let (raw, continuation) = AsyncStream<Int>.makeStream()
            let producer = Task {
                try? await Task.sleep(for: .milliseconds(200))
                continuation.yield(1)
                continuation.finish()
            }
            var batches: [[Int]] = []
            for await batch in Async.Stream(raw).buffer.window(count: 10, time: .milliseconds(20)) {
                batches.append(batch)
            }
            await producer.value
            return batches
        }
        #expect(batches != nil)
    }
}
