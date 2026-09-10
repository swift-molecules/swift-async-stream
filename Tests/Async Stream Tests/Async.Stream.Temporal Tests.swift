import Async_Stream
import Async
import Clocks_Dependencies
import Testing

extension `Async streams preserve values across composed operations`.`Stream operations preserve their basic behavior` {

    @Test
    func `Delay preserves all elements`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream.from([1, 2, 3]).delay(.seconds(1))
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [1, 2, 3])
        }
    }

    @Test
    func `Delay preserves element order`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream.from([5, 4, 3, 2, 1]).delay(.milliseconds(100))
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [5, 4, 3, 2, 1])
        }
    }

    @Test
    func `Delay on empty stream completes immediately`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Int>.empty.delay(.seconds(1))
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 0)
        }
    }

    @Test
    func `Interval emits sequential integers`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Int>.interval(.seconds(1)).prefix(5)
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [0, 1, 2, 3, 4])
        }
    }

    @Test
    func `Interval starts at zero`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Int>.interval(.milliseconds(100)).prefix(1)
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [0])
        }
    }

    @Test
    func `Timer emits once then completes`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Void>.timer(after: .seconds(5))
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 1)
        }
    }

    @Test
    func `Timer with value emits value once`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Swift.String>.timer(after: .seconds(1), value: "hello")
            var results: [Swift.String] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == ["hello"])
        }
    }

    @Test
    func `Throttle emits first and suppresses rapid followers`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {

            let stream = Async.Stream.from([1, 2, 3, 4, 5]).throttle(.seconds(1))
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [1])
        }
    }

    @Test
    func `Throttle on single element emits it`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream.from([42]).throttle(.seconds(1))
            var results: [Int] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == [42])
        }
    }

    @Test
    func `Throttle on empty stream completes`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Int>.empty.throttle(.seconds(1))
            var count = 0
            for await _ in stream {
                count += 1
            }
            #expect(count == 0)
        }
    }

    @Test
    func `Repeating with interval emits value N times`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Swift.String>.repeating("ping", every: .seconds(1), count: 3)
            var results: [Swift.String] = []
            for await value in stream {
                results.append(value)
            }
            #expect(results == ["ping", "ping", "ping"])
        }
    }

    @Test
    func `Repeating with interval and zero count emits nothing`() async {
        await withDependencies {
            $0.clock = Clock.`Any`(Clock.Immediate())
        } operation: {
            let stream = Async.Stream<Swift.String>.repeating("ping", every: .seconds(1), count: 0)
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
