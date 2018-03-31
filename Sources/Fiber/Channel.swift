public final class Channel<T> {
    @_versioned var closed: Bool
    @_versioned var queue: [T]
    @_versioned var buffer: [T]
    @_versioned let capacity: Int
    @_versioned var readers: [UnsafeMutablePointer<Fiber>]
    @_versioned var writers: [UnsafeMutablePointer<Fiber>]

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

    @_versioned
    var this: UnsafeMutablePointer<Fiber> {
        return FiberLoop.current.scheduler.running
    }

    @_versioned
    @inline(__always)
    func sleep() -> Fiber.State {
        return FiberLoop.current.scheduler.sleep()
    }

    @_versioned
    @inline(__always)
    func schedule(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .ready)
    }

    @_versioned
    @inline(__always)
    func cancel(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .canceled)
    }

    @_inlineable
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
            let state = sleep()
            return state == .ready
        }

        return true
    }

    @_inlineable
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
        let state = sleep()
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
