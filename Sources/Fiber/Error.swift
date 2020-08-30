extension FiberLoop {
    public enum Error: Swift.Error {
        case canceled
        case timeout
        case descriptorAlreadyInUse
    }
}
