@testable import Fiber
import Foundation
import Platform

@available(OSX 10.12, *)
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
        Thread {
            assertNotEqual(FiberLoop.main, FiberLoop.current)
        }.start()
    }

    func testFiberLoop() {
        let main = FiberLoop.current

        Thread {
            let first = FiberLoop.current
            let second = FiberLoop.current
            assertEqual(first, second)
            assertNotEqual(first, main)
        }.start()

        assertEqual(FiberLoop.main, FiberLoop.current)
    }
}
