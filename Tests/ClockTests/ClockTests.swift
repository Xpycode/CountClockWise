import XCTest
import Cocoa
@testable import Clock

final class ClockTests: XCTestCase {
    func testDropFrameMinuteTenMinuteAndHourBoundaries() {
        let rate = FrameRate.named("29.97 DF")
        XCTAssertEqual(rate.timecode(frameCount: 1799), "00:00:59;29")
        XCTAssertEqual(rate.timecode(frameCount: 1800), "00:01:00;02")
        XCTAssertEqual(rate.timecode(frameCount: 17981), "00:09:59;29")
        XCTAssertEqual(rate.timecode(frameCount: 17982), "00:10:00;00")
        XCTAssertEqual(rate.timecode(frameCount: 107892), "01:00:00;00")
        XCTAssertEqual(rate.timecode(frameCount: 2589408, wrap24Hours: true), "00:00:00;00")
        let fast = FrameRate.named("59.94 DF")
        XCTAssertEqual(fast.timecode(frameCount: 3599), "00:00:59;59")
        XCTAssertEqual(fast.timecode(frameCount: 3600), "00:01:00;04")
        XCTAssertEqual(fast.timecode(frameCount: 35964), "00:10:00;00")
    }
    func testFractionalRatesAreRationalAndNDFCountsContinuously() {
        XCTAssertEqual(FrameRate.named("23.976").fps, 24000.0 / 1001.0)
        XCTAssertEqual(FrameRate.named("29.97 NDF").timecode(frameCount: 1800), "00:01:00:00")
        XCTAssertEqual(FrameRate.named("23.976").timecode(seconds: 3600), "00:59:56:09")
        XCTAssertEqual(FrameRate.named("25").timecode(seconds: 1), "00:00:01:00")
    }
    func testDurationParsingRejectsInvalidInput() {
        XCTAssertEqual(ClockTimerState.parseDuration("90"), 90)
        XCTAssertEqual(ClockTimerState.parseDuration("05:00"), 300)
        XCTAssertEqual(ClockTimerState.parseDuration("1:30:00"), 5400)
        for invalid in ["", "0", "-1", "1:60", "1::2", "a", "999999999999999999999999", "605000"] {
            XCTAssertNil(ClockTimerState.parseDuration(invalid), invalid)
        }
    }
    func testTimerPauseResumeResetAndPersistence() throws {
        let start = Date(timeIntervalSince1970: 1000)
        var timer = ClockTimerState()
        timer.duration = 10
        timer.toggle(at: start)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(4)), 6)
        timer.toggle(at: start.addingTimeInterval(4))
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(20)), 4)
        timer.toggle(at: start.addingTimeInterval(20))
        let restored = try JSONDecoder().decode(ClockTimerState.self, from: JSONEncoder().encode(timer))
        XCTAssertEqual(restored.remaining(at: start.addingTimeInterval(30)), 0)
        timer.reset()
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.elapsed(at: start), 0)
    }
    func testIndependentSettingsAndFrameToggleRules() {
        let firstName = "ClockTests." + UUID().uuidString
        let secondName = "ClockTests." + UUID().uuidString
        let first = UserDefaults(suiteName: firstName)!, second = UserDefaults(suiteName: secondName)!
        defer { first.removePersistentDomain(forName: firstName); second.removePersistentDomain(forName: secondName) }
        let a = Settings(id: "a", defaults: first), b = Settings(id: "b", defaults: second)
        a.timeZoneIdentifier = "Asia/Tokyo"
        a.customLabel = "Tokyo office"
        a.borderless = true
        XCTAssertEqual(b.timeZoneIdentifier, "Europe/Berlin")
        XCTAssertEqual(b.customLabel, "")
        XCTAssertFalse(b.borderless)
        a.showFrames = true
        XCTAssertTrue(a.showSeconds)
        a.showSeconds = false
        XCTAssertFalse(a.showFrames)
        a.usesSystemTimeZone = true
        XCTAssertEqual(a.timeZone.identifier, TimeZone.autoupdatingCurrent.identifier)
        a.timeZoneIdentifier = "Europe/London"
        XCTAssertFalse(a.usesSystemTimeZone)
    }
    func testCitySearchAndSeasonalOffsets() {
        let berlin = TimeZoneEntry.catalog().first { $0.identifier == "Europe/Berlin" }!
        let winter = Date(timeIntervalSince1970: 1768478400), summer = Date(timeIntervalSince1970: 1784116800)
        XCTAssertTrue(berlin.matches("Germany", at: summer))
        XCTAssertTrue(berlin.matches("CEST", at: winter))
        XCTAssertEqual(TimeZoneEntry.detail(for: berlin.zone, at: winter), "CET · UTC+01:00")
        XCTAssertEqual(TimeZoneEntry.detail(for: berlin.zone, at: summer), "CEST · UTC+02:00")
        XCTAssertTrue(TimeZoneEntry.detail(for: TimeZone(identifier: "Asia/Kathmandu")!, at: summer).contains("UTC+05:45"))
        XCTAssertGreaterThan(TimeZoneEntry.cities.count, 30000)
        XCTAssertTrue(TimeZoneEntry.cities.contains { $0.matchesCity("Hamburg Germany") && $0.identifier == "Europe/Berlin" })
        XCTAssertTrue(TimeZoneEntry.cities.contains { $0.matchesCity("Los Angeles") && $0.identifier == "America/Los_Angeles" })
    }
    func testModesKeepSeparatePausedTimers() {
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        settings.mode = "Stopwatch"
        var timer = ClockTimerState(); timer.accumulated = 12; timer.startedAt = Date()
        settings.timerState = timer
        settings.mode = "Countdown"
        XCTAssertFalse(settings.timerState.isRunning)
        XCTAssertEqual(settings.timerState.accumulated, 0)
        settings.mode = "Stopwatch"
        XCTAssertFalse(settings.timerState.isRunning)
        XCTAssertGreaterThanOrEqual(settings.timerState.accumulated, 12)
    }

    func testWindowControlsAndMenuValidationStayInSync() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        settings.rememberWindowFrame = false
        let controller = ClockWindowController(settings: settings)
        settings.borderless = true
        XCTAssertFalse(controller.window!.styleMask.contains(.titled))
        settings.opacity = 0.65
        XCTAssertEqual(controller.window!.alphaValue, 0.65, accuracy: 0.001)
        settings.borderless = false
        XCTAssertTrue(controller.window!.styleMask.contains(.titled))
        let menu = controller.clockView.commandMenu()
        let start = menu.items.first { $0.title == "Start / Resume" }!
        XCTAssertFalse(controller.clockView.validateMenuItem(start))
        settings.mode = "Stopwatch"
        XCTAssertTrue(controller.clockView.validateMenuItem(start))
        XCTAssertTrue(NSApp.sendAction(start.action!, to: start.target, from: start))
        XCTAssertTrue(settings.timerState.isRunning)
        XCTAssertTrue(controller.clockView.validateMenuItem(start))
        XCTAssertEqual(start.title, "Pause")
        XCTAssertTrue(NSApp.sendAction(start.action!, to: start.target, from: start))
        XCTAssertFalse(settings.timerState.isRunning)
        // The existing command object survives state changes; menu tracking must not replace it.
        XCTAssertTrue(menu.items.contains { $0 === start })
        for size in [NSSize(width: 400, height: 92), NSSize(width: 1600, height: 92), NSSize(width: 400, height: 800)] {
            controller.clockView.setFrameSize(size)
            controller.clockView.layout()
            for label in controller.clockView.subviews.compactMap({ $0 as? NSTextField }) where !label.isHidden {
                XCTAssertTrue(controller.clockView.bounds.contains(label.frame))
            }
        }
    }

    func testDirectModeButtonsTimeClickAndFixedStatusBar() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        let view = ClockView(frame: NSRect(x: 0, y: 0, width: 600, height: 240), settings: settings)
        let selector = view.subviews.compactMap { $0 as? NSSegmentedControl }.first!
        selector.selectedSegment = 2
        XCTAssertTrue(NSApp.sendAction(selector.action!, to: selector.target, from: selector))
        XCTAssertEqual(settings.mode, "Stopwatch")
        let start = view.subviews.compactMap { $0 as? NSButton }.first { $0.title == "Start" }!
        start.performClick(nil)
        XCTAssertTrue(settings.timerState.isRunning)
        XCTAssertEqual(start.title, "Pause")
        view.layout()
        let time = view.subviews.compactMap { $0 as? NSTextField }[0]
        let event = NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: time.frame.midX, y: time.frame.midY), modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        view.mouseDown(with: event)
        XCTAssertFalse(settings.timerState.isRunning)
        let status = view.subviews.compactMap { $0 as? NSTextField }[1]
        XCTAssertEqual(status.font!.pointSize, 11)
        XCTAssertEqual(status.frame.width, 576)
        view.setFrameSize(NSSize(width: 1200, height: 400)); view.layout()
        XCTAssertEqual(status.font!.pointSize, 11)
        XCTAssertEqual(status.frame.width, 1176)
        settings.showStatusBar = false
        XCTAssertTrue(status.isHidden)
        settings.showControls = false
        XCTAssertTrue(selector.isHidden)
        XCTAssertTrue(start.isHidden)
        let modes = view.commandMenu().items.filter { ["Clock", "Countdown", "Stopwatch"].contains($0.title) }
        XCTAssertEqual(modes.count, 3)
        XCTAssertTrue(modes.allSatisfy { $0.submenu == nil })
    }

    func testFullTimeFitsAfterSwitchingModes() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        let view = ClockView(frame: NSRect(x: 0, y: 0, width: 900, height: 300), settings: settings)
        for mode in ["Clock", "Countdown", "Stopwatch", "Clock", "Stopwatch"] {
            settings.mode = mode
            for size in [NSSize(width: 900, height: 300), NSSize(width: 400, height: 160), NSSize(width: 1600, height: 400)] {
                view.setFrameSize(size); view.layout()
                let time = view.subviews.compactMap { $0 as? NSTextField }.first!
                let measured = ClockView.timeSize(time.stringValue, font: time.font!)
                XCTAssertLessThanOrEqual(measured.width, time.frame.width + 1)
                XCTAssertLessThanOrEqual(measured.height, time.frame.height + 1)
                if mode == "Stopwatch" { XCTAssertEqual(time.stringValue, "00:00:00") }
            }
        }
    }

    func testFocusModePreservesClockAreaAcrossResizingAndRepeatedToggles() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        settings.rememberWindowFrame = false
        let controller = ClockWindowController(settings: settings)
        let window = controller.window!
        defer { window.close() }
        func screenClockArea() -> NSRect {
            controller.clockView.layoutSubtreeIfNeeded()
            controller.clockView.layout()
            return window.convertToScreen(controller.clockView.convert(controller.clockView.clockFaceRect, to: nil))
        }
        // Exercise controller transitions and actual layout; keyboard routing is not under test.
        for mode in ["Clock", "Countdown", "Stopwatch"] {
            for borderless in [false, true] {
                for showsControls in [false, true] {
                    settings.focusMode = false
                    settings.mode = mode
                    settings.borderless = borderless
                    settings.showControls = showsControls
                    settings.showStatusBar = showsControls
                    window.setFrame(NSRect(x: 100, y: 200, width: 600, height: 350), display: false)
                    let initialClockArea = screenClockArea()
                    settings.focusMode = true
                    XCTAssertEqual(screenClockArea(), initialClockArea)
                    window.setFrame(NSRect(x: 150, y: 250, width: 1000, height: 500), display: false)
                    let enlargedClockArea = screenClockArea()
                    for _ in 0..<3 {
                        settings.focusMode.toggle()
                        XCTAssertEqual(screenClockArea(), enlargedClockArea)
                    }
                    XCTAssertFalse(settings.focusMode)
                    window.setFrame(NSRect(x: 200, y: 300, width: 800, height: 400), display: false)
                    let resizedNormalClockArea = screenClockArea()
                    settings.focusMode = true
                    XCTAssertEqual(screenClockArea(), resizedNormalClockArea)
                    settings.focusMode = false
                    XCTAssertEqual(screenClockArea(), resizedNormalClockArea)
                }
            }
        }
    }

    func testFocusModeResizeOverridesSavedNormalFrame() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        let autosaveName = "Clock-" + name
        defer {
            defaults.removePersistentDomain(forName: name)
            NSWindow.removeFrame(usingName: autosaveName)
        }
        let settings = Settings(id: name, defaults: defaults)
        settings.rememberWindowFrame = true
        let controller = ClockWindowController(settings: settings)
        let window = controller.window!
        defer { window.setFrameAutosaveName(""); window.close() }
        func screenClockArea() -> NSRect {
            controller.clockView.layoutSubtreeIfNeeded()
            controller.clockView.layout()
            return window.convertToScreen(controller.clockView.convert(controller.clockView.clockFaceRect, to: nil))
        }
        // Keep real AppKit frame autosaving enabled, using a unique test-only name.
        window.setFrame(NSRect(x: 100, y: 200, width: 600, height: 350), display: false)
        window.saveFrame(usingName: autosaveName)
        settings.focusMode = true
        window.setFrame(NSRect(x: 150, y: 250, width: 1000, height: 500), display: false)
        let resizedClockArea = screenClockArea()
        for _ in 0..<3 {
            settings.focusMode = false
            XCTAssertEqual(screenClockArea(), resizedClockArea)
            XCTAssertEqual(window.frameAutosaveName, autosaveName)
            settings.focusMode = true
            XCTAssertEqual(screenClockArea(), resizedClockArea)
        }
        settings.focusMode = false
        let expandedFrame = window.frame
        window.setFrameAutosaveName("")
        let restored = ClockWindowController(settings: Settings(id: name, defaults: defaults))
        defer { restored.window!.setFrameAutosaveName(""); restored.window!.close() }
        XCTAssertEqual(restored.window!.frame, expandedFrame)
    }

    func testFocusModeRestoresWindowAndPresentationPreferences() {
        _ = NSApplication.shared
        let name = "ClockTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = Settings(id: name, defaults: defaults)
        settings.rememberWindowFrame = false
        let controller = ClockWindowController(settings: settings)
        controller.window!.setFrame(NSRect(x: 100, y: 100, width: 600, height: 350), display: false)
        controller.clockView.layoutSubtreeIfNeeded()
        controller.clockView.layout()
        let original = controller.window!.frame
        settings.focusMode = true
        XCTAssertFalse(controller.window!.styleMask.contains(.titled))
        XCTAssertFalse(controller.window!.toolbar?.isVisible ?? false)
        XCTAssertLessThan(controller.window!.frame.height, original.height)
        XCTAssertTrue(settings.showControls)
        XCTAssertTrue(settings.showStatusBar)
        settings.focusMode = false
        XCTAssertTrue(controller.window!.styleMask.contains(.titled))
        XCTAssertTrue(controller.window!.toolbar!.isVisible)
        XCTAssertEqual(controller.window!.frame, original)
    }

}
