import XCTest
@testable import Clock

final class HelpContentTests: XCTestCase {
    @MainActor
    func testBundledHelpHasAllTopicsAndReadableContent() {
        let content = ClockSupport.helpContent()
        XCTAssertEqual(content.windowTitle, "Count Clock Wise Help")
        XCTAssertEqual(ClockSupport.config.appName, "Count Clock Wise")
        XCTAssertEqual(ClockSupport.config.appID, "count-clock-wise")
        XCTAssertEqual(URLComponents(url: ClockSupport.config.donateURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "app" })?.value, "count-clock-wise")
        XCTAssertEqual(Set(content.topics.map(\.id)), ["start", "timers", "appearance", "shortcuts", "timecode", "support"])
        for topic in content.topics {
            XCTAssertGreaterThan(topic.markdown.count, 100)
            XCTAssertFalse(topic.markdown.contains("could not be loaded"))
        }
    }
}
