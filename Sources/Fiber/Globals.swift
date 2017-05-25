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

@inline(__always)
public func fiber(_ task: @escaping AsyncTask) {
    FiberLoop.current.scheduler.async(task)
}

@inline(__always)
public func yield() {
    FiberLoop.current.scheduler.yield()
}

@inline(__always)
public func sleep(until deadline: Date) {
    FiberLoop.current.wait(for: deadline)
}

@inline(__always)
public func now() -> Date {
    return FiberLoop.current.now
}

/// Spawn DispatchQueue.global().async task and yield until it's done
@inline(__always)
public func syncTask<T>(
    qos: DispatchQoS.QoSClass = .background,
    deadline: Date = Date.distantFuture,
    task: @escaping () throws -> T
) throws -> T {
    return try FiberLoop.current.syncTask(
        qos: qos,
        deadline: deadline,
        task: task)
}
