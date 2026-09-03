//
//  Gamification.swift
//  Clarify
//
//  The points/levels/badges layer that sits alongside WorkflowManager.
//  Deliberately a separate `@Observable` class rather than folded into
//  WorkflowManager: XP, streaks, and badges span *every* workflow and
//  the glossary too, while WorkflowManager only ever knows about one
//  workflow at a time. Persistence is local JSON on disk, exactly like
//  WorkflowProgressStore — no account, no server, no leaderboard.
//

import Foundation
import Observation

enum BadgeCategory: String, CaseIterable, Identifiable {
    case guides = "Guides"
    case glossary = "Glossary"
    case streaks = "Streaks"
    case levels = "Levels"

    var id: String { rawValue }
}

/// The measurable goal behind a badge. Keeping the goal beside the
/// badge's display metadata gives unlocking logic and Journey progress
/// bars one shared source of truth.
enum BadgeGoal: Hashable {
    case guides(Int)
    case allGuides
    case providers(Int)
    case glossaryTerms(Int)
    case allGlossaryTerms
    case streak(Int)
    case level(Int)

    var category: BadgeCategory {
        switch self {
        case .guides, .allGuides, .providers:
            return .guides
        case .glossaryTerms, .allGlossaryTerms:
            return .glossary
        case .streak:
            return .streaks
        case .level:
            return .levels
        }
    }
}

/// A single unlockable achievement and the goal that earns it.
struct Badge: Identifiable, Hashable {
    let id: String
    let title: String
    let badgeDescription: String
    let symbolName: String
    let goal: BadgeGoal

    var category: BadgeCategory { goal.category }
}

struct BadgeProgress: Hashable {
    let current: Int
    let target: Int

    var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(current) / Double(target)))
    }

    var isComplete: Bool { target > 0 && current >= target }
}

enum BadgeLibrary {
    static let all: [Badge] = [
        // Guide milestones: frequent early wins, then wider spacing as
        // someone works through the 300-guide catalog.
        Badge(id: "first-flight", title: "First Flight", badgeDescription: "Complete your first guide.", symbolName: "airplane.departure", goal: .guides(1)),
        Badge(id: "triple-threat", title: "Triple Threat", badgeDescription: "Complete 3 guides.", symbolName: "3.circle.fill", goal: .guides(3)),
        Badge(id: "clear-path", title: "Clear Path", badgeDescription: "Complete 10 guides.", symbolName: "figure.walk", goal: .guides(10)),
        Badge(id: "pathfinder", title: "Pathfinder", badgeDescription: "Complete 25 guides.", symbolName: "map.fill", goal: .guides(25)),
        Badge(id: "guide-veteran", title: "Guide Veteran", badgeDescription: "Complete 50 guides.", symbolName: "medal.fill", goal: .guides(50)),
        Badge(id: "clarity-century", title: "Clarity Century", badgeDescription: "Complete 100 guides.", symbolName: "books.vertical.fill", goal: .guides(100)),
        Badge(id: "deep-library", title: "Deep Library", badgeDescription: "Complete 200 guides.", symbolName: "binoculars.fill", goal: .guides(200)),
        Badge(id: "guide-master", title: "Guide Master", badgeDescription: "Complete every guide in Clarify.", symbolName: "trophy.fill", goal: .allGuides),

        // Breadth across provider sections.
        Badge(id: "provider-explorer", title: "Provider Explorer", badgeDescription: "Complete a guide from every provider.", symbolName: "globe.americas.fill", goal: .providers(Company.allCases.count)),

        // Glossary milestones scale to the full 517-card collection.
        Badge(id: "jargon-collector", title: "Jargon Collector", badgeDescription: "Flip 10 different glossary cards.", symbolName: "rectangle.stack.fill", goal: .glossaryTerms(10)),
        Badge(id: "word-wrangler", title: "Word Wrangler", badgeDescription: "Flip 50 different glossary cards.", symbolName: "text.book.closed.fill", goal: .glossaryTerms(50)),
        Badge(id: "plain-speaker", title: "Plain Speaker", badgeDescription: "Flip 100 different glossary cards.", symbolName: "quote.bubble.fill", goal: .glossaryTerms(100)),
        Badge(id: "translation-pro", title: "Translation Pro", badgeDescription: "Flip 250 different glossary cards.", symbolName: "character.bubble.fill", goal: .glossaryTerms(250)),
        Badge(id: "master-translator", title: "Master Translator", badgeDescription: "Flip every card in the glossary.", symbolName: "character.book.closed.fill", goal: .allGlossaryTerms),

        // Habit milestones reward sustained return visits without making
        // a missed day erase badges that were already earned.
        Badge(id: "on-a-roll", title: "On a Roll", badgeDescription: "Keep a 3-day streak going.", symbolName: "flame.fill", goal: .streak(3)),
        Badge(id: "week-strong", title: "Week Strong", badgeDescription: "Keep a 7-day streak going.", symbolName: "flame.circle.fill", goal: .streak(7)),
        Badge(id: "fortnight-focus", title: "Fortnight Focus", badgeDescription: "Keep a 14-day streak going.", symbolName: "calendar.badge.checkmark", goal: .streak(14)),
        Badge(id: "monthly-momentum", title: "Monthly Momentum", badgeDescription: "Keep a 30-day streak going.", symbolName: "calendar.circle.fill", goal: .streak(30)),

        // The available one-time XP reaches roughly level 36, so level
        // rewards now span almost the entire achievable curve.
        Badge(id: "rising-star", title: "Rising Star", badgeDescription: "Reach level 5.", symbolName: "star.fill", goal: .level(5)),
        Badge(id: "clarity-expert", title: "Clarity Expert", badgeDescription: "Reach level 10.", symbolName: "star.circle.fill", goal: .level(10)),
        Badge(id: "bright-mind", title: "Bright Mind", badgeDescription: "Reach level 20.", symbolName: "lightbulb.max.fill", goal: .level(20)),
        Badge(id: "clarity-champion", title: "Clarity Champion", badgeDescription: "Reach level 30.", symbolName: "crown.fill", goal: .level(30)),
        Badge(id: "peak-clarity", title: "Peak Clarity", badgeDescription: "Reach level 35.", symbolName: "mountain.2.fill", goal: .level(35))
    ]

