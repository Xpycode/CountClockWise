import Cocoa
import ServiceManagement

final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController(settings: .shared)
    private var settings: Settings = .shared
    private var shortcut: GlobalShortcut?

    convenience init(settings: Settings, shortcut: GlobalShortcut? = nil) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Count Clock Wise Preferences"
        window.center()
        self.init(window: window)
        self.settings = settings
        self.shortcut = shortcut
        buildUI()
        refreshDisplayControls()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDisplayControls),
                                               name: .settingsDidChange, object: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDisplayControls),
                                               name: .appAppearanceDidChange, object: nil)
    }

    private func buildUI() {
        let tabView = NSTabView()
        tabView.delegate = self
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(displayTab())
        tabView.addTabViewItem(timeZoneTab())
        tabView.addTabViewItem(appearanceTab())
        tabView.addTabViewItem(windowTab())
        tabView.addTabViewItem(updatesTab())

        let contentView = NSView()
        contentView.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
        window?.contentView = contentView
    }

    // MARK: - Display

    private var use24HourCheckbox: NSButton!
    private var showSecondsCheckbox: NSButton!
    private var showDateCheckbox: NSButton!
    private var showTimeZoneCheckbox: NSButton!
    private var showStatusCheckbox: NSButton!
    private var showControlsCheckbox: NSButton!
    private var showFramesCheckbox: NSButton!
    private var frameRatePopup: NSPopUpButton!

    private func displayTab() -> NSTabViewItem {
        let s = settings
        let item = NSTabViewItem(identifier: "display")
        item.label = "Display"

        use24HourCheckbox = checkbox("Use 24-hour time", isOn: s.use24Hour, action: #selector(use24HourChanged))
        showSecondsCheckbox = checkbox("Show seconds", isOn: s.showSeconds, action: #selector(showSecondsChanged))
        showDateCheckbox = checkbox("Show date", isOn: s.showDate, action: #selector(showDateChanged))

        showStatusCheckbox = checkbox("Show status bar (date, time zone and FPS)", isOn: s.showStatusBar, action: #selector(showStatusChanged))
        showControlsCheckbox = checkbox("Show mode selector and timer buttons", isOn: s.showControls, action: #selector(showControlsChanged))
        showTimeZoneCheckbox = checkbox("Show time zone", isOn: s.showTimeZone, action: #selector(showTimeZoneChanged))
        showFramesCheckbox = checkbox("Show frames (includes seconds)", isOn: s.showFrames, action: #selector(showFramesChanged))
        frameRatePopup = NSPopUpButton()
        frameRatePopup.addItems(withTitles: FrameRate.all.map(\.title))
        frameRatePopup.selectItem(at: FrameRate.all.firstIndex(of: s.frameRate)!)
        frameRatePopup.target = self
        frameRatePopup.action = #selector(frameRateChanged)

        let hint = NSTextField(wrappingLabelWithString: "Frames use 24-hour timecode. Fractional NDF runs slightly behind wall time; DF corrects this by skipping frame numbers. Choose Clock, Countdown or Stopwatch in the Controls menu.")
        hint.font = .systemFont(ofSize: 11); hint.textColor = .secondaryLabelColor
        hint.preferredMaxLayoutWidth = 500
        item.view = wrapped(verticalStack([use24HourCheckbox, showSecondsCheckbox, showDateCheckbox, showTimeZoneCheckbox, showStatusCheckbox, showControlsCheckbox, showFramesCheckbox, labeledRow("Frame rate:", frameRatePopup), hint]))
        return item
    }

    @objc private func use24HourChanged() { settings.use24Hour = use24HourCheckbox.state == .on }
    @objc private func showSecondsChanged() { settings.showSeconds = showSecondsCheckbox.state == .on }
    @objc private func showDateChanged() { settings.showDate = showDateCheckbox.state == .on }

    @objc private func showStatusChanged() { settings.showStatusBar = showStatusCheckbox.state == .on }
    @objc private func showControlsChanged() { settings.showControls = showControlsCheckbox.state == .on }
    @objc private func showTimeZoneChanged() { settings.showTimeZone = showTimeZoneCheckbox.state == .on }
    @objc private func showFramesChanged() { settings.showFrames = showFramesCheckbox.state == .on }
    @objc private func frameRateChanged() {
        settings.frameRate = FrameRate.all[frameRatePopup.indexOfSelectedItem]
    }

    @objc private func refreshDisplayControls() {
        let s = settings
        use24HourCheckbox.state = s.use24Hour ? .on : .off
        use24HourCheckbox.isEnabled = s.mode == "Clock" && !s.showFrames
        showSecondsCheckbox.isEnabled = s.mode == "Clock"
        showDateCheckbox.isEnabled = s.mode == "Clock"
        showTimeZoneCheckbox.isEnabled = s.mode == "Clock"
        showSecondsCheckbox.state = s.showSeconds ? .on : .off
        showDateCheckbox.state = s.showDate ? .on : .off
        showTimeZoneCheckbox.state = s.showTimeZone ? .on : .off
        showStatusCheckbox.state = s.showStatusBar ? .on : .off
        showControlsCheckbox.state = s.showControls ? .on : .off
        showFramesCheckbox.state = s.showFrames ? .on : .off
        frameRatePopup.selectItem(at: FrameRate.all.firstIndex(of: s.frameRate)!)
        alwaysOnTopCheckbox.state = s.alwaysOnTop ? .on : .off
        borderlessCheckbox.state = s.borderless ? .on : .off
        spacesCheckbox.state = s.allSpaces ? .on : .off
        opacitySlider.doubleValue = s.opacity
        opacityLabel.stringValue = "\(Int(s.opacity * 100))%"
        appearancePopup.selectItem(at: AppAppearance.allCases.firstIndex(of: .current) ?? 0)
        backgroundColorWell.color = s.backgroundColor
        textColorWell.color = s.textColor
    }

    // MARK: - Time Zone

    private func timeZoneTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "timezone")
        item.label = "Time Zone"
        item.view = TimeZonePickerView(settings: settings)
        return item
    }

    // MARK: - Appearance

    private var backgroundColorWell: NSColorWell!
    private var textColorWell: NSColorWell!
    private var appearancePopup: NSPopUpButton!

    private func appearanceTab() -> NSTabViewItem {
        let s = settings
        let item = NSTabViewItem(identifier: "appearance")
        item.label = "Appearance"

        appearancePopup = NSPopUpButton()
        appearancePopup.addItems(withTitles: AppAppearance.allCases.map(\.title))
        appearancePopup.selectItem(at: AppAppearance.allCases.firstIndex(of: .current) ?? 0)
        appearancePopup.target = self
        appearancePopup.action = #selector(appearanceChanged)

        backgroundColorWell = NSColorWell()
        backgroundColorWell.color = s.backgroundColor
        backgroundColorWell.target = self
        backgroundColorWell.action = #selector(backgroundColorChanged)

        textColorWell = NSColorWell()
        textColorWell.color = s.textColor
        textColorWell.target = self
        textColorWell.action = #selector(textColorChanged)

        let bgRow = labeledRow("Background color:", backgroundColorWell)
        let textRow = labeledRow("Text color:", textColorWell)

        let hint = NSTextField(wrappingLabelWithString: "App appearance applies to all windows and controls. Clock colors apply only to the selected clock.")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.preferredMaxLayoutWidth = 500
        item.view = wrapped(verticalStack([labeledRow("App appearance:", appearancePopup), bgRow, textRow, hint]))
        return item
    }

    @objc private func backgroundColorChanged() { settings.backgroundColor = backgroundColorWell.color }
    @objc private func textColorChanged() { settings.textColor = textColorWell.color }
    @objc private func appearanceChanged() {
        guard AppAppearance.allCases.indices.contains(appearancePopup.indexOfSelectedItem) else { return }
        AppAppearance.current = AppAppearance.allCases[appearancePopup.indexOfSelectedItem]
    }

    // MARK: - Window

    private var alwaysOnTopCheckbox: NSButton!
    private var rememberFrameCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var borderlessCheckbox: NSButton!
    private var spacesCheckbox: NSButton!
    private var opacitySlider: NSSlider!
    private var opacityLabel: NSTextField!

    private func windowTab() -> NSTabViewItem {
        let s = settings
        let item = NSTabViewItem(identifier: "window")
        item.label = "Window"

        alwaysOnTopCheckbox = checkbox("Always on top", isOn: s.alwaysOnTop, action: #selector(alwaysOnTopChanged))
        rememberFrameCheckbox = checkbox("Remember window size & position", isOn: s.rememberWindowFrame, action: #selector(rememberFrameChanged))
        launchAtLoginCheckbox = checkbox("Launch at login", isOn: s.launchAtLogin, action: #selector(launchAtLoginChanged))

        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        borderlessCheckbox = checkbox("Borderless (drag anywhere; right-click to restore)", isOn: s.borderless, action: #selector(borderlessChanged))
        spacesCheckbox = checkbox("Show on all Spaces and over full-screen apps", isOn: s.allSpaces, action: #selector(spacesChanged))
        opacitySlider = NSSlider(value: s.opacity, minValue: 0.2, maxValue: 1, target: self, action: #selector(opacityChanged))
        opacitySlider.widthAnchor.constraint(equalToConstant: 220).isActive = true
        opacityLabel = NSTextField(labelWithString: "\(Int(s.opacity * 100))%")
        let hint = NSTextField(wrappingLabelWithString: "The global shortcut and login launch apply to the whole app. Keep Count Clock Wise.app in a stable location, such as Applications.")
        hint.textColor = .secondaryLabelColor; hint.font = .systemFont(ofSize: 11)
        hint.preferredMaxLayoutWidth = 500
        var rows: [NSView] = [alwaysOnTopCheckbox, borderlessCheckbox, spacesCheckbox,
            labeledRow("Opacity:", NSStackView(views: [opacitySlider, opacityLabel])), rememberFrameCheckbox, launchAtLoginCheckbox]
        if let shortcut { rows.append(ShortcutPreferencesView(shortcut: shortcut)) }
        rows.append(hint)
        item.view = wrapped(verticalStack(rows))
        return item
    }

    @objc private func borderlessChanged() { settings.borderless = borderlessCheckbox.state == .on }
    @objc private func spacesChanged() { settings.allSpaces = spacesCheckbox.state == .on }
    @objc private func opacityChanged() { settings.opacity = opacitySlider.doubleValue }

    private var automaticUpdatesCheckbox: NSButton!
    private func updatesTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "updates")
        item.label = "Updates"
        automaticUpdatesCheckbox = checkbox("Automatically check for updates", isOn: ClockUpdater.shared.automaticallyChecks, action: #selector(automaticUpdatesChanged))
        automaticUpdatesCheckbox.isEnabled = ClockUpdater.shared.isConfigured
        let check = NSButton(title: "Check for Updates…", target: ClockUpdater.shared, action: #selector(ClockUpdater.checkForUpdates(_:)))
        check.bezelStyle = .rounded
        let note = NSTextField(wrappingLabelWithString: ClockUpdater.shared.isConfigured
            ? "Count Clock Wise checks for signed releases. You choose when to install an update."
            : "Updates will become available when the public release channel is ready. This build is for local testing.")
        note.preferredMaxLayoutWidth = 500
        note.textColor = .secondaryLabelColor
        item.view = wrapped(verticalStack([automaticUpdatesCheckbox, check, note]))
        return item
    }
    @objc private func automaticUpdatesChanged() {
        ClockUpdater.shared.automaticallyChecks = automaticUpdatesCheckbox.state == .on
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func alwaysOnTopChanged() { settings.alwaysOnTop = alwaysOnTopCheckbox.state == .on }
    @objc private func rememberFrameChanged() { settings.rememberWindowFrame = rememberFrameCheckbox.state == .on }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginCheckbox.state == .on
        do {
            if enabled {
                guard Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" else {
                    throw NSError(domain: "Clock", code: 1, userInfo: [NSLocalizedDescriptionKey: "Open the packaged Count Clock Wise.app to enable Launch at Login."])
                }
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } catch {
            DiagnosticLogger.shared.record("login.registration.failed", error: error)
            launchAtLoginCheckbox.state = enabled ? .off : .on
            let alert = NSAlert()
            alert.messageText = "Couldn't update Login Item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    // MARK: - Helpers

    private func checkbox(_ title: String, isOn: Bool, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.state = isOn ? .on : .off
        return button
    }

    private func labeledRow(_ title: String, _ control: NSView) -> NSStackView {
        let row = NSStackView(views: [NSTextField(labelWithString: title), control])
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }

    private func verticalStack(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func wrapped(_ view: NSView) -> NSView {
        let container = NSView()
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
        ])
        return container
    }
}

extension PreferencesWindowController: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        let identifier = tabViewItem?.identifier as? String
        let height: CGFloat = identifier == "timezone" ? 460 : (identifier == "appearance" ? 280 : (identifier == "window" ? 510 : 420))
        guard let window else { return }
        let oldTop = window.frame.maxY
        var frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 620, height: height))
        frame.origin = NSPoint(x: window.frame.minX, y: oldTop - frame.height)
        window.setFrame(frame, display: true, animate: window.isVisible)
    }
}
