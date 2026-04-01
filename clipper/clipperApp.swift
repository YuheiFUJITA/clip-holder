//
//  clipperApp.swift
//  clipper
//
//  Created by Yuhei FUJITA on 2026/03/25.
//

import SwiftUI
import AppKit

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

    var body: some Scene {
        Window("オンボーディング", id: "onboarding") {
            OnboardingView(viewModel: OnboardingViewModel())
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)

        Settings {
            TabView {
                GeneralSettingsView(viewModel: SettingsViewModel())
                    .tabItem { Label("一般", systemImage: "gear") }
                HistorySettingsView(viewModel: SettingsViewModel())
                    .tabItem { Label("履歴", systemImage: "clock") }
                ShortcutsSettingsView()
                    .tabItem { Label("ショートカット", systemImage: "keyboard") }
            }
            .frame(width: 480)
        }

        MenuBarExtra("Clipper", systemImage: "paperclip", isInserted: $showMenuBarIcon) {
            MenuBarMenuView()
        }
    }
}
