import Cocoa
import ServiceManagement

final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clock Preferences"
        window.center()
        self.init(window: window)
        buildUI()
    }

    private func buildUI() {
        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(displayTab())
        tabView.addTabViewItem(timeZoneTab())
        tabView.addTabViewItem(appearanceTab())
        tabView.addTabViewItem(windowTab())

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
    private var fontSizeSlider: NSSlider!
    private var fontSizeValueLabel: NSTextField!

    private func displayTab() -> NSTabViewItem {
        let s = Settings.shared
        let item = NSTabViewItem(identifier: "display")
        item.label = "Display"

        use24HourCheckbox = checkbox("Use 24-hour time", isOn: s.use24Hour, action: #selector(use24HourChanged))
        showSecondsCheckbox = checkbox("Show seconds", isOn: s.showSeconds, action: #selector(showSecondsChanged))
        showDateCheckbox = checkbox("Show date", isOn: s.showDate, action: #selector(showDateChanged))

        fontSizeSlider = NSSlider(value: s.fontSize, minValue: 40, maxValue: 300, target: self, action: #selector(fontSizeChanged))
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        fontSizeSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        fontSizeValueLabel = NSTextField(labelWithString: "\(Int(s.fontSize))pt")
        fontSizeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let sliderRow = NSStackView(views: [NSTextField(labelWithString: "Clock size:"), fontSizeSlider, fontSizeValueLabel])
        sliderRow.orientation = .horizontal
        sliderRow.spacing = 8

        item.view = wrapped(verticalStack([use24HourCheckbox, showSecondsCheckbox, showDateCheckbox, sliderRow]))
        return item
    }

    @objc private func use24HourChanged() { Settings.shared.use24Hour = use24HourCheckbox.state == .on }
    @objc private func showSecondsChanged() { Settings.shared.showSeconds = showSecondsCheckbox.state == .on }
    @objc private func showDateChanged() { Settings.shared.showDate = showDateCheckbox.state == .on }

    @objc private func fontSizeChanged() {
        let value = fontSizeSlider.doubleValue
        Settings.shared.fontSize = value
        fontSizeValueLabel.stringValue = "\(Int(value))pt"
    }

    // MARK: - Time Zone

    private var timeZoneCombo: NSComboBox!

    private func timeZoneTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "timezone")
        item.label = "Time Zone"

        let identifiers = TimeZone.knownTimeZoneIdentifiers.sorted()
        timeZoneCombo = NSComboBox()
        timeZoneCombo.translatesAutoresizingMaskIntoConstraints = false
        timeZoneCombo.widthAnchor.constraint(equalToConstant: 300).isActive = true
        timeZoneCombo.completes = true
        timeZoneCombo.addItems(withObjectValues: identifiers)
        timeZoneCombo.stringValue = Settings.shared.timeZoneIdentifier
        timeZoneCombo.target = self
        timeZoneCombo.action = #selector(timeZoneChanged)
        timeZoneCombo.delegate = self

        let hint = NSTextField(wrappingLabelWithString: "Start typing a city or region, e.g. \"Berlin\", \"New_York\", \"Tokyo\". CEST = Europe/Berlin (or any other Central European city) in summer.")
        hint.textColor = .secondaryLabelColor
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.preferredMaxLayoutWidth = 300

        item.view = wrapped(verticalStack([timeZoneCombo, hint]))
        return item
    }

    @objc private func timeZoneChanged() {
        let candidate = timeZoneCombo.stringValue
        if TimeZone(identifier: candidate) != nil {
            Settings.shared.timeZoneIdentifier = candidate
        }
    }

    // MARK: - Appearance

    private var backgroundColorWell: NSColorWell!
    private var textColorWell: NSColorWell!

    private func appearanceTab() -> NSTabViewItem {
        let s = Settings.shared
        let item = NSTabViewItem(identifier: "appearance")
        item.label = "Appearance"

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

        item.view = wrapped(verticalStack([bgRow, textRow]))
        return item
    }

    @objc private func backgroundColorChanged() { Settings.shared.backgroundColor = backgroundColorWell.color }
    @objc private func textColorChanged() { Settings.shared.textColor = textColorWell.color }

    // MARK: - Window

    private var alwaysOnTopCheckbox: NSButton!
    private var rememberFrameCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!

    private func windowTab() -> NSTabViewItem {
        let s = Settings.shared
        let item = NSTabViewItem(identifier: "window")
        item.label = "Window"

        alwaysOnTopCheckbox = checkbox("Always on top", isOn: s.alwaysOnTop, action: #selector(alwaysOnTopChanged))
        rememberFrameCheckbox = checkbox("Remember window size & position", isOn: s.rememberWindowFrame, action: #selector(rememberFrameChanged))
        launchAtLoginCheckbox = checkbox("Launch at login", isOn: s.launchAtLogin, action: #selector(launchAtLoginChanged))

        let hint = NSTextField(wrappingLabelWithString: "Launch at login only takes effect once Clock.app is installed in /Applications (not when run via \"swift run\").")
        hint.textColor = .secondaryLabelColor
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.preferredMaxLayoutWidth = 300

        item.view = wrapped(verticalStack([alwaysOnTopCheckbox, rememberFrameCheckbox, launchAtLoginCheckbox, hint]))
        return item
    }

    @objc private func alwaysOnTopChanged() { Settings.shared.alwaysOnTop = alwaysOnTopCheckbox.state == .on }
    @objc private func rememberFrameChanged() { Settings.shared.rememberWindowFrame = rememberFrameCheckbox.state == .on }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginCheckbox.state == .on
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            Settings.shared.launchAtLogin = enabled
        } catch {
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

extension PreferencesWindowController: NSComboBoxDelegate {
    func comboBoxWillDismiss(_ notification: Notification) {
        timeZoneChanged()
    }
}
