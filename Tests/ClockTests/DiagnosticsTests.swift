import XCTest
@testable import Clock

final class DiagnosticsTests: XCTestCase {
    private func withDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ClockDiagnosticsTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    func testRotationBoundsAndNewestEventSurvives() throws {
        try withDirectory { directory in
            let logger = DiagnosticLogger(directory: directory, maxFileBytes: 256)
            for _ in 0..<50 { logger.record("notifications.delivery.submitted") }
            logger.record("app.finalEvent")
            let tail = logger.recentTail(maxBytes: 512)
            XCTAssertTrue(tail.contains("app.finalEvent"))
            XCTAssertLessThanOrEqual(tail.utf8.count, 512)
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            XCTAssertEqual(files.count, 2)
            for file in files { XCTAssertLessThanOrEqual(try Data(contentsOf: file).count, 256) }
            XCTAssertNil(logger.lastFailure)
            XCTAssertEqual(logger.recentTail(maxBytes: 0), "")
            XCTAssertLessThanOrEqual(logger.recentTail(maxBytes: 13).utf8.count, 13)
        }
    }

    func testErrorsExcludeDescriptionsPathsAndUnknownDomains() throws {
        try withDirectory { directory in
            let logger = DiagnosticLogger(directory: directory)
            logger.record("notifications.delivery.failed", error: NSError(domain: "private timer label", code: 42, userInfo: [NSLocalizedDescriptionKey: "Europe/Berlin 01:30 /Users/private"]))
            let tail = logger.recentTail()
            XCTAssertTrue(tail.contains("OtherError:42"))
            for privateValue in ["private timer label", "Europe/Berlin", "/Users/private"] { XCTAssertFalse(tail.contains(privateValue)) }
        }
    }

    func testWriteFailureIsReportedAndLaterWriteRecovers() throws {
        try withDirectory { directory in
            let blocked = directory.appendingPathComponent("blocked")
            try Data().write(to: blocked)
            let logger = DiagnosticLogger(directory: blocked)
            logger.record("app.started")
            XCTAssertNotNil(logger.lastFailure) // also drains the serial write queue
            XCTAssertEqual(logger.recentTail(), "")
            try FileManager.default.removeItem(at: blocked)
            logger.record("app.recovered")
            XCTAssertTrue(logger.recentTail().contains("app.recovered"))
            XCTAssertNil(logger.lastFailure)
        }
    }

    func testConcurrentWritersPreserveCompleteRecords() throws {
        try withDirectory { directory in
            let logger = DiagnosticLogger(directory: directory)
            DispatchQueue.concurrentPerform(iterations: 100) { _ in logger.record("app.concurrentEvent") }
            let tail = logger.recentTail(maxBytes: 131_072)
            let lines = tail.split(separator: "\n")
            XCTAssertEqual(lines.count, 100)
            XCTAssertTrue(lines.allSatisfy { $0.hasSuffix("app.concurrentEvent") })
        }
    }
}
