import XCTest
import Carbon
@testable import Clock

final class ShortcutTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        suite = "Clock.ShortcutTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
    }

    func testDefaultAndPersistedBinding() throws {
        let store = ShortcutSettingsStore(defaults: defaults)
        XCTAssertEqual(store.binding, .defaultBinding)
        let candidate = ShortcutBinding(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(controlKey | optionKey))
        try store.set(candidate) { XCTAssertEqual($0, candidate) }
        XCTAssertEqual(ShortcutSettingsStore(defaults: defaults).binding, candidate)
    }

    func testClearPersistsAndRestoreDefault() throws {
        let store = ShortcutSettingsStore(defaults: defaults)
        try store.set(nil) { XCTAssertNil($0) }
        XCTAssertNil(ShortcutSettingsStore(defaults: defaults).binding)
        try store.set(.defaultBinding) { _ in }
        XCTAssertEqual(ShortcutSettingsStore(defaults: defaults).binding, .defaultBinding)
    }

    func testRegistrationFailurePreservesPriorConfigurationAndPersistence() throws {
        let store = ShortcutSettingsStore(defaults: defaults)
        try store.set(.defaultBinding) { _ in }
        let previous = defaults.data(forKey: ShortcutSettingsStore.defaultsKey)
        let candidate = ShortcutBinding(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(controlKey | optionKey))
        XCTAssertThrowsError(try store.set(candidate) { _ in throw ShortcutError.message("Conflict") })
        XCTAssertEqual(store.binding, .defaultBinding)
        XCTAssertEqual(defaults.data(forKey: ShortcutSettingsStore.defaultsKey), previous)
        XCTAssertThrowsError(try store.set(nil) { _ in throw ShortcutError.message("Cannot unregister") })
        XCTAssertEqual(store.binding, .defaultBinding)
    }

    func testInvalidAndReservedBindingsNeverReachRegistration() {
        let store = ShortcutSettingsStore(defaults: defaults)
        for binding in [
            ShortcutBinding(keyCode: 8, modifiers: 0),
            ShortcutBinding(keyCode: 8, modifiers: UInt32(shiftKey)),
            ShortcutBinding(keyCode: 8, modifiers: UInt32(cmdKey)),
            ShortcutBinding(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey)),
            ShortcutBinding(keyCode: 49, modifiers: UInt32(cmdKey)),
            ShortcutBinding(keyCode: 3, modifiers: UInt32(cmdKey | controlKey)),
            ShortcutBinding(keyCode: 46, modifiers: UInt32(cmdKey | optionKey)),
            ShortcutBinding(keyCode: 9, modifiers: UInt32(cmdKey | optionKey | shiftKey)),
            ShortcutBinding(keyCode: 500, modifiers: UInt32(cmdKey | optionKey))
        ] {
            XCTAssertThrowsError(try store.set(binding) { _ in XCTFail("Invalid binding reached registration") })
        }
        XCTAssertNil(defaults.data(forKey: ShortcutSettingsStore.defaultsKey))
    }

    func testCorruptPersistenceFallsBackWithoutWriting() {
        let data = Data("invalid".utf8)
        defaults.set(data, forKey: ShortcutSettingsStore.defaultsKey)
        XCTAssertEqual(ShortcutSettingsStore(defaults: defaults).binding, .defaultBinding)
        XCTAssertEqual(defaults.data(forKey: ShortcutSettingsStore.defaultsKey), data)
    }

    func testDefaultDisplayAndMenuEquivalent() throws {
        let binding = ShortcutBinding.defaultBinding
        try binding.validate()
        XCTAssertEqual(binding.keyCode, UInt32(kVK_ANSI_C))
        XCTAssertFalse(binding.keyEquivalent.isEmpty)
        XCTAssertEqual(binding.displayString, "⌃⌥⌘" + binding.keyEquivalent.uppercased())
        XCTAssertEqual(binding.cocoaModifiers, [.control, .option, .command])
    }
}
