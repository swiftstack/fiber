import Async
import Platform
import Dispatch

import struct Foundation.Date

extension FiberLoop {
    public func dispatch<T>(
        qos: DispatchQoS.QoSClass = .background,
        deadline: Date = Date.distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        var result: T? = nil
        var taskError: Error? = nil

        let fd = try pipe()

        try wait(for: fd.1, event: .write, deadline: deadline)

        DispatchQueue.global(qos: qos).async {
            fiber {
                do {
                    result = try task()
                } catch {
                    taskError = error
                }
            }
            FiberLoop.current.run()
            var done: UInt8 = 1
            write(fd.1, &done, 1)
        }

        try wait(for: fd.0, event: .read, deadline: deadline)

        close(fd.0)
        close(fd.1)

        if currentFiber.pointee.state == .canceled {
            throw AsyncError.taskCanceled
        } else if let taskError = taskError {
            throw taskError
        } else if let result = result {
            return result
        } else {
            fatalError()
        }
    }

    fileprivate func pipe() throws -> (Descriptor, Descriptor) {
        var fd: (Descriptor, Descriptor) = (0, 0)
        let pointer = UnsafeMutableRawPointer(&fd)
            .assumingMemoryBound(to: Int32.self)
        guard Platform.pipe(pointer) != -1 else {
            throw SystemError()
        }
        return fd
    }
}
