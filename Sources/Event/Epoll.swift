#if os(Linux)

import Time
import CEpoll
import Platform

public typealias Poller = Epoll
public typealias Event = epoll_event

extension Descriptor {
    public static var maxLimit: Int {
        var rlim = rlimit()
        guard getrlimit(Int32(RLIMIT_NOFILE.rawValue), &rlim) >= 0 else {
            return 0
        }
        return Int(rlim.rlim_max)
    }
}

extension Event {
    init(descriptor: Descriptor, type: IOEvent) {
        let events: UInt32
        switch type {
        case .read: events = EPOLLIN.rawValue
        case .write: events = EPOLLOUT.rawValue
        }
        let data = epoll_data_t(fd: descriptor.rawValue)
        self.init(events: events, data: data)
    }

    public var descriptor: Descriptor {
        return Descriptor(rawValue: self.data.fd)!
    }
}

public struct TypeOptions: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let read = TypeOptions(rawValue: EPOLLIN.rawValue)
    public static let write = TypeOptions(rawValue: EPOLLOUT.rawValue)

    fileprivate static let error = TypeOptions(rawValue: EPOLLERR.rawValue)
    fileprivate static let hup = TypeOptions(rawValue: EPOLLHUP.rawValue)
    fileprivate static let rdhup = TypeOptions(rawValue: EPOLLRDHUP.rawValue)
}

extension Event {
    public var typeOptions: TypeOptions {
        return TypeOptions(rawValue: self.events)
    }

    public var isError: Bool {
        return typeOptions.contains(.error) || typeOptions.contains(.hup)
    }

    var isEOF: Bool {
        return typeOptions.contains(.rdhup)
    }
}

public struct Epoll: PollerProtocol {
    var descriptor: Descriptor
    var events: [Event]

    var pollSize = 256

    public init() {
        let fd = epoll_create1(Int32(EPOLL_CLOEXEC))
        guard let descriptor = Descriptor(rawValue: fd) else {
            fatalError("epoll init failed")
        }
        self.descriptor = descriptor

        self.events = [Event](repeating: Event(), count: pollSize)
    }

    public mutating func poll(deadline: Time?) throws -> ArraySlice<Event> {
        var count: Int32 = -1
        while count < 0 {
            count = epoll_wait(
                descriptor.rawValue,
                &events, Int32(events.count),
                deadline?.timeoutSinceNow ?? -1)
            guard count >= 0 || errno == EINTR else {
                throw SystemError()
            }
        }
        return events.prefix(upTo: Int(count))
    }

    public mutating func add(socket: Descriptor, event: IOEvent) {
        var event = Event(descriptor: socket, type: event)
        epoll_ctl(descriptor.rawValue, EPOLL_CTL_ADD, socket.rawValue, &event)
    }

    public mutating func remove(socket: Descriptor, event: IOEvent) {
        var event = Event(descriptor: socket, type: event)
        epoll_ctl(descriptor.rawValue, EPOLL_CTL_DEL, socket.rawValue, &event)
    }
}

#endif
