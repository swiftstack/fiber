import Test
@testable import Fiber

class BroadcastTests: TestCase {
    func testBroadcast() {
        let broadcast = Broadcast<Int>()

        fiber {
            guard let value = broadcast.wait() else {
                fail()
                return
            }
            expect(value == 42)
        }

        fiber {
            guard let value = broadcast.wait() else {
                fail()
                return
            }
            expect(value == 42)
        }

        expect(broadcast.subscribers.count == 2)

        fiber {
            expect(broadcast.dispatch(42) == true)
        }

        FiberLoop.current.run()

        expect(broadcast.subscribers.count == 0)
    }
}
