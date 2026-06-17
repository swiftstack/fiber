import Testing
@testable import Fiber

@Test("Fiber")
func fiber() {
    var a = 0

    fiber {
        a = 1
        yield()
        #expect(a == 2)
        a = 3
        yield()
        #expect(a == 4)
        a = 5
    }

    fiber {
        #expect(a == 1)
        a = 2
        yield()
        #expect(a == 3)
        a = 4
        yield()
        #expect(a == 5)
    }

    Scheduler.current.loop()
    #expect(a == 5)
}

@Test("Lifetime")
func lifetime() {
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

    {
        let test = Test(destructor: {
            released = true
        })
        fiber {
            test.nop()
            yield()
            test.nop()
        }
    }()

    Scheduler.current.loop()
    #expect(released == true)
}
