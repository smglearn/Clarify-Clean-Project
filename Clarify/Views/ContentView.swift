//
//  ContentView.swift
//  Clarify
//
//  Root of the visible UI. Four tabs: guided workflows, the gamified
//  Journey tab, the standalone glossary, and Settings. No sign-in gate,
//  no onboarding wall that blocks usage — the welcome carousel is
//  skippable and never gates anything below it.
//
//  GamificationManager is created once here and pushed into the
//  environment, so every tab (and every nested workflow run) shares
//  the same XP/level/badge state instead of each screen keeping its
//  own out-of-sync copy.
//

import SwiftUI

struct ContentView: View {
    @State private var gamification = GamificationManager()
    @State private var showOnboarding = !OnboardingStore().hasCompletedOnboarding()

    var body: some View {
        TabView {
            WorkflowListView()
                .tabItem {
                    Label("Guides", systemImage: "checklist")
                }

            ProgressHubView()
                .tabItem {
                    Label("Journey", systemImage: "star.circle.fill")
                }

            GlossaryView()
                .tabItem {
                    Label("Glossary", systemImage: "character.book.closed.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environment(gamification)
        .gamificationOverlays(gamification)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
            }
        }
    }
}

#Preview {
    ContentView()
}
