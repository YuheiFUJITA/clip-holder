import SwiftUI
import Observation

@Observable
final class AppSettings {
    @ObservationIgnored
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    @ObservationIgnored
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true

    @ObservationIgnored
    @AppStorage("maxHistoryCount") var maxHistoryCount: Int = 50

    @ObservationIgnored
    @AppStorage("saveTextData") var saveTextData: Bool = true

    @ObservationIgnored
    @AppStorage("saveImageData") var saveImageData: Bool = true

    @ObservationIgnored
    @AppStorage("excludedAppsJSON") var excludedAppsJSON: String = "[]"

    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var excludedApps: [ExcludedApp] {
        get {
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
