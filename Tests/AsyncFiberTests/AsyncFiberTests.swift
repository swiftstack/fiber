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
                async.loop.break()
            } catch {
                fail(String(describing: error))
            }
        }

        async.loop.run()
        assertEqual(result, 42)
        assertEqual(iterations, 10)
    }

    func testSyncTaskCancel() {
        let async = AsyncFiber()

        var taskDone = false
        var syncTaskDone = false

        var error: Error? = nil

        async.task {
            assertNotNil(try? async.testCancel())
            async.loop.break()
            assertNil(try? async.testCancel())
        }

        async.task {
            do {
                try async.syncTask {
                    try async.testCancel()
                    syncTaskDone = true
                }
            } catch let taskError {
                error = taskError
            }

            taskDone = true
        }

        async.loop.run()

        assertTrue(error is AsyncTaskCanceled)
        assertTrue(taskDone)
        assertFalse(syncTaskDone)
    }


    static var allTests = [
        ("testTask", testTask),
        ("testSyncTask", testSyncTask),
        ("testSyncTaskCancel", testSyncTaskCancel)
    ]
}
