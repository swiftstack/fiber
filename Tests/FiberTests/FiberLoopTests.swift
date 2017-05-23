import Test
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
}
