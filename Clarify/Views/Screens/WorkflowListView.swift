//
//  WorkflowListView.swift
//  Tech Unknotted (project: Clarify)
//
//  Home screen: pick a guided setup, then run it through FocusPagerView
//  until every step is complete. Each workflow gets its own
//  WorkflowManager instance so progress for one guide never bleeds
//  into another.
//
//  The catalog is grouped into sections — Everyday & Universal first,
//  then Google, Apple, Microsoft, Amazon and Facebook — and each section
//  runs easiest-first, from Very Easy fixes like a forgotten password up
//  to Very Hard cloud configuration.
//
//  While browsing, every section is collapsed to one summary row so the
//  first screen stays short. Searching or picking a difficulty level
//  switches to expanded results instead: a matching guide you can
//  already see is worth more than one more tap.
//

import SwiftUI

struct WorkflowListView: View {
    @Environment(GamificationManager.self) private var gamification
    @State private var searchText = ""
    @State private var selectedLevel: GuideLevel?

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// True whenever the list should show expanded, filtered results
    /// rather than the collapsed section rows.
    private var isFiltering: Bool {
        !trimmedQuery.isEmpty || selectedLevel != nil
    }

    /// The most recent guide that's been started but not finished, if
    /// any — surfaced as a "Continue" card so picking back up doesn't
    /// mean re-scanning the whole catalog. Cheap: each lookup is a tiny
    /// on-disk JSON read, not a full `WorkflowManager` instantiation.
    private var inProgressWorkflow: Workflow? {
        let store = WorkflowProgressStore()
        return WorkflowLibrary.all.first {
            store.hasInProgressSave(workflowID: $0.id, totalSteps: $0.steps.count)
        }
    }

    /// Guide counts per level for the current search, so each level chip
    /// can say how many results it would show.
    private var levelCounts: [GuideLevel: Int] {
        let matching = WorkflowLibrary.all.filter { WorkflowSearch.matches($0, query: trimmedQuery) }
        return Dictionary(grouping: matching, by: \.level).mapValues(\.count)
    }

