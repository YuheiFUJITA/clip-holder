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
            MenuBarMenuView()
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

        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) {
            // クリップボード履歴表示 UI が実装された後にここで表示する
        }
    }
}
