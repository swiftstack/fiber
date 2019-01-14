public final class Broadcast<T> {
    var subscribers: [UnsafeMutablePointer<Fiber>] = []
    var queue: [(value: T, count: Int)] = []

    public init() {}

    @usableFromInline
    var this: UnsafeMutablePointer<Fiber> {
        return FiberLoop.current.scheduler.running
    }

    @usableFromInline
    @inline(__always)
    func schedule(_ fiber: UnsafeMutablePointer<Fiber>) {
        FiberLoop.current.scheduler.schedule(fiber: fiber, state: .ready)
    }

    public func wait() -> T? {
        subscribers.append(this)
        let state = suspend()
        guard state == .ready else {
            return nil
        }
        guard queue.count > 0 else {
            fatalError("corrupted queue")
        }
        queue[queue.endIndex-1].count -= 1
        return queue[queue.endIndex-1].count == 0 ?
            queue.removeLast().value :
            queue[queue.endIndex-1].value
    }

    @discardableResult
    public func dispatch(_ value: T) -> Bool {
        guard subscribers.count > 0 else {
            return false
        }
        queue.append((value: value, count: subscribers.count))
        subscribers.forEach(schedule)
        subscribers.removeAll()
        return true
    }
}
