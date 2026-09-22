import Cocoa
import SwiftUI
import AppCitizenshipKit
import FeedbackKit
import HelpMenu

@MainActor
final class ClockSupport: NSObject, NSWindowDelegate {
    static let shared = ClockSupport()
    static let config = CitizenshipConfig(appID: "count-clock-wise", appName: "Count Clock Wise",
        websiteURL: URL(string: "https://apps.lucesumbrarum.com"),
        supportEmail: "contact@lucesumbrarum.com",
        logProvider: { DiagnosticLogger.shared.recentTail() })
    private var feedbackWindow: NSWindow?

    static func helpContent() -> HelpContent {
        do { return try HelpContent(manifest: "help-manifest", in: .module) }
        catch {
            DiagnosticLogger.shared.record("help.load.failed", error: error)
            return HelpContent(topics: [HelpTopic(id: "unavailable", title: "Help Unavailable",
                markdown: "Help could not be loaded. Contact contact@lucesumbrarum.com for assistance.")], windowTitle: "Count Clock Wise Help")
        }
    }

    @objc func showHelp() { HelpWindowController.showHelp(content: Self.helpContent()) }
    @objc func showAbout() { CitizenshipAbout.show(Self.config) }
    @objc func leaveTip() { open(Self.config.donateURL) }
    @objc func emailSupport() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "contact@lucesumbrarum.com"
        components.queryItems = [URLQueryItem(name: "subject", value: "Count Clock Wise feedback")]
        if let url = components.url { open(url) }
    }

    @objc func sendFeedback() {
        if let feedbackWindow { feedbackWindow.makeKeyAndOrderFront(nil); return }
        let view = FeedbackView(config: Self.config.feedbackConfig, onClose: { [weak self] in self?.feedbackWindow?.close() })
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Send Feedback"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setContentSize(NSSize(width: 460, height: 540))
        window.center()
        feedbackWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === feedbackWindow { feedbackWindow = nil }
    }

    private func open(_ url: URL) {
        guard !NSWorkspace.shared.open(url) else { return }
        DiagnosticLogger.shared.record("support.link.openFailed")
        let alert = NSAlert()
        alert.messageText = "Could not open the link"
        alert.informativeText = "Open apps.lucesumbrarum.com in your browser, or email contact@lucesumbrarum.com."
        alert.runModal()
    }
}
