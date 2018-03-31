/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Time
import Platform

extension Time {
#if os(macOS) || os(iOS)
    var kqueueMaximumTimeout: Time.Duration {
        return (60*60*24).s
    }

    var timeoutSinceNow: timespec {
        guard self < .now + kqueueMaximumTimeout else {
            return timespec(
                tv_sec: kqueueMaximumTimeout.seconds,
                tv_nsec: kqueueMaximumTimeout.nanoseconds)
        }
        let duration = timeIntervalSinceNow.duration
        return timespec(tv_sec: duration.seconds, tv_nsec: duration.nanoseconds)
    }
#else
    var timeoutSinceNow: Int32 {
        guard self < Time.distantFuture else {
            return Int32.max
        }
        let timeout = timeIntervalSinceNow.duration.ms
        guard timeout < Int(Int32.max) else {
            return Int32.max
        }
        return Int32(timeout)
    }
#endif
}
