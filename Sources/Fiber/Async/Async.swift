import Async

extension Fiber: Asynchronous {
    public static var async: Async {
        return AsyncFiber()
    }
}
