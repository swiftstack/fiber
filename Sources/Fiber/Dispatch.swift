import Async
import Platform
import Dispatch

import struct Foundation.Date

extension FiberLoop {
    public func syncTask<T>(
        onQueue queue: DispatchQueue = DispatchQueue.global(),
        qos: DispatchQoS = .background,
        deadline: Date = Date.distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        var value: T? = nil
        var error: Error? = nil

        let fd = try pipe()

        let state1 = try wait(for: fd.1, event: .write, deadline: deadline)
        guard state1 == .ready else {
            throw AsyncError.taskCanceled
        }

        let workItem = DispatchWorkItem(qos: qos) {
            fiber {
                do {
                    value = try task()
                } catch let taskError {
                    error = taskError
                }
            }
            FiberLoop.current.run()
            var done: UInt8 = 1
            write(fd.1.rawValue, &done, 1)
        }

        queue.async(execute: workItem)

        defer {
            close(fd.0.rawValue)
            close(fd.1.rawValue)
        }

        let state2 = try wait(for: fd.0, event: .read, deadline: deadline)
        guard state2 == .ready else {
            throw AsyncError.taskCanceled
        }

        guard let result = value else {
            switch error {
            case .some(let error): throw error
            default: fatalError("unreachable")
            }
        }
        return result
    }

    fileprivate func pipe() throws -> (Descriptor, Descriptor) {
        var fd: (Int32, Int32) = (0, 0)
        let pointer = UnsafeMutableRawPointer(&fd)
            .assumingMemoryBound(to: Int32.self)
        guard Platform.pipe(pointer) != -1 else {
            throw SystemError()
        }
        return (Descriptor(rawValue: fd.0)!, Descriptor(rawValue: fd.1)!)
    }
}