    static func badge(id: String) -> Badge? {
        all.first { $0.id == id }
    }
}

/// Everything that gets written to disk. Kept separate from
/// `GamificationManager` itself so the class can stay `@Observable`
/// without every property needing to be `Codable`-friendly.
private struct GamificationSnapshot: Codable {
    var totalXP: Int = 0
    var completedWorkflowIDs: Set<UUID> = []
    var flippedTermIDs: Set<UUID> = []
    var streakCount: Int = 0
    var lastActivityDay: Date?
    var unlockedBadgeIDs: Set<String> = []
    /// Every step ID XP has ever been paid out for. Deliberately
    /// separate from (and never cleared by) a single workflow's own
    /// `completedStepIDs` — that set resets when someone replays a
    /// guide via "Start Over" or the per-guide reset, but the XP for a
    /// step should only ever be earned once, or resetting a guide would
    /// turn into an infinite XP farm.
    var xpAwardedStepIDs: Set<UUID> = []
}

@Observable
final class GamificationManager {

    // MARK: Public, read-only state

    private(set) var totalXP: Int = 0
    private(set) var completedWorkflowIDs: Set<UUID> = []
    private(set) var flippedTermIDs: Set<UUID> = []
    private(set) var streakCount: Int = 0
    private(set) var unlockedBadgeIDs: Set<String> = []
    private var xpAwardedStepIDs: Set<UUID> = []

    /// The most recent XP award, for a toast to display. Paired with
    /// `xpEventPulse` (which always changes) since two awards of the
    /// same amount in a row wouldn't otherwise re-trigger a `.onChange`.
    private(set) var lastXPGain: Int = 0
    private(set) var xpEventPulse: Int = 0

    /// Set to the level just reached whenever a level-up occurs, and
    /// cleared once the celebration overlay has consumed it.
    private(set) var levelUpPulse: Int = 0
    private(set) var justReachedLevel: Int?

