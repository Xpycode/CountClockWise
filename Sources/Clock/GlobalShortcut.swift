import Cocoa
import Carbon

extension Notification.Name {
    static let globalShortcutDidChange = Notification.Name("globalShortcutDidChange")
}

struct ShortcutBinding: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    static let defaultBinding = ShortcutBinding(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(controlKey | optionKey | cmdKey))
    static let allowedModifiers = UInt32(controlKey | optionKey | cmdKey | shiftKey)

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init(event: NSEvent) {
        keyCode = UInt32(event.keyCode)
        var flags: UInt32 = 0
        if event.modifierFlags.contains(.command) { flags |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.control) { flags |= UInt32(controlKey) }
        if event.modifierFlags.contains(.option) { flags |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { flags |= UInt32(shiftKey) }
        modifiers = flags
    }

    var cocoaModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if modifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if modifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }

    private static let keys: [UInt32: String] = [
        0:"A", 1:"S", 2:"D", 3:"F", 4:"H", 5:"G", 6:"Z", 7:"X", 8:"C", 9:"V", 11:"B",
        12:"Q", 13:"W", 14:"E", 15:"R", 16:"Y", 17:"T", 18:"1", 19:"2", 20:"3", 21:"4",
        22:"6", 23:"5", 24:"=", 25:"9", 26:"7", 27:"-", 28:"8", 29:"0", 30:"]", 31:"O",
        32:"U", 33:"[", 34:"I", 35:"P", 37:"L", 38:"J", 39:"'", 40:"K", 41:";", 42:"\\",
        43:",", 44:"/", 45:"N", 46:"M", 47:".", 50:"`"
    ]
    private var keyLabel: String {
        // Persist physical key codes, but label them using the current keyboard layout.
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return Self.keys[keyCode] ?? "?"
        }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(data) else { return Self.keys[keyCode] ?? "?" }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        var deadKey: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0,
                                    UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                    &deadKey, characters.count, &length, &characters)
        guard status == noErr, length > 0 else { return Self.keys[keyCode] ?? "?" }
        return String(utf16CodeUnits: characters, count: length)
    }
    var keyEquivalent: String { keyLabel.lowercased() }
    var displayString: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + keyLabel.uppercased()
    }

    func validate() throws {
        guard Self.keys[keyCode] != nil else {
            throw ShortcutError.message("Use a letter, number or punctuation key. Escape cancels recording.")
        }
        guard modifiers & ~Self.allowedModifiers == 0,
              modifiers & UInt32(controlKey | optionKey | cmdKey) != 0 else {
            throw ShortcutError.message("Include Control, Option or Command in the shortcut.")
        }
        let base = modifiers & ~UInt32(shiftKey)
        if base == UInt32(cmdKey) || base == UInt32(controlKey) ||
            (base == UInt32(cmdKey | optionKey) && [3, 4, 12, 13, 35, 37, 46].contains(keyCode)) ||
            (modifiers == UInt32(cmdKey | optionKey | shiftKey) && keyCode == 9) ||
            (base == UInt32(cmdKey | controlKey) && [3, 12].contains(keyCode)) {
            throw ShortcutError.message("That combination is reserved for standard app or system commands. Try Control–Option–Command with a letter.")
        }
    }
}

enum ShortcutError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(text) = self { return text }; return nil }
}

