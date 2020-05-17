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
        expect(done == true)
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
            scope {
                result = try async.syncTask {
                    // block thread
                    sleep(1)
                    return 42
                }
                expect(result == 42)
                expect(iterations == 10)
                tested = true
            }
        }

        async.loop.run()
        expect(tested == true)
    }

    func testSyncTaskCancel() {
        var taskDone = false
        var syncTaskDone = false

        async.task {
            scope {
                try async.testCancel()
                // the only way right now to cancel the fiber. all of them.
                async.loop.terminate()
            }
            expect(throws: AsyncError.taskCanceled) {
                try async.testCancel()
            }
        }

        async.task {
            expect(throws: AsyncError.taskCanceled) {
                try async.syncTask {
                    async.loop.terminate()
                    try async.testCancel()
                    syncTaskDone = true
                }
            }

            taskDone = true
        }

        async.loop.run()

        expect(taskDone == true)
        expect(syncTaskDone == false)
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
        expect(asyncError == .timeout)
    }
}
