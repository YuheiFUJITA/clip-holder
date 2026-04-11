import Foundation

enum OnboardingStepType: Equatable {
    case welcome
    case feature
    case accessibilityPermission
    case launchAtLogin
    case complete
}

struct OnboardingStepContent {
    let iconName: String
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let stepType: OnboardingStepType
}

extension OnboardingStepContent {
    static let allSteps: [OnboardingStepContent] = [
        OnboardingStepContent(
            iconName: "clipboard",
            title: "Welcome to Clip Holder",
            description: "Make your macOS clipboard\nmore powerful and smarter.",
            stepType: .welcome
        ),
        OnboardingStepContent(
            iconName: "clock.arrow.circlepath",
            title: "Clipboard History",
            description: "Automatically record everything you copy.\nRetrieve past clips anytime.",
            stepType: .feature
        ),
        OnboardingStepContent(
            iconName: "magnifyingglass",
            title: "Easy Search",
            description: "Quickly find past clips\nby keyword.",
            stepType: .feature
        ),
        OnboardingStepContent(
            iconName: "lock.shield",
            title: "Accessibility Permission",
            description: "Accessibility permission is required\nto monitor the clipboard. Please grant it below.",
            stepType: .accessibilityPermission
        ),
        OnboardingStepContent(
            iconName: "power",
            title: "Launch at Login",
            description: "Clip Holder will launch automatically\nevery time you start your Mac.",
            stepType: .launchAtLogin
        ),
        OnboardingStepContent(
            iconName: "checkmark.circle",
            title: "You're all set!",
            description: "Setup is complete.\nStart using Clip Holder.",
            stepType: .complete
        ),
    ]
}

enum NavigationDirection: Equatable {
    case forward
    case backward
}
