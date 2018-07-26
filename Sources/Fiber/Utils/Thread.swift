import Platform

#if os(Linux)
let _CFIsMainThread: @convention(c) () -> Bool = {
    return try! resolveFunction(name: "_CFIsMainThread")
}()

private func pthread_main_np() -> Int32 {
    return _CFIsMainThread() ? 1 : 0
}
#endif

var isMainThread: Bool {
    return pthread_main_np() != 0
}
