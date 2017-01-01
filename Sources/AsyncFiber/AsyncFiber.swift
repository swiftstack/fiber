import Async
import Fiber
import Foundation

public struct Loop: AsyncLoop {
    public func run() {
        FiberLoop.current.run()
    }
}

public struct AsyncFiber: Async {
    public init() {}

    public var loop: AsyncLoop = Loop()

    public var task: (@escaping AsyncTask) -> Void = fiber

    public var awaiter: IOAwaiter? = FiberAwaiter()
}

public struct FiberAwaiter: IOAwaiter {
    public init() {}

    public func wait(for descriptor: Descriptor, event: IOEvent) throws {
        try FiberLoop.current.wait(for: descriptor, event: event, deadline: Date.distantFuture)
    }
}
