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

//public typealias Deadline = timespec
public typealias Deadline = Date

extension Date {
#if os(macOS) || os(iOS)
    var timeoutSinceNow: timespec {
        guard self < Date.distantFuture else {
            return timespec.distantFuture
        }
        var interval = self.timeIntervalSinceNow
        interval = max(interval, 0)
        return timespec(interval)
    }
#else
    var timeoutSinceNow: Int32 {
        guard self < Date.distantFuture else {
            return Int32.max
        }
        var timeout = self.timeIntervalSinceNow * 1000.0
        timeout = max(timeout, 0)
        guard timeout < Double(Int32.max) else {
            return Int32.max
        }
        return Int32(timeout)
    }
#endif
}
