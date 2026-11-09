public import Async
internal import Standard_Library_Extensions

extension Async.Stream {

    public struct Combine: Sendable {
        @usableFromInline
        let base: Async.Stream<Element>

        @usableFromInline
        init(base: Async.Stream<Element>) {
            self.base = base
        }
    }
}

extension Async.Stream {

    public var combine: Combine { Combine(base: self) }
}

extension Async.Stream.Combine {

    public func latest<Other: Sendable>(
        _ other: Async.Stream<Other>
    ) -> Async.Stream<(Element, Other)> {
        Async.Stream<(Element, Other)> { [base] in
            let state = Async.Stream<(Element, Other)>.Combine.State<Element, Other>()

            let task1 = Task {
                await state.run { state in
                    for await element in base {
                        state.updateA(element)
                    }
                    state.completeA()
                }
            }

            let task2 = Task {
                await state.run { state in
                    for await element in other {
                        state.updateB(element)
                    }
                    state.completeB()
                }
            }

            let cursor = Async.Stream<(Element, Other)>.Combine.Cursor(
                state: state,
                task1: task1,
                task2: task2
            )

            return Async.Stream<(Element, Other)>.Iterator {
                await cursor.next()
            }
        }
    }
}
