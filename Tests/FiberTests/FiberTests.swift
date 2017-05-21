/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

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

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }


    static var allTests = [
        ("testFiber", testFiber),
    ]
}
