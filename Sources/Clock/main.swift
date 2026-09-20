import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMainMenu()

        let initialFrame = NSRect(x: 0, y: 0, width: 900, height: 500)

        window = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clock"
        window.minSize = NSSize(width: 400, height: 250)
        window.isOpaque = true
        window.contentView = ClockView(frame: initialFrame)

        window.center()
        if Settings.shared.rememberWindowFrame {
            window.setFrameAutosaveName("ClockMainWindow")
        }

        applyWindowLevel()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsDidChange), name: .settingsDidChange, object: nil
        )

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    @objc private func settingsDidChange() {
        applyWindowLevel()
        if Settings.shared.rememberWindowFrame {
            window.setFrameAutosaveName("ClockMainWindow")
        }
    }

    private func applyWindowLevel() {
        window.level = Settings.shared.alwaysOnTop ? .floating : .normal
    }

    @objc func showPreferences() {
        PreferencesWindowController.shared.showWindow(nil)
        PreferencesWindowController.shared.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let preferencesItem = NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(preferencesItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Clock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)

        NSApp.mainMenu = mainMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
