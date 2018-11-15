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

    func testLifeTimeScope() {
        var released = false

        class Test {
            var destructor: () -> Void
            init(destructor: @escaping () -> Void) {
                self.destructor = destructor
            }
            @inline(never)
            func nop() {}
            deinit { destructor() }
        }

        scope {
            let test = Test(destructor: {
                released = true
            })
            fiber {
                test.nop()
                yield()
                test.nop()
            }
        }

        FiberLoop.current.run()
        assertTrue(released)
    }
}