    /// Badges unlocked but not yet celebrated with a toast, oldest first.
    /// A queue rather than a single "most recent" badge because one user
    /// action can trigger two separate XP awards — e.g. finishing a
    /// workflow's last step pays out that step's own XP, then a moment
    /// later the workflow-completion bonus — and each award re-checks
    /// every badge from scratch. If two different badges crossed their
    /// threshold across those two awards (or even within one, if a
    /// single award happens to satisfy two conditions at once), a plain
    /// "last unlocked badge" property would let the second overwrite the
    /// first before its toast ever displayed, silently skipping a
    /// celebration for a badge the user did actually earn. Draining a
    /// queue instead means every fresh unlock gets its moment.
    private(set) var pendingBadgeCelebrations: [Badge] = []

    /// The next badge toast to show, if any. Kept as the public surface
    /// (rather than exposing the queue directly) so existing callers —
    /// and `.onChange(of:)` observers — don't need to know this is
    /// backed by more than one pending badge.
    var newlyUnlockedBadge: Badge? { pendingBadgeCelebrations.first }

    var level: Int { Self.level(forTotalXP: totalXP) }

    var xpIntoCurrentLevel: Int {
        totalXP - Self.cumulativeXP(throughLevel: level - 1)
    }

    var xpRequiredForCurrentLevel: Int { Self.xpRequired(forLevel: level) }

    var levelProgress: Double {
        let required = xpRequiredForCurrentLevel
        guard required > 0 else { return 1 }
        return min(1, max(0, Double(xpIntoCurrentLevel) / Double(required)))
    }

    /// Counts only identifiers that still exist in the bundled catalog.
    /// This keeps legacy or removed content from inflating current
    /// milestones while allowing the persisted ID sets to remain a
    /// lightweight source of truth.
    var completedWorkflowCount: Int {
        WorkflowLibrary.all.filter { completedWorkflowIDs.contains($0.id) }.count
    }

    var flippedTermCount: Int {
        JargonGlossary.allTerms.filter { flippedTermIDs.contains($0.id) }.count
    }

    var unlockedBadges: [Badge] {
        BadgeLibrary.all.filter { unlockedBadgeIDs.contains($0.id) }
    }

    var lockedBadges: [Badge] {
        BadgeLibrary.all.filter { !unlockedBadgeIDs.contains($0.id) }
    }

    func badgeProgress(for badge: Badge) -> BadgeProgress {
        switch badge.goal {
        case .guides(let target):
            return BadgeProgress(current: completedWorkflowCount, target: target)
        case .allGuides:
            return BadgeProgress(current: completedWorkflowCount, target: WorkflowLibrary.all.count)
        case .providers(let target):
            let completedProviders = Set(
                WorkflowLibrary.all
                    .filter { completedWorkflowIDs.contains($0.id) }
                    .compactMap(\.company)
            ).count
            return BadgeProgress(current: completedProviders, target: target)
        case .glossaryTerms(let target):
            return BadgeProgress(current: flippedTermCount, target: target)
        case .allGlossaryTerms:
            return BadgeProgress(current: flippedTermCount, target: JargonGlossary.allTerms.count)
        case .streak(let target):
            return BadgeProgress(current: streakCount, target: target)
        case .level(let target):
            return BadgeProgress(current: level, target: target)
        }
    }

    // MARK: Private

    private var store: GamificationStore
    private let calendar = Calendar.current

    init(store: GamificationStore = .init()) {
        self.store = store
        restore()
    }

    // MARK: Earning XP

    /// Call whenever the user does something worth rewarding: finishing
    /// a step, flipping a new jargon card, completing a workflow. Rolls
    /// the streak forward and re-checks every badge in one place, so no
    /// caller has to remember to do that itself.
    func awardXP(_ amount: Int) {
        guard amount > 0 else { return }
        let previousLevel = level
        totalXP += amount
        lastXPGain = amount
        xpEventPulse += 1

        let newLevel = level
        if newLevel > previousLevel {
            justReachedLevel = newLevel
            levelUpPulse += 1
        }

        recordActivityToday()
        refreshBadges()
        persist()
    }

