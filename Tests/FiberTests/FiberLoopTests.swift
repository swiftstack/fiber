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
        var tested = false
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .background).async {
            assertNotEqual(FiberLoop.main, FiberLoop.current)
            tested = true
            semaphore.signal()
        }
        semaphore.wait()
        assertTrue(tested)
    }

    func testFiberLoop() {
        var tested = false
        let semaphore = DispatchSemaphore(value: 0)
        let main = FiberLoop.current

        DispatchQueue.global(qos: .background).async {
            let first = FiberLoop.current
            let second = FiberLoop.current
            assertEqual(first, second)
            assertNotEqual(first, main)
            tested = true
            semaphore.signal()
        }

        semaphore.wait()
        assertTrue(tested)
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
                try FiberLoop.current.wait(for: 0, event: .read, deadline: Date())
            } catch {
                pollError = error as? PollError
            }
        }

        FiberLoop.current.run()
        assertEqual(pollError, .timeout)
    }
}
