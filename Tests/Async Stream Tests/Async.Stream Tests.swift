import Async_Stream
import Async
import Testing

@Suite
struct `Async streams preserve values across composed operations` {
    @Suite struct `Stream operations preserve their basic behavior` {}
    @Suite struct `Stream operations preserve boundary behavior` {}
    @Suite struct `Stream operations compose with their dependencies` {}
    @Suite(.serialized) struct `Stream operations preserve values during repeated execution` {}
}

extension `Async streams preserve values across composed operations`.`Stream operations preserve their basic behavior` {

    @Test
    func `From creates stream from sequence`() async {
        let stream = Async.Stream.from([1, 2, 3])
        var results: [Int] = []

        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3])
    }

    @Test
    func `Just emits single value`() async {
        let stream = Async.Stream.just(42)
        var results: [Int] = []

        for await value in stream {
            results.append(value)
        }

        #expect(results == [42])
    }

    @Test
    func `An empty stream completes immediately`() async {
        let stream = Async.Stream<Int>.empty
        var count = 0

        for await _ in stream {
            count += 1
        }

        #expect(count == 0)
    }

    @Test
    func `Unfold generates from state`() async {
        let fib = Async.Stream.unfold((0, 1)) { state -> (Int, (Int, Int))? in
            let value = state.0
            if value > 5 { return nil }
            return (value, (state.1, state.0 + state.1))
        }

        var results: [Int] = []
        for await value in fib {
            results.append(value)
        }

        #expect(results == [0, 1, 1, 2, 3, 5])
    }

    @Test
    func `Stream mapping transforms every element`() async {
        let stream = Async.Stream.from([1, 2, 3])
            .map { $0 * 2 }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [2, 4, 6])
    }

    @Test
    func `Stream filtering removes rejected elements`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5])
            .filter { $0 % 2 == 0 }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [2, 4])
    }

    @Test
    func `CompactMap transforms and filters`() async {
        let stream = Async.Stream.from(["1", "two", "3"])
            .map.compact { Int($0) }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 3])
    }

    @Test
    func `FlatMap concatenates inner streams`() async {
        let stream = Async.Stream.from([1, 2, 3])
            .map.flat { n in
                Async.Stream.from([n, n * 10])
            }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 10, 2, 20, 3, 30])
    }

    @Test
    func `Stream scanning accumulates successive values`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5])
            .scan(0) { $0 + $1 }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 3, 6, 10, 15])
    }

    @Test
    func `Reduce to single value`() async {
        let sum = await Async.Stream.from([1, 2, 3, 4, 5])
            .reduce(0) { $0 + $1 }

        #expect(sum == 15)
    }

    @Test
    func `Stream concatenation joins its inputs in order`() async {
        let a = Async.Stream.from([1, 2])
        let b = Async.Stream.from([3, 4])
        let stream = Async.Stream.concat(a, b)

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3, 4])
    }

    @Test
    func `Stream zipping pairs corresponding elements`() async {
        let a = Async.Stream.from([1, 2, 3])
        let b = Async.Stream.from(["a", "b", "c"])
        let stream = a.zip(b)

        var results: [(Int, String)] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results.count == 3)
        #expect(results[0].0 == 1 && results[0].1 == "a")
        #expect(results[1].0 == 2 && results[1].1 == "b")
        #expect(results[2].0 == 3 && results[2].1 == "c")
    }

    @Test
    func `Prefix takes first N elements`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).prefix(3)

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3])
    }

    @Test
    func `Prefix while takes until predicate fails`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).prefix.while { $0 < 4 }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3])
    }

    @Test
    func `Drop skips first N elements`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).drop(2)

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [3, 4, 5])
    }

    @Test
    func `Drop while skips until predicate fails`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).drop.while { $0 < 3 }

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [3, 4, 5])
    }

    @Test
    func `First returns only first element`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).first()

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1])
    }

    @Test
    func `Last returns only last element`() async {
        let stream = Async.Stream.from([1, 2, 3, 4, 5]).last()

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [5])
    }

    @Test
    func `DistinctUntilChanged removes consecutive duplicates`() async {
        let stream = Async.Stream.from([1, 1, 2, 2, 2, 3, 1, 1]).distinct.untilChanged()

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3, 1])
    }

    @Test
    func `Distinct stream values are compared by their selected key`() async {
        let stream = Async.Stream.from([1, -1, 2, -2, 3])
            .distinct.untilChanged(by: { abs($0) })

        var results: [Int] = []
        for await value in stream {
            results.append(value)
        }

        #expect(results == [1, 2, 3])
    }
}
