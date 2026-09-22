import Cocoa

final class DurationSheetController: NSWindowController, NSTextFieldDelegate {
    private let hours = NSTextField(string: "0")
    private let minutes = NSTextField(string: "5")
    private let seconds = NSTextField(string: "0")
    private let errorLabel = NSTextField(labelWithString: "")
    private let saveButton = NSButton(title: "Set Duration", target: nil, action: nil)
    private var onSave: ((TimeInterval) -> Void)?

    init(duration: TimeInterval, onSave: @escaping (TimeInterval) -> Void) {
        self.onSave = onSave
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 202),
                            styleMask: [.titled], backing: .buffered, defer: false)
        panel.title = "Set Duration"
        panel.isReleasedWhenClosed = false
        super.init(window: panel)
        let total = Int(duration)
        hours.stringValue = String(total / 3600)
        minutes.stringValue = String((total / 60) % 60)
        seconds.stringValue = String(total % 60)
        let title = NSTextField(labelWithString: "Set Countdown Duration")
        title.font = .boldSystemFont(ofSize: 13)
        let columns = zip(["Hours", "Minutes", "Seconds"], [hours, minutes, seconds]).map { name, field -> NSView in
            field.alignment = .right
            field.font = .monospacedDigitSystemFont(ofSize: 20, weight: .regular)
            field.delegate = self
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            formatter.allowsFloats = false
            formatter.minimum = 0
            formatter.maximum = name == "Hours" ? 168 : 59
            field.formatter = formatter
            field.bezelStyle = .roundedBezel
            field.setAccessibilityLabel(name)
            field.widthAnchor.constraint(equalToConstant: 88).isActive = true
            let label = NSTextField(labelWithString: name)
            label.font = .systemFont(ofSize: 11); label.textColor = .secondaryLabelColor
            let stack = NSStackView(views: [label, field])
            stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 6
            return stack
        }
        let fields = NSStackView(views: columns); fields.spacing = 16
        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.stringValue = "Hours: 0–168. Minutes and seconds: 0–59."
        errorLabel.maximumNumberOfLines = 2
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelSheet))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let save = saveButton
        save.target = self; save.action = #selector(saveDuration)
        save.bezelStyle = .rounded; save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, save]); buttons.spacing = 8
        let content = NSView()
        for view in [title, fields, errorLabel, buttons] { view.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(view) }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            fields.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            fields.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            errorLabel.topAnchor.constraint(equalTo: fields.bottomAnchor, constant: 8),
            errorLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            errorLabel.heightAnchor.constraint(equalToConstant: 30),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
        panel.contentView = content
    }
    required init?(coder: NSCoder) { fatalError() }
    func present(on parent: NSWindow) {
        guard let window else { return }
        parent.beginSheet(window)
        window.makeFirstResponder(hours)
        hours.selectText(nil)
    }
    @objc private func cancelSheet() { if let window { window.sheetParent?.endSheet(window) } }
    func controlTextDidChange(_ obj: Notification) { validateDuration() }

    @discardableResult private func validateDuration() -> TimeInterval? {
        let fields = [hours, minutes, seconds]
        let values = fields.map { $0.currentEditor()?.string ?? $0.stringValue }
        let duration = ClockTimerState.parseDuration(values.joined(separator: ":"))
        saveButton.isEnabled = duration != nil
        if duration != nil {
            errorLabel.textColor = .secondaryLabelColor
            errorLabel.stringValue = "Hours: 0–168. Minutes and seconds: 0–59."
        } else {
            errorLabel.textColor = .systemRed
            if let h = Int(values[0]), h > 168 { errorLabel.stringValue = "Hours must be between 0 and 168 (7 days)." }
            else if let m = Int(values[1]), m > 59 { errorLabel.stringValue = "Minutes must be between 0 and 59." }
            else if let s = Int(values[2]), s > 59 { errorLabel.stringValue = "Seconds must be between 0 and 59." }
            else { errorLabel.stringValue = "Choose a total from 1 second to 7 days." }
        }
        return duration
    }

    @objc private func saveDuration() {
        guard let duration = validateDuration() else { return }
        onSave?(duration)
        cancelSheet()
    }
}
