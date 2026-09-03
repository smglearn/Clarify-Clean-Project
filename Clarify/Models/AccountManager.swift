//
//  AccountManager.swift
//  Clarify
//
//  Optional, local-only sign-in. Clarify's guides, XP, and badges have
//  never needed an account and still don't — this exists purely so
//  someone can put a name on their own progress if they want to. There
//  is no backend: signing in with Apple authenticates you to Apple,
//  once, on-device, and Clarify simply remembers the name Apple handed
//  back, in the same local JSON store every other piece of state in
//  this app already uses. Nothing here is synced, and nothing is sent
//  anywhere Clarify doesn't already send data to — which is nowhere.
//

import Foundation
import AuthenticationServices
import Observation

/// Provider metadata for the optional local profile. Settings currently
/// offers Sign in with Apple only; the remaining cases keep the model
/// ready for a future provider without exposing unfinished buttons.
enum AccountProvider: String, Codable, CaseIterable, Hashable, Identifiable {
    case apple
    case google
    case microsoft
    case amazon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .microsoft: return "Microsoft"
        case .amazon: return "Amazon"
        }
    }

    /// Google, Microsoft, and Amazon get neutral, non-trademarked
    /// stand-ins here — same reasoning as `Company.symbolName`: evocative
    /// of the provider, never their actual logo mark, since these three
    /// buttons don't lead to a real, provider-verified sign-in. Apple is
    /// the one exception: its own Sign in with Apple guidelines require
    /// the real Apple mark on that specific button, which is why the
    /// button itself uses SwiftUI's native `SignInWithAppleButton`
    /// rather than this symbol — this case exists only for the small
    /// "Signed in with Apple" badge shown after the fact.
    var symbolName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "magnifyingglass.circle.fill"
        case .microsoft: return "square.grid.2x2.fill"
        case .amazon: return "cart.fill"
        }
    }

    var isAvailable: Bool { self == .apple }
}

/// A signed-in profile, once someone has actually completed a sign-in
/// flow. Deliberately tiny — just enough to say a name back to the
/// person and remember which provider they used — because nothing in
/// Clarify's guides, XP, or badges is gated behind having an account.
struct AccountProfile: Codable, Hashable {
    let provider: AccountProvider
    var displayName: String
    var email: String?
    /// Apple's stable per-app-per-user identifier, kept only so a
    /// future launch can ask Apple "is this still valid?" rather than
    /// trusting a locally-cached name forever.
    let providerUserID: String
}

private struct AccountSnapshot: Codable {
    var profile: AccountProfile?
}

/// Optional, local-only sign-in on top of Apple's own authentication.
///
/// This is deliberately *not* an accounts system: there is no Clarify
/// server, no session token, no backend that knows this profile exists.
/// Signing in with Apple simply asks Apple's on-device authentication
/// UI to vouch for who's holding the phone, and Clarify keeps the name
/// it hands back locally — nothing new leaves the device, because
/// nothing in this app ever talks to a server to begin with.
///
/// Settings deliberately exposes only Apple's finished system flow.
/// Other provider metadata remains dormant until a future version has
/// a complete, privacy-reviewed implementation worth showing to users.
@Observable
final class AccountManager {

    private(set) var profile: AccountProfile?
    private(set) var lastSignInError: String?

    var isSignedIn: Bool { profile != nil }

    private var store: AccountStore

    init(store: AccountStore = .init()) {
        self.store = store
        restore()
        Task { await refreshAppleCredentialState() }
    }

    // MARK: Sign in with Apple

    /// Turns Apple's authorization result into a stored local profile.
    /// Apple only hands back a name and email on the *first*
    /// authorization for a given user/app pair — every sign-in after
    /// that returns nil for both, by design — so this only overwrites
    /// what's already on file when Apple actually provides something
    /// new to overwrite it with.
    func completeAppleSignIn(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            lastSignInError = "That didn't look like an Apple sign-in response."
            return
        }

        let resolvedName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let name = resolvedName.isEmpty ? (profile?.displayName ?? "Apple User") : resolvedName
        let email = credential.email ?? profile?.email

        profile = AccountProfile(
            provider: .apple,
            displayName: name,
            email: email,
            providerUserID: credential.user
        )
        lastSignInError = nil
        persist()
    }

    func handleAppleSignInFailure(_ error: Error) {
        // Apple represents "the person tapped Cancel" as an error too —
        // that's expected behavior, not a failure worth surfacing.
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            return
        }
        lastSignInError = "Sign-in didn't go through. Try again."
    }

    func signOut() {
        profile = nil
        lastSignInError = nil
        store.clear()
    }

    /// Checks Apple's own record of whether the stored credential is
    /// still valid — e.g. the person revoked Clarify's access under
    /// Settings > Apple ID > Sign in with Apple — and quietly signs out
    /// locally if so, rather than continuing to show a name that isn't
    /// actually authenticated anymore.
    @MainActor
    private func refreshAppleCredentialState() async {
        guard let profile, profile.provider == .apple else { return }
        let provider = ASAuthorizationAppleIDProvider()
        let state: ASAuthorizationAppleIDProvider.CredentialState = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: profile.providerUserID) { state, _ in
                continuation.resume(returning: state)
            }
        }
        if state == .revoked || state == .notFound {
            signOut()
        }
    }

    // MARK: Persistence

    private func restore() {
        guard let snapshot = store.load() else { return }
        profile = snapshot.profile
    }

    private func persist() {
        store.save(AccountSnapshot(profile: profile))
    }
}

/// Thin, testable wrapper around on-disk JSON persistence, mirroring
/// every other store in this app (`WorkflowProgressStore`,
/// `GamificationStore`, `OnboardingStore`).
struct AccountStore {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("Clarify/Progress", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("account.json")
    }

    fileprivate func load() -> AccountSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AccountSnapshot.self, from: data)
    }

    fileprivate func save(_ snapshot: AccountSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
