extension Async.Stream.Latest {

    @usableFromInline
    actor Cursor<Other: Sendable> {
        @usableFromInline
        let state: Async.Stream<Element>.Latest.State<Other>

        @usableFromInline
        let otherTask: Task<Void, Never>

        @usableFromInline
        init(state: Async.Stream<Element>.Latest.State<Other>, otherTask: Task<Void, Never>) {
            self.state = state
            self.otherTask = otherTask
        }

        deinit {
            otherTask.cancel()
        }
    }
}

extension Async.Stream.Latest.Cursor {
    @usableFromInline
    func next() async -> (Element, Other)? {
        let result = await state.next()
        if result == nil {
            otherTask.cancel()
        }
        return result
    }
}
