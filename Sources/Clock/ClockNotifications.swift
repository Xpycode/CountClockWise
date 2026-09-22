import Cocoa
import UserNotifications

enum ClockNotifications {
    // Accessed only on the main queue. A failure never interrupts every countdown.
    private static var didPresentFailure = false
    private static var pendingMessage: String?
    private static var windowObservers: [NSObjectProtocol] = []

    static func requestPermission() {
        guard Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                DiagnosticLogger.shared.record("notifications.authorization.failed", error: error)
                reportFailure("Count Clock Wise could not request notification permission. Try selecting Countdown again, or allow Count Clock Wise notifications in System Settings → Notifications.")
            } else if !granted {
                DiagnosticLogger.shared.record("notifications.authorization.denied")
                reportFailure("Countdown notifications are turned off. To enable them, open System Settings → Notifications → Count Clock Wise and turn on Allow Notifications.")
            } else {
                DiagnosticLogger.shared.record("notifications.authorization.granted")
            }
        }
    }
    static func finished(label: String) {
        DispatchQueue.main.async {
            NSSound.beep()
            NSApp.requestUserAttention(.informationalRequest)
        }
        guard Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                DiagnosticLogger.shared.record("notifications.delivery.permissionUnavailable")
                reportFailure("Count Clock Wise could not show a countdown notification. Allow Count Clock Wise notifications in System Settings → Notifications.")
                return
            }
            let content = UNMutableNotificationContent()
            content.title = label.isEmpty ? "Countdown finished" : label
            content.body = "Your countdown has finished."
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)) { error in
                if let error {
                    DiagnosticLogger.shared.record("notifications.delivery.failed", error: error)
                    reportFailure("Count Clock Wise could not submit the countdown notification. Check System Settings → Notifications → Count Clock Wise and try another countdown. If this continues, include diagnostics when reporting the problem from Help.")
                } else {
                    DiagnosticLogger.shared.record("notifications.delivery.submitted")
                }
            }
        }
    }

    private static func reportFailure(_ message: String) {
        DispatchQueue.main.async {
            guard !didPresentFailure else { return }
            pendingMessage = message
            presentPendingFailure()
            if !didPresentFailure && windowObservers.isEmpty {
                for name in [NSWindow.didBecomeMainNotification, NSWindow.didEndSheetNotification] {
                    windowObservers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                        presentPendingFailure()
                    })
                }
            }
        }
    }

    private static func presentPendingFailure() {
        guard !didPresentFailure, let message = pendingMessage,
              let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }),
              window.attachedSheet == nil else { return }
        didPresentFailure = true
        pendingMessage = nil
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers.removeAll()
        let alert = NSAlert()
        alert.messageText = "Countdown notifications are unavailable"
        alert.informativeText = message + "\n\nCountdowns continue running, and Count Clock Wise still plays its completion beep."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Notification Settings")
        alert.beginSheetModal(for: window) { response in
            guard response == .alertSecondButtonReturn else { return }
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
            if !NSWorkspace.shared.open(url) {
                DiagnosticLogger.shared.record("notifications.settings.openFailed")
                let recovery = NSAlert()
                recovery.messageText = "Open Notification Settings manually"
                recovery.informativeText = "Choose System Settings from the Apple menu, then Notifications → Count Clock Wise."
                recovery.beginSheetModal(for: window)
            }
        }
    }
}
