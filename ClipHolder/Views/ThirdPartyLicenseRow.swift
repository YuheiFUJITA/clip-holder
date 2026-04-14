import SwiftUI

struct ThirdPartyLicenseRow: View {
    let name: String
    let version: String
    let licenseType: String
    let licenseResourceName: String
    let url: URL?

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView {
                Text(loadLicense())
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 160, maxHeight: 220)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name).bold()
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(licenseType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let url {
                    Link(destination: url) {
                        Text(url.absoluteString)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func loadLicense() -> String {
        guard let url = Bundle.main.url(forResource: licenseResourceName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "License text unavailable."
        }
        return text
    }
}
