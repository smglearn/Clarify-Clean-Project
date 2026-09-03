//
//  ProgressHubView.swift
//  Clarify
//
//  The "Journey" tab: a home base for everything GamificationManager
//  tracks — level, XP, streak, and the full badge collection. Reads
//  are the only thing this screen does; every number here is driven by
//  state that already exists elsewhere (WorkflowManager completions,
//  jargon flips), so there's nothing new to keep in sync.
//

import SwiftUI

struct ProgressHubView: View {
    @Environment(GamificationManager.self) private var gamification

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    levelCard
                    statsRow
                    milestonesSection
                    providerProgressSection
                    badgesSection
                }
                .padding(20)
            }
            .navigationTitle("Journey")
            .background(AmbientBackground().ignoresSafeArea())
        }
    }

    // MARK: Level card

    private var levelCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: gamification.levelProgress)
                    .stroke(
                        AngularGradient(colors: [.orange, .pink, .indigo, .orange], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: gamification.levelProgress)

                VStack(spacing: 2) {
                    Text("Level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(gamification.level)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                }
            }
            .frame(width: 150, height: 150)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Level \(gamification.level)")
            .accessibilityValue("\(gamification.xpIntoCurrentLevel) of \(gamification.xpRequiredForCurrentLevel) experience points to next level")

            Text("\(gamification.xpIntoCurrentLevel) / \(gamification.xpRequiredForCurrentLevel) XP to Level \(gamification.level + 1)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(gamification.totalXP) total XP earned")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: Stats row

    private var statsRow: some View {
        AdaptiveHStack(spacing: 12) {
            statTile(
                symbol: "flame.fill",
                tint: .orange,
                value: "\(gamification.streakCount)",
                label: "Day Streak"
            )
            statTile(
                symbol: "checklist",
                tint: .green,
                value: "\(gamification.completedWorkflowCount)/\(WorkflowLibrary.all.count)",
                label: "Guides Done"
            )
            statTile(
                symbol: "rosette",
                tint: .indigo,
                value: "\(gamification.unlockedBadgeIDs.count)/\(BadgeLibrary.all.count)",
                label: "Badges"
            )
        }
    }

    private func statTile(symbol: String, tint: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Milestones

    /// How close each still-locked badge is to unlocking, computed
    /// straight from state `GamificationManager` already exposes
    /// publicly — nothing new is persisted here, this is purely a
    /// different lens on the same numbers `refreshBadges()` checks
    /// internally. Kept in sync automatically: since every badge's
    /// target is itself derived from live data (`WorkflowLibrary.all.count`,
    /// `JargonGlossary.allTerms.count`), a badge's progress bar never
    /// needs updating by hand when the guide or glossary catalog grows.
    private struct BadgeMilestone: Identifiable {
        let badge: Badge
        let current: Int
        let target: Int
        let catalogOrder: Int
        var id: String { badge.id }
        var fraction: Double { target > 0 ? min(1, Double(current) / Double(target)) : 0 }
    }

    /// The three locked badges nearest to unlocking, so someone always
    /// has a concrete "almost there" target instead of just a wall of
    /// grayed-out badges below. Ties resolve in `BadgeLibrary.all`'s own
    /// order, which keeps this list stable rather than jittering between
    /// otherwise-equal badges as XP changes.
    private var upcomingMilestones: [BadgeMilestone] {
        gamification.lockedBadges
            .enumerated()
            .map { catalogOrder, badge in
                let progress = gamification.badgeProgress(for: badge)
                return BadgeMilestone(
                    badge: badge,
                    current: progress.current,
                    target: progress.target,
                    catalogOrder: catalogOrder
                )
            }
            .sorted {
                if $0.fraction == $1.fraction {
                    return $0.catalogOrder < $1.catalogOrder
                }
                return $0.fraction > $1.fraction
            }
            .prefix(3)
            .map { $0 }
    }

    @ViewBuilder
    private var milestonesSection: some View {
        if !upcomingMilestones.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Almost There")
                    .font(.title3.bold())

                VStack(spacing: 10) {
                    ForEach(upcomingMilestones) { milestone in
                        milestoneRow(milestone)
                    }
                }
            }
        }
    }

    private func milestoneRow(_ milestone: BadgeMilestone) -> some View {
        HStack(spacing: 14) {
            Image(systemName: milestone.badge.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.indigo)
                .frame(width: 36, height: 36)
                .background(Color.indigo.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(milestone.badge.title)
                    .font(.subheadline.weight(.semibold))
                ProgressView(value: milestone.fraction)
                    .tint(.indigo)
            }

            Text("\(milestone.current)/\(milestone.target)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.badge.title), \(milestone.current) of \(milestone.target)")
    }

    // MARK: Progress by provider

    private struct ProviderProgress: Identifiable {
        let company: Company?
        let completed: Int
        let total: Int
        var id: String { company?.rawValue ?? "universal" }
        var fraction: Double { total > 0 ? Double(completed) / Double(total) : 0 }
    }

    /// Mirrors the same grouping `WorkflowListView` uses for its
    /// sections, so "how many Google guides have I finished" always
    /// matches what the Guides tab itself would show — computed fresh
    /// from `WorkflowLibrary.grouped()` rather than a second, separately
    /// maintained count that could drift out of sync.
    private var providerProgress: [ProviderProgress] {
        WorkflowLibrary.grouped().map { group in
            ProviderProgress(
                company: group.company,
                completed: group.workflows.filter { gamification.completedWorkflowIDs.contains($0.id) }.count,
                total: group.workflows.count
            )
        }
    }

    private var providerProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress by Provider")
                .font(.title3.bold())

            VStack(spacing: 10) {
                ForEach(providerProgress) { progress in
                    providerRow(progress)
                }
            }
        }
    }

    private func providerRow(_ progress: ProviderProgress) -> some View {
        let tint = progress.company?.tint ?? .purple
        let name = progress.company?.displayName ?? "Universal"

        return HStack(spacing: 14) {
            Image(systemName: progress.company?.symbolName ?? "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                ProgressView(value: progress.fraction)
                    .tint(tint)
            }

            Text("\(progress.completed)/\(progress.total)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(progress.completed) of \(progress.total) guides complete")
    }

    // MARK: Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.title3.bold())

            ForEach(BadgeCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)], spacing: 12) {
                        ForEach(BadgeLibrary.all.filter { $0.category == category }) { badge in
                            BadgeCell(badge: badge, isUnlocked: gamification.unlockedBadgeIDs.contains(badge.id))
                        }
                    }
                }
            }
        }
    }
}

private struct BadgeCell: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? AnyShapeStyle(Color.indigo.opacity(0.15)) : AnyShapeStyle(Color.secondary.opacity(0.1)))
                    .frame(width: 56, height: 56)
                // Fixed point size, not a scalable text style — this icon
                // is meant to sit inside the 56x56 circle behind it. A
                // Dynamic-Type-scalable font would keep growing past that
                // circle at large accessibility text sizes and spill
                // outside it; the badge's title and description text
                // still scale normally underneath.
                Image(systemName: isUnlocked ? badge.symbolName : "lock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Color.indigo : Color.secondary)
            }
            Text(badge.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(badge.badgeDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(isUnlocked ? 1 : 0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isUnlocked ? "\(badge.title), unlocked. \(badge.badgeDescription)" : "\(badge.title), locked. \(badge.badgeDescription)")
    }
}
