/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

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
