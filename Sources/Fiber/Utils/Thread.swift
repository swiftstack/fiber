/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Platform
import Foundation

#if os(Linux)
let _CFIsMainThread: @convention(c) (Void) -> Bool = {
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
