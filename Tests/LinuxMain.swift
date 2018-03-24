import XCTest

import FiberTests

var tests = [XCTestCaseEntry]()
tests += FiberTests.__allTests()

XCTMain(tests)
