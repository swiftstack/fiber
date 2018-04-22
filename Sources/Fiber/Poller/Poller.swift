/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************
 *  This file contains code that has not yet been described                   *
 ******************************************************************************/

import Time
import Async
import Platform
import Foundation

protocol PollerProtocol {
    var descriptor: Descriptor { get }
    mutating func poll(deadline: Time?) throws -> ArraySlice<Event>
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
