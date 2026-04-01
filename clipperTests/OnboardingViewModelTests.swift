import Testing
import Foundation
@testable import clipper

final class MockAccessibilityService: AccessibilityPermissionChecking {
    var isGranted: Bool = false
    var pollingStarted = false
    var pollingStopped = false
    var settingsOpened = false
    private var onStatusChange: ((Bool) -> Void)?

    func startPolling(onStatusChange: @escaping (Bool) -> Void) {
        pollingStarted = true
        self.onStatusChange = onStatusChange
    }

    func stopPolling() {
        pollingStopped = true
    }

    func openSystemSettings() {
        settingsOpened = true
    }

    func simulateGranted(_ granted: Bool) {
        isGranted = granted
        onStatusChange?(granted)
    }
}

final class MockLoginItemService: LoginItemManaging {
    var isEnabled: Bool = false
    var lastSetEnabledValue: Bool?
    var shouldThrow = false

    func setEnabled(_ enabled: Bool) throws {
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
        lastSetEnabledValue = enabled
        isEnabled = enabled
    }
}

@Suite
struct OnboardingViewModelTests {

    @Test @MainActor func initialState() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        #expect(vm.currentStep == 0)
        #expect(vm.isFirstStep == true)
        #expect(vm.isLastStep == false)
        #expect(vm.navigationDirection == .forward)
    }

    @Test @MainActor func goToNextStepIncrementsStep() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        vm.goToNextStep()
        #expect(vm.currentStep == 1)
        #expect(vm.navigationDirection == .forward)
        #expect(vm.isFirstStep == false)
    }

    @Test @MainActor func goToPreviousStepDecrementsStep() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        vm.goToNextStep()
        vm.goToPreviousStep()
        #expect(vm.currentStep == 0)
        #expect(vm.navigationDirection == .backward)
    }

    @Test @MainActor func cannotGoPreviousOnFirstStep() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        vm.goToPreviousStep()
        #expect(vm.currentStep == 0)
    }

    @Test @MainActor func cannotGoNextOnLastStep() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        for _ in 0..<vm.totalSteps {
            vm.goToNextStep()
        }
        #expect(vm.currentStep == vm.totalSteps - 1)
        #expect(vm.isLastStep == true)
    }

    @Test @MainActor func lastStepShowsCorrectContent() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        for _ in 0..<(vm.totalSteps - 1) {
            vm.goToNextStep()
        }
        #expect(vm.currentStepContent.stepType == .complete)
    }

    @Test @MainActor func completeOnboardingSetsFlag() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        vm.completeOnboarding()
        #expect(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == true)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    @Test @MainActor func skipOnboardingOnNonPermissionStepCompletes() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        vm.skipOnboarding()
        #expect(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == true)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    @Test @MainActor func skipOnPermissionStepWithoutGrantShowsWarning() {
        let mockAccess = MockAccessibilityService()
        mockAccess.isGranted = false
        let vm = OnboardingViewModel(
            accessibilityService: mockAccess,
            loginItemService: MockLoginItemService()
        )
        // Navigate to accessibility permission step (index 3)
        for _ in 0..<3 {
            vm.goToNextStep()
        }
        #expect(vm.currentStepContent.stepType == .accessibilityPermission)
        vm.skipOnboarding()
        #expect(vm.showAccessibilityWarning == true)
    }

    @Test @MainActor func confirmSkipWithoutPermissionCompletes() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        vm.showAccessibilityWarning = true
        vm.confirmSkipWithoutPermission()
        #expect(vm.showAccessibilityWarning == false)
        #expect(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == true)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    @Test @MainActor func startAccessibilityPollingDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = OnboardingViewModel(
            accessibilityService: mockAccess,
            loginItemService: MockLoginItemService()
        )
        vm.startAccessibilityPolling()
        #expect(mockAccess.pollingStarted == true)
    }

    @Test @MainActor func stopAccessibilityPollingDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = OnboardingViewModel(
            accessibilityService: mockAccess,
            loginItemService: MockLoginItemService()
        )
        vm.stopAccessibilityPolling()
        #expect(mockAccess.pollingStopped == true)
    }

    @Test @MainActor func openAccessibilitySettingsDelegatesToService() {
        let mockAccess = MockAccessibilityService()
        let vm = OnboardingViewModel(
            accessibilityService: mockAccess,
            loginItemService: MockLoginItemService()
        )
        vm.openAccessibilitySettings()
        #expect(mockAccess.settingsOpened == true)
    }

    @Test @MainActor func toggleLaunchAtLoginSuccess() {
        let mockLogin = MockLoginItemService()
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: mockLogin
        )
        vm.toggleLaunchAtLogin(true)
        #expect(vm.isLaunchAtLoginEnabled == true)
        #expect(mockLogin.lastSetEnabledValue == true)
    }

    @Test @MainActor func toggleLaunchAtLoginFailureReverts() {
        let mockLogin = MockLoginItemService()
        mockLogin.shouldThrow = true
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: mockLogin
        )
        vm.toggleLaunchAtLogin(true)
        #expect(vm.isLaunchAtLoginEnabled == false)
    }

    @Test @MainActor func totalStepsMatchesAllSteps() {
        let vm = OnboardingViewModel(
            accessibilityService: MockAccessibilityService(),
            loginItemService: MockLoginItemService()
        )
        #expect(vm.totalSteps == 6)
    }
}
