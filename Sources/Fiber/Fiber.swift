/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

import Log
import Time
import Async
import CCoro
import ListEntry

typealias Context = coro_context
typealias WatcherEntry = ListEntry<UnsafeMutablePointer<Fiber>>

public struct Fiber {
    public enum State {
        case none, sleep, ready, canceled, expired, cached
    }

    var id: Int
    var state: State
    var stack: Stack?
    var context = Context()

    var task: AsyncTask?

    var caller: UnsafeMutablePointer<Fiber>?

    var deadline: Time = .distantFuture
    var watcherEntry: UnsafeMutablePointer<WatcherEntry>

    init(schedulerId: Int, pointer: UnsafeMutablePointer<Fiber>) {
        self.id = schedulerId
        self.stack = nil
        self.state = .none
        self.watcherEntry = UnsafeMutablePointer<WatcherEntry>.allocate(
            payload: pointer)
    }

    init(id: Int, pointer: UnsafeMutablePointer<Fiber>) {
        self.id = id
        self.state = .none

        self.watcherEntry = UnsafeMutablePointer<WatcherEntry>.allocate(
            payload: pointer)

        self.stack = Stack.allocate()

        coro_create(&context, { _ in
            FiberLoop.current.scheduler.lifecycle()
        }, nil, stack!.pointer, stack!.size)
    }

    mutating func deallocate() {
        watcherEntry.deallocate()
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
