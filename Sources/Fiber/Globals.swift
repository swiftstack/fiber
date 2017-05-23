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
public func dispatch<T>(
    qos: DispatchQoS.QoSClass = .background,
    deadline: Date = Date.distantFuture,
    task: @escaping () throws -> T
) throws -> T {
    return try FiberLoop.current.dispatch(
        qos: qos,
        deadline: deadline,
        task: task)
}
