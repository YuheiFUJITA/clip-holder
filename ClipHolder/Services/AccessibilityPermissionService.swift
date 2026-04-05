import Foundation
import ApplicationServices
import AppKit

protocol AccessibilityPermissionChecking {
    var isGranted: Bool { get }
    func startPolling(onStatusChange: @escaping (Bool) -> Void)
    func stopPolling()
    func openSystemSettings()
}

final class AccessibilityPermissionService: AccessibilityPermissionChecking {
    private(set) var isGranted: Bool = false
    private var timer: Timer?
    private var onStatusChange: ((Bool) -> Void)?

    init() {
        isGranted = AXIsProcessTrusted()
    }

    func startPolling(onStatusChange: @escaping (Bool) -> Void) {
        self.onStatusChange = onStatusChange
        stopPolling()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let newStatus = AXIsProcessTrusted()
            if newStatus != self.isGranted {
                self.isGranted = newStatus
                self.onStatusChange?(newStatus)
            }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    deinit {
        stopPolling()
    }
}
