import Async
import Foundation

protocol PollerProtocol {
    var descriptor: Descriptor { get }
    mutating func poll(deadline: Deadline?) throws -> ArraySlice<Event>
    mutating func add(socket: Descriptor, event: IOEvent)
    mutating func remove(socket: Descriptor, event: IOEvent)
}

extension PollerProtocol {
    mutating func clear(socket: Descriptor) {
        remove(socket: socket, event: .read)
        remove(socket: socket, event: .write)
    }
}

extension Poller: Equatable {
    public static func ==(lhs: Poller, rhs: Poller) -> Bool {
        return lhs.descriptor == rhs.descriptor
    }
}
