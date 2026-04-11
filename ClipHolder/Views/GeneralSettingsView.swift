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
            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { viewModel.settings.launchAtLogin },
                    set: { viewModel.toggleLaunchAtLogin($0) }
                ))
                .accessibilityLabel("Launch Clip Holder at login")

                Toggle("Show menu bar icon", isOn: Binding(
                    get: { viewModel.settings.showMenuBarIcon },
                    set: { viewModel.settings.showMenuBarIcon = $0 }
                ))
                    .accessibilityLabel("Show Clip Holder icon in the menu bar")

                Toggle("Show Dock icon", isOn: Binding(
                    get: { viewModel.settings.showDockIcon },
                    set: { viewModel.toggleDockIcon($0) }
                ))
                    .accessibilityLabel("Show Clip Holder icon in the Dock")

                Toggle("Open Settings on launch", isOn: Binding(
                    get: { viewModel.settings.openSettingsOnLaunch },
                    set: { viewModel.settings.openSettingsOnLaunch = $0 }
                ))
                    .accessibilityLabel("Open Settings on launch")
            }

            Section("Clipboard History") {
                HStack {
                    Text("Maximum entries")
                    Spacer()
                    TextField("", value: Binding(
                        get: { viewModel.settings.maxHistoryCount },
                        set: { viewModel.updateMaxHistoryCount($0) }
                    ), format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                .accessibilityLabel("Maximum number of clipboard history entries")
                .accessibilityValue("\(viewModel.settings.maxHistoryCount) entries")
            }

            Section("Accessibility Permission") {
                HStack {
                    Circle()
                        .fill(viewModel.isAccessibilityGranted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isAccessibilityGranted ? "Granted" : "Not granted")
                        .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)
                        .font(.subheadline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Accessibility permission status")
                .accessibilityValue(viewModel.isAccessibilityGranted ? "Granted" : "Not granted")

                if !viewModel.isAccessibilityGranted {
                    Button("Open System Settings") {
                        viewModel.openAccessibilitySettings()
                    }
                    .accessibilityLabel("Open the Accessibility permission pane in System Settings")
                }
            }

            Section("Updates") {
                Toggle("Automatically download and install", isOn: Binding(
                    get: { viewModel.settings.automaticallyDownloadsUpdates },
                    set: { viewModel.toggleAutomaticallyDownloadsUpdates($0) }
                ))
                    .accessibilityLabel("Automatically download and install updates")

                HStack {
                    Button("Check for Updates") {
                        viewModel.checkForUpdates()
                    }
                    .disabled(!(viewModel.updateService?.canCheckForUpdates ?? false))

                    Text("v\(Bundle.main.shortVersionString) (Latest)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let date = viewModel.updateService?.lastUpdateCheckDate {
                    Text("Last checked: \(date.formatted(date: .numeric, time: .shortened))")
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
