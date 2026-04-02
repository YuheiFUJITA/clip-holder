//
//  clipperApp.swift
//  clipper
//
//  Created by Yuhei FUJITA on 2026/03/25.
//

import SwiftUI
import AppKit
import KeyboardShortcuts

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
                panelService: service
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
        }
    }
}

@main
struct clipperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    private let controller = AppController.shared

    var body: some Scene {
        Window("オンボーディング", id: "onboarding") {
            OnboardingView(viewModel: OnboardingViewModel())
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)

        Settings {
            TabView {
                GeneralSettingsView(viewModel: controller.settingsViewModel)
                    .tabItem { Label("一般", systemImage: "gear") }
                HistorySettingsView(viewModel: controller.settingsViewModel)
                    .tabItem { Label("履歴", systemImage: "clock") }
                ShortcutsSettingsView()
                    .tabItem { Label("ショートカット", systemImage: "keyboard") }
            }
            .frame(width: 480)
        }

        MenuBarExtra("Clipper", systemImage: "paperclip", isInserted: $showMenuBarIcon) {
            MenuBarMenuView(onShowHistory: { controller.showHistoryPanel() })
        }
    }

    init() {
        controller.startMonitoring()

        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) {
            Task { @MainActor in
                AppController.shared.showHistoryPanel()
            }
        }
    }
}
