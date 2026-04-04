import Testing
import Foundation
@testable import clipper

@Suite(.serialized)
struct AppSettingsTests {

    private func cleanDefaults() {
        let keys = ["launchAtLogin", "showMenuBarIcon", "maxHistoryCount",
                     "saveTextData", "saveImageData", "excludedAppsJSON", "hasCompletedOnboarding",
                     "openSettingsOnLaunch"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    @Test func defaultMaxHistoryCount() {
        cleanDefaults()
        let settings = AppSettings()
        let original = settings.maxHistoryCount
        settings.maxHistoryCount = 100
        #expect(settings.maxHistoryCount == 100)
        settings.maxHistoryCount = original
        cleanDefaults()
    }

    @Test func excludedAppsEmptyByDefault() {
        cleanDefaults()
        let settings = AppSettings()
        #expect(settings.excludedApps.isEmpty)
        cleanDefaults()
    }

    @Test func excludedAppsSerializationRoundTrip() {
        cleanDefaults()
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.excludedApps = [app]

        let decoded = settings.excludedApps
        #expect(decoded.count == 1)
        #expect(decoded[0].id == "com.test.app")
        #expect(decoded[0].name == "Test App")
        #expect(decoded[0].bundlePath == "/Applications/Test.app")
        cleanDefaults()
    }

    @Test func addExcludedAppPreventsduplicates() {
        cleanDefaults()
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.addExcludedApp(app)
        settings.addExcludedApp(app)
        #expect(settings.excludedApps.count == 1)
        cleanDefaults()
    }

    @Test func removeExcludedApp() {
        cleanDefaults()
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.excludedApps = [app]
        settings.removeExcludedApp(app)
        #expect(settings.excludedApps.isEmpty)
        cleanDefaults()
    }

    @Test func openSettingsOnLaunchDefaultsToTrue() {
        cleanDefaults()
        let settings = AppSettings()
        #expect(settings.openSettingsOnLaunch == true)
        cleanDefaults()
    }

    @Test func openSettingsOnLaunchPersistsValue() {
        cleanDefaults()
        let settings = AppSettings()
        settings.openSettingsOnLaunch = true
        #expect(settings.openSettingsOnLaunch == true)
        #expect(UserDefaults.standard.bool(forKey: "openSettingsOnLaunch") == true)
        settings.openSettingsOnLaunch = false
        #expect(settings.openSettingsOnLaunch == false)
        cleanDefaults()
    }

    @Test func invalidJSONReturnsEmptyArray() {
        cleanDefaults()
        UserDefaults.standard.set("invalid json", forKey: "excludedAppsJSON")
        let settings = AppSettings()
        #expect(settings.excludedApps.isEmpty)
        cleanDefaults()
    }
}
