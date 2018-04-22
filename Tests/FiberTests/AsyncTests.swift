/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************
 *  This file contains code that has not yet been described                   *
 ******************************************************************************/

import Test
import Time
import Fiber
import Platform
import Dispatch

@testable import Async
@testable import Fiber

class AsyncTests: TestCase {
    override func setUp() {
        async.setUp(Fiber.self)
    }

    func testTask() {
        var done = false
        async.task {
            done = true
        }
        assertTrue(done)
    }

    func testSyncTask() {
        var tested = false

        var iterations: Int = 0
        var result: Int = 0

        async.task {
            while iterations < 10 {
                iterations += 1
                // tick tock tick tock
                async.sleep(until: .now - 1.ms)
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
        var taskDone = false
        var syncTaskDone = false

        var error: Error? = nil

        async.task {
            assertNotNil(try? async.testCancel())
            // the only way right now to cancel the fiber. well, all of them.
            async.loop.terminate()
            assertNil(try? async.testCancel())
        }

        async.task {
            do {
                try async.syncTask {
                    async.loop.terminate()
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
        var asyncError: AsyncError? = nil
        async.task {
            do {
                let descriptor = Descriptor(rawValue: 0)!
                try async.wait(for: descriptor, event: .read, deadline: .now)
            } catch {
                asyncError = error as? AsyncError
            }
        }

        async.loop.run()
        assertEqual(asyncError, .timeout)
    }
}
