import Platform
import Foundation

// right now used only for macOS timespec.distantFuture
extension timespec {
    static var now: timespec {
        var ts = timespec()
    #if os(macOS) || os(iOS)
        if #available(OSX 10.12, *) {
            clock_gettime(CLOCK_MONOTONIC, &ts)
        } else {
            var info = mach_timebase_info_data_t()
            if info.numer == 0 || info.denom == 0 {
                mach_timebase_info(&info)
            }
            let time = mach_absolute_time() * UInt64(info.numer / info.denom);
            ts.tv_sec = Int(time / 1_000_000_000)
            ts.tv_nsec = Int(time % 1_000_000_000)
        };
    #else
        clock_gettime(CLOCK_MONOTONIC, &ts)
    #endif
        return ts
    }
}

// Date.distantFuture is too far for kqueue timeout
extension timespec {
    static var distantFuture: timespec {
        return timespec.now + timespec(tv_sec: 365 * 24 * 3600, tv_nsec: 0)
    }
}

// alternative for Deadline typealias instead of Date
extension timespec {
    #if os(macOS) || os(iOS)
    var timeoutSinceNow: timespec {
        let timeout = self - timespec.now
        return timeout
    }
    #else
    var timeoutSinceNow: Int32 {
        let timeout = self - timespec.now
        let result = timeout.tv_sec * 1000 + timeout.tv_nsec / 1_000_000
        guard result < Int(Int32.max) else {
            return Int32.max
        }
        return Int32(result)
    }
    #endif
}

// Date -> timespec convestion
extension timespec {
    init(_ date: Date) {
        guard date < Date.distantFuture else {
            self = timespec.distantFuture
            return
        }
        self = timespec(date.timeIntervalSince1970)
    }

    init(_ interval: TimeInterval) {
        var int = 0.0
        let frac = modf(interval, &int)
        self.tv_sec = Int(int)
        self.tv_nsec = Int(frac * 1_000_000_000.0)
    }
}


/// Equatable, Comparable

extension timespec: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: timespec, rhs: timespec) -> Bool {
        return lhs.tv_sec == rhs.tv_sec && lhs.tv_nsec == rhs.tv_nsec
    }
}

extension timespec: Comparable {
    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than that of the second argument.
    ///
    /// This function is the only requirement of the `Comparable` protocol. The
    /// remainder of the relational operator functions are implemented by the
    /// standard library for any type that conforms to `Comparable`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func <(lhs: timespec, rhs: timespec) -> Bool {
        if lhs.tv_sec < rhs.tv_sec {
            return true
        } else if lhs.tv_sec == rhs.tv_sec {
            return lhs.tv_nsec < rhs.tv_nsec
        } else {
            return false
        }
    }

    /// Returns a Boolean value indicating whether the value of the first
    /// argument is greater than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func >(lhs: timespec, rhs: timespec) -> Bool {
        if lhs.tv_sec > rhs.tv_sec {
            return true
        } else if lhs.tv_sec == rhs.tv_sec {
            return lhs.tv_nsec > rhs.tv_nsec
        } else {
            return false
        }
    }
}

/// partial IntegerArithmetic

extension timespec {
    /// Adds `lhs` and `rhs`, returning the result and trapping in case of
    /// arithmetic overflow (except in -Ounchecked builds).
    static func +(lhs: timespec, rhs: timespec) -> timespec {
        var result = timespec()
        if lhs.tv_nsec + rhs.tv_nsec >= 1_000_000_000 {
            result.tv_sec = lhs.tv_sec + rhs.tv_sec + 1
            result.tv_nsec = lhs.tv_nsec + rhs.tv_nsec - 1_000_000_000
        } else {
            result.tv_sec = lhs.tv_sec + rhs.tv_sec
            result.tv_nsec = lhs.tv_nsec + rhs.tv_nsec
        }
        return result
    }

    /// Subtracts `lhs` and `rhs`, returning the result and trapping in case of
    /// arithmetic overflow (except in -Ounchecked builds).
    static func -(lhs: timespec, rhs: timespec) -> timespec {
        var result = timespec()
        if lhs.tv_nsec - rhs.tv_nsec < 0 {
            result.tv_sec = lhs.tv_sec - rhs.tv_sec - 1
            result.tv_nsec = lhs.tv_nsec - rhs.tv_nsec + 1_000_000_000
        } else {
            result.tv_sec = lhs.tv_sec - rhs.tv_sec
            result.tv_nsec = lhs.tv_nsec - rhs.tv_nsec
        }
        return result
    }
}
