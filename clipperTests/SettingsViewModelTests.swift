import Testing
import Foundation
@testable import clipper

@Suite
struct SettingsViewModelTests {

    @Test @MainActor func toggleLaunchAtLoginSuccess() {
        let mockLogin = MockLoginItemService()
        let settings = AppSettings()
        let vm = SettingsViewModel(settings: settings, loginItemService: mockLogin, accessibilityService: MockAccessibilityService())
        vm.toggleLaunchAtLogin(true)
        #expect(settings.launchAtLogin == true)
        #expect(mockLogin.lastSetEnabledValue == true)
    }

    @Test @MainActor func toggleLaunchAtLoginFailureReverts() {
        let mockLogin = MockLoginItemService()
        mockLogin.shouldThrow = true
        let settings = AppSettings()
        let vm = SettingsViewModel(settings: settings, loginItemService: mockLogin, accessibilityService: MockAccessibilityService())
        vm.toggleLaunchAtLogin(true)
        #expect(settings.launchAtLogin == false)
    }

    @Test @MainActor func toggleSaveTextDataPreventsAllOff() {
        let settings = AppSettings()
        settings.saveTextData = true
        settings.saveImageData = false
        let vm = SettingsViewModel(settings: settings, loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.toggleSaveTextData(false)
        #expect(settings.saveTextData == true)
    }

    @Test @MainActor func toggleSaveImageDataPreventsAllOff() {
        let settings = AppSettings()
        settings.saveTextData = false
        settings.saveImageData = true
        let vm = SettingsViewModel(settings: settings, loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.toggleSaveImageData(false)
        #expect(settings.saveImageData == true)
    }

    @Test @MainActor func toggleSaveTextDataAllowsWhenOtherEnabled() {
        let settings = AppSettings()
        settings.saveTextData = true
        settings.saveImageData = true
        let vm = SettingsViewModel(settings: settings, loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.toggleSaveTextData(false)
        #expect(settings.saveTextData == false)
    }

    @Test @MainActor func requestClearHistoryShowsConfirmation() {
        let vm = SettingsViewModel(settings: AppSettings(), loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.requestClearHistory()
        #expect(vm.showDeleteConfirmation == true)
    }

    @Test @MainActor func confirmClearHistoryDismissesConfirmation() {
        let vm = SettingsViewModel(settings: AppSettings(), loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.showDeleteConfirmation = true
        vm.confirmClearHistory()
        #expect(vm.showDeleteConfirmation == false)
    }

    @Test @MainActor func resetOnboardingClearsFlag() {
        let settings = AppSettings()
        settings.hasCompletedOnboarding = true
        let vm = SettingsViewModel(settings: settings, loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.resetOnboarding()
        #expect(settings.hasCompletedOnboarding == false)
    }

    @Test @MainActor func removeExcludedAppDelegatesToSettings() {
        let settings = AppSettings()
        let app = ExcludedApp(id: "com.test", name: "Test", bundlePath: "/test")
        settings.excludedApps = [app]
        let vm = SettingsViewModel(settings: settings, loginItemService: MockLoginItemService(), accessibilityService: MockAccessibilityService())
        vm.removeExcludedApp(app)
        #expect(settings.excludedApps.isEmpty)
    }

    @Test @MainActor func startAccessibilityPollingDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = SettingsViewModel(settings: AppSettings(), loginItemService: MockLoginItemService(), accessibilityService: mockAccess)
        vm.startAccessibilityPolling()
        #expect(mockAccess.pollingStarted == true)
    }

    @Test @MainActor func stopAccessibilityPollingDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = SettingsViewModel(settings: AppSettings(), loginItemService: MockLoginItemService(), accessibilityService: mockAccess)
        vm.stopAccessibilityPolling()
        #expect(mockAccess.pollingStopped == true)
    }

    @Test @MainActor func openAccessibilitySettingsDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = SettingsViewModel(settings: AppSettings(), loginItemService: MockLoginItemService(), accessibilityService: mockAccess)
        vm.openAccessibilitySettings()
        #expect(mockAccess.settingsOpened == true)
    }
}
