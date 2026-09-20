import AppKit

extension Notification.Name {
    static let settingsDidChange = Notification.Name("ClockSettingsDidChange")
}

final class Settings {
    static let shared = Settings()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let use24Hour = "use24Hour"
        static let showSeconds = "showSeconds"
        static let showDate = "showDate"
        static let fontSize = "fontSize"
        static let timeZoneIdentifier = "timeZoneIdentifier"
        static let backgroundColor = "backgroundColorHex"
        static let textColor = "textColorHex"
        static let alwaysOnTop = "alwaysOnTop"
        static let launchAtLogin = "launchAtLogin"
        static let rememberWindowFrame = "rememberWindowFrame"
    }

    private init() {
        defaults.register(defaults: [
            Keys.use24Hour: true,
            Keys.showSeconds: true,
            Keys.showDate: true,
            Keys.fontSize: 160.0,
            Keys.timeZoneIdentifier: "Europe/Berlin",
            Keys.backgroundColor: "#000000",
            Keys.textColor: "#FFFFFF",
            Keys.alwaysOnTop: false,
            Keys.launchAtLogin: false,
            Keys.rememberWindowFrame: true,
        ])
    }

    private func notifyChanged() {
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    var use24Hour: Bool {
        get { defaults.bool(forKey: Keys.use24Hour) }
        set { defaults.set(newValue, forKey: Keys.use24Hour); notifyChanged() }
    }

    var showSeconds: Bool {
        get { defaults.bool(forKey: Keys.showSeconds) }
        set { defaults.set(newValue, forKey: Keys.showSeconds); notifyChanged() }
    }

    var showDate: Bool {
        get { defaults.bool(forKey: Keys.showDate) }
        set { defaults.set(newValue, forKey: Keys.showDate); notifyChanged() }
    }

    var fontSize: Double {
        get { defaults.double(forKey: Keys.fontSize) }
        set { defaults.set(newValue, forKey: Keys.fontSize); notifyChanged() }
    }

    var timeZoneIdentifier: String {
        get { defaults.string(forKey: Keys.timeZoneIdentifier) ?? "Europe/Berlin" }
        set { defaults.set(newValue, forKey: Keys.timeZoneIdentifier); notifyChanged() }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: "Europe/Berlin")!
    }

    var backgroundColor: NSColor {
        get { NSColor(hex: defaults.string(forKey: Keys.backgroundColor) ?? "#000000") ?? .black }
        set { defaults.set(newValue.hexString, forKey: Keys.backgroundColor); notifyChanged() }
    }

    var textColor: NSColor {
        get { NSColor(hex: defaults.string(forKey: Keys.textColor) ?? "#FFFFFF") ?? .white }
        set { defaults.set(newValue.hexString, forKey: Keys.textColor); notifyChanged() }
    }

    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: Keys.alwaysOnTop) }
        set { defaults.set(newValue, forKey: Keys.alwaysOnTop); notifyChanged() }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin); notifyChanged() }
    }

    var rememberWindowFrame: Bool {
        get { defaults.bool(forKey: Keys.rememberWindowFrame) }
        set {
            defaults.set(newValue, forKey: Keys.rememberWindowFrame)
            if !newValue {
                defaults.removeObject(forKey: "NSWindow Frame ClockMainWindow")
            }
            notifyChanged()
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard hexString.count == 6, let rgb = UInt32(hexString, radix: 16) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
