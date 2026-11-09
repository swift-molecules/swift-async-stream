extension Async.Stream.Map.Flat.Latest {

    @usableFromInline
    actor Cursor<U: Sendable> {
        @usableFromInline
        let state: Async.Stream<Element>.Map.Flat.Latest.State<U>

        @usableFromInline
        let outerTask: Task<Void, Never>

        @usableFromInline
        init(
            base: Async.Stream<Element>,
            transform: Async.Stream<Element>.Map.Flat.Latest.State<U>.Transform
        ) {
            let state = Async.Stream<Element>.Map.Flat.Latest.State<U>()
            self.state = state
            self.outerTask = Task {
                for await element in base {
                    let inner: Async.Stream<U>
                    switch transform {
                    case .sync(let f): inner = f(element)
                    case .async(let f): inner = await f(element)
                    }
                    await state.switchInner(to: inner)
                }
                await state.finishOuter()
            }
        }

        deinit {
            outerTask.cancel()
            Task { [state] in await state.cancel() }
        }
    }
}

extension Async.Stream.Map.Flat.Latest.Cursor {
    @usableFromInline
    func next() async -> U? {
        let result = await state.next()
        if result == nil {
            outerTask.cancel()
            await state.cancel()
        }
        return result
    }
}
