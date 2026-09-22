import AppKit

extension Notification.Name {
    static let settingsDidChange = Notification.Name("ClockSettingsDidChange")
}

final class Settings {
    static let shared = Settings()
    let defaults: UserDefaults
    let id: String

    private enum Keys {
        static let use24Hour = "use24Hour"
        static let showSeconds = "showSeconds"
        static let showDate = "showDate"
        static let timeZoneIdentifier = "timeZoneIdentifier"
        static let backgroundColor = "backgroundColorHex"
        static let textColor = "textColorHex"
        static let alwaysOnTop = "alwaysOnTop"
        static let launchAtLogin = "launchAtLogin"
        static let rememberWindowFrame = "rememberWindowFrame"
    }

    init(id: String = "primary", defaults: UserDefaults? = nil) {
        self.id = id
        self.defaults = defaults ?? (id == "primary" ? .standard : UserDefaults(suiteName: "com.lucesumbrarum.Clock.window." + id)!)
        if id == "primary", defaults == nil, !self.defaults.bool(forKey: "bundledSettingsMigrated") {
            let keys = ["use24Hour", "showSeconds", "showDate", "timeZoneIdentifier", "backgroundColorHex", "textColorHex", "alwaysOnTop", "rememberWindowFrame", "showTimeZone", "showFrames", "framesPerSecond", "usesSystemTimeZone", "NSWindow Frame ClockMainWindow"]
            if let legacy = UserDefaults.standard.persistentDomain(forName: "Clock") {
                for key in keys where self.defaults.object(forKey: key) == nil {
                    if let value = legacy[key] { self.defaults.set(value, forKey: key) }
                }
            }
            if let frame = self.defaults.string(forKey: "NSWindow Frame ClockMainWindow"), self.defaults.object(forKey: "NSWindow Frame Clock-primary") == nil {
                self.defaults.set(frame, forKey: "NSWindow Frame Clock-primary")
            }
            self.defaults.set(true, forKey: "bundledSettingsMigrated")
        }
        let defaults = self.defaults
        defaults.removeObject(forKey: "fontSize")
        defaults.register(defaults: [
            Keys.use24Hour: true,
            Keys.showSeconds: true,
            Keys.showDate: true,
            Keys.timeZoneIdentifier: "Europe/Berlin",
            Keys.backgroundColor: "#000000",
            Keys.textColor: "#FFFFFF",
            Keys.alwaysOnTop: false,
            Keys.launchAtLogin: false,
            Keys.rememberWindowFrame: true,
        ])
    }

    private func notifyChanged() {
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
    }

    var use24Hour: Bool {
        get { defaults.bool(forKey: Keys.use24Hour) }
        set { defaults.set(newValue, forKey: Keys.use24Hour); notifyChanged() }
    }

    var showSeconds: Bool {
        get { defaults.bool(forKey: Keys.showSeconds) }
        set {
            defaults.set(newValue, forKey: Keys.showSeconds)
            if !newValue { defaults.set(false, forKey: "showFrames") }
            notifyChanged()
        }
    }

    var showDate: Bool {
        get { defaults.bool(forKey: Keys.showDate) }
        set { defaults.set(newValue, forKey: Keys.showDate); notifyChanged() }
    }

    // Presentation-only state; relaunch with the normal controls available.
    var focusMode = false {
        didSet { if focusMode != oldValue { notifyChanged() } }
    }

    var showStatusBar: Bool {
        get { defaults.object(forKey: "showStatusBar") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showStatusBar"); notifyChanged() }
    }
    var showControls: Bool {
        get { defaults.object(forKey: "showControls") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showControls"); notifyChanged() }
    }

    var showTimeZone: Bool {
        get { defaults.object(forKey: "showTimeZone") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showTimeZone"); notifyChanged() }
    }

    var showFrames: Bool {
        get { defaults.bool(forKey: "showFrames") }
        set {
            defaults.set(newValue, forKey: "showFrames")
            if newValue { defaults.set(true, forKey: Keys.showSeconds) }
            notifyChanged()
        }
    }

    var frameRate: FrameRate {
        get {
            if let name = defaults.string(forKey: "frameRate") { return .named(name) }
            let legacy = defaults.integer(forKey: "framesPerSecond")
            return .named(legacy == 0 ? "25" : String(legacy))
        }
        set { defaults.set(newValue.id, forKey: "frameRate"); notifyChanged() }
    }

    var customLabel: String {
        get { defaults.string(forKey: "customLabel") ?? "" }
        set { defaults.set(newValue, forKey: "customLabel"); notifyChanged() }
    }
    var selectedCity: String {
        get { defaults.string(forKey: "selectedCity") ?? "" }
        set { defaults.set(newValue, forKey: "selectedCity"); notifyChanged() }
    }
    var borderless: Bool {
        get { defaults.bool(forKey: "borderless") }
        set { defaults.set(newValue, forKey: "borderless"); notifyChanged() }
    }
    var opacity: Double {
        get { max(0.2, min(1, defaults.object(forKey: "opacity") as? Double ?? 1)) }
        set { defaults.set(max(0.2, min(1, newValue)), forKey: "opacity"); notifyChanged() }
    }
    var allSpaces: Bool {
        get { defaults.bool(forKey: "allSpaces") }
        set { defaults.set(newValue, forKey: "allSpaces"); notifyChanged() }
    }
    var mode: String {
        get { defaults.string(forKey: "mode") ?? "Clock" }
        set {
            guard ["Clock", "Countdown", "Stopwatch"].contains(newValue), newValue != mode else { return }
            var current = timerState
            if current.isRunning { current.toggle(at: Date()); timerState = current }
            defaults.set(newValue, forKey: "mode"); notifyChanged()
        }
    }
    var timerState: ClockTimerState {
        get { defaults.data(forKey: "timerState." + mode).flatMap { try? JSONDecoder().decode(ClockTimerState.self, from: $0) } ?? ClockTimerState() }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "timerState." + mode); notifyChanged() }
    }

    var timeZoneIdentifier: String {
        get { defaults.string(forKey: Keys.timeZoneIdentifier) ?? "Europe/Berlin" }
        set {
            defaults.removeObject(forKey: "selectedCity")
            defaults.set(newValue, forKey: Keys.timeZoneIdentifier)
            defaults.set(false, forKey: "usesSystemTimeZone")
            notifyChanged()
        }
    }

    var usesSystemTimeZone: Bool {
        get { defaults.bool(forKey: "usesSystemTimeZone") }
        set { defaults.set(newValue, forKey: "usesSystemTimeZone"); notifyChanged() }
    }

    var timeZone: TimeZone {
        usesSystemTimeZone ? .autoupdatingCurrent
            : (TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: "Europe/Berlin")!)
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
                UserDefaults.standard.removeObject(forKey: "NSWindow Frame Clock-" + id)
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
