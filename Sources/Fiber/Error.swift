import Platform

public enum PollError: Error {
    case alreadyInUse
    case doesNotExist
    case timeout
}
