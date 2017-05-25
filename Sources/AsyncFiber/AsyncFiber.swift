/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Fiber

@_exported import Async

import struct Foundation.Date
import struct Dispatch.DispatchQoS

public struct AsyncFiber: Async {
    public init() {}

    public var loop: AsyncLoop = Loop()
    public var awaiter: IOAwaiter? = Awaiter()

    public func task(_ closure: @escaping AsyncTask) -> Void {
        fiber(closure)
    }

    public func syncTask<T>(
        qos: DispatchQoS.QoSClass = .background,
        deadline: Date = Date.distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        return try dispatch(qos: qos, deadline: deadline, task: task)
    }

    public func sleep(until deadline: Date) {
        FiberLoop.current.wait(for: deadline)
    }

    public func testCancel() throws {
        yield()
        // TODO: Fiber.current.isCanceled
        if FiberLoop.current.isCanceled {
            throw AsyncError.taskCanceled
        }
    }
}

extension AsyncFiber {
    public struct Loop: AsyncLoop {
        public func run() {
            FiberLoop.current.run()
        }

        public func run(until date: Date) {
            FiberLoop.current.run(until: date)
        }
    }
}

extension AsyncFiber {
    public struct Awaiter: IOAwaiter {
        public init() {}

        public func wait(
            for descriptor: Descriptor,
            event: IOEvent,
            deadline: Date = Date.distantFuture
        ) throws {
            try FiberLoop.current.wait(
                for: descriptor,
                event: event,
                deadline: deadline)
        }
    }
}
