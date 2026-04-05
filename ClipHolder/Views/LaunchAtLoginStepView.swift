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

            Text("ログイン時に自動起動")
                .font(.title2)
                .fontWeight(.bold)

            Text("Mac を起動するたびに Clip Holder が\n自動で立ち上がります。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Toggle("ログイン時に起動", isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)
            .fixedSize()
            .accessibilityLabel("ログイン時に Clip Holder を自動起動する")

            Text("この設定は後から変更できます")
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
