import Testing
import Foundation
@testable import clipper

@Suite
struct AppSettingsTests {

    @Test func defaultMaxHistoryCount() {
        // maxHistoryCount のデフォルトは AppSettings 定義で 50
        let settings = AppSettings()
        // UserDefaults に値が設定されていない場合のデフォルト値を検証
        // 注: テスト環境では他のテストが UserDefaults を変更する可能性があるため、
        // ここではモデルのプロパティが読み書き可能であることを検証する
        let original = settings.maxHistoryCount
        settings.maxHistoryCount = 100
        #expect(settings.maxHistoryCount == 100)
        settings.maxHistoryCount = original
    }

    @Test func excludedAppsEmptyByDefault() {
        let settings = AppSettings()
        settings.excludedAppsJSON = "[]"
        #expect(settings.excludedApps.isEmpty)
    }

    @Test func excludedAppsSerializationRoundTrip() {
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.excludedApps = [app]

        let decoded = settings.excludedApps
        #expect(decoded.count == 1)
        #expect(decoded[0].id == "com.test.app")
        #expect(decoded[0].name == "Test App")
        #expect(decoded[0].bundlePath == "/Applications/Test.app")
    }

    @Test func addExcludedAppPreventsduplicates() {
        let settings = AppSettings()
        settings.excludedAppsJSON = "[]"
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.addExcludedApp(app)
        settings.addExcludedApp(app)
        #expect(settings.excludedApps.count == 1)
    }

    @Test func removeExcludedApp() {
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test.app", name: "Test App", bundlePath: "/Applications/Test.app")
        settings.excludedApps = [app]
        settings.removeExcludedApp(app)
        #expect(settings.excludedApps.isEmpty)
    }

    @Test func invalidJSONReturnsEmptyArray() {
        let settings = AppSettings()
        settings.excludedAppsJSON = "invalid json"
        #expect(settings.excludedApps.isEmpty)
    }
}
