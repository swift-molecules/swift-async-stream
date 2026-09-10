import Async_Stream
import Testing

@Suite
struct `Async stream erasure preserves its nonthrowing failure behavior` {
    private enum Error: Swift.Error {
        case upstream
    }

    @Test
    func `Erasing a throwing upstream sequence ends iteration when it fails`() async {
        let source = AsyncThrowingStream<Int, any Swift.Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: Error.upstream)
        }
        let stream = Async.Stream(source)
        var values: [Int] = []

        for await value in stream {
            values.append(value)
        }

        #expect(values == [1])
    }
}