    /// Filters the catalog by search text and level. A section that ends
    /// up with zero matching guides is dropped entirely rather than shown
    /// empty, so results read as a clean, shorter catalog.
    private var filteredGroups: [WorkflowGroup] {
        let groups = WorkflowLibrary.grouped()
        guard isFiltering else { return groups }

        return groups.compactMap { group in
            let matches = group.workflows.filter { workflow in
                (selectedLevel == nil || workflow.level == selectedLevel)
                    && WorkflowSearch.matches(workflow, query: trimmedQuery)
            }
            return matches.isEmpty ? nil : WorkflowGroup(company: group.company, workflows: matches)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    LevelFilterBar(selection: $selectedLevel, counts: levelCounts)

                    if let selectedLevel {
                        Text(selectedLevel.audience)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if filteredGroups.isEmpty {
                        emptyState
                    } else {
                        // A resume shortcut and the beginner prompt have no
                        // business cluttering a search or a level filter.
                        if !isFiltering {
                            if let inProgressWorkflow {
                                ContinueCard(workflow: inProgressWorkflow)
                            } else if gamification.completedWorkflowIDs.isEmpty {
                                StartHereCard { selectedLevel = .veryEasy }
                            }
                        }

                        ForEach(filteredGroups) { group in
                            if isFiltering {
                                WorkflowSection(company: group.company, workflows: group.workflows)
                            } else {
                                SectionSummaryRow(group: group)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Tech Unknotted")
            .searchable(text: $searchText, prompt: "Search guides, e.g. password")
            .navigationDestination(for: Workflow.self) { workflow in
                WorkflowRunnerView(workflow: workflow)
            }
            .navigationDestination(for: WorkflowGroup.self) { group in
                CompanyGuideListView(group: group)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if trimmedQuery.isEmpty, let selectedLevel {
            ContentUnavailableView(
                "No \(selectedLevel.displayName) Guides",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Try another level, or tap All to see every guide.")
            )
            .padding(.top, 40)
        } else {
            ContentUnavailableView.search(text: searchText)
                .padding(.top, 40)
        }
    }
}

/// Search rules shared by the home list and level counts: title,
/// summary, provider name, level name, and the words used in each step,
/// so searching "locked out" finds a guide even if the title says
/// "Get Back Into Your Account".
enum WorkflowSearch {
    static func matches(_ workflow: Workflow, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let fields = [
            workflow.title,
            workflow.summary,
            workflow.company?.displayName ?? "Universal Everyday",
            workflow.level.displayName,
        ] + workflow.steps.map(\.title)
        return fields.contains { $0.lowercased().contains(query) }
    }
}

/// Shown on a fresh install in place of the Continue card: one tap to
/// see only the Very Easy guides, so a nervous first-timer never has to
/// scroll past cloud consoles to find "I forgot my password".
private struct StartHereCard: View {
    var showVeryEasy: () -> Void

    var body: some View {
        Button(action: showVeryEasy) {
            HStack(spacing: 16) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New here? Start with Very Easy")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Login trouble, forgotten passwords, and everyday fixes.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
            .frame(minHeight: 60)
            .background(
                LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: .green.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows only the Very Easy guides.")
    }
}

/// Display details shared by a provider section and the Universal one.
private extension WorkflowGroup {
    var displayName: String { company?.displayName ?? "Everyday & Universal" }
    var tagline: String { company?.tagline ?? "Login help, passwords, Wi-Fi, and fixes for any device" }
    var symbolName: String { company?.symbolName ?? "sparkles" }
    var tint: Color { company?.tint ?? .green }

    /// "Very Easy to Very Hard", or a single level name.
    var levelRange: String? {
        guard let lowest = workflows.map(\.level).min(),
              let highest = workflows.map(\.level).max() else { return nil }
        return lowest == highest ? lowest.displayName : "\(lowest.displayName) to \(highest.displayName)"
    }
}

/// The collapsed, browsing-mode stand-in for an entire section — name,
/// tagline, level range and progress. Tapping pushes
/// `CompanyGuideListView` to see the actual guides. Styled like
/// `WorkflowCard` so the list reads as one consistent catalog.
private struct SectionSummaryRow: View {
    let group: WorkflowGroup
    @Environment(GamificationManager.self) private var gamification

    private var completedCount: Int {
        group.workflows.filter { gamification.completedWorkflowIDs.contains($0.id) }.count
    }

    var body: some View {
        NavigationLink(value: group) {
            HStack(spacing: 16) {
                Image(systemName: group.symbolName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(group.tint)
                    .frame(width: 52, height: 52)
                    .background(group.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.displayName)
                        .font(.headline)
                    Text(group.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("\(group.workflows.count) guides · \(completedCount) done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                    if let range = group.levelRange {
                        Text(range)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(minHeight: 60)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.displayName), \(group.workflows.count) guides, \(completedCount) completed")
        .accessibilityHint("Opens the full list of \(group.displayName) guides, easiest first.")
    }
}

/// The full guide list for one section, pushed from its summary row.
/// Guides are split under level headings, easiest first, with the same
/// level chips as the home screen to narrow it further.
struct CompanyGuideListView: View {
    let group: WorkflowGroup
    @Environment(GamificationManager.self) private var gamification
    @State private var selectedLevel: GuideLevel?

    private var levelCounts: [GuideLevel: Int] {
        Dictionary(grouping: group.workflows, by: \.level).mapValues(\.count)
    }

    private var visibleLevels: [GuideLevel] {
        GuideLevel.allCases.filter { level in
            (selectedLevel == nil || selectedLevel == level) && levelCounts[level, default: 0] > 0
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                LevelFilterBar(selection: $selectedLevel, counts: levelCounts)
                    .padding(.bottom, 4)

                if visibleLevels.isEmpty, let selectedLevel {
                    ContentUnavailableView(
                        "No \(selectedLevel.displayName) Guides Here",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try another level, or tap All.")
                    )
                    .padding(.top, 30)
                }

                ForEach(visibleLevels) { level in
                    LevelHeader(level: level)
                        .padding(.top, 10)
                    ForEach(group.workflows.filter { $0.level == level }) { workflow in
                        NavigationLink(value: workflow) {
                            WorkflowCard(workflow: workflow, isCompleted: gamification.completedWorkflowIDs.contains(workflow.id))
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(group.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
}

/// "●●○○○ Easy — Simple settings anyone can change…" above each block
/// of guides in a section.
private struct LevelHeader: View {
    let level: GuideLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(level.meter)
                    .font(.system(size: 9))
                    .tracking(1.5)
                    .foregroundStyle(level.tint)
                    .accessibilityHidden(true)
                Text(level.displayName)
                    .font(.title3.bold())
            }
            Text(level.audience)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A single, prominent shortcut back into whichever guide was left
/// mid-flight. Deliberately styled differently from `WorkflowCard` —
/// solid accent-gradient fill rather than a neutral card — so it reads
/// as "pick up where you left off" at a glance, not as just another
/// catalog entry.
private struct ContinueCard: View {
    let workflow: Workflow

    var body: some View {
        NavigationLink(value: workflow) {
            HStack(spacing: 16) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(workflow.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
            .frame(minHeight: 60)
            .background(
                LinearGradient(colors: [.indigo, .pink], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: .indigo.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue \(workflow.title)")
        .accessibilityHint("Resumes this guide where you left off.")
    }
}

/// Expanded results for one section while searching or filtering.
private struct WorkflowSection: View {
    let company: Company?
    let workflows: [Workflow]
    @Environment(GamificationManager.self) private var gamification

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            LazyVStack(spacing: 14) {
                ForEach(workflows) { workflow in
                    NavigationLink(value: workflow) {
                        WorkflowCard(workflow: workflow, isCompleted: gamification.completedWorkflowIDs.contains(workflow.id))
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: company?.symbolName ?? "sparkles")
                .font(.headline)
                .foregroundStyle(company?.tint ?? .green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(company?.displayName ?? "Everyday & Universal")
                    .font(.title3.bold())
                Text(company?.tagline ?? "Login help, passwords, Wi-Fi, and fixes for any device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct WorkflowCard: View {
    let workflow: Workflow
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Deliberately a fixed point size rather than a scalable text
            // style like `.title2`: this icon sits inside a hard-fixed
            // 52x52 frame, and a Dynamic-Type-scalable font would keep
            // growing past that box at larger accessibility text sizes,
            // overflowing its background. The title and summary text next
            // to it still scale normally.
            Image(systemName: workflow.symbolName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 52, height: 52)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(workflow.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .accessibilityLabel("Completed")
                    }
                }
                Text(workflow.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    GuideLevelBadge(level: workflow.level)
                    Label("\(workflow.steps.count) steps", systemImage: "list.number")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Label("\(workflow.totalXPValue) XP", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(minHeight: 60)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isCompleted ? "Completed. Opens this guide again." : "Opens this guide. \(workflow.steps.count) steps, worth \(workflow.totalXPValue) experience points.")
    }
}

/// Owns the WorkflowManager for one run of a workflow, and swaps between
/// the step pager and a completion screen without ever exposing a way
/// to jump between arbitrary steps.
struct WorkflowRunnerView: View {
    @State private var manager: WorkflowManager
    @State private var isFinished: Bool

    init(workflow: Workflow) {
        let manager = WorkflowManager(workflow: workflow)
        _manager = State(initialValue: manager)
        // If every step was already completed in a previous session,
        // resume straight into the completion screen instead of
        // silently re-showing step one.
        _isFinished = State(initialValue: manager.completedStepIDs.count == workflow.steps.count)
    }

    var body: some View {
        if isFinished {
            WorkflowCompletionView(workflow: manager.workflow) {
                manager.resetProgress()
                isFinished = false
            }
        } else {
            FocusPagerView(manager: manager) {
                isFinished = true
            } content: { step in
                WorkflowStepView(step: step, company: manager.workflow.company)
            }
        }
    }
}

private struct WorkflowCompletionView: View {
    let workflow: Workflow
    var onRestart: () -> Void

    @Environment(GamificationManager.self) private var gamification
    @State private var didCelebrate = false
    @State private var burstTrigger = 0

    /// A few rotating lines instead of one fixed sentence, so finishing
    /// your fifth guide of the day doesn't read exactly like your first.
    /// Deliberately derived from state that already exists rather than
    /// adding anything new to persist: by the time this screen appears,
    /// `recordWorkflowCompleted` has already run, so this workflow is
    /// already counted in `completedWorkflowIDs` — that count alone is
    /// enough to pick a message without tracking "have I shown this
    /// message before" separately.
    private var completionMessage: String {
        switch gamification.completedWorkflowIDs.count {
        case 1:
            return "You finished every step. There's nothing else to do here."
        case 2, 3:
            return "Another one wrapped up. That jargon didn't stand a chance."
        case 4, 5:
            return "You're building a real habit here. On to the next whenever you're ready."
        default:
            return "Done and done. Check the Journey tab to see how far you've come."
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                ParticleBurstView(trigger: burstTrigger)
                    .frame(width: 180, height: 180)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
            }
            .accessibilityHidden(true)

            Text("\(workflow.title) Complete")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(completionMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Label("+\(workflow.totalXPValue) XP earned", systemImage: "sparkles")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.orange)

            Spacer()

            Button(action: onRestart) {
                Text("Start Over")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .sensoryFeedback(.success, trigger: didCelebrate)
        .onAppear { burstTrigger += 1 }
        .onAppear { didCelebrate = true }
        .accessibilityElement(children: .contain)
    }
}
