import Time

import struct Dispatch.DispatchQoS
import class Dispatch.DispatchQueue

@inline(__always)
public func fiber(_ task: @escaping Fiber.Task) {
    Scheduler.current.async(task)
}

@inline(__always)
@discardableResult
public func yield() -> Fiber.State {
    return Scheduler.current.yield()
}

@inline(__always)
@discardableResult
public func suspend() -> Fiber.State {
    return FiberLoop.current.scheduler.suspend()
}

@inline(__always)
@discardableResult
public func sleep(until deadline: Time) -> Fiber.State {
    return FiberLoop.current.wait(for: deadline)
}

@inline(__always)
public func now() -> Time {
    return FiberLoop.current.now
}

/// Spawn DispatchQueue.global().async task and yield until it's done
@inline(__always)
public func syncTask<T>(
    onQueue queue: DispatchQueue = DispatchQueue.global(),
    qos: DispatchQoS = .background,
    deadline: Time = .distantFuture,
    task: @escaping () throws -> T
) throws -> T {
    return try FiberLoop.current.syncTask(
        qos: qos,
        deadline: deadline,
        task: task)
}
