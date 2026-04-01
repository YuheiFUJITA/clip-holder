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

            Text("アクセシビリティ権限")
                .font(.title2)
                .fontWeight(.bold)

            Text("クリップボードの監視にはアクセシビリティ\n権限が必要です。下のボタンから設定してください。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isAccessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(viewModel.isAccessibilityGranted ? "設定済み" : "未設定")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("アクセシビリティ権限の状態")
            .accessibilityValue(viewModel.isAccessibilityGranted ? "設定済み" : "未設定")

            if viewModel.isAccessibilityGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    Text("システム設定を開く")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("システム設定のアクセシビリティ権限画面を開く")
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
