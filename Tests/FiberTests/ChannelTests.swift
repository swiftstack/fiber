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

        FiberLoop.current.run()
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

        FiberLoop.current.run()
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

        FiberLoop.current.run()
    }

    func testChannelCapacity0() {
        let channel = Channel<Int>()

        fiber {
            assertTrue(channel.isEmpty)
            assertFalse(channel.canWrite)
            assertFalse(channel.canRead)
        }

        FiberLoop.current.run()
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

        FiberLoop.current.run()
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
        FiberLoop.current.run()
    }

    func testChannelCloseHasReader() {
        let channel = Channel<Int>(capacity: 10)

        var first: Int? = nil
        fiber {
            first = channel.read()
        }

        fiber {
            for i in 0..<10 {
                channel.write(i)
            }
            channel.close()
        }

        FiberLoop.current.run()
        assertTrue(channel.isEmpty)
        assertEqual(first, 0)
    }

    func testChannelCloseHasWaitingReader() {
        let channel = Channel<Int>()

        var result: Optional<Int> = 42
        fiber {
            result = channel.read()
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run()
        assertNil(result)
    }

    func testChannelCloseHasWaitingWriter() {
        let channel = Channel<Int>()

        var result = true
        fiber {
            result = channel.write(42)
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run()
        assertFalse(result)
    }
}
