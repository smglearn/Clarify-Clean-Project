//
//  WorkflowManager.swift
//  Clarify
//
//  The single state machine that owns "where is the user in this
//  workflow right now". Deliberately strict: there is no public API
//  for jumping to an arbitrary step, only `advance()` and `retreat()`,
//  so the UI layer cannot accidentally let someone skip ahead.
//
//  Persistence is local-only JSON on disk via FileManager. There is no
//  account system, no CloudKit container, and no network call anywhere
//  in this file — progress lives entirely on the device.
//

import Foundation
import Observation

/// Progress for a single workflow, persisted independently so a user can
/// have several in-flight guides at once.
private struct WorkflowProgress: Codable {
    let workflowID: UUID
    var completedStepIDs: Set<UUID>
    var currentStepIndex: Int
}

@Observable
final class WorkflowManager {

    // MARK: Public, read-only state

    private(set) var workflow: Workflow
    private(set) var currentStepIndex: Int = 0
    private(set) var completedStepIDs: Set<UUID> = []

    /// Bumped on every completed step so `.sensoryFeedback(.success, trigger:)`
    /// has a value to key off of.
    private(set) var completionPulse: Int = 0

    var currentStep: WorkflowStep {
        workflow.steps[currentStepIndex]
    }

    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex == workflow.steps.count - 1 }
    var progressFraction: Double {
        guard workflow.steps.count > 1 else { return 1 }
        return Double(currentStepIndex) / Double(workflow.steps.count - 1)
    }

    // MARK: Private

    private let store: WorkflowProgressStore

    init(workflow: Workflow, store: WorkflowProgressStore = .init()) {
        self.workflow = workflow
        self.store = store
        restore()
    }

    // MARK: State machine transitions

    /// Marks the current step complete and, if there is a next step,
    /// moves to it. This is the *only* way the current index advances —
    /// there is no "jump to step N" entry point, which is what keeps the
    /// flow strictly linear.
    func advance() {
        completedStepIDs.insert(currentStep.id)
        completionPulse += 1

        guard !isLastStep else {
            persist()
            return
        }
        currentStepIndex += 1
        persist()
    }

    /// Steps backward to review a previous screen. Does not un-complete
    /// the step being left, since revisiting a finished step isn't the
    /// same as un-finishing it.
    func retreat() {
        guard !isFirstStep else { return }
        currentStepIndex -= 1
        persist()
    }

    func resetProgress() {
        currentStepIndex = 0
        completedStepIDs.removeAll()
        store.clear(workflowID: workflow.id)
    }

    // MARK: Persistence (local disk only, no network, no account)

    private func restore() {
        guard let saved = store.load(workflowID: workflow.id) else { return }
        // Clamp defensively in case the bundled workflow content changed
        // step count since this progress was last saved on disk.
        currentStepIndex = min(saved.currentStepIndex, workflow.steps.count - 1)
        completedStepIDs = saved.completedStepIDs
    }

    private func persist() {
        let progress = WorkflowProgress(
            workflowID: workflow.id,
            completedStepIDs: completedStepIDs,
            currentStepIndex: currentStepIndex
        )
        store.save(progress, workflowID: workflow.id)
    }
}

/// Thin, testable wrapper around on-disk JSON persistence. Kept separate
/// from `WorkflowManager` so the state machine itself has no direct
/// FileManager dependency and can be unit tested with an in-memory store.
struct WorkflowProgressStore {
    private let directory: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        directory = base.appendingPathComponent("Clarify/Progress", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    fileprivate func load(workflowID: UUID) -> WorkflowProgress? {
        let url = fileURL(for: workflowID)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WorkflowProgress.self, from: data)
    }

    fileprivate func save(_ progress: WorkflowProgress, workflowID: UUID) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        try? data.write(to: fileURL(for: workflowID), options: .atomic)
    }

    func clear(workflowID: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: workflowID))
    }

    /// True when this workflow has a save on disk that's past its first
    /// step but not yet finished. Used by `WorkflowListView` to surface
    /// a "Continue" card without instantiating a full `WorkflowManager`
    /// (and its own restore/persist cycle) just to check.
    func hasInProgressSave(workflowID: UUID, totalSteps: Int) -> Bool {
        guard let saved = load(workflowID: workflowID) else { return false }
        return !saved.completedStepIDs.isEmpty && saved.completedStepIDs.count < totalSteps
    }

    /// Wipes every per-workflow save on disk — used by the Settings
    /// screen's "Reset All Guides" action. Deliberately leaves
    /// `gamification.json`, `onboarding.json`, and `account.json` alone,
    /// since those live in the same directory but aren't per-workflow
    /// saves — resetting guide progress shouldn't also sign someone out.
    static func clearAll(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("Clarify/Progress", isDirectory: true)
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        let reservedNames: Set<String> = ["gamification.json", "onboarding.json", "account.json"]
        for file in files where !reservedNames.contains(file.lastPathComponent) {
            try? fileManager.removeItem(at: file)
        }
    }

    private func fileURL(for workflowID: UUID) -> URL {
        directory.appendingPathComponent("\(workflowID.uuidString).json")
    }
}
