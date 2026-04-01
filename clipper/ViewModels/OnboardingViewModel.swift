import SwiftUI
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    var currentStep: Int = 0
    var isAccessibilityGranted: Bool = false
    var isLaunchAtLoginEnabled: Bool = false
    var navigationDirection: NavigationDirection = .forward
    var showAccessibilityWarning: Bool = false

    private(set) var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    let steps: [OnboardingStepContent] = OnboardingStepContent.allSteps

    private let accessibilityService: AccessibilityPermissionChecking
    private let loginItemService: LoginItemManaging

    var totalSteps: Int { steps.count }

    var isFirstStep: Bool { currentStep == 0 }

    var isLastStep: Bool { currentStep == totalSteps - 1 }

    var currentStepContent: OnboardingStepContent { steps[currentStep] }

    init(
        accessibilityService: AccessibilityPermissionChecking = AccessibilityPermissionService(),
        loginItemService: LoginItemManaging = LoginItemService()
    ) {
        self.accessibilityService = accessibilityService
        self.loginItemService = loginItemService
        self.isAccessibilityGranted = accessibilityService.isGranted
        self.isLaunchAtLoginEnabled = loginItemService.isEnabled
    }

    func goToNextStep() {
        guard currentStep < totalSteps - 1 else { return }
        navigationDirection = .forward
        currentStep += 1
    }

    func goToPreviousStep() {
        guard currentStep > 0 else { return }
        navigationDirection = .backward
        currentStep -= 1
    }

    func skipOnboarding() {
        if currentStepContent.stepType == .accessibilityPermission && !isAccessibilityGranted {
            showAccessibilityWarning = true
            return
        }
        completeOnboarding()
    }

    func confirmSkipWithoutPermission() {
        showAccessibilityWarning = false
        hasCompletedOnboarding = true
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func openAccessibilitySettings() {
        accessibilityService.openSystemSettings()
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemService.setEnabled(enabled)
            isLaunchAtLoginEnabled = enabled
        } catch {
            isLaunchAtLoginEnabled = !enabled
        }
    }

    func startAccessibilityPolling() {
        accessibilityService.startPolling { [weak self] granted in
            Task { @MainActor in
                self?.isAccessibilityGranted = granted
            }
        }
    }

    func stopAccessibilityPolling() {
        accessibilityService.stopPolling()
    }
}
