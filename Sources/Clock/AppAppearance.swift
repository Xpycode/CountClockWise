import Cocoa

extension Notification.Name {
    static let appAppearanceDidChange = Notification.Name("ClockAppAppearanceDidChange")
}

enum AppAppearance: String, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return "Match System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    static var current: Self {
        get { Self(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appAppearance")
            NSApp.appearance = newValue.appearance
            NotificationCenter.default.post(name: .appAppearanceDidChange, object: nil)
        }
    }
}
