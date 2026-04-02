import SwiftUI
import AppKit

struct HistorySettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("保存するデータの種類") {
                Toggle("テキストデータ", isOn: Binding(
                    get: { viewModel.settings.saveTextData },
                    set: { viewModel.toggleSaveTextData($0) }
                ))
                .accessibilityLabel("テキストデータをクリップボード履歴に保存する")

                Toggle("画像データ", isOn: Binding(
                    get: { viewModel.settings.saveImageData },
                    set: { viewModel.toggleSaveImageData($0) }
                ))
                .accessibilityLabel("画像データをクリップボード履歴に保存する")
            }

            Section("除外アプリ") {
                ForEach(viewModel.settings.excludedApps) { app in
                    HStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.bundlePath))
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(app.name)
                        Spacer()
                        Button {
                            viewModel.removeExcludedApp(app)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(app.name) を除外リストから削除")
                    }
                    .accessibilityElement(children: .combine)
                }

                Button("+ 追加") {
                    viewModel.addExcludedApp()
                }
                .accessibilityLabel("除外アプリを追加する")
            }

            Section("履歴データ") {
                Button("すべての履歴を削除", role: .destructive) {
                    viewModel.requestClearHistory()
                }
                .accessibilityLabel("すべてのクリップボード履歴を削除する")
            }
        }
        .formStyle(.grouped)
        .alert("すべての履歴を削除しますか？", isPresented: $viewModel.showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                viewModel.confirmClearHistory()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}

#Preview {
    HistorySettingsView(viewModel: SettingsViewModel(settings: AppSettings()))
        .frame(width: 450, height: 400)
}
