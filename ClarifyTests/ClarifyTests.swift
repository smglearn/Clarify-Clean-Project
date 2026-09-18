import XCTest
@testable import Clarify

final class ClarifyTests: XCTestCase {
    func testAppModuleIsTestable() throws {
        // Basic smoke test to confirm the Clarify module can be imported
        // and unit tests run as part of CI.
        XCTAssertTrue(true)
    }
}