    /// The only entry point a step's completion should ever go
    /// through. Pays out `xpValue` exactly once per step, no matter how
    /// many times that step gets revisited across a guide reset —
    /// unlike `recordWorkflowCompleted`'s own one-time bonus, a plain
    /// `awardXP` call here would have let "Reset This Guide" become a
    /// free XP loop.
    func awardStepCompletion(stepID: UUID, xpValue: Int) {
        guard !xpAwardedStepIDs.contains(stepID) else { return }
        xpAwardedStepIDs.insert(stepID)
        awardXP(xpValue)
    }

    func recordWorkflowCompleted(_ workflow: Workflow) {
        guard !completedWorkflowIDs.contains(workflow.id) else { return }
        completedWorkflowIDs.insert(workflow.id)
        awardXP(Workflow.completionBonusXP)
    }

    /// Rewards curiosity in the glossary itself, not just inside a
    /// workflow — flipping a card you haven't seen before is worth a
    /// small amount of XP, once per term.
    func recordJargonFlip(termID: UUID) {
        guard !flippedTermIDs.contains(termID) else { return }
        flippedTermIDs.insert(termID)
        awardXP(3)
    }

    func acknowledgeLevelUp() {
        justReachedLevel = nil
    }

    /// Dismisses the badge currently at the front of the celebration
    /// queue. If another badge unlocked in the same action is waiting
    /// behind it, `newlyUnlockedBadge` immediately reflects that one
    /// next — the view's `.onChange` picks it up and shows its toast in
    /// turn, so a double unlock plays as two toasts back to back instead
    /// of one getting silently dropped.
    func acknowledgeBadge() {
        guard !pendingBadgeCelebrations.isEmpty else { return }
        pendingBadgeCelebrations.removeFirst()
    }

    func resetAll() {
        totalXP = 0
        completedWorkflowIDs.removeAll()
        flippedTermIDs.removeAll()
        streakCount = 0
        unlockedBadgeIDs.removeAll()
        xpAwardedStepIDs.removeAll()
        justReachedLevel = nil
        pendingBadgeCelebrations.removeAll()
        store.lastActivityDay = nil
        store.clear()
    }

    // MARK: Streaks

    /// Catches a streak that broke while the app was closed. `streakCount`
    /// only ever gets *recalculated* inside `recordActivityToday()`, which
    /// only runs when a real XP-earning action happens — so if someone
    /// hits a 5-day streak, then doesn't open the app again for a week,
    /// `streakCount` would otherwise sit frozen at 5 (still showing as
    /// "alive" on the Journey tab) right up until their next action, which
    /// would silently reset it. Run once at launch instead, so a broken
    /// streak reads as broken the moment you open the app, not only after
    /// you've already done something. Deliberately mirrors, rather than
    /// awards, `recordActivityToday`'s own gap check: today or yesterday
    /// means the streak is still alive (just not yet extended today) and
    /// is left untouched; anything further back means it's actually over.
    private func decayStreakIfNeeded() {
        guard streakCount > 0, let lastDay = store.lastActivityDay else { return }
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(lastDay, inSameDayAs: today) { return }
        if let expected = calendar.date(byAdding: .day, value: 1, to: lastDay),
           calendar.isDate(expected, inSameDayAs: today) {
            return
        }
        streakCount = 0
        persist()
    }

    private func recordActivityToday() {
        let today = calendar.startOfDay(for: Date())
        defer { store.lastActivityDay = today }

        guard let lastDay = store.lastActivityDay else {
            streakCount = 1
            return
        }
        if calendar.isDate(lastDay, inSameDayAs: today) {
            return // already counted today
        }
        if let expected = calendar.date(byAdding: .day, value: 1, to: lastDay),
           calendar.isDate(expected, inSameDayAs: today) {
            streakCount += 1
        } else {
            streakCount = 1
        }
    }

    // MARK: Badges

