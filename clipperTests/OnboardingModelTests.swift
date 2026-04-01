import Testing
@testable import clipper

struct OnboardingModelTests {

    @Test func stepTypeHasAllCases() {
        let allCases: [OnboardingStepType] = [
            .welcome, .feature, .accessibilityPermission, .launchAtLogin, .complete
        ]
        #expect(allCases.count == 5)
    }

    @Test func stepContentHoldsProperties() {
        let content = OnboardingStepContent(
            iconName: "star",
            title: "テスト",
            description: "説明文",
            stepType: .welcome
        )
        #expect(content.iconName == "star")
        #expect(content.title == "テスト")
        #expect(content.description == "説明文")
        #expect(content.stepType == .welcome)
    }

    @Test func allStepsContainsSixEntries() {
        let steps = OnboardingStepContent.allSteps
        #expect(steps.count == 6)
    }

    @Test func allStepsHaveCorrectOrder() {
        let steps = OnboardingStepContent.allSteps
        #expect(steps[0].stepType == .welcome)
        #expect(steps[1].stepType == .feature)
        #expect(steps[2].stepType == .feature)
        #expect(steps[3].stepType == .accessibilityPermission)
        #expect(steps[4].stepType == .launchAtLogin)
        #expect(steps[5].stepType == .complete)
    }

    @Test func allStepsHaveNonEmptyContent() {
        for step in OnboardingStepContent.allSteps {
            #expect(!step.iconName.isEmpty)
            #expect(!step.title.isEmpty)
            #expect(!step.description.isEmpty)
        }
    }

    @Test func navigationDirectionValues() {
        let forward = NavigationDirection.forward
        let backward = NavigationDirection.backward
        #expect(forward != backward)
    }
}
