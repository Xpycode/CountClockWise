import Cocoa
import Carbon

/// Uses the app's existing registration owner; opening preferences never registers a second hotkey.
final class ShortcutPreferencesView: NSView {
    private let shortcut: GlobalShortcut
    private let value = NSTextField(labelWithString: "")
    private let message = NSTextField(wrappingLabelWithString: "")
    private let recordButton = NSButton(title: "Record Shortcut…", target: nil, action: nil)
    private var monitor: Any?
    private var recording = false

    init(shortcut: GlobalShortcut) {
        self.shortcut = shortcut
        super.init(frame: .zero)
        recordButton.target = self
        recordButton.action = #selector(record)
        let clear = NSButton(title: "Clear", target: self, action: #selector(clearShortcut))
        let restore = NSButton(title: "Restore Default", target: self, action: #selector(restoreDefault))
        value.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        value.setAccessibilityLabel("Global visibility shortcut")
        message.font = .systemFont(ofSize: 11)
        message.textColor = .secondaryLabelColor
        message.preferredMaxLayoutWidth = 490
        let buttons = NSStackView(views: [recordButton, clear, restore])
        buttons.spacing = 8
        let title = NSTextField(labelWithString: "Show or hide all clock windows from any app:")
        let stack = NSStackView(views: [title, value, buttons, message])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .globalShortcutDidChange, object: shortcut)
        NotificationCenter.default.addObserver(self, selector: #selector(windowResigned(_:)), name: NSWindow.didResignKeyNotification, object: nil)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var acceptsFirstResponder: Bool { true }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    @objc private func refresh() {
        value.stringValue = shortcut.displayString
        if !recording {
            message.stringValue = shortcut.lastError ?? "Click Record Shortcut, then press a combination. Escape cancels. The default is \(ShortcutBinding.defaultBinding.displayString). Clear disables the global shortcut."
            message.textColor = shortcut.lastError == nil ? .secondaryLabelColor : .systemRed
        }
    }

    @objc private func record() {
        if recording { stopRecording(); return }
        guard let window, window.makeFirstResponder(self) else { return }
        recording = true
        shortcut.isRecording = true
        recordButton.title = "Cancel Recording"
        message.stringValue = "Press a shortcut with Control, Option or Command. Escape cancels."
        message.textColor = .secondaryLabelColor
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.recording else { return event }
            guard self.window?.isKeyWindow == true, self.window?.firstResponder === self,
                  !self.isHiddenOrHasHiddenAncestor else { self.stopRecording(); return event }
            if event.type != .keyDown {
                let cancelsButton = self.recordButton.bounds.contains(self.recordButton.convert(event.locationInWindow, from: nil))
                self.stopRecording()
                return cancelsButton ? nil : event
            }
            guard !event.isARepeat else { return nil }
            self.stopRecording()
            if event.keyCode != UInt16(kVK_Escape) { self.apply(ShortcutBinding(event: event)) }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = false
        shortcut.isRecording = false
        recordButton.title = "Record Shortcut…"
        refresh()
    }

    @objc private func clearShortcut() { stopRecording(); apply(nil) }
    @objc private func restoreDefault() { stopRecording(); apply(.defaultBinding) }

    private func apply(_ binding: ShortcutBinding?) {
        do { try shortcut.setShortcut(binding) }
        catch { message.stringValue = error.localizedDescription; message.textColor = .systemRed }
    }

    @objc private func windowResigned(_ notification: Notification) {
        if let source = notification.object as? NSWindow, source === window { stopRecording() }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { stopRecording() }
        super.viewWillMove(toWindow: newWindow)
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
        shortcut.isRecording = false
        NotificationCenter.default.removeObserver(self)
    }
}
