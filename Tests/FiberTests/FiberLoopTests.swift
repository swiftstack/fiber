import XCTest
@testable import Fiber
import Foundation
import Dispatch
import Platform

class FiberLoopTests: XCTestCase {
    func testEventLoop() {
        let loop = FiberLoop()
        XCTAssertNotNil(loop)
    }

    func testEventLoopMain() {
        XCTAssertNotNil(FiberLoop.main)
    }

    func testEventLoopCurrent() {
        XCTAssertNotNil(FiberLoop.current)
        XCTAssertEqual(FiberLoop.main, FiberLoop.current)
    }

    func testEvenLoopAnotherThread() {
        DispatchQueue.global().async {
            XCTAssertNotEqual(FiberLoop.main, FiberLoop.current)
        }
        FiberLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }

    @available(OSX 10.12, *)
    func testFiberLoop() {
        let main = FiberLoop.current

        Thread {
            let first = FiberLoop.current
            let second = FiberLoop.current
            XCTAssertEqual(first, second)
            XCTAssertNotEqual(first, main)
        }.start()

        XCTAssertEqual(FiberLoop.main, FiberLoop.current)

        FiberLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}
