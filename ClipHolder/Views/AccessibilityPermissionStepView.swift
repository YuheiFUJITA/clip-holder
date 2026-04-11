import SwiftUI

struct AccessibilityPermissionStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            Text("Accessibility Permission")
                .font(.title2)
                .fontWeight(.bold)

            Text("Accessibility permission is required\nto monitor the clipboard. Please grant it below.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isAccessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(viewModel.isAccessibilityGranted ? "Granted" : "Not granted")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Accessibility permission status")
            .accessibilityValue(viewModel.isAccessibilityGranted ? "Granted" : "Not granted")

            if viewModel.isAccessibilityGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    Text("Open System Settings")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Open the Accessibility permission pane in System Settings")
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: viewModel.isAccessibilityGranted)
        .onAppear {
            viewModel.startAccessibilityPolling()
        }
        .onDisappear {
            viewModel.stopAccessibilityPolling()
        }
    }
}

#Preview {
    let vm = OnboardingViewModel(
        accessibilityService: AccessibilityPermissionService(),
        loginItemService: LoginItemService()
    )
    AccessibilityPermissionStepView(viewModel: vm)
        .frame(width: 520, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
}
