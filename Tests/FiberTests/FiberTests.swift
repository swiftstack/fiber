import Test
@testable import Fiber

class FiberTests: TestCase {
    func testFiber() {
        var a = 0

        fiber {
            a = 1
            yield()
            assertEqual(a, 2)
            a = 3
        }

        fiber {
            assertEqual(a, 1)
            a = 2
            yield()
            assertEqual(a, 3)
        }

        FiberLoop.current.run()
    }

    func testMemoryLeak() {
        var released = false

        class Test {
            var task: () -> Void
            init(_ task: @escaping () -> Void) {
                self.task = task
            }
            @inline(never)
            func nop() {}
            deinit { task() }
        }

        scope {
            let test = Test {
                released = true
            }
            fiber {
                test.nop()
                yield()
                test.nop()
                // TODO: document to use `weak` pointer or release manually
                Unmanaged.passUnretained(test).release()
            }
        }

        FiberLoop.current.run()
        assertTrue(released)
    }
}
