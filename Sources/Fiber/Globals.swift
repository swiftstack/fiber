/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Async

import struct Foundation.Date
import struct Dispatch.DispatchQoS
import class Dispatch.DispatchQueue

@inline(__always)
public func fiber(_ task: @escaping AsyncTask) {
    FiberLoop.current.scheduler.async(task)
}

@inline(__always)
@discardableResult
public func yield() -> Fiber.State {
    return FiberLoop.current.scheduler.yield()
}

@inline(__always)
@discardableResult
public func suspend() -> Fiber.State {
    return FiberLoop.current.scheduler.suspend()
}

@inline(__always)
@discardableResult
public func sleep(until deadline: Date) -> Fiber.State {
    return FiberLoop.current.wait(for: deadline)
}

@inline(__always)
public func now() -> Date {
    return FiberLoop.current.now
}

/// Spawn DispatchQueue.global().async task and yield until it's done
@inline(__always)
public func syncTask<T>(
    onQueue queue: DispatchQueue = DispatchQueue.global(),
    qos: DispatchQoS = .background,
    deadline: Date = Date.distantFuture,
    task: @escaping () throws -> T
) throws -> T {
    return try FiberLoop.current.syncTask(
        qos: qos,
        deadline: deadline,
        task: task)
}
