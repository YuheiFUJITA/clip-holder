import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("起動") {
                Toggle("ログイン時に自動起動", isOn: Binding(
                    get: { viewModel.settings.launchAtLogin },
                    set: { viewModel.toggleLaunchAtLogin($0) }
                ))
                .accessibilityLabel("ログイン時に Clipper を自動起動する")

                Toggle("メニューバーにアイコンを表示", isOn: viewModel.settings.$showMenuBarIcon)
                    .accessibilityLabel("メニューバーに Clipper アイコンを表示する")
            }

            Section("クリップボード履歴") {
                HStack {
                    Text("最大保存件数")
                    Spacer()
                    TextField("", value: Binding(
                        get: { viewModel.settings.maxHistoryCount },
                        set: { viewModel.updateMaxHistoryCount($0) }
                    ), format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                .accessibilityLabel("クリップボード履歴の最大保存件数")
                .accessibilityValue("\(viewModel.settings.maxHistoryCount)件")
            }

            Section("アクセシビリティ権限") {
                HStack {
                    Circle()
                        .fill(viewModel.isAccessibilityGranted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isAccessibilityGranted ? "設定済み" : "未設定")
                        .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)
                        .font(.subheadline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("アクセシビリティ権限の状態")
                .accessibilityValue(viewModel.isAccessibilityGranted ? "設定済み" : "未設定")

                if !viewModel.isAccessibilityGranted {
                    Button("システム設定を開く") {
                        viewModel.openAccessibilitySettings()
                    }
                    .accessibilityLabel("システム設定のアクセシビリティ権限画面を開く")
                }
            }

            Section("オンボーディング") {
                Button("オンボーディングをリセット") {
                    viewModel.resetOnboarding()
                }
                .accessibilityLabel("オンボーディングをリセットして次回起動時に再表示する")
            }
        }
        .formStyle(.grouped)
        .onAppear { viewModel.startAccessibilityPolling() }
        .onDisappear { viewModel.stopAccessibilityPolling() }
    }
}

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 450, height: 400)
}
