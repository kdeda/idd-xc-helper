import XCTest
@testable import XCHelper

final class XCHelperTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(XCHelper.Dependency.version, "1.0.0")
    }
}
