/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

#if os(Linux)

    import Async
    import CEpoll
    import Platform
    import Foundation

    public typealias Descriptor = Int32

    typealias Poller = Epoll
    typealias Event = epoll_event

    extension Descriptor {
        static var maxLimit: Int {
            var rlim = rlimit()
            guard getrlimit(Int32(RLIMIT_NOFILE.rawValue), &rlim) >= 0 else {
                return 0
            }
            return Int(rlim.rlim_max);
        }
    }

    extension Event {
        init(descriptor: Descriptor, type: IOEvent) {
            switch type {
            case .read: self.events = EPOLLIN.rawValue
            case .write: self.events = EPOLLOUT.rawValue
            }
            self.data = epoll_data_t(fd: descriptor)
        }

        var descriptor: Descriptor {
            return Descriptor(self.data.fd)
        }
    }

    struct TypeOptions: OptionSet {
        let rawValue: UInt32

        static let read = TypeOptions(rawValue: EPOLLIN.rawValue)
        static let write = TypeOptions(rawValue: EPOLLOUT.rawValue)

        fileprivate static let error = TypeOptions(rawValue: EPOLLERR.rawValue)
        fileprivate static let hup = TypeOptions(rawValue: EPOLLHUP.rawValue)
        fileprivate static let rdhup = TypeOptions(rawValue: EPOLLRDHUP.rawValue)
    }

    extension Event {
        var typeOptions: TypeOptions {
            return TypeOptions(rawValue: self.events)
        }

        var isError: Bool {
            return typeOptions.contains(.error) || typeOptions.contains(.hup)
        }

        var isEOF: Bool {
            return typeOptions.contains(.rdhup)
        }
    }

    struct Epoll: PollerProtocol {
        var descriptor: Descriptor
        var events: [Event]

        var pollSize = 256

        init() {
            events = [Event](repeating: Event(), count: pollSize)

            var descriptor = epoll_create1(Int32(EPOLL_CLOEXEC))
            if descriptor == -1 && (errno == EINVAL || errno == ENOSYS) {
                descriptor = epoll_create(Int32(pollSize))
                if descriptor != -1 {
                    _ = ioctl(descriptor, UInt(FIOCLEX));
                }
            }
            assert(descriptor != -1, "epoll init failed")
            self.descriptor = descriptor
            self.descriptor.flags |= FD_CLOEXEC
        }

        mutating func poll(deadline: Deadline?) throws -> ArraySlice<Event> {
            var count: Int32 = -1
            while count < 0 {
                count = epoll_wait(descriptor, &events, Int32(events.count), deadline?.timeoutSinceNow ?? -1)
                guard count >= 0 || errno == EINTR else {
                    throw EventError()
                }
            }
            return events.prefix(upTo: Int(count))
        }

        mutating func add(socket: Descriptor, event: IOEvent) {
            var event = Event(descriptor: socket, type: event)
            epoll_ctl(descriptor, EPOLL_CTL_ADD, socket, &event)
        }

        mutating func remove(socket: Descriptor, event: IOEvent) {
            var event = Event(descriptor: socket, type: event)
            epoll_ctl(descriptor, EPOLL_CTL_DEL, socket, &event)
        }
    }
    
#endif
