import Test
import Time
import Platform
import Dispatch
@testable import Fiber

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
            sleep(until: .now - 1.s)
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
                    .wait(for: descriptor, event: .read, deadline: .now)
            } catch {
                pollError = error as? PollError
            }
        }

        FiberLoop.current.run()
        assertEqual(pollError, .timeout)
    }

    func testYieldDefersInTheSameCycle() {
        fiber {
            // wait for loop.run()
            sleep(until: .now)
            // save current time
            let time = FiberLoop.main.now
            // suspend
            yield()
            // test if the loop time is the same
            assertEqual(FiberLoop.main.now, time)
        }
        FiberLoop.main.run()
    }
}
