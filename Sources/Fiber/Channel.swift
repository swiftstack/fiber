/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

public final class Channel<T> {
    var closed: Bool
    var queue: [T]
    var buffer: [T]
    let capacity: Int
    var readers: [UnsafeMutablePointer<Fiber>]
    var writers: [UnsafeMutablePointer<Fiber>]

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

    @inline(__always)
    fileprivate func waitForReader() -> Fiber.State {
        writers.append(FiberLoop.current.scheduler.running)
        FiberLoop.current.scheduler.sleep()
        return FiberLoop.current.scheduler.running.pointee.state
    }

    @inline(__always)
    fileprivate func waitForWriter() -> Fiber.State {
        readers.append(FiberLoop.current.scheduler.running)
        FiberLoop.current.scheduler.sleep()
        return FiberLoop.current.scheduler.running.pointee.state
    }

    @inline(__always)
    fileprivate func schedule(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .ready)
    }

    @inline(__always)
    fileprivate func cancel(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .canceled)
    }

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
            return waitForReader() == .ready
        }

        return true
    }

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

        guard waitForWriter() == .ready else {
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
