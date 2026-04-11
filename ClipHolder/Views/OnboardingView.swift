import SwiftUI

struct OnboardingView: View {
    @State var viewModel: OnboardingViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openSettings) private var openSettings

    private func finishOnboarding() {
        openSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismissWindow(id: "onboarding")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step content area
            ZStack {
                stepView(for: viewModel.currentStep)
                    .id(viewModel.currentStep)
                    .transition(stepTransition)
            }
            .frame(maxWidth: 520, maxHeight: 300)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            .animation(.smooth(duration: 0.35), value: viewModel.currentStep)
            .padding(.horizontal, 40)
            .padding(.top, 30)

            Spacer()

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")

            Spacer().frame(height: 12)

            // Navigation area
            ZStack {
                // Back + Next/Start buttons (centered)
                HStack(spacing: 12) {
                    if !viewModel.isFirstStep && !viewModel.isLastStep {
                        Button("Back") {
                            viewModel.goToPreviousStep()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Go back to previous step")
                    }

                    Button(viewModel.isLastStep ? "Get Started" : "Next") {
                        if viewModel.isLastStep {
                            viewModel.completeOnboarding()
                            finishOnboarding()
                        } else {
                            viewModel.goToNextStep()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(viewModel.isLastStep ? "Complete onboarding and start the app" : "Go to next step")
                }

                // Skip link (right-aligned)
                if !viewModel.isLastStep {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            viewModel.skipOnboarding()
                            if viewModel.hasCompletedOnboarding {
                                finishOnboarding()
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Skip onboarding")
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 600, height: 450)
        .alert("Accessibility permission is not granted", isPresented: $viewModel.showAccessibilityWarning) {
            Button("Skip") {
                viewModel.confirmSkipWithoutPermission()
                finishOnboarding()
            }
            Button("Back to Settings", role: .cancel) {}
        } message: {
            Text("Without accessibility permission, the app's main features will be limited.")
        }
    }

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        let content = viewModel.steps[step]
        switch content.stepType {
        case .welcome, .feature, .complete:
            OnboardingStepView(content: content)
        case .accessibilityPermission:
            AccessibilityPermissionStepView(viewModel: viewModel)
        case .launchAtLogin:
            LaunchAtLoginStepView(viewModel: viewModel)
        }
    }

    private var stepTransition: AnyTransition {
        switch viewModel.navigationDirection {
        case .forward:
            AnyTransition.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            AnyTransition.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(
        accessibilityService: AccessibilityPermissionService(),
        loginItemService: LoginItemService()
    ))
}
