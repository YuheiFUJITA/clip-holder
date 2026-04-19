//
//  ClipHolderApp.swift
//  ClipHolder
//
//  Created by Yuhei FUJITA on 2026/03/25.
//

import SwiftUI
import AppKit
import KeyboardShortcuts

private struct SettingsWindowResizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.styleMask.insert(.resizable)
            var frame = window.frame
            frame.size.height = 600
            frame.size.width = 480
            window.setFrame(frame, display: true)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

/// アプリ全体の状態を保持するコントローラー
/// SwiftUI App struct のライフサイクルに依存しない安定した参照を提供する
@MainActor
final class AppController {
    static let shared = AppController()

    let appSettings = AppSettings()
    let historyStore = ClipboardHistoryStore()
    let pasteService = PasteService()
    let updateService = UpdateService()
    lazy var settingsViewModel = SettingsViewModel(
        settings: appSettings,
        historyStore: historyStore
    )

    private var clipboardMonitor: ClipboardMonitorService?
    private var panelWindowService: PanelWindowService?
    private var historyPanelViewModel: HistoryPanelViewModel?

    private init() {}

    func startMonitoring() {
        guard clipboardMonitor == nil else { return }
        let monitor = ClipboardMonitorService(settings: appSettings, store: historyStore)
        monitor.startMonitoring()
        clipboardMonitor = monitor
        settingsViewModel.updateService = updateService
        print("[AppController] Monitoring started")
    }

    func showHistoryPanel() {
        pasteService.recordPreviousApp()

        let service: PanelWindowService
        if let existing = panelWindowService {
            service = existing
        } else {
            service = PanelWindowService()
            let vm = HistoryPanelViewModel(
                store: historyStore,
                pasteService: pasteService,
                panelService: service,
                appSettings: appSettings
            )
            historyPanelViewModel = vm
            service.contentView = { [weak service] in
                AnyView(
                    HistoryPanelView(
                        viewModel: vm,
                        onDismiss: { service?.hidePanel() }
                    )
                )
            }
            panelWindowService = service
        }

        service.togglePanel()
        if service.isVisible {
            historyPanelViewModel?.onPanelShow()
            service.resizePanel(showPreview: appSettings.showPreview)
        }
    }
}

@main
struct ClipHolderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    private let controller = AppController.shared

    var body: some Scene {
        Window("Onboarding", id: "onboarding") {
            OnboardingView(viewModel: OnboardingViewModel())
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(hasCompletedOnboarding ? .suppressed : .presented)

        Settings {
            TabView {
                GeneralSettingsView(viewModel: controller.settingsViewModel)
                    .tabItem { Label("General", systemImage: "gear") }
                HistorySettingsView(viewModel: controller.settingsViewModel)
                    .tabItem { Label("History", systemImage: "clock") }
                ShortcutsSettingsView()
                    .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                AboutSettingsView()
                    .tabItem { Label("About", systemImage: "info.circle") }
            }
            .frame(minWidth: 480, minHeight: 400)
            .background(SettingsWindowResizer())
        }
        .defaultLaunchBehavior(hasCompletedOnboarding && controller.appSettings.openSettingsOnLaunch ? .presented : .suppressed)

        MenuBarExtra("Clip Holder", image: "MenuBarIcon", isInserted: $showMenuBarIcon) {
            MenuBarMenuView(
                onShowHistory: { controller.showHistoryPanel() },
                onCheckForUpdates: { controller.updateService.checkForUpdates() },
                canCheckForUpdates: controller.updateService.canCheckForUpdates
            )
        }
    }

    init() {
        controller.startMonitoring()
        controller.updateService.syncSettings(with: controller.appSettings)
        controller.updateService.startUpdater()

        if !controller.appSettings.showDockIcon {
            NSApplication.shared.setActivationPolicy(.accessory)
        }

        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) {
            Task { @MainActor in
                AppController.shared.showHistoryPanel()
            }
        }
    }
}
