import SwiftUI

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    var bundleVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    var copyrightString: String {
        infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }
}

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage())
                        .resizable()
                        .frame(width: 96, height: 96)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clip Holder")
                            .font(.title2).bold()
                        Text("Version \(Bundle.main.shortVersionString) (\(Bundle.main.bundleVersion))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(Bundle.main.copyrightString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section("License") {
                ScrollView {
                    Text(Self.loadLicenseText())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .frame(minHeight: 200, maxHeight: 260)
            }

            // Step 3 でここに Third-Party Licenses Section を追加する
        }
        .formStyle(.grouped)
    }

    private static func loadLicenseText() -> String {
        guard let url = Bundle.main.url(forResource: "LICENSE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "License text unavailable."
        }
        return text
    }
}

#Preview {
    AboutSettingsView()
        .frame(width: 450, height: 500)
}
