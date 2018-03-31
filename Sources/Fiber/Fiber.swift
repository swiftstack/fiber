/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Log
import Time
import Async
import CCoro
import ListEntry
import Foundation

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
