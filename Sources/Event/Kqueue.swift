#if os(macOS) || os(iOS)

import Time
import Platform

public typealias Poller = Kqueue
public typealias Event = kevent

extension Descriptor {
    public static var maxLimit: Int {
        return Int(OPEN_MAX)
    }
}

extension Event {
    enum Action {
        case add, delete
    }

    init(descriptor: Descriptor, type: IOEvent, action: Action) {
        let filter: Int32
        switch type {
        case .read: filter = EVFILT_READ
        case .write: filter = EVFILT_WRITE
        }
        let flags: Int32
        switch action {
        case .add: flags = EV_ADD | EV_ONESHOT
        case .delete: flags = EV_DELETE
        }
        self.init(
            ident: UInt(descriptor.rawValue),
            filter: Int16(filter),
            flags: UInt16(flags),
            fflags: 0,
            data: 0,
            udata: nil)
    }

    public var descriptor: Descriptor {
        return Descriptor(rawValue: Int32(self.ident))!
    }
}

public struct TypeOptions: OptionSet {
    public let rawValue: Int16

    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    public static let read = TypeOptions(rawValue: Int16(EVFILT_READ))
    public static let write = TypeOptions(rawValue: Int16(EVFILT_WRITE))
}

fileprivate struct FlagOptions: OptionSet  {
    let rawValue: UInt16

    static let add = FlagOptions(rawValue: UInt16(EV_ADD))
    static let delete = FlagOptions(rawValue: UInt16(EV_DELETE))
    static let oneShot = FlagOptions(rawValue: UInt16(EV_ONESHOT))

    static let error = FlagOptions(rawValue: UInt16(EV_ERROR))
    static let eof = FlagOptions(rawValue: UInt16(EV_EOF))
}

extension Event {
    public var typeOptions: TypeOptions {
        return TypeOptions(rawValue: self.filter)
    }

    fileprivate var flagOptions: FlagOptions {
        return FlagOptions(rawValue: self.flags)
    }

    public var isError: Bool {
        return flagOptions.contains(.error)
    }

    var isEOF: Bool {
        return flagOptions.contains(.eof)
    }
}

public struct Kqueue: PollerProtocol {
    var descriptor: Descriptor
    var events: [Event]
    var changes: [Event]

    var pollSize = 256

    public init() {
        let fd = kqueue()
        guard var descriptor = Descriptor(rawValue: fd) else {
            fatalError("kqueue init failed")
        }
        descriptor.flags |= FD_CLOEXEC
        self.descriptor = descriptor

        self.events = [Event](repeating: Event(), count: pollSize)
        self.changes = [Event]()
    }

    public mutating func poll(deadline: Time?) throws -> ArraySlice<Event> {
        var count: Int32 = -1

        while count < 0 {
            if let deadline = deadline {
                var timeout = deadline.timeoutSinceNow
                count = kevent(
                    descriptor.rawValue,
                    changes, Int32(changes.count),
                    &events, Int32(events.count),
                    &timeout)
            } else {
                var events = self.events
                count = kevent(
                    descriptor.rawValue,
                    changes, Int32(changes.count),
                    &events, Int32(events.count),
                    nil)
            }

            changes.removeAll(keepingCapacity: true)

            guard count >= 0 || errno == EINTR else {
                throw SystemError()
            }
        }

        return events.prefix(upTo: Int(count))
    }

    public mutating func add(socket: Descriptor, event: IOEvent) {
        let change = Event(descriptor: socket, type: event, action: .add)
        changes.append(change)
    }

    // Use EV_ONESHOT because if descriptor was closed before we remove a filter
    // kqueue throws an error on batch change and ignore next 'add filter' event
    // so we either should call kevent with 'delete filter' here directrly
    // or use built-in kernel option.
    //
    // TODO: try to make it work
    // issue found in examples/socket-example: hangs on second loop iteration
    // until we need extended lifetime for event filter (why would we need that)
    // EV_ONESHOT works just fine.
    //
    public mutating func remove(socket: Descriptor, event: IOEvent) {
        //let change = Event(descriptor: socket, type: event, action: .delete)
        //changes.append(change)
    }
}

#endif