    private func refreshBadges(celebrateNewUnlocks: Bool = true) {
        var earned = unlockedBadgeIDs
        // Every badge that newly crosses its threshold in *this* call,
        // in check order — plural because a single award can legitimately
        // satisfy more than one condition at once (e.g. completing the
        // one guide that's simultaneously your last guide overall and
        // your last remaining company unlocks both "guide-master" and
        // "provider-explorer" together).
        var freshlyEarnedIDs: [String] = []

        func unlock(_ id: String, when condition: Bool) {
            guard condition, !earned.contains(id) else { return }
            earned.insert(id)
            freshlyEarnedIDs.append(id)
        }

        for badge in BadgeLibrary.all {
            unlock(badge.id, when: badgeProgress(for: badge).isComplete)
        }

        unlockedBadgeIDs = earned
        guard celebrateNewUnlocks else { return }
        for id in freshlyEarnedIDs {
            if let badge = BadgeLibrary.badge(id: id) {
                pendingBadgeCelebrations.append(badge)
            }
        }
    }

    // MARK: Level curve

    /// Each level costs a bit more than the last (100, 140, 180, ...),
    /// so early levels come quickly — rewarding a brand-new user right
    /// away — while later levels take sustained use to reach.
    static func xpRequired(forLevel level: Int) -> Int {
        100 + (level - 1) * 40
    }

    static func cumulativeXP(throughLevel level: Int) -> Int {
        guard level >= 1 else { return 0 }
        return (1...level).reduce(0) { $0 + xpRequired(forLevel: $1) }
    }

    static func level(forTotalXP totalXP: Int) -> Int {
        var level = 1
        while totalXP >= cumulativeXP(throughLevel: level) {
            level += 1
        }
        return level
    }

    // MARK: Persistence

    private func restore() {
        guard let snapshot = store.load() else { return }

        let currentWorkflowIDs = Set(WorkflowLibrary.all.map(\.id))
        let currentStepIDs = Set(WorkflowLibrary.all.flatMap { $0.steps.map(\.id) })
        let currentTermIDs = Set(JargonGlossary.allTerms.map(\.id))
        let currentBadgeIDs = Set(BadgeLibrary.all.map(\.id))

        totalXP = snapshot.totalXP
        completedWorkflowIDs = snapshot.completedWorkflowIDs.intersection(currentWorkflowIDs)
        flippedTermIDs = snapshot.flippedTermIDs.intersection(currentTermIDs)
        streakCount = snapshot.streakCount
        unlockedBadgeIDs = snapshot.unlockedBadgeIDs.intersection(currentBadgeIDs)
        xpAwardedStepIDs = snapshot.xpAwardedStepIDs.intersection(currentStepIDs)
        store.lastActivityDay = snapshot.lastActivityDay
        decayStreakIfNeeded()

        // New badge definitions should recognize progress that already
        // qualifies, but an app update must not replay a backlog of old
        // celebration toasts. Existing earned badges remain earned even
        // if a streak has since ended.
        refreshBadges(celebrateNewUnlocks: false)

        let didReconcilePersistedState =
            completedWorkflowIDs != snapshot.completedWorkflowIDs ||
            flippedTermIDs != snapshot.flippedTermIDs ||
            unlockedBadgeIDs != snapshot.unlockedBadgeIDs ||
            xpAwardedStepIDs != snapshot.xpAwardedStepIDs
        if didReconcilePersistedState {
            persist()
        }
    }

    private func persist() {
        let snapshot = GamificationSnapshot(
            totalXP: totalXP,
            completedWorkflowIDs: completedWorkflowIDs,
            flippedTermIDs: flippedTermIDs,
            streakCount: streakCount,
            lastActivityDay: store.lastActivityDay,
            unlockedBadgeIDs: unlockedBadgeIDs,
            xpAwardedStepIDs: xpAwardedStepIDs
        )
        store.save(snapshot)
    }
}

/// Thin, testable wrapper around on-disk JSON persistence, mirroring
/// `WorkflowProgressStore`'s shape.
struct GamificationStore {
    private let fileURL: URL

    fileprivate var lastActivityDay: Date?

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("Clarify/Progress", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("gamification.json")
    }

    fileprivate func load() -> GamificationSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(GamificationSnapshot.self, from: data)
    }

    fileprivate func save(_ snapshot: GamificationSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
