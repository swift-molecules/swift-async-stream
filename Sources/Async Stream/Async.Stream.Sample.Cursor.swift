extension Async.Stream.Sample {

    @usableFromInline
    actor Cursor<Trigger: Sendable> {
        @usableFromInline
        let state: Async.Stream<Element>.Sample.State<Trigger>

        @usableFromInline
        let sourceTask: Task<Void, Never>

        @usableFromInline
        init(state: Async.Stream<Element>.Sample.State<Trigger>, sourceTask: Task<Void, Never>) {
            self.state = state
            self.sourceTask = sourceTask
        }

        deinit {
            sourceTask.cancel()
        }
    }
}

extension Async.Stream.Sample.Cursor {
    @usableFromInline
    func next() async -> Element? {
        let result = await state.next()
        if result == nil {
            sourceTask.cancel()
        }
        return result
    }
}
