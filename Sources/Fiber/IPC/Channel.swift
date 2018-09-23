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

public final class Channel<T> {
    @usableFromInline var closed: Bool
    @usableFromInline var queue: [T]
    @usableFromInline var buffer: [T]
    @usableFromInline let capacity: Int
    @usableFromInline var readers: [UnsafeMutablePointer<Fiber>]
    @usableFromInline var writers: [UnsafeMutablePointer<Fiber>]

    public init(capacity: Int = 0) {
        self.closed = false
        self.queue = []
        self.buffer = []
        self.readers = []
        self.writers = []
        self.capacity = max(0, capacity)

        if capacity > 0 {
            buffer.reserveCapacity(capacity)
        }
    }

    deinit {
        close()
    }

    public var isEmpty: Bool {
        return buffer.count == 0
    }

    public var canRead: Bool {
        return buffer.count > 0 || hasWriters
    }

    public var canWrite: Bool {
        return buffer.count < capacity || hasReaders
    }

    public var hasReaders: Bool {
        return readers.count > 0
    }

    public var hasWriters: Bool {
        return writers.count > 0
    }

    @usableFromInline
    var this: UnsafeMutablePointer<Fiber> {
        return FiberLoop.current.scheduler.running
    }

    @usableFromInline
    @inline(__always)
    func schedule(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .ready)
    }

    @usableFromInline
    @inline(__always)
    func cancel(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .canceled)
    }

    @inlinable
    @discardableResult
    public func write(_ value: T) -> Bool {
        guard !closed else {
            return false
        }

        if hasReaders {
            queue.append(value)
            schedule(readers.removeFirst())
        } else {
            buffer.append(value)
        }

        guard buffer.count <= capacity else {
            writers.append(this)
            let state = suspend()
            return state == .ready
        }

        return true
    }

    @inlinable
    public func read() -> T? {
        guard !closed else {
            return nil
        }

        if hasWriters {
            schedule(writers.removeFirst())
        }

        guard isEmpty else {
            return buffer.removeFirst()
        }

        readers.append(this)
        let state = suspend()
        guard state == .ready else {
            return nil
        }

        assert(queue.count > 0)
        return queue.removeFirst()
    }

    public func close() {
        guard !closed else {
            return
        }
        closed = true
        readers.forEach(cancel)
        writers.forEach(cancel)
        buffer.removeAll(keepingCapacity: false)
        readers.removeAll(keepingCapacity: false)
        writers.removeAll(keepingCapacity: false)
    }
}
