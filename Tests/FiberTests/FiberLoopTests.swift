import Test
import Time
import Platform
import Dispatch
@testable import Fiber

class FiberLoopTests: TestCase {
    func testFiberLoop() {
        let loop = FiberLoop()
        expect((loop as Any) is FiberLoop)
    }

    func testFiberLoopMain() {
        expect((FiberLoop.main as Any) is FiberLoop)
    }

    func testFiberLoopCurrent() {
        expect((FiberLoop.current as Any) is FiberLoop)
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

    func testFiberLoops() {
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
            state = sleep(until: .now - 1.s)
            wokeUp = true
        }

        FiberLoop.current.run()
        expect(wokeUp == true)
        expect(state == .expired)
    }

    func testPollDeadline() {
        var result: FiberLoop.Error?

        fiber {
            do {
                let descriptor = Descriptor(rawValue: 0)!
                try FiberLoop.current.wait(
                    for: descriptor,
                    event: .read,
                    deadline: .now)
            } catch {
                result = error as? FiberLoop.Error
            }
        }

        FiberLoop.current.run()
        expect(result == .timeout)
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
