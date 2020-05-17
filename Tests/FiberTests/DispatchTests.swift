import Test
import Time
import Platform
@testable import Fiber

class DispatchTests: TestCase {
    func testDispatch() {
        let loop = FiberLoop.current

        var iterations: Int = 0
        var result: Int = 0

        fiber {
            while iterations < 10 {
                iterations += 1
                // tick tock tick tock
                sleep(until: .now - 1.ms)
            }
        }

        fiber {
            scope {
                result = try syncTask {
                    // block thread
                    sleep(1)
                    return 42
                }
                loop.break()
            }
        }

        loop.run()
        expect(result == 42)
        expect(iterations == 10)
    }

    func testDispatchThrow() {
        struct TestError: Error, Equatable {
            let code: Int
        }
        var testError: TestError? = nil

        fiber {
            do {
                _ = try syncTask { throw TestError(code: 42) }
            } catch {
                testError = error as? TestError
            }
        }

        FiberLoop.current.run()

        guard let error = testError else {
            fail("invalid error")
            return
        }
        expect(error == TestError(code: 42))
    }
}
