import SwiftUI

struct LaunchAtLoginStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "power")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            Text("Launch at Login")
                .font(.title2)
                .fontWeight(.bold)

            Text("Clip Holder will launch automatically\nevery time you start your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Toggle("Launch at login", isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)
            .fixedSize()
            .accessibilityLabel("Launch Clip Holder at login")

            Text("You can change this later")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let vm = OnboardingViewModel(
        accessibilityService: AccessibilityPermissionService(),
        loginItemService: LoginItemService()
    )
    LaunchAtLoginStepView(viewModel: vm)
        .frame(width: 520, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
}
