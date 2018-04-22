/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

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
