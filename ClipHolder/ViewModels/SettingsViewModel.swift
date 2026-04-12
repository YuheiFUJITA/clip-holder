import SwiftUI
import Observation
import AppKit
import UniformTypeIdentifiers

@Observable
@MainActor
final class SettingsViewModel {
    var isAccessibilityGranted: Bool = false
    var showDeleteConfirmation: Bool = false

    let settings: AppSettings
    var updateService: UpdateService?

    private let loginItemService: LoginItemManaging
    private let accessibilityService: AccessibilityPermissionChecking
    private let historyStore: ClipboardHistoryStoring?

    init(
        settings: AppSettings,
        loginItemService: LoginItemManaging? = nil,
        accessibilityService: AccessibilityPermissionChecking? = nil,
        historyStore: ClipboardHistoryStoring? = nil
    ) {
        self.settings = settings
        self.loginItemService = loginItemService ?? LoginItemService()
        self.accessibilityService = accessibilityService ?? AccessibilityPermissionService()
        self.historyStore = historyStore
        self.isAccessibilityGranted = self.accessibilityService.isGranted

        // ログイン項目のシステム状態と設定値を同期（初回のみ）
        // UserDefaults に値が明示的に保存されていない場合のみシステム状態で初期化
        if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
            settings.launchAtLogin = self.loginItemService.isEnabled
        }
    }

    // MARK: - 一般設定

    func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemService.setEnabled(enabled)
            settings.launchAtLogin = enabled
        } catch {
            settings.launchAtLogin = !enabled
        }
    }

    func toggleDockIcon(_ enabled: Bool) {
        settings.showDockIcon = enabled
        NSApplication.shared.setActivationPolicy(enabled ? .regular : .accessory)
    }

    func toggleAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        settings.automaticallyDownloadsUpdates = enabled
        updateService?.syncSettings(with: settings)
    }

    func checkForUpdates() {
        updateService?.checkForUpdates()
    }

    // MARK: - 権限管理

    func openAccessibilitySettings() {
        accessibilityService.openSystemSettings()
    }

    func startAccessibilityPolling() {
        // ポーリング開始前にキャッシュ済みの状態を同期
        isAccessibilityGranted = accessibilityService.isGranted
        accessibilityService.startPolling { [weak self] granted in
            Task { @MainActor in
                self?.isAccessibilityGranted = granted
            }
        }
    }

    func stopAccessibilityPolling() {
        accessibilityService.stopPolling()
    }

    // MARK: - 履歴管理

    func requestClearHistory() {
        showDeleteConfirmation = true
    }

    func confirmClearHistory() {
        showDeleteConfirmation = false
        historyStore?.clearAll()
    }

    private var activeToggleCount: Int {
        [settings.saveTextData, settings.saveImageData, settings.savePDFData, settings.saveFileData]
            .filter { $0 }.count
    }

    func toggleSaveTextData(_ enabled: Bool) {
        if !enabled && activeToggleCount <= 1 { return }
        settings.saveTextData = enabled
    }

    func toggleSaveImageData(_ enabled: Bool) {
        if !enabled && activeToggleCount <= 1 { return }
        settings.saveImageData = enabled
    }

    func toggleSavePDFData(_ enabled: Bool) {
        if !enabled && activeToggleCount <= 1 { return }
        settings.savePDFData = enabled
    }

    func toggleSaveFileData(_ enabled: Bool) {
        if !enabled && activeToggleCount <= 1 { return }
        settings.saveFileData = enabled
    }

    func updateMaxHistoryCount(_ count: Int) {
        let clamped = max(1, count)
        settings.maxHistoryCount = clamped
        historyStore?.trimToCount(clamped)
    }

    // MARK: - 除外アプリ

    func addExcludedApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [UTType.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundleID = Bundle(url: url)?.bundleIdentifier ?? url.lastPathComponent
        let name = FileManager.default.displayName(atPath: url.path)

        let app = ExcludedApp(id: bundleID, name: name, bundlePath: url.path)
        settings.addExcludedApp(app)
    }

    func removeExcludedApp(_ app: ExcludedApp) {
        settings.removeExcludedApp(app)
    }

}
