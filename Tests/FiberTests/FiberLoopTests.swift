/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import XCTest
@testable import Fiber
import Foundation
import Platform

class FiberLoopTests: XCTestCase {
    func testEventLoop() {
        let loop = FiberLoop()
        XCTAssertNotNil(loop)
    }

    func testEventLoopMain() {
        XCTAssertNotNil(FiberLoop.main)
    }

    func testEventLoopCurrent() {
        XCTAssertNotNil(FiberLoop.current)
        XCTAssertEqual(FiberLoop.main, FiberLoop.current)
    }

    @available(OSX 10.12, *)
    func testEvenLoopAnotherThread() {
        Thread {
            XCTAssertNotEqual(FiberLoop.main, FiberLoop.current)
        }.start()
    }

    @available(OSX 10.12, *)
    func testFiberLoop() {
        let main = FiberLoop.current

        Thread {
            let first = FiberLoop.current
            let second = FiberLoop.current
            XCTAssertEqual(first, second)
            XCTAssertNotEqual(first, main)
        }.start()

        XCTAssertEqual(FiberLoop.main, FiberLoop.current)
    }

    
    @available(OSX 10.12, *)
    static var allTests : [(String, (FiberLoopTests) -> () throws -> Void)] {
        return [
            ("testEventLoop", testEventLoop),
            ("testEventLoopMain", testEventLoopMain),
            ("testEventLoopCurrent", testEventLoopCurrent),
            ("testEvenLoopAnotherThread", testEvenLoopAnotherThread),
            ("testFiberLoop", testFiberLoop),
        ]
    }
}
