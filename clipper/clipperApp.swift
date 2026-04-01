//
//  clipperApp.swift
//  clipper
//
//  Created by Yuhei FUJITA on 2026/03/25.
//

import SwiftUI

@main
struct clipperApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(viewModel: OnboardingViewModel())
            }
        }
        .windowResizability(.contentSize)
    }
}
