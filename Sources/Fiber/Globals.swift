/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Async
import Foundation

public func fiber(_ task: @escaping AsyncTask) {
    FiberLoop.current.scheduler.async(task)
}

public func yield() {
    FiberLoop.current.scheduler.yield()
}

public func sleep(until deadline: Date) {
    FiberLoop.current.wait(for: deadline)
}

public func now() -> Date {
    return FiberLoop.current.now
}
