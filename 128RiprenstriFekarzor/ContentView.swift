//
//  ContentView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ContentView: View {
    @StateObject private var progress = GameProgressStore()

    var body: some View {
        Group {
            if progress.hasSeenOnboarding {
                MainShellView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(progress)
    }
}

#Preview {
    ContentView()
}
