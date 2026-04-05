import Foundation
import Sparkle

protocol UpdateManaging {
    var canCheckForUpdates: Bool { get }
    var lastUpdateCheckDate: Date? { get }
    func startUpdater()
    func checkForUpdates()
}

@Observable
@MainActor
final class UpdateService: NSObject, UpdateManaging {
    private let updaterController: SPUStandardUpdaterController
    private(set) var canCheckForUpdates: Bool = false

    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }

    override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        // 自動確認は常に有効
        updaterController.updater.automaticallyChecksForUpdates = true

        // KVO で canCheckForUpdates を監視
        updaterController.updater.addObserver(
            self,
            forKeyPath: "canCheckForUpdates",
            options: [.initial, .new],
            context: nil
        )
    }

    deinit {
        updaterController.updater.removeObserver(self, forKeyPath: "canCheckForUpdates")
    }

    nonisolated override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "canCheckForUpdates" {
            let newValue = change?[.newKey] as? Bool ?? false
            Task { @MainActor in
                self.canCheckForUpdates = newValue
            }
        }
    }

    func startUpdater() {
        do {
            try updaterController.updater.start()
            print("[UpdateService] Updater started")
        } catch {
            print("[UpdateService] Failed to start updater: \(error)")
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func syncSettings(with settings: AppSettings) {
        updaterController.updater.automaticallyDownloadsUpdates = settings.automaticallyDownloadsUpdates
    }
}
