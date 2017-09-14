/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Foundation

import Test
import Fiber
import Platform
@testable import AsyncFiber

import struct Foundation.Date

class AsyncFiberTests: TestCase {
    func testTask() {
        let async = AsyncFiber()
        let condition = AtomicCondition()

        var done = false
        async.task {
            done = true
            condition.signal()
        }

        condition.wait()
        assertTrue(done)
    }

    func testSyncTask() {
        let async = AsyncFiber()
        var tested = false

        var iterations: Int = 0
        var result: Int = 0

        async.task {
            while iterations < 10 {
                iterations += 1
                // tick tock tick tock
                async.sleep(until: Date().addingTimeInterval(0.1))
            }
        }

        async.task {
            do {
                result = try async.syncTask {
                    // block thread
                    sleep(1)
                    return 42
                }
                assertEqual(result, 42)
                assertEqual(iterations, 10)
                tested = true
            } catch {
                fail(String(describing: error))
            }
        }

        async.loop.run()
        assertTrue(tested)
    }

    func testSyncTaskCancel() {
        let async = AsyncFiber()

        var taskDone = false
        var syncTaskDone = false

        var error: Error? = nil

        async.task {
            assertNotNil(try? async.testCancel())
            // the only way right now to cancel the fiber. well, all of them.
            FiberLoop.current.break()
            assertNil(try? async.testCancel())
        }

        async.task {
            do {
                try async.syncTask {
                    FiberLoop.current.break()
                    try async.testCancel()
                    syncTaskDone = true
                }
            } catch let taskError {
                error = taskError
            }

            taskDone = true
        }

        async.loop.run()

        assertEqual(error as? AsyncError, .taskCanceled)
        assertTrue(taskDone)
        assertFalse(syncTaskDone)
    }

    func testAwaiterDeadline() {
        let async = AsyncFiber()
        var asyncError: AsyncError? = nil
        async.task {
            do {
                let descriptor = Descriptor(rawValue: 0)!
                try async.wait(for: descriptor, event: .read, deadline: Date())
            } catch {
                asyncError = error as? AsyncError
            }
        }

        FiberLoop.current.run()
        assertEqual(asyncError, .timeout)
    }


    static var allTests = [
        ("testTask", testTask),
        ("testSyncTask", testSyncTask),
        ("testSyncTaskCancel", testSyncTaskCancel),
        ("testAwaiterDeadline", testAwaiterDeadline),
    ]
}
