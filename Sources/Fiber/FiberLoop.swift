import Log
import Async
import Platform
import Foundation

enum PollError: Error {
    case alreadyInUse
    case doesNotExist
}

struct Watcher {
    let fiber: UnsafeMutablePointer<Fiber>
    let deadline: Deadline
}

extension Watcher: Equatable {
    public static func ==(lhs: Watcher, rhs: Watcher) -> Bool {
        return lhs.fiber == rhs.fiber
    }
}

struct WatchersPair {
    var read: Watcher?
    var write: Watcher?
}

public struct EventError: Error, CustomStringConvertible {
    public let number = errno
    public let description = String(cString: strerror(errno))
}

extension FiberLoop: Equatable {
    public static func ==(lhs: FiberLoop, rhs: FiberLoop) -> Bool {
        return lhs.poller == rhs.poller
    }
}

extension Thread {
    var isMain: Bool {
        return true
    }
}

public class FiberLoop {
    var poller: Poller
    var watchers: [WatchersPair]
    var activeWatchers: [Watcher]

    @_versioned
    var scheduler: FiberScheduler

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

    var deadline = Deadline.distantFuture

    var nextDeadline: Deadline {
        if scheduler.hasReady {
            return now
        }

        precondition(activeWatchers.count > 0)

        var deadline = Date.distantFuture
        for watcher in activeWatchers {
            deadline = min(deadline, watcher.deadline)
        }
        return deadline
    }

    public init() {
        scheduler = FiberScheduler()
        poller = Poller()

        watchers = [WatchersPair](repeating: WatchersPair(), count: Descriptor.maxLimit)
        activeWatchers = []
    }

    var readyCount = 0

    @_versioned
    var now = Date()

    var canceled = false
    public var isCanceled: Bool {
        return canceled
    }

    var running = false
    public func run(until deadline: Date = Date.distantFuture) {
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
                now = Date()

                scheduleReady(events)
                scheduleExpired()
                runScheduled()
            } catch {
                Log.error("poll error \(error)")
            }
        }

        wakeupSuspended()
        self.running = false
        self.canceled = false
    }

    public func `break`() {
        canceled = true
    }

    func wakeupSuspended() {
        for watcher in activeWatchers {
            scheduler.schedule(fiber: watcher.fiber, state: .canceled)
        }
        runScheduled()
    }

    func scheduleReady(_ events: ArraySlice<Event>) {
        for event in events {
            let index = Int(event.descriptor)

            guard watchers[index].read != nil || watchers[index].write != nil else {
                // kqueue error on closed descriptor
                if event.isError {
                    Log.error("event \(EventError())")
                    return
                }
                // shouldn't happen
                Log.critical("zombie descriptor \(event.descriptor) event (\"\\(O.o)/\") booooo!")
                abort()
            }

            if event.typeOptions.contains(.read),
                let watcher = watchers[index].read {
                scheduler.schedule(fiber: watcher.fiber, state: .ready)
            }

            if event.typeOptions.contains(.write),
                let watcher = watchers[index].write {
                scheduler.schedule(fiber: watcher.fiber, state: .ready)
            }
        }
    }

    func scheduleExpired() {
        for watcher in activeWatchers {
            if watcher.deadline <= now {
                scheduler.schedule(fiber: watcher.fiber, state: .expired)
            }
        }
    }

    func runScheduled() {
        if scheduler.hasReady {
            scheduler.runReadyChain()
        }
    }

    public func wait(for deadline: Deadline) {
        let watcher = Watcher(fiber: currentFiber, deadline: deadline)
        activeWatchers.append(watcher)
        scheduler.sleep()
        activeWatchers.remove(watcher)
    }

    public func wait(for socket: Descriptor, event: IOEvent, deadline: Deadline) throws {
        let watcher = Watcher(fiber: currentFiber, deadline: deadline)
        try add(watcher, for: socket, event: event)
        scheduler.sleep()
        remove(watcher, for: socket, event: event)
    }

    func add(_ watcher: Watcher, for descriptor: Descriptor, event: IOEvent) throws {
        let fd = Int(descriptor)

        switch event {
        case .read:
            guard watchers[fd].read == nil else {
                throw PollError.alreadyInUse
            }
            watchers[fd].read = watcher
            activeWatchers.append(watcher)
        case .write:
            guard watchers[fd].write == nil else {
                throw PollError.alreadyInUse
            }
            watchers[fd].write = watcher
            activeWatchers.append(watcher)
        }

        poller.add(socket: descriptor, event: event)
    }

    func remove(_ watcher: Watcher, for descriptor: Descriptor, event: IOEvent) {
        let fd = Int(descriptor)

        switch event {
        case .read:
            watchers[fd].read = nil
            activeWatchers.remove(watcher)

        case .write:
            watchers[fd].write = nil
            activeWatchers.remove(watcher)
        }

        poller.remove(socket: descriptor, event: event)
    }
}

extension Array where Element : Equatable {
    @inline(__always)
    @discardableResult
    mutating func remove(_ element: Element) -> Bool {
        guard let index = self.index(of: element) else {
            return false
        }
        self.remove(at: index)
        return true
    }
}
