import Platform

public enum PollError: Error {
    case alreadyInUse
    case doesNotExist
    case timeout
}

public struct EventError: Error, CustomStringConvertible {
    public let number = errno
    public let description = String(cString: strerror(errno))
}
