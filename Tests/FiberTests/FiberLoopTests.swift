/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Test
import Platform
@testable import Fiber

import class Foundation.Thread

@available(OSX 10.12, *)
class FiberLoopTests: TestCase {
    func testEventLoop() {
        let loop = FiberLoop()
        assertNotNil(loop)
    }

    func testEventLoopMain() {
        assertNotNil(FiberLoop.main)
    }

    func testEventLoopCurrent() {
        assertNotNil(FiberLoop.current)
        assertEqual(FiberLoop.main, FiberLoop.current)
    }

    func testEvenLoopAnotherThread() {
        Thread {
            assertNotEqual(FiberLoop.main, FiberLoop.current)
        }.start()
    }

    func testFiberLoop() {
        let main = FiberLoop.current

        Thread {
            let first = FiberLoop.current
            let second = FiberLoop.current
            assertEqual(first, second)
            assertNotEqual(first, main)
        }.start()

        assertEqual(FiberLoop.main, FiberLoop.current)
    }


    static var allTests = [
        ("testEventLoop", testEventLoop),
        ("testEventLoopMain", testEventLoopMain),
        ("testEventLoopCurrent", testEventLoopCurrent),
        ("testEvenLoopAnotherThread", testEvenLoopAnotherThread),
        ("testFiberLoop", testFiberLoop),
    ]
}
