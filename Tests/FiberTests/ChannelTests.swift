import Testing
@testable import Fiber

import struct Foundation.Date

@Test("Channel")
func channel() {
    let channel = Channel<Int>()

    fiber {
        guard let value = channel.read() else {
            Issue.record("channel.read() Issue.recorded")
            return
        }
        #expect(value == 42)
    }

    fiber {
        #expect(channel.write(42) == true)
    }

    Scheduler.current.loop()
}

@Test("ChannelClose")
func channelClose() {
    let channel = Channel<Int>()

    channel.close()
    #expect(channel.write(42) == false)
    #expect(channel.read() == nil)
}

@Test("ChannelHasReader")
func channelHasReader() {
    let channel = Channel<Int>()

    fiber {
        #expect(!channel.hasReaders)
        _ = channel.read()
        #expect(!channel.hasReaders)
        #expect(channel.queue.count == 0)
    }

    fiber {
        #expect(channel.hasReaders)
        #expect(channel.queue.count == 0)
        channel.write(42)
        #expect(!channel.hasReaders)
        #expect(channel.queue.count == 1)
    }

    Scheduler.current.loop()
}

@Test("ChannelHasWriter")
func channelHasWriter() {
    let channel = Channel<Int>()

    fiber {
        #expect(!channel.hasWriters)
        channel.write(42)
        #expect(!channel.hasWriters)
    }

    fiber {
        #expect(channel.hasWriters)
        _ = channel.read()
        #expect(!channel.hasWriters)
    }

    Scheduler.current.loop()
}

@Test("ChannelCapacity0")
func channelCapacity0() {
    let channel = Channel<Int>()

    fiber {
        #expect(channel.isEmpty)
        #expect(!channel.canWrite)
        #expect(!channel.canRead)
    }

    Scheduler.current.loop()
}

@Test("ChannelCapacity1")
func channelCapacity1() {
    let channel = Channel<Int>(capacity: 1)

    fiber {
        #expect(channel.isEmpty)
        #expect(channel.canWrite)
        #expect(!channel.canRead)
        channel.write(1)
        #expect(!channel.isEmpty)
        #expect(!channel.canWrite)
        #expect(channel.canRead)
        _ = channel.read()
        #expect(channel.isEmpty)
        #expect(channel.canWrite)
        #expect(!channel.canRead)
    }

    Scheduler.current.loop()
}

@Test("ChannelCloseNoReader")
func channelCloseNoReader() {
    let channel = Channel<Int>(capacity: 10)

    fiber {
        for i in 0..<10 {
            channel.write(i)
        }
        channel.close()
    }

    #expect(channel.isEmpty)
    Scheduler.current.loop()
}

@Test("ChannelCloseHasReader")
func channelCloseHasReader() {
    let channel = Channel<Int>(capacity: 10)

    var first: Int?
    fiber {
        first = channel.read()
    }

    fiber {
        for i in 0..<10 {
            channel.write(i)
        }
        channel.close()
    }

    Scheduler.current.loop()
    #expect(channel.isEmpty)
    #expect(first == 0)
}

@Test("ChannelCloseHasWaitingReader")
func channelCloseHasWaitingReader() {
    let channel = Channel<Int>()

    var result: Int? = 42
    fiber {
        result = channel.read()
    }

    fiber {
        channel.close()
    }

    Scheduler.current.loop()
    #expect(result == nil)
}

@Test("ChannelCloseHasWaitingWriter")
func channelCloseHasWaitingWriter() {
    let channel = Channel<Int>()

    var result = true
    fiber {
        result = channel.write(42)
    }

    fiber {
        channel.close()
    }

    Scheduler.current.loop()
    #expect(result == false)
}
