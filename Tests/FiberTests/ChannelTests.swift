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

class ChannelTests: TestCase {
    func testChannel() {
        let channel = Channel<Int>()

        fiber {
            guard let value = channel.read() else {
                fail()
                return
            }
            assertEqual(value, 42)
        }

        fiber {
            assertTrue(channel.write(42))
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelClose() {
        let channel = Channel<Int>()

        channel.close()
        assertFalse(channel.write(42))
        assertNil(channel.read())
    }

    func testChannelHasReader() {
        let channel = Channel<Int>()

        fiber {
            assertFalse(channel.hasReaders)
            _ = channel.read()
            assertFalse(channel.hasReaders)
            assertEqual(channel.queue.count, 0)
        }

        fiber {
            assertTrue(channel.hasReaders)
            assertEqual(channel.queue.count, 0)
            channel.write(42)
            assertFalse(channel.hasReaders)
            assertEqual(channel.queue.count, 1)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelHasWriter() {
        let channel = Channel<Int>()

        fiber {
            assertFalse(channel.hasWriters)
            channel.write(42)
            assertFalse(channel.hasWriters)
        }

        fiber {
            assertTrue(channel.hasWriters)
            _ = channel.read()
            assertFalse(channel.hasWriters)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCapacity0() {
        let channel = Channel<Int>()

        fiber {
            assertTrue(channel.isEmpty)
            assertFalse(channel.canWrite)
            assertFalse(channel.canRead)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCapacity1() {
        let channel = Channel<Int>(capacity: 1)

        fiber {
            assertTrue(channel.isEmpty)
            assertTrue(channel.canWrite)
            assertFalse(channel.canRead)
            channel.write(1)
            assertFalse(channel.isEmpty)
            assertFalse(channel.canWrite)
            assertTrue(channel.canRead)
            _ = channel.read()
            assertTrue(channel.isEmpty)
            assertTrue(channel.canWrite)
            assertFalse(channel.canRead)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCloseNoReader() {
        let channel = Channel<Int>(capacity: 10)

        fiber {
            for i in 0..<10 {
                channel.write(i)
            }
            channel.close()
        }

        assertTrue(channel.isEmpty)

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCloseHasReader() {
        let channel = Channel<Int>(capacity: 10)

        fiber {
            let first = channel.read()
            assertTrue(channel.isEmpty)
            assertEqual(first, 0)
        }

        fiber {
            for i in 0..<10 {
                channel.write(i)
            }
            channel.close()
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    // TODO: test succeed if run manually
    func testChannelCloseHasWaitingReader() {
        let channel = Channel<Int>()

        var result: Optional<Int> = 42
        fiber {
            result = channel.read()
            assertNil(result)
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
        // failed
        // assertNil(result)
    }

    // TODO: test succeed if run manually
    func testChannelCloseHasWaitingWriter() {
        let channel = Channel<Int>()

        var result = true
        fiber {
            result = channel.write(42)
            assertFalse(result)
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
        // failed
        // assertFalse(result)
    }


    static var allTests = [
        ("testChannel", testChannel),
        ("testChannelClose", testChannelClose),
        ("testChannelHasReader", testChannelHasReader),
        ("testChannelHasWriter", testChannelHasWriter),
        ("testChannelCapacity0", testChannelCapacity0),
        ("testChannelCapacity1", testChannelCapacity1),
        ("testChannelCloseNoReader", testChannelCloseNoReader),
        ("testChannelCloseHasReader", testChannelCloseHasReader),
        ("testChannelCloseHasWaitingReader", testChannelCloseHasWaitingReader),
        ("testChannelCloseHasWaitingWriter", testChannelCloseHasWaitingWriter)
    ]
}
