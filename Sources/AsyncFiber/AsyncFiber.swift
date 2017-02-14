import Async
import Fiber
import Foundation

public struct AsyncFiber: Async {
    public struct Loop: AsyncLoop {
        public func run() {
            FiberLoop.current.run()
        }

        public func run(until date: Date) {
            FiberLoop.current.run(until: date)
        }
    }

    public struct Awaiter: IOAwaiter {
        public init() {}

        public func wait(for descriptor: Descriptor, event: IOEvent) throws {
            try FiberLoop.current.wait(for: descriptor, event: event, deadline: Date.distantFuture)
        }
    }

    public init() {}
    public var loop: AsyncLoop = Loop()
    public var task: (@escaping AsyncTask) -> Void = fiber
    public var awaiter: IOAwaiter? = Awaiter()
}
