import Async
import Foundation

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
