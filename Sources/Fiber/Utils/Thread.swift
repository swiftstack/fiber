import Platform
import Foundation

#if os(Linux)
let _CFIsMainThread: @convention(c) () -> Bool = {
    return try! resolveFunction(name: "_CFIsMainThread")
}()

private func pthread_main_np() -> Int32 {
    return _CFIsMainThread() ? 1 : 0
}
#endif

extension Thread {
    class var isMain: Bool {
        return pthread_main_np() != 0
    }
}
