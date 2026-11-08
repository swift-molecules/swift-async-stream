public import Async
internal import Buffer
import Buffer
import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
internal import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Memory
internal import Memory
import Memory_Allocator
internal import Memory_Allocator
import Memory_Allocator_Pool
import Memory_Pool
import Ownership
import Ownership_Shared_Primitive
internal import Standard_Library_Extensions
import Storage
import Store


extension Async.Stream.Map.Flat.Latest.State {
    @usableFromInline
    enum Transform {
        case sync(@Sendable (Element) -> Async.Stream<U>)
        case async(@Sendable (Element) async -> Async.Stream<U>)
    }
}
