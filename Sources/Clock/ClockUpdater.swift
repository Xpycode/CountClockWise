import Cocoa
import Sparkle

/// Local builds remain usable before a signed, published update channel exists.
final class ClockUpdater: NSObject, NSMenuItemValidation {
    static let shared = ClockUpdater()
    private var controller: SPUStandardUpdaterController?

    static func validConfiguration(_ info: [String: Any]) -> Bool {
        guard let feed = info["SUFeedURL"] as? String,
              let url = URL(string: feed), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil,
              let key = info["SUPublicEDKey"] as? String,
              let data = Data(base64Encoded: key), data.count == 32 else { return false }
        return true
    }

    var isConfigured: Bool { controller != nil }
    var automaticallyChecks: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    func start() {
        guard controller == nil, Self.validConfiguration(Bundle.main.infoDictionary ?? [:]) else {
            DiagnosticLogger.shared.record("updates.channel.notConfigured")
            return
        }
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        DiagnosticLogger.shared.record("updates.started")
    }

    @objc func checkForUpdates(_ sender: Any?) {
        guard let controller else {
            let alert = NSAlert()
            alert.messageText = "Updates are not available for this build"
            alert.informativeText = "This local testing build does not have a published update channel yet. Use Help → Send Feedback if you need assistance."
            alert.addButton(withTitle: "OK")
            if let window = NSApp.keyWindow, window.attachedSheet == nil { alert.beginSheetModal(for: window) }
            else { alert.runModal() }
            return
        }
        controller.checkForUpdates(sender)
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        controller?.updater.canCheckForUpdates ?? true
    }
}
