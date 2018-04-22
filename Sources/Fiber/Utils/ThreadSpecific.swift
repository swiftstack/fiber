/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

import Foundation

public class ThreadSpecific<T: AnyObject> {
    var key: pthread_key_t
    public init() {
        key = pthread_key_t()
        pthread_key_create(&key, { pointer in
            #if os(Linux)
                Unmanaged<AnyObject>.fromOpaque(pointer!).release()
            #else
                Unmanaged<AnyObject>.fromOpaque(pointer).release()
            #endif
        })
    }

    public func get(_ constructor: () -> T) -> T {
        if let specific = pthread_getspecific(key) {
            return Unmanaged<T>.fromOpaque(specific).takeUnretainedValue()
        } else {
            let value = constructor()
            set(value)
            return value
        }
    }

    public func set(_ value: T) {
        pthread_setspecific(key, Unmanaged.passRetained(value).toOpaque())
    }
}
