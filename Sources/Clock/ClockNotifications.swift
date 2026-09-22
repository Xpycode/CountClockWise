import Cocoa
import UserNotifications

enum ClockNotifications {
    static func requestPermission() {
        guard Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    static func finished(label: String) {
        NSSound.beep()
        NSApp.requestUserAttention(.informationalRequest)
        guard Bundle.main.bundleIdentifier == "com.lucesumbrarum.Clock" else { return }
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Countdown finished" : label
        content.body = "Your countdown has finished."
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
