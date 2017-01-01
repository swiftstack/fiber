/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

#if os(macOS) || os(iOS)

    import Async
    import Platform
    import Foundation

    public typealias Descriptor = Int32

    typealias Poller = Kqueue
    typealias Event = kevent

    extension Descriptor {
        static var maxLimit: Int {
            return Int(OPEN_MAX)
        }
    }

    extension Event {
        enum Action {
            case add, delete
        }

        init(descriptor: Descriptor, type: IOEvent, action: Action) {
            self.ident = UInt(descriptor)
            switch type {
            case .read: self.filter = Int16(EVFILT_READ)
            case .write: self.filter = Int16(EVFILT_WRITE)
            }
            switch action {
            case .add: self.flags = UInt16(EV_ADD) | UInt16(EV_ONESHOT)
            case .delete: self.flags = UInt16(EV_DELETE)
            }
            self.fflags = 0
            self.data = 0
            self.udata = nil
        }

        var descriptor: Descriptor {
            return Descriptor(self.ident)
        }
    }

    struct TypeOptions: OptionSet {
        let rawValue: Int16

        static let read = TypeOptions(rawValue: Int16(EVFILT_READ))
        static let write = TypeOptions(rawValue: Int16(EVFILT_WRITE))
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
        var typeOptions: TypeOptions {
            return TypeOptions(rawValue: self.filter)
        }

        fileprivate var flagOptions: FlagOptions {
            return FlagOptions(rawValue: self.flags)
        }

        var isError: Bool {
            return flagOptions.contains(.error)
        }

        var isEOF: Bool {
            return flagOptions.contains(.eof)
        }
    }

    struct Kqueue: PollerProtocol {
        var descriptor: Descriptor
        var events: [Event]
        var changes: [Event]

        var pollSize = 256

        init() {
            descriptor = kqueue()
            descriptor.flags |= FD_CLOEXEC

            events = [Event](repeating: Event(), count: pollSize)
            changes = [Event]()

            assert(descriptor != -1, "kqueue init failed")
        }

        mutating func poll(deadline: Deadline?) throws -> ArraySlice<Event> {
            var count: Int32 = -1

            while count < 0 {
                if let deadline = deadline {
                    var timeout = deadline.timeoutSinceNow
                    count = kevent(descriptor, &changes, Int32(changes.count), &events, Int32(events.count), &timeout)
                } else {
                    count = kevent(descriptor, &changes, Int32(changes.count), &events, Int32(events.count), nil)
                }

                changes.removeAll(keepingCapacity: true)

                guard count >= 0 || errno == EINTR else {
                    throw EventError()
                }
            }

            return events.prefix(upTo: Int(count))
        }

        mutating func add(socket: Descriptor, event: IOEvent) {
            let change = Event(descriptor: socket, type: event, action: .add)
            changes.append(change)
        }

        // Use EV_ONESHOT because if descriptor closed before we remove filter
        // kqueue throws an error on batch change and ignore next 'add filter' event
        // so we either should call kevent with 'delete filter' here directrly
        // or use built-in kernel option.
        //
        // TODO: try to make it work
        // issue found in examples/socket-example: hangs on second loop iteration
        // until we need extended lifetime for event filter (why would we need that?)
        // EV_ONESHOT works just fine.
        //
        mutating func remove(socket: Descriptor, event: IOEvent) {
            //let change = Event(descriptor: socket, type: event, action: .delete)
            //changes.append(change)
        }
    }
    
#endif