/// Persistence is independent of Carbon so failures can be tested without a global registration.
final class ShortcutSettingsStore {
    static let defaultsKey = "visibilityShortcut"
    private struct Record: Codable { let binding: ShortcutBinding? }
    private let defaults: UserDefaults
    private(set) var binding: ShortcutBinding?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let record = try? JSONDecoder().decode(Record.self, from: data),
           record.binding == nil || (try? record.binding?.validate()) != nil {
            binding = record.binding
        } else {
            binding = .defaultBinding
        }
    }

    func set(_ candidate: ShortcutBinding?, apply: (ShortcutBinding?) throws -> Void) throws {
        try candidate?.validate()
        let data = try JSONEncoder().encode(Record(binding: candidate))
        try apply(candidate)
        binding = candidate
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

final class GlobalShortcut: NSObject {
    private var hotKey: EventHotKeyRef?
    // A failed rollback still owns its Carbon handle, even though its ID never triggers the action.
    private var pendingCleanup: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    private var registeredBinding: ShortcutBinding?
    private var nextID: UInt32 = 1
    private var activeID: UInt32 = 0
    private let store: ShortcutSettingsStore
    let action: () -> Void
    private(set) var lastError: String?
    var isRecording = false
    var configuration: ShortcutBinding? { store.binding }
    var displayString: String { configuration?.displayString ?? "None" }
    var isRegistered: Bool { hotKey != nil }

    init(defaults: UserDefaults = .standard, action: @escaping () -> Void) {
        self.store = ShortcutSettingsStore(defaults: defaults)
        self.action = action
        super.init()
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context, let event else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue()
            var identifier = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                                    MemoryLayout<EventHotKeyID>.size, nil, &identifier) == noErr,
                  identifier.signature == 0x434C4F43, identifier.id == owner.activeID else { return OSStatus(eventNotHandledErr) }
            if !owner.isRecording { owner.action() }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        if status != noErr { lastError = "Could not install the shortcut handler (\(status)). Restart Count Clock Wise and try again." }
    }

    @discardableResult func register() -> Bool {
        do {
            try replaceRegistration(with: configuration)
            lastError = nil
            notify()
            return true
        } catch {
            lastError = error.localizedDescription
            notify()
            return false
        }
    }

    func setShortcut(_ candidate: ShortcutBinding?) throws {
        do {
            try store.set(candidate) { try self.replaceRegistration(with: $0) }
            lastError = nil
            notify()
        } catch {
            lastError = error.localizedDescription
            notify()
            throw error
        }
    }

    private func replaceRegistration(with candidate: ShortcutBinding?) throws {
        pendingCleanup.removeAll { UnregisterEventHotKey($0) == noErr }
        guard pendingCleanup.isEmpty else {
            throw ShortcutError.message("macOS could not release an unused shortcut registration. Your previous shortcut is unchanged. Restart Count Clock Wise before changing the shortcut again.")
        }
        if candidate == registeredBinding { return }
        try candidate?.validate()
        var replacement: EventHotKeyRef?
        let identifier = nextID
        if let candidate {
            guard handler != nil else { throw ShortcutError.message("The shortcut handler is unavailable. Restart Count Clock Wise and try again.") }
            var symbolicKeys: Unmanaged<CFArray>?
            if CopySymbolicHotKeys(&symbolicKeys) == noErr,
               let entries = symbolicKeys?.takeRetainedValue() as? [[String: Any]],
               entries.contains(where: {
                   ($0[kHISymbolicHotKeyEnabled as String] as? NSNumber)?.boolValue == true &&
                   ($0[kHISymbolicHotKeyCode as String] as? NSNumber)?.uint32Value == candidate.keyCode &&
                   ($0[kHISymbolicHotKeyModifiers as String] as? NSNumber)?.uint32Value == candidate.modifiers
               }) {
                throw ShortcutError.message("That shortcut is enabled in macOS Keyboard Shortcuts. Choose another combination or change it in System Settings → Keyboard → Keyboard Shortcuts.")
            }
            nextID &+= 1
            let status = RegisterEventHotKey(candidate.keyCode, candidate.modifiers,
                                            EventHotKeyID(signature: 0x434C4F43, id: identifier),
                                            GetApplicationEventTarget(), 0, &replacement)
            guard status == noErr else {
                throw ShortcutError.message("Could not register \(candidate.displayString) (\(status)). It may be used by another app or macOS. Choose another shortcut or change it in System Settings → Keyboard → Keyboard Shortcuts. Your previous shortcut is unchanged.")
            }
        }
        // Acquire the replacement first: a conflict must never remove the working shortcut.
        if let hotKey {
            let status = UnregisterEventHotKey(hotKey)
            if status != noErr {
                if let replacement {
                    let rollbackStatus = UnregisterEventHotKey(replacement)
                    if rollbackStatus != noErr {
                        pendingCleanup.append(replacement)
                        throw ShortcutError.message("Could not release the previous shortcut (\(status)) or undo the replacement (\(rollbackStatus)). Your previous shortcut is unchanged. Restart Count Clock Wise to release the unused registration.")
                    }
                }
                throw ShortcutError.message("Could not release the previous shortcut (\(status)). Restart Count Clock Wise and try again.")
            }
        }
        hotKey = replacement
        registeredBinding = candidate
        activeID = candidate == nil ? 0 : identifier
    }

    private func notify() { NotificationCenter.default.post(name: .globalShortcutDidChange, object: self) }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        for unusedHotKey in pendingCleanup { UnregisterEventHotKey(unusedHotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
