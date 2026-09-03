//
//  SettingsView.swift
//  Clarify
//
//  The one screen in Clarify that talks *about* the app rather than
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

                Section("About Clarify") {
                    Label("Sign-in is optional and never required to use the app", systemImage: "person.crop.circle.badge.checkmark")
                    Label("No Clarify account or server exists — ever", systemImage: "antenna.radiowaves.left.and.right.slash")
                    Label("All progress is stored locally only", systemImage: "internaldrive")
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
                    account.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
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
                ? "Signing in only personalizes this screen. Your guide progress, XP, and badges were never tied to an account and still aren't — none of it is synced anywhere."
                : "Completely optional. Sign in with Apple is handled by Apple and only personalizes this screen. Clarify has no account server, and your guide activity never leaves this device.")
        }
    }

    private func resetEverything() {
        gamification.resetAll()
        WorkflowProgressStore.clearAll()
        didReset.toggle()
    }
}
