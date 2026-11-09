extension Async.Stream.Combine {

    @usableFromInline
    actor Cursor<A: Sendable, B: Sendable> {
        @usableFromInline
        let state: Async.Stream<Element>.Combine.State<A, B>

        @usableFromInline
        let task1: Task<Void, Never>

        @usableFromInline
        let task2: Task<Void, Never>

        @usableFromInline
        init(
            state: Async.Stream<Element>.Combine.State<A, B>,
            task1: Task<Void, Never>,
            task2: Task<Void, Never>
        ) {
            self.state = state
            self.task1 = task1
            self.task2 = task2
        }

        deinit {
            task1.cancel()
            task2.cancel()
        }
    }
}

extension Async.Stream.Combine.Cursor {
    @usableFromInline
    func next() async -> (A, B)? {
        let result = await state.receive()
        if result == nil {
            task1.cancel()
            task2.cancel()
        }
        return result
    }
}
