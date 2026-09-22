import Cocoa
import UserNotifications

final class ClockWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class ClockWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    private let modeControl = NSSegmentedControl(labels: ["Clock", "Countdown", "Stopwatch"], trackingMode: .selectOne, target: nil, action: nil)
    private let modeItemID = NSToolbarItem.Identifier("clockMode")
    let settings: Settings
    let clockView: ClockView
    private var preferences: PreferencesWindowController?
    private let clockToolbar = NSToolbar(identifier: "ClockToolbar")
    private var showingFocusMode = false
    var onClose: (() -> Void)?

    init(settings: Settings) {
        self.settings = settings
        let frame = NSRect(x: 0, y: 0, width: 900, height: 300)
        clockView = ClockView(frame: frame, settings: settings)
        let window = ClockWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.minSize = NSSize(width: 400, height: 120)
        window.contentView = clockView
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        let toolbar = clockToolbar
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifier = modeItemID
        window.toolbarStyle = .expanded
        window.toolbar = toolbar
        modeControl.target = self
        modeControl.action = #selector(selectToolbarMode)
        modeControl.setAccessibilityLabel("Clock mode")
        for (index, mode) in ["Clock", "Countdown", "Stopwatch"].enumerated() {
            modeControl.setToolTip("Show " + mode, forSegment: index)
        }
        window.center()
        if settings.rememberWindowFrame && !settings.focusMode { window.setFrameAutosaveName("Clock-" + settings.id) }
        clockView.onSettings = { [weak self] in self?.showSettings() }
        NotificationCenter.default.addObserver(self, selector: #selector(applySettings), name: .settingsDidChange, object: settings)
        applySettings()
    }
    required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func applySettings() {
        guard let window else { return }
        let focusChanged = showingFocusMode != settings.focusMode
        let faceFrame = window.convertToScreen(clockView.convert(clockView.clockFaceRect(focusMode: showingFocusMode), to: nil))
        if focusChanged && settings.focusMode {
            if settings.rememberWindowFrame { window.saveFrame(usingName: "Clock-" + settings.id) }
            window.setFrameAutosaveName("")
        }
        let borderless = settings.borderless || settings.focusMode
        var desired: NSWindow.StyleMask = borderless ? [.borderless, .resizable] : [.titled, .closable, .miniaturizable, .resizable]
        if window.styleMask.contains(.fullScreen) { desired.insert(.fullScreen) }
        if window.styleMask != desired {
            let frame = window.frame
            window.styleMask = desired
            window.setFrame(frame, display: true)
        }
        if !borderless && window.toolbar == nil { window.toolbar = clockToolbar }
        clockToolbar.isVisible = settings.showControls && !borderless
        modeControl.selectedSegment = ["Clock", "Countdown", "Stopwatch"].firstIndex(of: settings.mode) ?? 0
        window.minSize = NSSize(width: 400, height: settings.focusMode ? 64 : (settings.showControls ? (settings.mode != "Clock" ? 220 : 160) : 120))
        if window.frame.height < window.minSize.height {
            var frame = window.frame
            frame.origin.y -= window.minSize.height - frame.height
            frame.size.height = window.minSize.height
            window.setFrame(frame, display: true)
        }
        window.title = settings.customLabel.isEmpty ? settings.mode : settings.customLabel
        window.subtitle = settings.mode == "Clock" ? (settings.selectedCity.isEmpty ? settings.timeZone.identifier : settings.selectedCity) : ""
        window.level = settings.alwaysOnTop ? .floating : .normal
        window.alphaValue = settings.opacity
        window.collectionBehavior = settings.allSpaces ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.fullScreenPrimary]
        window.isMovableByWindowBackground = borderless
        if focusChanged {
            showingFocusMode = settings.focusMode
            // Add/remove chrome around the current clock area, including manual resizing.
            let newFaceFrame = window.convertToScreen(clockView.convert(clockView.clockFaceRect(focusMode: settings.focusMode), to: nil))
            var frame = window.frame
            frame.origin.x += faceFrame.minX - newFaceFrame.minX
            frame.origin.y += faceFrame.minY - newFaceFrame.minY
            frame.size.width = max(window.minSize.width, frame.width + faceFrame.width - newFaceFrame.width)
            frame.size.height = max(window.minSize.height, frame.height + faceFrame.height - newFaceFrame.height)
            window.setFrame(frame, display: true)
            clockView.needsLayout = true
        }
        if settings.rememberWindowFrame && !settings.focusMode {
            let autosaveName = "Clock-" + settings.id
            // Reattaching autosave also restores its saved frame. Replace the stale normal
            // frame first so it cannot undo the geometry calculated when leaving focus mode.
            if focusChanged { window.saveFrame(usingName: autosaveName) }
            window.setFrameAutosaveName(autosaveName)
        }
        else { window.setFrameAutosaveName("") }
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [.flexibleSpace, modeItemID] }
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [.flexibleSpace, modeItemID, .flexibleSpace] }
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard identifier == modeItemID else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "Mode"
        item.view = modeControl
        modeControl.frame = NSRect(x: 0, y: 0, width: 290, height: 28)
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        if modeControl.constraints.isEmpty {
            modeControl.widthAnchor.constraint(equalToConstant: 290).isActive = true
            modeControl.heightAnchor.constraint(equalToConstant: 28).isActive = true
        }
        return item
    }
    @objc private func selectToolbarMode() { settings.mode = ["Clock", "Countdown", "Stopwatch"][modeControl.selectedSegment] }

    func showSettings() {
        if preferences == nil { preferences = PreferencesWindowController(settings: settings) }
        preferences?.showWindow(nil)
        preferences?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func windowWillClose(_ notification: Notification) { preferences?.close(); onClose?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate, NSMenuItemValidation {
    private var clocks: [ClockWindowController] = []
    private var statusItem: NSStatusItem!
    private var shortcut: GlobalShortcut?
    private var quitting = false
    private var keyMonitor: Any?
    private weak var lastActive: ClockWindowController?
    private let displayMenu = NSMenu(title: "Controls")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMainMenu()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 48, event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty,
                  let self, let clock = self.clocks.first(where: { $0.window === NSApp.keyWindow }),
                  clock.window?.attachedSheet == nil,
                  !(clock.window?.firstResponder is NSTextView) else { return event }
            clock.settings.focusMode.toggle()
            return nil
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCommands), name: .settingsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCommands), name: NSWindow.didBecomeMainNotification, object: nil)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Clock")
        let menu = NSMenu()
        add(menu, "Show / Hide All Clocks", #selector(toggleVisibility))
        add(menu, "New Clock", #selector(newClock))
        add(menu, "Settings…", #selector(showPreferences))
        menu.addItem(.separator()); add(menu, "Quit Clock", #selector(quit))
        statusItem.menu = menu
        shortcut = GlobalShortcut { [weak self] in self?.toggleVisibility() }
        if shortcut?.register() != true {
            let alert = NSAlert(); alert.messageText = "Clock shortcut is unavailable"
            alert.informativeText = "Control–Option–Command–C may be used by another app. Show and hide clocks using Clock’s menu bar icon."
            alert.runModal()
        }
        let ids = UserDefaults.standard.stringArray(forKey: "clockWindowIDs") ?? ["primary"]
        for id in ids { createClock(id: id) }
        if clocks.isEmpty { createClock(id: "primary") }
        if Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" { UNUserNotificationCenter.current().delegate = self }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createClock(id: String) {
        let controller = ClockWindowController(settings: id == "primary" ? .shared : Settings(id: id))
        controller.onClose = { [weak self, weak controller] in
            guard let self, !self.quitting, let controller else { return }
            self.clocks.removeAll { $0 === controller }
            self.persistWindows()
        }
        clocks.append(controller)
        if displayMenu.items.isEmpty {
            let commands = controller.clockView.commandMenu()
            for item in commands.items { commands.removeItem(item); displayMenu.addItem(item) }
        }
        controller.window?.makeKeyAndOrderFront(nil)
        lastActive = controller
        persistWindows()
    }
    private func persistWindows() { UserDefaults.standard.set(clocks.map { $0.settings.id }, forKey: "clockWindowIDs") }
    private var activeClock: ClockWindowController? {
        if let active = clocks.first(where: { $0.window === NSApp.mainWindow || $0.window === NSApp.keyWindow }) {
            lastActive = active; return active
        }
        return lastActive ?? clocks.first
    }
    @objc private func newClock() { createClock(id: UUID().uuidString); NSApp.activate(ignoringOtherApps: true) }
    @objc func showPreferences() {
        if clocks.isEmpty { createClock(id: "primary") }
        activeClock?.showSettings()
    }
    @objc private func toggleVisibility() {
        if clocks.isEmpty { createClock(id: "primary") }
        else if clocks.contains(where: { $0.window?.isVisible == true && $0.window?.isMiniaturized == false }) {
            for clock in clocks { clock.window?.orderOut(nil) }
        } else {
            for clock in clocks { clock.window?.deminiaturize(nil); clock.window?.makeKeyAndOrderFront(nil) }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(toggleFocusMode) {
            item.state = activeClock?.settings.focusMode == true ? .on : .off
            return clocks.contains { $0.window === NSApp.keyWindow && $0.window?.attachedSheet == nil }
        }
        return true
    }
    @objc private func toggleFocusMode() { activeClock?.settings.focusMode.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func about() {
        NSApp.orderFrontStandardAboutPanel(options: [.credits: NSAttributedString(string: "Offline city data: GeoNames (CC BY 4.0).\nTime-zone country mapping: IANA (public domain).\nSee Help → Clock Help for details.")])
    }
    @objc private func help() {
        let alert = NSAlert(); alert.messageText = "Clock"
        alert.informativeText = "Create independent clocks with File → New Clock. Use the Controls menu or right-click a clock to change mode, start/pause/reset timers, or set a countdown.\n\nSettings apply to the selected clock. Borderless clocks can be dragged anywhere; right-click to restore the title bar. Control–Option–Command–C shows/hides all clocks.\n\nFractional frame timecode counts continuously from local midnight (or timer start). NDF differs from wall time; DF skips frame numbers at minute boundaries. This is a display, not an LTC/MTC synchronization source.\n\nCity data: geonames.org, CC BY 4.0 (creativecommons.org/licenses/by/4.0/). Includes cities above 15,000 population and capitals."
        alert.runModal()
    }
    @objc private func refreshCommands() {
        menuNeedsUpdate(displayMenu)
        displayMenu.update()
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === displayMenu else { return }
        // Keep item identities stable while AppKit tracks the menu (including accessibility).
        func retarget(_ menu: NSMenu) {
            for item in menu.items {
                if item.action != nil { item.target = activeClock?.clockView }
                if let submenu = item.submenu { retarget(submenu) }
            }
        }
        retarget(menu)
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String = "", target: AnyObject? = nil) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target ?? self; menu.addItem(item)
    }
    private func buildMainMenu() {
        let main = NSMenu()
        func submenu(_ name: String) -> NSMenu {
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            let menu = NSMenu(title: name); item.submenu = menu; main.addItem(item); return menu
        }
        let app = submenu("Clock")
        add(app, "About Clock", #selector(about)); app.addItem(.separator())
        add(app, "Settings…", #selector(showPreferences), ",")
        let services = NSMenu(title: "Services")
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: ""); servicesItem.submenu = services
        app.addItem(servicesItem); NSApp.servicesMenu = services; app.addItem(.separator())
        add(app, "Hide Clock", #selector(NSApplication.hide(_:)), "h", target: NSApp)
        let others = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        others.keyEquivalentModifierMask = [.command, .option]; others.target = NSApp; app.addItem(others)
        add(app, "Show All", #selector(NSApplication.unhideAllApplications(_:)), target: NSApp)
        app.addItem(.separator()); add(app, "Quit Clock", #selector(quit), "q")
        let file = submenu("File"); add(file, "New Clock", #selector(newClock), "n")
        let close = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"); file.addItem(close)
        let edit = submenu("Edit")
        for (title, selector, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(NSMenuItem(title: title, action: NSSelectorFromString(selector), keyEquivalent: key))
        }
        let view = submenu("View")
        add(view, "Clock-Only View", #selector(toggleFocusMode), "\t")
        view.items.last?.keyEquivalentModifierMask = []
        add(view, "Show / Hide All Clocks", #selector(toggleVisibility), "c")
        view.items.last?.keyEquivalentModifierMask = [.control, .option, .command]
        view.addItem(NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f"))
        view.items.last?.keyEquivalentModifierMask = [.control, .command]
        let clockItem = NSMenuItem(title: "Controls", action: nil, keyEquivalent: ""); clockItem.submenu = displayMenu
        displayMenu.delegate = self; main.addItem(clockItem)
        let windows = submenu("Window"); NSApp.windowsMenu = windows
        windows.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windows.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        add(windows, "Bring All to Front", #selector(NSApplication.arrangeInFront(_:)), target: NSApp)
        let helpMenu = submenu("Help"); add(helpMenu, "Clock Help", #selector(help)); NSApp.helpMenu = helpMenu
        NSApp.mainMenu = main
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { quitting = true; persistWindows() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { toggleVisibility() }; return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
