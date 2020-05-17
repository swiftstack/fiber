import Test
import Time
import Platform
import Dispatch
@testable import Fiber

class FiberLoopTests: TestCase {
    func testEventLoop() {
        let loop = FiberLoop()
        expect(loop is FiberLoop)
    }

    func testEventLoopMain() {
        expect(FiberLoop.main is FiberLoop)
    }

    func testEventLoopCurrent() {
        expect(FiberLoop.current is FiberLoop)
        expect(FiberLoop.main == FiberLoop.current)
    }

    func testEvenLoopAnotherThread() {
        var tested = false
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .background).async {
            expect(FiberLoop.main != FiberLoop.current)
            tested = true
            semaphore.signal()
        }
        semaphore.wait()
        expect(tested == true)
    }

    func testFiberLoop() {
        var tested = false
        let semaphore = DispatchSemaphore(value: 0)
        let main = FiberLoop.current

        DispatchQueue.global(qos: .background).async {
            let first = FiberLoop.current
            let second = FiberLoop.current
            expect(first == second)
            expect(first != main)
            tested = true
            semaphore.signal()
        }

        semaphore.wait()
        expect(tested == true)
        expect(FiberLoop.main == FiberLoop.current)
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
        expect(wokeUp == true)
        expect(state == .expired)
    }

    func testPollDeadline() {
        var pollError: PollError? = nil

        fiber {
            do {
                let descriptor = Descriptor(rawValue: 0)!
                try FiberLoop.current.wait(
                    for: descriptor,
                    event: .read,
                    deadline: .now)
            } catch {
                pollError = error as? PollError
            }
        }

        FiberLoop.current.run()
        expect(pollError == .timeout)
    }

    func testYieldDefersInTheSameCycle() {
        fiber {
            // wait for loop.run()
            sleep(until: .now)
            // save current time
            let time = FiberLoop.main.now
            // suspend
            yield()
            // loop time shouldn't change between yields
            expect(FiberLoop.main.now == time)
        }
        FiberLoop.main.run()
    }
}
