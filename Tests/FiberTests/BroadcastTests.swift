/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

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
            assertEqual(value, 42)
        }

        fiber {
            guard let value = broadcast.wait() else {
                fail()
                return
            }
            assertEqual(value, 42)
        }

        assertEqual(broadcast.subscribers.count, 2)

        fiber {
            assertTrue(broadcast.dispatch(42))
        }

        FiberLoop.current.run()

        assertEqual(broadcast.subscribers.count, 0)
    }
}
