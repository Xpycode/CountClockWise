import XCTest
@testable import Clock

final class UpdateConfigurationTests: XCTestCase {
    func testUpdateChannelRequiresHTTPSAndPublicSigningKey() {
        let key = Data(repeating: 1, count: 32).base64EncodedString()
        XCTAssertTrue(ClockUpdater.validConfiguration(["SUFeedURL": "https://example.com/clock/appcast.xml", "SUPublicEDKey": key]))
        XCTAssertFalse(ClockUpdater.validConfiguration([:]))
        XCTAssertFalse(ClockUpdater.validConfiguration(["SUFeedURL": "http://example.com/appcast.xml", "SUPublicEDKey": key]))
        XCTAssertFalse(ClockUpdater.validConfiguration(["SUFeedURL": "https://user:password@example.com/appcast.xml", "SUPublicEDKey": key]))
        XCTAssertFalse(ClockUpdater.validConfiguration(["SUFeedURL": "https://example.com/appcast.xml", "SUPublicEDKey": "invalid"]))
    }
}
