import XCTest

extension AsyncFiberTests {
    static let __allTests = [
        ("testAwaiterDeadline", testAwaiterDeadline),
        ("testSyncTask", testSyncTask),
        ("testSyncTaskCancel", testSyncTaskCancel),
        ("testTask", testTask),
    ]
}

extension ChannelTests {
    static let __allTests = [
        ("testChannel", testChannel),
        ("testChannelCapacity0", testChannelCapacity0),
        ("testChannelCapacity1", testChannelCapacity1),
        ("testChannelClose", testChannelClose),
        ("testChannelCloseHasReader", testChannelCloseHasReader),
        ("testChannelCloseHasWaitingReader", testChannelCloseHasWaitingReader),
        ("testChannelCloseHasWaitingWriter", testChannelCloseHasWaitingWriter),
        ("testChannelCloseNoReader", testChannelCloseNoReader),
        ("testChannelHasReader", testChannelHasReader),
        ("testChannelHasWriter", testChannelHasWriter),
    ]
}

extension DispatchTests {
    static let __allTests = [
        ("testDispatch", testDispatch),
        ("testDispatchThrow", testDispatchThrow),
    ]
}

extension FiberLoopTests {
    static let __allTests = [
        ("testEvenLoopAnotherThread", testEvenLoopAnotherThread),
        ("testEventLoop", testEventLoop),
        ("testEventLoopCurrent", testEventLoopCurrent),
        ("testEventLoopMain", testEventLoopMain),
        ("testFiberLoop", testFiberLoop),
        ("testLoopRunDeadline", testLoopRunDeadline),
        ("testPollDeadline", testPollDeadline),
    ]
}

extension FiberTests {
    static let __allTests = [
        ("testFiber", testFiber),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AsyncFiberTests.__allTests),
        testCase(ChannelTests.__allTests),
        testCase(DispatchTests.__allTests),
        testCase(FiberLoopTests.__allTests),
        testCase(FiberTests.__allTests),
    ]
}
#endif
