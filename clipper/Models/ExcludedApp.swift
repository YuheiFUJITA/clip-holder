import Foundation

struct ExcludedApp: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let bundlePath: String
}
