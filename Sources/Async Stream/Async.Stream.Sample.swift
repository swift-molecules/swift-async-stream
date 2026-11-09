public import Async

extension Async.Stream {

    public var sample: Sample { Sample(base: self) }

    public struct Sample: Sendable {
        @usableFromInline
        let base: Async.Stream<Element>

        @usableFromInline
        init(base: Async.Stream<Element>) {
            self.base = base
        }
    }
}

extension Async.Stream.Sample {

    public func on<Trigger: Sendable>(
        _ trigger: Async.Stream<Trigger>
    ) -> Async.Stream<Element> {
        Async.Stream<Element> { [base] in
            let state = Async.Stream<Element>.Sample.State<Trigger>(trigger: trigger)
            let sourceTask = Task {
                for await element in base {
                    await state.updateLatest(element)
                }
                await state.markSourceDone()
            }
            let cursor = Async.Stream<Element>.Sample.Cursor(state: state, sourceTask: sourceTask)
            return Async.Stream<Element>.Iterator {
                await cursor.next()
            }
        }
    }
}
