/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************
 *  This file contains code that has not yet been described                   *
 ******************************************************************************/

import Test
@testable import Fiber

import struct Foundation.Date

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
}
