//
//  WorkflowListView.swift
//  Clarify
//
//  Home screen: pick a guided setup, then run it through FocusPagerView
//  until every step is complete. Each workflow gets its own
//  WorkflowManager instance so progress for one guide never bleeds
//  into another. Guides are grouped by provider — Google, Apple,
//  Microsoft, Amazon, plus a universal section for guides that aren't
//  tied to any one company — so the library reads as a catalog rather
//  than one long undifferentiated list.
//
//  With the catalog now well past a hundred guides, the provider
//  sections are collapsed to a single summary row apiece — just the
//  provider's name, tagline, and progress — and only expand into their
//  own full list when tapped. This keeps first scroll of the Guides tab
//  short and scannable instead of dumping every provider's entire
//  catalog in one long scroll. Universal guides aren't tied to any
//  provider, so they stay inline as before. Search intentionally
//  bypasses the collapse: a search result you can already see is worth
//  more than one more tap, so matching company guides render expanded
//  the moment there's a query.
//

import SwiftUI

struct WorkflowListView: View {
    @Environment(GamificationManager.self) private var gamification
    @State private var searchText = ""

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

    /// Filters the catalog by title, summary, or provider name. A
    /// section that ends up with zero matching guides is dropped
    /// entirely rather than shown empty, so search results read as a
    /// clean, shorter catalog rather than a full one with gaps.
    private var filteredGroups: [WorkflowGroup] {
        let groups = WorkflowLibrary.grouped()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return groups }

        return groups.compactMap { group in
            let matches = group.workflows.filter { workflow in
                workflow.title.lowercased().contains(query)
                    || workflow.summary.lowercased().contains(query)
                    || (group.company?.displayName.lowercased().contains(query) ?? false)
            }
            return matches.isEmpty ? nil : WorkflowGroup(company: group.company, workflows: matches)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filteredGroups.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 60)
                } else {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        // Only shown while not searching — a resume
                        // shortcut has no business cluttering search
                        // results for something specific.
                        if searchText.isEmpty, let inProgressWorkflow {
                            ContinueCard(workflow: inProgressWorkflow)
                        }
                        ForEach(filteredGroups) { group in
                            // Collapsed to a single tappable summary row
                            // for a company section while browsing —
                            // but the instant there's a search query,
                            // fall back to the full expanded section so
                            // a matching guide is never hidden behind an
                            // extra tap.
                            if searchText.isEmpty, group.company != nil {
                                CompanySummaryRow(group: group)
                            } else {
                                WorkflowSection(company: group.company, workflows: group.workflows)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Clarify")
            .searchable(text: $searchText, prompt: "Search guides")
            .navigationDestination(for: Workflow.self) { workflow in
                WorkflowRunnerView(workflow: workflow)
            }
            .navigationDestination(for: WorkflowGroup.self) { group in
                CompanyGuideListView(group: group)
            }
        }
    }
}

/// The collapsed, browsing-mode stand-in for an entire company section —
/// name, tagline, and a progress readout, nothing else. Tapping pushes
/// `CompanyGuideListView` to see the actual guides. Deliberately styled
/// like `WorkflowCard` (same card shape, icon treatment, shadow) so the
/// list still reads as one consistent catalog rather than two different
/// UI languages stacked on top of each other.
private struct CompanySummaryRow: View {
    let group: WorkflowGroup
    @Environment(GamificationManager.self) private var gamification

    private var completedCount: Int {
        group.workflows.filter { gamification.completedWorkflowIDs.contains($0.id) }.count
    }

    var body: some View {
        // Safe to force-unwrap: `WorkflowListView` only ever routes a
        // `company == nil` (Universal) group through the full
        // `WorkflowSection` branch, never this one.
        let company = group.company!

        NavigationLink(value: group) {
            HStack(spacing: 16) {
                Image(systemName: company.symbolName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(company.tint)
                    .frame(width: 52, height: 52)
                    .background(company.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(company.displayName)
                        .font(.headline)
                    Text(company.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(group.workflows.count) guides · \(completedCount) done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
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
        .accessibilityLabel("\(company.displayName), \(group.workflows.count) guides, \(completedCount) completed")
        .accessibilityHint("Opens the full list of \(company.displayName) guides.")
    }
}

/// The full guide list for a single company, pushed from tapping its
/// `CompanySummaryRow`. Reuses `WorkflowCard` so a guide looks identical
/// whether it was reached from here or from an expanded Universal
/// section on the root list.
struct CompanyGuideListView: View {
    let group: WorkflowGroup
    @Environment(GamificationManager.self) private var gamification

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(group.workflows) { workflow in
                    NavigationLink(value: workflow) {
                        WorkflowCard(workflow: workflow, isCompleted: gamification.completedWorkflowIDs.contains(workflow.id))
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(20)
        }
        .navigationTitle(group.company?.displayName ?? "Guides")
        .navigationBarTitleDisplayMode(.large)
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

    @ViewBuilder
    private var header: some View {
        if let company {
            HStack(spacing: 10) {
                Image(systemName: company.symbolName)
                    .font(.headline)
                    .foregroundStyle(company.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(company.displayName)
                        .font(.title3.bold())
                    Text(company.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text("Universal")
                .font(.title3.bold())
        }
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
            // overflowing its background circle. The title and summary
            // text next to it still scale normally — only this decorative
            // glyph stays put, matching `ContinueCard`'s icon below.
            Image(systemName: workflow.symbolName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 52, height: 52)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(workflow.title)
                        .font(.headline)
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Text(workflow.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("\(workflow.totalXPValue) XP", systemImage: "sparkles")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(minHeight: 60)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isCompleted ? "Completed. Opens this guided setup again." : "Opens this guided setup. Worth \(workflow.totalXPValue) experience points.")
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
