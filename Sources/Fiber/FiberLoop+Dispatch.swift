import Time
import Platform
import Dispatch

extension FiberLoop {
    enum Result<T> {
        case success(T)
        case error(Swift.Error)
    }

    public func syncTask<T>(
        onQueue queue: DispatchQueue = DispatchQueue.global(),
        qos: DispatchQoS = .background,
        deadline: Time = .distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        let fd = try pipe()

        guard try wait(for: fd.1, event: .write, deadline: deadline) == .ready
        else { throw Error.canceled }

        var result: Result<T>?

        let workItem = DispatchWorkItem(qos: qos) {
            fiber {
                do { result = .success(try task()) }
                catch { result = .error(error) }
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

        guard try wait(for: fd.0, event: .read, deadline: deadline) == .ready
        else { throw Error.canceled }

        switch result {
        case .some(.success(let result)): return result
        case .some(.error(let error)): throw error
        default: throw Error.canceled
        }
    }

    fileprivate func pipe() throws -> (Descriptor, Descriptor) {
        var fd: (Int32, Int32) = (0, 0)
        try withUnsafeMutablePointer(to: &fd) { pointer in
            try pointer.withMemoryRebound(to: Int32.self, capacity: 2) {
                guard Platform.pipe($0) != -1 else {
                    throw SystemError()
                }
            }
        }
        return (Descriptor(rawValue: fd.0)!, Descriptor(rawValue: fd.1)!)
    }
}
