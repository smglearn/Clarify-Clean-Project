//
//  SettingsView.swift
//  Clarify
//
//  The one screen in the app that talks *about* the app rather than
//  walking someone through a task: a reminder of what "no accounts, no
//  tracking" actually means in practice, and the one genuinely
//  destructive action in the whole app — wiping local progress —
//  gated behind a confirmation, since there is no server copy to
//  recover it from.
//

import AuthenticationServices
import SwiftUI

struct SettingsView: View {
    @Environment(GamificationManager.self) private var gamification
    @Environment(\.colorScheme) private var colorScheme
    @State private var account = AccountManager()
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var didReset = false

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// Every path that adds XP — a step, a workflow completion, a jargon
    /// flip — routes through `GamificationManager.awardXP`, so a totalXP
    /// of zero reliably means nothing has ever been touched: no in-progress
    /// guide save, no streak, no badge. Used to keep the destructive reset
    /// button from presenting a scary "this can't be undone" confirmation
    /// for a fresh install that has nothing to lose.
    private var hasProgress: Bool {
        gamification.totalXP > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Guides & XP", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .disabled(!hasProgress)
                } header: {
                    Text("Progress")
                } footer: {
                    Text(hasProgress
                        ? "Clears every guide's progress, your level, XP, streak, and badges. This can't be undone — there's no account to restore it from."
                        : "You haven't started any guides yet, so there's nothing to reset.")
                }

                Section {
                    Label("Sign-in is optional and never required to use the app", systemImage: "person.crop.circle.badge.checkmark")
                    Label("No Tech Unknotted account or server exists", systemImage: "antenna.radiowaves.left.and.right.slash")
                    Label("All progress is stored on this device only", systemImage: "internaldrive")
                    Label("Works fully offline", systemImage: "wifi.slash")
                } header: {
                    Text("About Tech Unknotted")
                } footer: {
                    Text("Tech Unknotted is an independent guide from Glenn's Gaming. It is not affiliated with, endorsed by, or sponsored by Google, Apple, Microsoft, Amazon, or Meta. Product names are used only to describe what each guide covers. Menus on those services change over time, so if a step doesn't match exactly, look for the closest option with a similar name.")
                }

                if AppLinks.support != nil || AppLinks.privacyPolicy != nil {
                    Section("Help") {
                        if let support = AppLinks.support {
                            Link(destination: support) {
                                Label("Get Support", systemImage: "questionmark.circle")
                            }
                        }
                        if let privacy = AppLinks.privacyPolicy {
                            Link(destination: privacy) {
                                Label("Privacy Policy", systemImage: "hand.raised")
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all guides and XP?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetEverything()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your level, XP, streak, badges, and every guide's progress will be cleared. This can't be undone.")
            }
            .confirmationDialog(
                "Sign out and delete your profile?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out & Delete", role: .destructive) {
                    account.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your name and email are removed from this device. Guide progress, XP, and badges stay as they are.")
            }
            .sensoryFeedback(.warning, trigger: didReset)
        }
    }

    // MARK: Account

    @ViewBuilder
    private var accountSection: some View {
        Section {
            if let profile = account.profile {
                HStack(spacing: 12) {
                    Image(systemName: profile.provider.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName)
                            .font(.headline)
                        if let email = profile.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Signed in with \(profile.provider.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out & Delete Profile", systemImage: "person.crop.circle.badge.xmark")
                }
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        account.completeAppleSignIn(authorization)
                    case .failure(let error):
                        account.handleAppleSignInFailure(error)
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 46)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                if let error = account.lastSignInError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Account")
        } footer: {
            Text(account.isSignedIn
                ? "Signing in only personalizes this screen. Signing out deletes the name and email stored on this device. Your guide progress, XP, and badges were never tied to an account. To also stop Apple sharing your sign-in with this app, open Settings, tap your name, then Sign-In & Security, then Sign in with Apple."
                : "Completely optional. Sign in with Apple is handled by Apple and only personalizes this screen. There's no account server, and your guide activity never leaves this device.")
        }
    }

    private func resetEverything() {
        gamification.resetAll()
        WorkflowProgressStore.clearAll()
        didReset.toggle()
    }
}
