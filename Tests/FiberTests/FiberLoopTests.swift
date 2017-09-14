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
import Dispatch
@testable import Fiber

import struct Foundation.Date

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
        let condition = AtomicCondition()
        DispatchQueue.global(qos: .background).async {
            assertNotEqual(FiberLoop.main, FiberLoop.current)
            condition.signal()
        }
        condition.wait()
    }

    func testFiberLoop() {
        let condition = AtomicCondition()
        let main = FiberLoop.current

        DispatchQueue.global(qos: .background).async {
            let first = FiberLoop.current
            let second = FiberLoop.current
            assertEqual(first, second)
            assertNotEqual(first, main)
            condition.signal()
        }

        condition.wait()
        assertEqual(FiberLoop.main, FiberLoop.current)
    }

    func testLoopRunDeadline() {
        var wokeUp = false
        var state: Fiber.State = .none
        fiber {
            sleep(until: Date().addingTimeInterval(-1))
            state = FiberLoop.current.scheduler.running.pointee.state
            wokeUp = true
        }

        FiberLoop.current.run()
        assertTrue(wokeUp)
        assertEqual(state, .expired)
    }

    func testPollDeadline() {
        var pollError: PollError? = nil
        fiber {
            do {
                let descriptor = Descriptor(rawValue: 0)!
                try FiberLoop.current
                    .wait(for: descriptor, event: .read, deadline: Date())
            } catch {
                pollError = error as? PollError
            }
        }

        FiberLoop.current.run()
        assertEqual(pollError, .timeout)
    }


    static var allTests = [
        ("testEventLoop", testEventLoop),
        ("testEventLoopMain", testEventLoopMain),
        ("testEventLoopCurrent", testEventLoopCurrent),
        ("testEvenLoopAnotherThread", testEvenLoopAnotherThread),
        ("testFiberLoop", testFiberLoop),
        ("testLoopRunDeadline", testLoopRunDeadline),
        ("testPollDeadline", testPollDeadline)
    ]
}
