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

    mutating func deallocate() {
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
