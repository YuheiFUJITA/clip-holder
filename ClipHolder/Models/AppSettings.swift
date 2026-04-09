import SwiftUI
import Observation

@Observable
final class AppSettings: @unchecked Sendable {
    private let defaults = UserDefaults.standard

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }

    var showMenuBarIcon: Bool {
        get { defaults.object(forKey: "showMenuBarIcon") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showMenuBarIcon") }
    }

    var showDockIcon: Bool {
        get { defaults.object(forKey: "showDockIcon") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showDockIcon") }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { defaults.bool(forKey: "automaticallyDownloadsUpdates") }
        set { defaults.set(newValue, forKey: "automaticallyDownloadsUpdates") }
    }

    var maxHistoryCount: Int {
        get {
            let val = defaults.integer(forKey: "maxHistoryCount")
            return val > 0 ? val : 50
        }
        set { defaults.set(newValue, forKey: "maxHistoryCount") }
    }

    var saveTextData: Bool {
        get { defaults.object(forKey: "saveTextData") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "saveTextData") }
    }

    var saveImageData: Bool {
        get { defaults.object(forKey: "saveImageData") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "saveImageData") }
    }

    var savePDFData: Bool {
        get { defaults.object(forKey: "savePDFData") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "savePDFData") }
    }

    var saveFileData: Bool {
        get { defaults.object(forKey: "saveFileData") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "saveFileData") }
    }

    var openSettingsOnLaunch: Bool {
        get { defaults.object(forKey: "openSettingsOnLaunch") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "openSettingsOnLaunch") }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // Observation でトラッキングされるプロパティ（ビュー更新のトリガー）
    var excludedAppsVersion: Int = 0

    private var excludedAppsJSON: String {
        get { defaults.string(forKey: "excludedAppsJSON") ?? "[]" }
        set { defaults.set(newValue, forKey: "excludedAppsJSON") }
    }

    var excludedApps: [ExcludedApp] {
        get {
            _ = excludedAppsVersion // Observation アクセスを登録
            guard let data = excludedAppsJSON.data(using: .utf8),
                  let apps = try? JSONDecoder().decode([ExcludedApp].self, from: data) else {
                return []
            }
            return apps
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                excludedAppsJSON = json
                excludedAppsVersion += 1
            }
        }
    }

    func addExcludedApp(_ app: ExcludedApp) {
        var apps = excludedApps
        guard !apps.contains(where: { $0.id == app.id }) else { return }
        apps.append(app)
        excludedApps = apps
    }

    func removeExcludedApp(_ app: ExcludedApp) {
        var apps = excludedApps
        apps.removeAll { $0.id == app.id }
        excludedApps = apps
    }
}
