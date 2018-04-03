/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Log
import Time
import Async
import Platform
import ListEntry

import class Foundation.Thread

extension FiberLoop {
    struct Watchers {
        var read: UnsafeMutablePointer<Fiber>?
        var write: UnsafeMutablePointer<Fiber>?
    }
}

extension FiberLoop.Watchers {
    var isActive: Bool {
        @inline(__always) get {
            return read != nil || write != nil
        }
    }
}

public class FiberLoop {
    var poller = Poller()
    var watchers: UnsafeMutableBufferPointer<Watchers>
    var activeWatchers: UnsafeMutablePointer<WatcherEntry>

    @usableFromInline
    var scheduler = FiberScheduler()

    var currentFiber: UnsafeMutablePointer<Fiber> {
        @inline (__always) get {
            return scheduler.running
        }
    }

    public private(set) static var main = FiberLoop()
    private static var _current = ThreadSpecific<FiberLoop>()
    public class var current: FiberLoop {
        if Thread.isMain {
            return main
        }
        return FiberLoop._current.get() {
            return FiberLoop()
        }
    }

    var deadline = Time.distantFuture

    var nextDeadline: Time {
        if scheduler.hasReady {
            return now
        }
        assert(!activeWatchers.isEmpty)
        return activeWatchers.first!.pointee.payload.pointee.deadline
    }

    public init() {
        watchers = UnsafeMutableBufferPointer.allocate(
            repeating: Watchers(),
            count: Descriptor.maxLimit)

        activeWatchers = UnsafeMutablePointer.allocate(
            payload: scheduler.running)
    }

    deinit {
        watchers.deallocate()
        activeWatchers.deallocate()
    }

    var readyCount = 0

    @usableFromInline
    var now = Time()

    var canceled = false
    public var isCanceled: Bool {
        return canceled
    }

    var running = false
    public func run(until deadline: Time = .distantFuture) {
        guard !self.running else {
            return
        }
        self.running = true
        self.deadline = deadline

        while !canceled {
            do {
                guard now < deadline else {
                    break
                }

                guard activeWatchers.count > 0 || scheduler.hasReady else {
                    Log.debug("No fiber to schedule, shutting down.")
                    break
                }

                let events = try poller.poll(deadline: nextDeadline)
                now = Time()

                scheduleReady(events)
                scheduleExpired()
                runScheduled()
            } catch {
                Log.error("poll error \(error)")
            }
        }

        scheduler.cancelReady()
        wakeupSuspended()
        runScheduled()
        self.running = false
        self.canceled = false
    }

    public func `break`() {
        canceled = true
    }

    func wakeupSuspended() {
        for watcher in activeWatchers.pointee {
            scheduler.schedule(fiber: watcher.pointee.payload, state: .canceled)
        }
    }

    func scheduleReady(_ events: ArraySlice<Event>) {
        for event in events {
            let index = Int(event.descriptor.rawValue)

            guard watchers[index].isActive else {
                // kqueue error on closed descriptor
                if event.isError {
                    Log.error("event error: \(SystemError())")
                    return
                }
                fatalError("defunct descriptor \(event.descriptor)")
            }

            if event.typeOptions.contains(.read),
                let fiber = watchers[index].read {
                scheduler.schedule(fiber: fiber, state: .ready)
            }

            if event.typeOptions.contains(.write),
                let fiber = watchers[index].write {
                scheduler.schedule(fiber: fiber, state: .ready)
            }
        }
    }

    func scheduleExpired() {
        for watcher in activeWatchers.pointee {
            let fiber = watcher.pointee.payload
            guard fiber.pointee.deadline <= now else {
                break
            }
            scheduler.schedule(fiber: fiber, state: .expired)
        }
    }

    func runScheduled() {
        if scheduler.hasReady {
            scheduler.runReadyChain()
        }
    }

    @discardableResult
    public func wait(for deadline: Time) -> Fiber.State {
        insertWatcher(deadline: deadline)
        scheduler.suspend()
        removeWatcher()
        return currentFiber.pointee.state
    }

    @discardableResult
    public func wait(
        for socket: Descriptor,
        event: IOEvent,
        deadline: Time) throws -> Fiber.State
    {
        try insertWatcher(for: socket, event: event, deadline: deadline)
        scheduler.suspend()
        removeWatcher(for: socket, event: event)
        if currentFiber.pointee.state == .expired {
            throw PollError.timeout
        }
        return currentFiber.pointee.state
    }

    func insertWatcher(
        for descriptor: Descriptor,
        event: IOEvent,
        deadline: Time
    ) throws {
        let fd = Int(descriptor.rawValue)

        switch event {
        case .read:
            guard watchers[fd].read == nil else {
                throw PollError.alreadyInUse
            }
            watchers[fd].read = currentFiber
        case .write:
            guard watchers[fd].write == nil else {
                throw PollError.alreadyInUse
            }
            watchers[fd].write = currentFiber
        }

        insertWatcher(deadline: deadline)
        poller.add(socket: descriptor, event: event)
    }

    func removeWatcher(for descriptor: Descriptor, event: IOEvent) {
        let fd = Int(descriptor.rawValue)

        switch event {
        case .read: watchers[fd].read = nil
        case .write: watchers[fd].write = nil
        }

        removeWatcher()
        poller.remove(socket: descriptor, event: event)
    }

    func insertWatcher(deadline: Time) {
        currentFiber.pointee.deadline = deadline
        if activeWatchers.isEmpty || deadline >= activeWatchers.maxDeadline! {
            activeWatchers.append(currentFiber.pointee.watcherEntry)
        } else if deadline < activeWatchers.minDeadline! {
            activeWatchers.insert(currentFiber.pointee.watcherEntry)
        } else {
            for watcher in activeWatchers.pointee {
                if deadline < watcher.pointee.payload.pointee.deadline {
                    watcher.insert(currentFiber.pointee.watcherEntry)
                    return
                }
            }
            fatalError("unreachable")
        }
    }

    func removeWatcher() {
        currentFiber.pointee.watcherEntry.remove()
    }
}

extension UnsafeMutableBufferPointer where Element == FiberLoop.Watchers {
    typealias Watchers = FiberLoop.Watchers

    static func allocate(
        repeating element: Watchers, count: Int
    ) -> UnsafeMutableBufferPointer<Watchers> {
        let pointer = UnsafeMutablePointer<Watchers>.allocate(capacity: count)
        pointer.initialize(repeating: element, count: count)

        return UnsafeMutableBufferPointer(
            start: pointer,
            count: Descriptor.maxLimit)
    }
}

extension UnsafeMutablePointer
where Pointee == ListEntry<UnsafeMutablePointer<Fiber>> {
    var minDeadline: Time? {
        return first?.payload.pointee.deadline
    }

    var maxDeadline: Time? {
        return last?.payload.pointee.deadline
    }
}

extension FiberLoop: Equatable {
    public static func ==(lhs: FiberLoop, rhs: FiberLoop) -> Bool {
        return lhs.poller == rhs.poller
    }
}
