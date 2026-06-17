import Testing
import Platform
@testable import Fiber

@Test("Dispatch")
func dispatch() {
    let loop = FiberLoop.current

    var iterations: Int = 0
    var result: Int = 0

    fiber {
        while iterations < 10 {
            iterations += 1
            // tick tock tick tock
            sleep(until: .now.advanced(by: .milliseconds(-1)))
        }
    }

    fiber {
        #expect(throws: Never.self) {
            result = try syncTask {
                // block thread
                sleep(1)
                return 42
            }
            loop.break()
        }
    }

    loop.run()
    #expect(result == 42)
    #expect(iterations == 10)
}

@Test("DispatchThrow")
func dispatchThrow() {
    struct TestError: Swift.Error, Equatable {
        let code: Int
    }
    var testError: TestError?

    fiber {
        do {
            _ = try syncTask { throw TestError(code: 42) }
        } catch {
            testError = error as? TestError
        }
    }

    FiberLoop.current.run()

    guard let error = testError else {
        Issue.record("invalid error")
        return
    }
    #expect(error == TestError(code: 42))
}

