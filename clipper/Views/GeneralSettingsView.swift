import SwiftUI

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
}

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

                Toggle("メニューバーにアイコンを表示", isOn: Binding(
                    get: { viewModel.settings.showMenuBarIcon },
                    set: { viewModel.settings.showMenuBarIcon = $0 }
                ))
                    .accessibilityLabel("メニューバーに Clipper アイコンを表示する")

                Toggle("Dock にアイコンを表示", isOn: Binding(
                    get: { viewModel.settings.showDockIcon },
                    set: { viewModel.toggleDockIcon($0) }
                ))
                    .accessibilityLabel("Dock に Clipper アイコンを表示する")

                Toggle("起動時に設定画面を開く", isOn: Binding(
                    get: { viewModel.settings.openSettingsOnLaunch },
                    set: { viewModel.settings.openSettingsOnLaunch = $0 }
                ))
                    .accessibilityLabel("起動時に設定画面を開く")
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

            Section("アップデート") {
                Toggle("自動的にダウンロードしてインストール", isOn: Binding(
                    get: { viewModel.settings.automaticallyDownloadsUpdates },
                    set: { viewModel.toggleAutomaticallyDownloadsUpdates($0) }
                ))
                    .accessibilityLabel("アップデートを自動的にダウンロードしてインストールする")

                HStack {
                    Button("アップデートを確認") {
                        viewModel.checkForUpdates()
                    }
                    .disabled(!(viewModel.updateService?.canCheckForUpdates ?? false))

                    Text("v\(Bundle.main.shortVersionString)（最新）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let date = viewModel.updateService?.lastUpdateCheckDate {
                    Text("最終確認: \(date.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        }
        .formStyle(.grouped)
        .onAppear { viewModel.startAccessibilityPolling() }
        .onDisappear { viewModel.stopAccessibilityPolling() }
    }
}

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel(settings: AppSettings()))
        .frame(width: 450, height: 400)
}
