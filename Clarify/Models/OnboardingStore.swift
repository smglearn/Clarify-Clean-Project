//
//  OnboardingStore.swift
//  Clarify
//
//  A single boolean — has the welcome carousel been shown yet — but
//  persisted the same way as everything else in Clarify: local JSON on
//  disk via FileManager, not UserDefaults. Consistency with
//  WorkflowProgressStore and GamificationStore matters more here than
//  the extra ceremony a single Bool would normally warrant, since
//  UserDefaults is deliberately absent everywhere else in this app.
//

import Foundation

struct OnboardingStore {
    private struct Snapshot: Codable {
        var hasCompletedOnboarding: Bool = false
    }

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("Clarify/Progress", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("onboarding.json")
    }

    func hasCompletedOnboarding() -> Bool {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return false }
        return snapshot.hasCompletedOnboarding
    }

    func markCompleted() {
        let snapshot = Snapshot(hasCompletedOnboarding: true)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
