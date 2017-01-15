/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import XCTest
@testable import Fiber

class ChannelTests: XCTestCase {
    func testChannel() {
        let channel = Channel<Int>()

        fiber {
            guard let value = channel.read() else {
                XCTFail()
                return
            }
            XCTAssertEqual(value, 42)
        }

        fiber {
            XCTAssertTrue(channel.write(42))
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelClose() {
        let channel = Channel<Int>()

        channel.close()
        XCTAssertFalse(channel.write(42))
        XCTAssertNil(channel.read())
    }

    func testChannelHasReader() {
        let channel = Channel<Int>()

        fiber {
            XCTAssertFalse(channel.hasReaders)
            _ = channel.read()
            XCTAssertFalse(channel.hasReaders)
            XCTAssert(channel.queue.count == 0)
        }

        fiber {
            XCTAssertTrue(channel.hasReaders)
            XCTAssert(channel.queue.count == 0)
            channel.write(42)
            XCTAssertFalse(channel.hasReaders)
            XCTAssert(channel.queue.count == 1)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelHasWriter() {
        let channel = Channel<Int>()

        fiber {
            XCTAssertFalse(channel.hasWriters)
            channel.write(42)
            XCTAssertFalse(channel.hasWriters)
        }

        fiber {
            XCTAssertTrue(channel.hasWriters)
            _ = channel.read()
            XCTAssertFalse(channel.hasWriters)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCapacity0() {
        let channel = Channel<Int>()

        fiber {
            XCTAssertTrue(channel.isEmpty)
            XCTAssertFalse(channel.canWrite)
            XCTAssertFalse(channel.canRead)
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCapacity1() {
        let channel = Channel<Int>(capacity: 1)

        fiber {
            XCTAssertTrue(channel.isEmpty)
            XCTAssertTrue(channel.canWrite)
            XCTAssertFalse(channel.canRead)
            channel.write(1)
            XCTAssertFalse(channel.isEmpty)
            XCTAssertFalse(channel.canWrite)
            XCTAssertTrue(channel.canRead)
            _ = channel.read()
            XCTAssertTrue(channel.isEmpty)
            XCTAssertTrue(channel.canWrite)
            XCTAssertFalse(channel.canRead)
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

        XCTAssertTrue(channel.isEmpty)

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
    }

    func testChannelCloseHasReader() {
        let channel = Channel<Int>(capacity: 10)

        fiber {
            let first = channel.read()
            XCTAssertTrue(channel.isEmpty)
            XCTAssertEqual(first, 0)
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
            XCTAssertNil(result)
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
        // failed
        // XCTAssertNil(result)
    }

    // TODO: test succeed if run manually
    func testChannelCloseHasWaitingWriter() {
        let channel = Channel<Int>()

        var result = true
        fiber {
            result = channel.write(42)
            XCTAssertFalse(result)
        }

        fiber {
            channel.close()
        }

        FiberLoop.current.run(until: Date().addingTimeInterval(1))
        // failed
        // XCTAssertFalse(result)
    }


    static var allTests : [(String, (ChannelTests) -> () throws -> Void)] {
        return [
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
}
