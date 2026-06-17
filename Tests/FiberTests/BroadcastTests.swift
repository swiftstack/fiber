import Testing
@testable import Fiber

@Test("Broadcast")
func broadcast() {
    let broadcast = Broadcast<Int>()

    fiber {
        guard let value = broadcast.wait() else {
            Issue.record()
            return
        }
        #expect(value == 42)
    }

    fiber {
        guard let value = broadcast.wait() else {
            Issue.record()
            return
        }
        #expect(value == 42)
    }

    #expect(broadcast.subscribers.count == 2)

    fiber {
        #expect(broadcast.dispatch(42) == true)
    }

    Scheduler.current.loop()

    #expect(broadcast.subscribers.count == 0)
}
