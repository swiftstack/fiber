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
import Fiber
import Foundation

public struct Loop: AsyncLoop {
    public func run() {
        FiberLoop.current.run()
    }
}

public struct AsyncFiber: Async {
    public init() {}

    public var loop: AsyncLoop = Loop()

    public var task: (@escaping AsyncTask) -> Void = fiber

    public var awaiter: IOAwaiter? = FiberAwaiter()
}

public struct FiberAwaiter: IOAwaiter {
    public init() {}

    public func wait(for descriptor: Descriptor, event: IOEvent) throws {
        try FiberLoop.current.wait(for: descriptor, event: event, deadline: Date.distantFuture)
    }
}
