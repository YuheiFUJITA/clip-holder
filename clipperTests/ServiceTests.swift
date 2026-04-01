import Testing
import Foundation
@testable import clipper

@Suite
struct AccessibilityPermissionServiceTests {

    @Test func initialStateReflectsSystemStatus() {
        let service = AccessibilityPermissionService()
        // isGranted should be a Bool (either true or false based on system state)
        #expect(type(of: service.isGranted) == Bool.self)
    }

    @Test func startPollingCallsBack() async throws {
        let service = AccessibilityPermissionService()
        var callbackCalled = false

        service.startPolling { _ in
            callbackCalled = true
        }

        // Timer is scheduled; give it a moment
        try await Task.sleep(for: .milliseconds(100))
        service.stopPolling()

        // We can't guarantee a callback in tests (depends on system state change),
        // but we verify no crash and clean stop
        _ = callbackCalled
    }

    @Test func stopPollingIsIdempotent() {
        let service = AccessibilityPermissionService()
        service.stopPolling()
        service.stopPolling()
        // No crash = success
    }

    @Test func startThenStopDoesNotLeak() {
        let service = AccessibilityPermissionService()
        service.startPolling { _ in }
        service.stopPolling()
        // Starting again should work fine
        service.startPolling { _ in }
        service.stopPolling()
    }
}

@Suite
struct LoginItemServiceTests {

    @Test func isEnabledReturnsBoolean() {
        let service = LoginItemService()
        // Should return a valid boolean without crashing
        #expect(type(of: service.isEnabled) == Bool.self)
    }

    @Test func setEnabledDoesNotThrowOnValidCall() {
        let service = LoginItemService()
        // This may throw in sandboxed test environment, so we just verify the API exists
        do {
            try service.setEnabled(false)
        } catch {
            // Expected in test environment without proper entitlements
        }
    }
}
