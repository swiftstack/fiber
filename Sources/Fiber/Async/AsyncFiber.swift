/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

import Time
import Platform

@_exported import Async

import struct Dispatch.DispatchQoS
import class Dispatch.DispatchQueue

public struct AsyncFiber: Async {
    public init() {}

    public var loop: AsyncLoop = Loop()

    public func task(_ closure: @escaping AsyncTask) -> Void {
        fiber(closure)
    }

    public func syncTask<T>(
        onQueue queue: DispatchQueue = DispatchQueue.global(),
        qos: DispatchQoS = .background,
        deadline: Time = Time.distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        return try FiberLoop.current.syncTask(
            onQueue: queue, qos: qos, deadline: deadline, task: task)
    }

    public func wait(
        for descriptor: Descriptor,
        event: IOEvent,
        deadline: Time = Time.distantFuture
    ) throws {
        do {
            try FiberLoop.current.wait(
                for: descriptor, event: event, deadline: deadline)
        } catch let error as PollError where error == .timeout {
            throw AsyncError.timeout
        }
    }

    public func yield() {
        FiberLoop.current.scheduler.yield()
    }

    public func sleep(until deadline: Time) {
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

        public func run(until deadline: Time) {
            FiberLoop.current.run(until: deadline)
        }

        public func terminate() {
            FiberLoop.current.break()
        }
    }
}
