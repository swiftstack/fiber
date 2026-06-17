import Event
import Platform
import ListEntry

public final class FiberLoop {
    var poller = Poller()
    var watchers: UnsafeMutableBufferPointer<Watchers>
    var sleeping: UnsafeMutablePointer<WatcherEntry>

    struct Watchers {
        var read: UnsafeMutablePointer<Fiber>?
        var write: UnsafeMutablePointer<Fiber>?

        var isEmpty: Bool { read == nil && write == nil }
    }

    @usableFromInline
    var scheduler = Scheduler.current

    var currentFiber: UnsafeMutablePointer<Fiber> {
        @inline(always) get {
            return scheduler.running
        }
    }

    nonisolated(unsafe) public private(set) static var main = FiberLoop()
    nonisolated(unsafe) private static var _current = ThreadSpecific<FiberLoop>()

    public class var current: FiberLoop {
        Thread.isMain
            ? main
            : FiberLoop._current.get(defaultValue: .init())
    }

    var deadline: Instant = .distantFuture

    var nextDeadline: Instant {
        if scheduler.hasReady {
            return now
        }
        assert(!sleeping.isEmpty)
        return sleeping.first!.pointee.payload.pointee.deadline
    }

    public init() {
        watchers = UnsafeMutableBufferPointer.allocate(
            repeating: Watchers(),
            count: Descriptor.maxLimit)

        sleeping = UnsafeMutablePointer.allocate(
            payload: scheduler.running)
    }

    deinit {
        watchers.deallocate()
        sleeping.deallocate()
    }

    var readyCount = 0

    @usableFromInline
    var now: Instant = .now

    var canceled = false
    public var isCanceled: Bool {
        return canceled
    }

    var running = false
    public func run(until deadline: Instant = .distantFuture) {
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

                guard sleeping.count > 0 || scheduler.hasReady else {
                    #if DEBUG_FIBER
                    Log.debug("No fiber to schedule, shutting down.")
                    #endif
                    break
                }

                let events = try poller.poll(deadline: nextDeadline)
                now = .now

                scheduleReady(events)
                scheduleExpired()
                runScheduled()
            } catch {
                print("poll error:", error)
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
        for watcher in sleeping.pointee {
            scheduler.schedule(fiber: watcher.pointee.payload, state: .canceled)
        }
    }

    func scheduleReady(_ events: ArraySlice<Event>) {
        for event in events {
            let pair = watchers[event.descriptor]

            guard !pair.isEmpty else { continue }

            if event.typeOptions.contains(.read), let fiber = pair.read {
                scheduler.schedule(fiber: fiber, state: .ready)
            }

            if event.typeOptions.contains(.write), let fiber = pair.write {
                scheduler.schedule(fiber: fiber, state: .ready)
            }
        }
    }

    func scheduleExpired() {
        for watcher in sleeping.pointee {
            let fiber = watcher.pointee.payload
            guard fiber.pointee.deadline <= now else {
                break
            }
            scheduler.schedule(fiber: fiber, state: .expired)
        }
    }

    func runScheduled() {
        while scheduler.hasReady {
            scheduler.runReadyChain()
        }
    }

    @discardableResult
    public func wait(for deadline: Instant) -> Fiber.State {
        insertWatcher(deadline: deadline)
        scheduler.suspend()
        removeWatcher()
        return currentFiber.pointee.state
    }

    @discardableResult
    public func wait(
        for socket: Descriptor,
        event: IOEvent,
        deadline: Instant
    ) throws -> Fiber.State {
        try insertWatcher(for: socket, event: event, deadline: deadline)
        scheduler.suspend()
        removeWatcher(for: socket, event: event)
        if currentFiber.pointee.state == .expired {
            throw Error.timeout
        }
        return currentFiber.pointee.state
    }

    func insertWatcher(
        for descriptor: Descriptor,
        event: IOEvent,
        deadline: Instant
    ) throws {
        switch event {
        case .read:
            guard watchers[descriptor].read == nil else {
                throw Error.descriptorAlreadyInUse
            }
            watchers[descriptor].read = currentFiber
        case .write:
            guard watchers[descriptor].write == nil else {
                throw  Error.descriptorAlreadyInUse
            }
            watchers[descriptor].write = currentFiber
        }

        insertWatcher(deadline: deadline)
        poller.add(socket: descriptor, event: event)
    }

    func removeWatcher(for descriptor: Descriptor, event: IOEvent) {
        switch event {
        case .read: watchers[descriptor].read = nil
        case .write: watchers[descriptor].write = nil
        }
        // TODO: investigate & test more
        poller.remove(socket: descriptor, event: event)
        removeWatcher()
    }

    func insertWatcher(deadline: Instant) {
        currentFiber.pointee.deadline = deadline
        if sleeping.isEmpty || deadline >= sleeping.maxDeadline! {
            sleeping.append(currentFiber.pointee.watcherEntry)
        } else if deadline < sleeping.minDeadline! {
            sleeping.insert(currentFiber.pointee.watcherEntry)
        } else {
            for watcher in sleeping.pointee where deadline < watcher.deadline {
                watcher.insert(currentFiber.pointee.watcherEntry)
                return
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

    subscript(_ descriptor: Descriptor) -> Watchers {
        get { self[Int(descriptor.rawValue)] }
        set { self[Int(descriptor.rawValue)] = newValue }
    }

    static func allocate(
        repeating element: Watchers,
        count: Int
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
    var deadline: Instant {
        pointee.payload.pointee.deadline
    }

    var minDeadline: Instant? {
        first?.payload.pointee.deadline
    }

    var maxDeadline: Instant? {
        last?.payload.pointee.deadline
    }
}

extension FiberLoop: Equatable {
    public static func == (lhs: FiberLoop, rhs: FiberLoop) -> Bool {
        return lhs.poller == rhs.poller
    }
}
