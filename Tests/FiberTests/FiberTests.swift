import XCTest
@testable import Fiber

class FiberTests: XCTestCase {
    func testFiber() {
        var a = 0

        fiber {
            a = 1
            yield()
            XCTAssertEqual(a, 2)
            a = 3
        }

        fiber {
            XCTAssertEqual(a, 1)
            a = 2
            yield()
            XCTAssertEqual(a, 3)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }
}
