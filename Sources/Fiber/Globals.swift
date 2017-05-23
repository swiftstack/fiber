import Async

import struct Foundation.Date
import struct Dispatch.DispatchQoS

public func fiber(_ task: @escaping AsyncTask) {
    FiberLoop.current.scheduler.async(task)
}

public func yield() {
    FiberLoop.current.scheduler.yield()
}

public func sleep(until deadline: Date) {
    FiberLoop.current.wait(for: deadline)
}

public func now() -> Date {
    return FiberLoop.current.now
}

/// Spawn DispatchQueue.global().async task and yield until it's done
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
