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

@main
struct clipperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    private let appSettings = AppSettings()
    private let historyStore = ClipboardHistoryStore()
    @State private var settingsViewModel: SettingsViewModel?
    @State private var clipboardMonitor: ClipboardMonitorService?
    @State private var panelWindowService: PanelWindowService?
    @State private var pasteService = PasteService()
    @State private var historyPanelViewModel: HistoryPanelViewModel?

    var body: some Scene {
        Window("オンボーディング", id: "onboarding") {
            OnboardingView(viewModel: OnboardingViewModel())
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)

        Settings {
            if let vm = settingsViewModel {
                TabView {
                    GeneralSettingsView(viewModel: vm)
                        .tabItem { Label("一般", systemImage: "gear") }
                    HistorySettingsView(viewModel: vm)
                        .tabItem { Label("履歴", systemImage: "clock") }
                    ShortcutsSettingsView()
                        .tabItem { Label("ショートカット", systemImage: "keyboard") }
                }
                .frame(width: 480)
            }
        }

        MenuBarExtra("Clipper", systemImage: "paperclip", isInserted: $showMenuBarIcon) {
            MenuBarMenuView(onShowHistory: { showHistoryPanel() })
        }
    }

    init() {
        let vm = SettingsViewModel(
            settings: appSettings,
            historyStore: historyStore
        )
        _settingsViewModel = State(initialValue: vm)

        let monitor = ClipboardMonitorService(settings: appSettings, store: historyStore)
        monitor.startMonitoring()
        _clipboardMonitor = State(initialValue: monitor)

        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) { [self] in
            showHistoryPanel()
        }
    }

    private func showHistoryPanel() {
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
