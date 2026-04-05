import Testing
import Foundation
@testable import ClipHolder

// テスト用のモック ClipboardHistoryStore
final class MockClipboardHistoryStore: ClipboardHistoryStoring {
    var entries: [ClipboardHistoryEntry] = []
    var addedEntries: [ClipboardHistoryEntry] = []
    var clearAllCalled = false

    func add(_ entry: ClipboardHistoryEntry, maxCount: Int) {
        addedEntries.append(entry)
        entries.insert(entry, at: 0)
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
    }

    func clearAll() {
        entries.removeAll()
        addedEntries.removeAll()
        clearAllCalled = true
    }

    func trimToCount(_ maxCount: Int) {
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
    }
}

@Suite
struct SettingsViewModelIntegrationTests {

    @Test @MainActor func initSyncsLoginItemStateOnFirstLaunch() {
        // UserDefaults に launchAtLogin が未設定の場合、システム状態で初期化
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
        let mockLogin = MockLoginItemService()
        mockLogin.isEnabled = true
        let settings = AppSettings()

        let _ = SettingsViewModel(
            settings: settings,
            loginItemService: mockLogin,
            accessibilityService: MockAccessibilityService()
        )

        #expect(settings.launchAtLogin == true)
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    @Test @MainActor func initPreservesUserSettingWhenAlreadySet() {
        // UserDefaults に明示的に保存済みの場合、ユーザー設定を維持
        UserDefaults.standard.set(true, forKey: "launchAtLogin")
        let mockLogin = MockLoginItemService()
        mockLogin.isEnabled = false
        let settings = AppSettings()

        let _ = SettingsViewModel(
            settings: settings,
            loginItemService: mockLogin,
            accessibilityService: MockAccessibilityService()
        )

        #expect(settings.launchAtLogin == true)
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    @Test @MainActor func confirmClearHistoryDelegatesToStore() {
        let mockStore = MockClipboardHistoryStore()
        mockStore.entries = [
            ClipboardHistoryEntry(dataType: .text, textContent: "test")
        ]
        let vm = SettingsViewModel(
            settings: AppSettings(),
            loginItemService: MockLoginItemService(),
            accessibilityService: MockAccessibilityService(),
            historyStore: mockStore
        )
        vm.showDeleteConfirmation = true
        vm.confirmClearHistory()
        #expect(mockStore.clearAllCalled == true)
    }
}
