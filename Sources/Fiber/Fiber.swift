import Log
import Async
import CCoro
import Foundation

typealias Context = coro_context

struct Stack {
    let pointer: UnsafeMutableRawBufferPointer
}

extension Stack {
    private static let defaultSize = 64 * 1024

    static func allocate() -> Stack {
        return Stack(pointer: UnsafeMutableRawBufferPointer.allocate(
            count: defaultSize))
    }

    func deallocate() {
        pointer.deallocate()
    }
}

public struct Fiber {
    enum State {
        case none, sleep, ready, canceled, expired, cached
    }

    var id: Int
    var state: State
    var stack: Stack?
    var context = Context()

    var task: AsyncTask?

    var caller: UnsafeMutablePointer<Fiber>?

    init(schedulerId: Int) {
        self.id = schedulerId
        self.stack = nil
        self.state = .none
    }

    init(id: Int) {
        self.id = id
        self.state = .none

        // TODO: inject allocator
        self.stack = Stack.allocate()

        coro_create(&context, { _ in
            FiberLoop.current.scheduler.lifecycle()
        }, nil, stack!.pointer.baseAddress, stack!.pointer.count)
    }

    mutating func deallocateStack() {
        if let stack = stack {
            stack.deallocate()
            self.stack = nil
        }
    }

    mutating func transfer(from fiber: UnsafeMutablePointer<Fiber>) {
        coro_transfer(&fiber.pointee.context, &context)
    }

    mutating func yield(to fiber: UnsafeMutablePointer<Fiber>) {
        coro_transfer(&context, &fiber.pointee.context)
    }
}
