import SwiftUI
import AppKit

struct HistorySettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Saved Data Types") {
                Toggle("Text", isOn: Binding(
                    get: { viewModel.settings.saveTextData },
                    set: { viewModel.toggleSaveTextData($0) }
                ))
                .accessibilityLabel("Save text data to clipboard history")

                Toggle("Images", isOn: Binding(
                    get: { viewModel.settings.saveImageData },
                    set: { viewModel.toggleSaveImageData($0) }
                ))
                .accessibilityLabel("Save image data to clipboard history")

                Toggle("PDF", isOn: Binding(
                    get: { viewModel.settings.savePDFData },
                    set: { viewModel.toggleSavePDFData($0) }
                ))
                .accessibilityLabel("Save PDF data to clipboard history")

                Toggle("Files", isOn: Binding(
                    get: { viewModel.settings.saveFileData },
                    set: { viewModel.toggleSaveFileData($0) }
                ))
                .accessibilityLabel("Save file references to clipboard history")
            }

            Section("Excluded Apps") {
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
                        .accessibilityLabel("Remove \(app.name) from the excluded list")
                    }
                    .accessibilityElement(children: .combine)
                }

                Button("+ Add") {
                    viewModel.addExcludedApp()
                }
                .accessibilityLabel("Add excluded app")
            }

            Section("History Data") {
                Button("Delete All History", role: .destructive) {
                    viewModel.requestClearHistory()
                }
                .accessibilityLabel("Delete all clipboard history")
            }
        }
        .formStyle(.grouped)
        .alert("Delete all history?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.confirmClearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

#Preview {
    HistorySettingsView(viewModel: SettingsViewModel(settings: AppSettings()))
        .frame(width: 450, height: 400)
}
