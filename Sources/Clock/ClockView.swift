import Cocoa

final class ClockView: NSView, NSMenuItemValidation {
    let settings: Settings
    var onSettings: (() -> Void)?
    private var clockTimer = ClockTimerState()
    private var lastSecond = Int.min
    private var layoutKey = ""
    private var cachedZoneFooter = ""
    private(set) var clockFaceRect = NSRect.zero
    private let timeLabel = NSTextField(labelWithString: "")
    private var dateText = ""
    private let modeSelector = NSSegmentedControl(labels: ["Clock", "Countdown", "Stopwatch"], trackingMode: .selectOne, target: nil, action: nil)
    private let startButton = NSButton(title: "Start", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)
    private var durationSheet: DurationSheetController?
    private let controlsBar = NSVisualEffectView()
    private let divider = NSBox()
    private let durationButton = NSButton(title: "Set Duration…", target: nil, action: nil)
    private let zoneLabel = NSTextField(labelWithString: "")
    private var timer: Timer?

    init(frame: NSRect, settings: Settings = .shared) {
        self.settings = settings
        super.init(frame: frame)
        wantsLayer = true
        setupLabels()
        applySettings()
        NotificationCenter.default.addObserver(
            self, selector: #selector(applySettings), name: .settingsDidChange, object: settings
        )
        NotificationCenter.default.addObserver(self, selector: #selector(applySettings), name: .appAppearanceDidChange, object: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLabels() {
        controlsBar.material = .windowBackground
        controlsBar.blendingMode = .withinWindow
        controlsBar.state = .followsWindowActiveState
        controlsBar.appearance = NSApp.effectiveAppearance
        addSubview(controlsBar)
        divider.boxType = .separator
        addSubview(divider)
        for label in [timeLabel, zoneLabel] {
            label.alignment = .center
            label.maximumNumberOfLines = 1
            addSubview(label)
        }
        modeSelector.target = self; modeSelector.action = #selector(modeChanged)
        modeSelector.controlSize = .regular
        for (index, mode) in ["Clock", "Countdown", "Stopwatch"].enumerated() {
            modeSelector.setToolTip("Show " + mode, forSegment: index)
        }
        modeSelector.setAccessibilityLabel("Clock mode")
        addSubview(modeSelector)
        for button in [startButton, resetButton, durationButton] {
            button.target = self; button.bezelStyle = .rounded; button.controlSize = .regular
            button.appearance = NSApp.effectiveAppearance
            addSubview(button)
        }
        startButton.imagePosition = .imageLeading
        startButton.bezelColor = .controlAccentColor
        startButton.toolTip = "Start or pause (Space). You can also click the time."
        resetButton.toolTip = "Stop and reset this timer"
        durationButton.toolTip = "Choose hours, minutes and seconds"
        startButton.action = #selector(toggleTimer)
        resetButton.action = #selector(resetTimer)
        durationButton.action = #selector(setCountdown)
        timeLabel.setAccessibilityLabel("Time — click to start or pause a timer")
    }

    // Calculate either presentation before changing window chrome or receiving layout callbacks.
    func clockFaceRect(focusMode: Bool) -> NSRect {
        let showsStatus = settings.showStatusBar && !focusMode
        let showsTimerControls = settings.showControls && settings.mode != "Clock" && !focusMode
        let showsModeSelector = settings.showControls && settings.borderless && !focusMode
        let bottom: CGFloat = 4 + (showsStatus ? 24 : 0)
            + (showsTimerControls ? 40 : 0) + (showsStatus || showsTimerControls ? 8 : 0)
        let top: CGFloat = 4 + (showsModeSelector ? 28 : 0)
        return NSRect(x: bounds.minX, y: bounds.minY + bottom, width: bounds.width,
                      height: max(1, bounds.height - top - bottom))
    }

    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let suffix = timeLabel.stringValue.hasSuffix("AM") ? "AM" : (timeLabel.stringValue.hasSuffix("PM") ? "PM" : "")
        let key = "\(bounds.size),\(timeLabel.stringValue.count),\(suffix),\(settings.showStatusBar),\(settings.showControls),\(settings.borderless),\(settings.focusMode),\(settings.mode)"
        if layoutKey == key { return }
        layoutKey = key
        let inset: CGFloat = 8
        let width = max(1, bounds.width - 2 * inset)
        var top = bounds.maxY - 4
        var bottom = bounds.minY + 4
        if !modeSelector.isHidden {
            let selectorWidth = min(width, 270)
            modeSelector.frame = NSRect(x: bounds.midX - selectorWidth / 2, y: top - 24, width: selectorWidth, height: 24)
            top -= 28
        }
        if !zoneLabel.isHidden {
            zoneLabel.frame = NSRect(x: bounds.minX + 12, y: bottom + 3, width: max(1, bounds.width - 24), height: 16)
            bottom += 24
        }
        if !startButton.isHidden {
            let buttons = [startButton, resetButton, durationButton].filter { !$0.isHidden }
            let buttonWidth: CGFloat = 104
            let total = CGFloat(buttons.count) * buttonWidth + CGFloat(buttons.count - 1) * 8
            for (index, button) in buttons.enumerated() {
                button.frame = NSRect(x: bounds.midX - total / 2 + CGFloat(index) * (buttonWidth + 8), y: bottom, width: buttonWidth, height: 32)
            }
            bottom += 40
        }
        controlsBar.frame = NSRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bottom)
        controlsBar.isHidden = zoneLabel.isHidden && startButton.isHidden
        divider.isHidden = controlsBar.isHidden
        divider.frame = NSRect(x: bounds.minX, y: bottom, width: bounds.width, height: 1)
        if !controlsBar.isHidden { bottom += 8 }
        clockFaceRect = clockFaceRect(focusMode: settings.focusMode)
        let availableHeight = clockFaceRect.height
        // Measure only the time. The status line and controls have fixed, readable sizes.
        var lower: CGFloat = 0.1
        var upper = max(bounds.width, bounds.height)
        for _ in 0..<20 {
            let candidate = (lower + upper) / 2
            let font = NSFont.monospacedDigitSystemFont(ofSize: candidate, weight: .bold)
            let size = Self.timeSize(timeLabel.stringValue, font: font)
            if size.width <= width && size.height <= availableHeight { lower = candidate }
            else { upper = candidate }
        }
        timeLabel.font = .monospacedDigitSystemFont(ofSize: lower, weight: .bold)
        let height = min(availableHeight, Self.timeSize(timeLabel.stringValue, font: timeLabel.font!).height)
        timeLabel.frame = NSRect(x: bounds.minX + inset, y: bottom + (availableHeight - height) / 2, width: width, height: height)
    }

    static func timeSize(_ text: String, font: NSFont) -> NSSize {
        let measured = (text as NSString).size(withAttributes: [.font: font])
        return NSSize(width: ceil(measured.width) + 4, height: ceil(font.ascender - font.descender + font.leading) + 4)
    }

    @objc private func applySettings() {
        let s = settings
        layer?.backgroundColor = s.backgroundColor.cgColor
        let rgb = s.backgroundColor.usingColorSpace(.sRGB) ?? .black
        let brightness = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
        appearance = NSAppearance(named: brightness < 0.5 ? .darkAqua : .aqua)
        controlsBar.appearance = NSApp.effectiveAppearance
        for button in [startButton, resetButton, durationButton] { button.appearance = NSApp.effectiveAppearance }
        modeSelector.appearance = NSApp.effectiveAppearance
        timeLabel.textColor = s.textColor
        zoneLabel.font = .systemFont(ofSize: 11)
        zoneLabel.appearance = NSApp.effectiveAppearance
        zoneLabel.textColor = .secondaryLabelColor
        zoneLabel.lineBreakMode = .byTruncatingTail
        zoneLabel.isHidden = !s.showStatusBar || s.focusMode
        modeSelector.isHidden = !s.showControls || !s.borderless || s.focusMode
        modeSelector.selectedSegment = ["Clock", "Countdown", "Stopwatch"].firstIndex(of: s.mode) ?? 0
        startButton.isHidden = !s.showControls || s.mode == "Clock" || s.focusMode
        resetButton.isHidden = startButton.isHidden
        durationButton.isHidden = !s.showControls || s.mode != "Countdown" || s.focusMode
        timeFormatter.timeZone = s.timeZone
        timeFormatter.dateFormat = s.use24Hour
            ? (s.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (s.showSeconds ? "h:mm:ss" : "h:mm")
        periodFormatter.timeZone = s.timeZone
        periodFormatter.dateFormat = "a"
        dateFormatter.timeZone = s.timeZone
        dateFormatter.dateFormat = "EEE, d MMM yyyy"
        clockTimer = s.timerState
        lastSecond = Int.min
        timer?.invalidate()
        let interval = s.mode != "Clock" && !clockTimer.isRunning ? 0.5
            : (s.showFrames ? 1.0 / s.frameRate.fps : (s.mode == "Clock" ? 0.2 : 0.05))
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        newTimer.tolerance = interval * 0.05
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        tick()
        needsLayout = true
    }

    private let timeFormatter = DateFormatter()
    private let periodFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()

    private func tick() {
        let s = settings
        let now = Date()
        let zone = s.timeZone
        let second = Int(now.timeIntervalSince1970)
        let refreshSecond = second != lastSecond
        if refreshSecond {
            lastSecond = second
            timeFormatter.timeZone = zone
            periodFormatter.timeZone = zone
            dateFormatter.timeZone = zone
            let date = dateFormatter.string(from: now)
            dateText = date
        }
        var time: String
        var footer: [String] = []
        if !s.customLabel.isEmpty { footer.append(s.customLabel) }
        if s.mode == "Clock" {
            time = timeFormatter.string(from: now)
            if s.showFrames {
                // Continuous timecode, anchored at local midnight. NDF intentionally drifts from civil time.
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = zone
                let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
                let seconds = Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0))
                    + Double(components.nanosecond ?? 0) / 1_000_000_000
                time = s.frameRate.timecode(seconds: seconds, wrap24Hours: true)
                footer.append(s.frameRate.title)
            } else if !s.use24Hour { time += " " + periodFormatter.string(from: now) }
            if s.showTimeZone {
                if refreshSecond {
                let name = s.usesSystemTimeZone || s.selectedCity.isEmpty
                    ? zone.identifier.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? zone.identifier
                    : s.selectedCity
                var label = name + " · " + TimeZoneEntry.abbreviation(for: zone, at: now)
                var local = Calendar(identifier: .gregorian)
                local.timeZone = .current
                var remote = local
                remote.timeZone = zone
                let localDay = local.dateComponents([.year, .month, .day], from: now)
                let remoteDay = remote.dateComponents([.year, .month, .day], from: now)
                if let first = local.date(from: localDay), let other = local.date(from: remoteDay) {
                    let difference = local.dateComponents([.day], from: first, to: other).day ?? 0
                    if difference > 0 { label += " · Tomorrow" }
                    if difference < 0 { label += " · Yesterday" }
                }
                cachedZoneFooter = label
                }
                footer.append(cachedZoneFooter)
            }
        } else {
            let remaining = clockTimer.remaining(at: now)
            let seconds = s.mode == "Countdown" ? remaining : clockTimer.elapsed(at: now)
            time = s.showFrames ? s.frameRate.timecode(seconds: seconds)
                : ClockTimerState.display(seconds: s.mode == "Countdown" ? ceil(seconds) : floor(seconds))
            let finished = s.mode == "Countdown" && remaining <= 0
            footer.append(s.mode + " · " + (finished ? "Finished" : (clockTimer.isRunning ? "Running" : "Paused")))
            if s.showFrames { footer.append(s.frameRate.title) }
            timeLabel.textColor = finished ? .systemRed : s.textColor
            if finished && !clockTimer.completionDelivered {
                clockTimer.completionDelivered = true
                clockTimer.accumulated = clockTimer.duration
                clockTimer.startedAt = nil
                ClockNotifications.finished(label: s.customLabel)
                s.timerState = clockTimer
            }
        }
        if s.showDate { footer.append(dateText) }
        let text = footer.joined(separator: " · ")
        if text != zoneLabel.stringValue { zoneLabel.stringValue = text; zoneLabel.toolTip = text }
        let buttonTitle = clockTimer.isRunning ? "Pause" : (clockTimer.accumulated > 0 ? "Resume" : "Start")
        if startButton.title != buttonTitle || startButton.image == nil {
            startButton.title = buttonTitle
            startButton.image = NSImage(systemSymbolName: clockTimer.isRunning ? "pause.fill" : "play.fill", accessibilityDescription: nil)
        }
        resetButton.isEnabled = clockTimer.accumulated > 0 || clockTimer.isRunning
        if time.count != timeLabel.stringValue.count { needsLayout = true }
        if timeLabel.stringValue != time { timeLabel.stringValue = time }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if settings.borderless || settings.focusMode {
            guard let next = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { return }
            if next.type == .leftMouseDragged { window?.performDrag(with: event); return }
        }
        if settings.mode != "Clock" && timeLabel.frame.contains(point) { toggleTimer() }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        // Preserve native interaction with the mode selector and buttons.
        return hit === timeLabel || hit === zoneLabel || hit === controlsBar || hit === divider ? self : hit
    }

    override func menu(for event: NSEvent) -> NSMenu? { commandMenu() }

    func commandMenu() -> NSMenu {
        let s = settings
        let menu = NSMenu()
        func toggle(_ title: String, _ action: Selector, _ enabled: Bool) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.state = enabled ? .on : .off
            menu.addItem(item)
        }
        for name in ["Clock", "Countdown", "Stopwatch"] {
            let item = NSMenuItem(title: name, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self; item.state = s.mode == name ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        toggle(clockTimer.isRunning ? "Pause" : "Start / Resume", #selector(toggleTimer), false)
        menu.items.last?.keyEquivalent = " "
        menu.items.last?.keyEquivalentModifierMask = []
        toggle("Reset", #selector(resetTimer), false)
        toggle("Set Countdown…", #selector(setCountdown), false)
        menu.addItem(.separator())
        toggle("Use 24-hour Time", #selector(toggle24Hour), s.use24Hour)
        toggle("Show Seconds", #selector(toggleSeconds), s.showSeconds)
        toggle("Show Frames", #selector(toggleFrames), s.showFrames)
        let rateItem = NSMenuItem(title: "Frame Rate", action: nil, keyEquivalent: "")
        let rates = NSMenu()
        for (index, rate) in FrameRate.all.enumerated() {
            let item = NSMenuItem(title: rate.title, action: #selector(selectFrameRate(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = s.frameRate == rate ? .on : .off
            rates.addItem(item)
        }
        rateItem.submenu = rates
        menu.addItem(rateItem)
        toggle("Clock-Only View", #selector(toggleFocusMode), s.focusMode)
        toggle("Show Status Bar", #selector(toggleStatusBar), s.showStatusBar)
        toggle("Show Controls", #selector(toggleControls), s.showControls)
        toggle("Show Date", #selector(toggleDate), s.showDate)
        toggle("Show Time Zone", #selector(toggleZone), s.showTimeZone)
        menu.addItem(.separator())
        toggle("Always on Top", #selector(toggleOnTop), s.alwaysOnTop)
        toggle("Borderless", #selector(toggleBorderless), s.borderless)
        toggle("Show on All Spaces", #selector(toggleSpaces), s.allSpaces)
        toggle("Rename Clock…", #selector(renameClock), false)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        let s = settings
        switch item.action {
        case #selector(toggleTimer):
            item.title = clockTimer.isRunning ? "Pause" : "Start / Resume"
            return s.mode != "Clock"
        case #selector(resetTimer): return s.mode != "Clock" && (clockTimer.accumulated > 0 || clockTimer.isRunning)
        case #selector(setCountdown): return s.mode == "Countdown"
        case #selector(selectMode(_:)): item.state = item.title == s.mode ? .on : .off
        case #selector(selectFrameRate(_:)): item.state = FrameRate.all[item.tag] == s.frameRate ? .on : .off
        case #selector(toggle24Hour): item.state = s.use24Hour ? .on : .off; return s.mode == "Clock" && !s.showFrames
        case #selector(toggleSeconds): item.state = s.showSeconds ? .on : .off; return s.mode == "Clock"
        case #selector(toggleFocusMode): item.state = s.focusMode ? .on : .off
        case #selector(toggleStatusBar): item.state = s.showStatusBar ? .on : .off
        case #selector(toggleControls): item.state = s.showControls ? .on : .off
        case #selector(toggleFrames): item.state = s.showFrames ? .on : .off
        case #selector(toggleDate): item.state = s.showDate ? .on : .off; return s.mode == "Clock"
        case #selector(toggleZone): item.state = s.showTimeZone ? .on : .off; return s.mode == "Clock"
        case #selector(toggleOnTop): item.state = s.alwaysOnTop ? .on : .off
        case #selector(toggleBorderless): item.state = s.borderless ? .on : .off
        case #selector(toggleSpaces): item.state = s.allSpaces ? .on : .off
        default: break
        }
        return true
    }

    @objc private func toggleFocusMode() { settings.focusMode.toggle() }
    @objc private func toggleStatusBar() { settings.showStatusBar.toggle() }
    @objc private func toggleControls() { settings.showControls.toggle() }
    @objc private func modeChanged() { settings.mode = ["Clock", "Countdown", "Stopwatch"][modeSelector.selectedSegment] }
    @objc private func toggle24Hour() { settings.use24Hour.toggle() }
    @objc private func toggleSeconds() { settings.showSeconds.toggle() }
    @objc private func toggleFrames() { settings.showFrames.toggle() }
    @objc private func toggleDate() { settings.showDate.toggle() }
    @objc private func toggleZone() { settings.showTimeZone.toggle() }
    @objc private func toggleOnTop() { settings.alwaysOnTop.toggle() }
    @objc private func selectFrameRate(_ item: NSMenuItem) { settings.frameRate = FrameRate.all[item.tag] }
    @objc private func openSettings() { onSettings?() }
    @objc private func toggleBorderless() { settings.borderless.toggle() }
    @objc private func toggleSpaces() { settings.allSpaces.toggle() }
    @objc private func selectMode(_ item: NSMenuItem) { settings.mode = item.title }
    @objc private func toggleTimer() {
        if settings.mode == "Countdown" && clockTimer.remaining(at: Date()) <= 0 { clockTimer.reset() }
        if settings.mode == "Countdown" { ClockNotifications.requestPermission() }
        clockTimer.toggle(at: Date()); settings.timerState = clockTimer
    }
    @objc private func resetTimer() { clockTimer.reset(); settings.timerState = clockTimer }
    @objc private func setCountdown() {
        guard let window, window.attachedSheet == nil else { return }
        durationSheet = DurationSheetController(duration: clockTimer.duration) { [weak self] duration in
            guard let self else { return }
            self.clockTimer.reset()
            self.clockTimer.duration = duration
            self.settings.timerState = self.clockTimer
        }
        durationSheet?.present(on: window)
    }
    @objc private func renameClock() {
        let alert = NSAlert(); alert.messageText = "Clock label"
        let field = NSTextField(string: settings.customLabel)
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field; alert.addButton(withTitle: "Save"); alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { settings.customLabel = field.stringValue }
    }
}
