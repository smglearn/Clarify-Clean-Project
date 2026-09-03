//
//  GamificationOverlays.swift
//  Clarify
//
//  App-wide reactions to GamificationManager events: a small "+XP"
//  toast, a badge-unlock toast, and a full level-up celebration. Hosted
//  once at the root (see `ContentView`) via `.gamificationOverlays()`
//  so a level-up reads the same whether it happens mid-workflow or
//  while browsing the glossary.
//

import SwiftUI

private struct GamificationOverlaysModifier: ViewModifier {
    let gamification: GamificationManager

    @State private var showXPToast = false
    @State private var showBadgeToast = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                VStack(spacing: 10) {
                    if showXPToast {
                        XPToastView(amount: gamification.lastXPGain)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if showBadgeToast, let badge = gamification.newlyUnlockedBadge {
                        BadgeUnlockToastView(badge: badge)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showXPToast)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBadgeToast)
            }
            // A badge is a bigger deal than routine step XP, so it gets
            // its own distinct haptic rather than riding along on
            // whatever feedback the triggering action already fired.
            .sensoryFeedback(.success, trigger: showBadgeToast) { _, newValue in newValue }
            .overlay {
                if let level = gamification.justReachedLevel {
                    LevelUpCelebrationView(level: level) {
                        gamification.acknowledgeLevelUp()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(10)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: gamification.justReachedLevel)
            .onChange(of: gamification.xpEventPulse) { _, _ in
                guard gamification.justReachedLevel == nil else { return }
                flashXPToast()
            }
            .onChange(of: gamification.newlyUnlockedBadge) { _, newValue in
                guard newValue != nil else { return }
                flashBadgeToast(delay: showXPToast ? 1.4 : 0)
            }
    }

    /// Shows the "+XP" toast for a couple of seconds, then hides it.
    private func flashXPToast() {
        showXPToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showXPToast = false
        }
    }

    /// Shows the badge-unlock toast, staggered behind an in-flight XP
    /// toast so the two never visually collide, then clears the badge
    /// from `GamificationManager` once it's been shown.
    private func flashBadgeToast(delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            showBadgeToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showBadgeToast = false
                gamification.acknowledgeBadge()
            }
        }
    }
}

extension View {
    /// Hosts every gamification reaction (XP toast, badge toast, level-up
    /// celebration) for the given manager. Apply once near the root.
    func gamificationOverlays(_ gamification: GamificationManager) -> some View {
        modifier(GamificationOverlaysModifier(gamification: gamification))
    }
}

// MARK: - XP toast

private struct XPToastView: View {
    let amount: Int

    var body: some View {
        Label("+\(amount) XP", systemImage: "sparkles")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                )
            )
            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            .accessibilityLabel("Earned \(amount) experience points.")
    }
}

// MARK: - Badge toast

private struct BadgeUnlockToastView: View {
    let badge: Badge

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: badge.symbolName)
                .font(.headline)
            VStack(alignment: .leading, spacing: 1) {
                Text("Badge Unlocked").font(.caption2.weight(.semibold)).opacity(0.85)
                Text(badge.title).font(.subheadline.weight(.bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.indigo))
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Badge unlocked: \(badge.title). \(badge.badgeDescription)")
    }
}

// MARK: - Level-up celebration

private struct LevelUpCelebrationView: View {
    let level: Int
    var onDismiss: () -> Void

    @State private var burstTrigger = 0
    @State private var didAppear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 18) {
                ZStack {
                    ParticleBurstView(trigger: burstTrigger)
                        .frame(width: 220, height: 220)

                    Circle()
                        .fill(
                            LinearGradient(colors: [.orange, .pink, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 108, height: 108)
                        .scaleEffect(didAppear ? 1 : 0.6)
                        .overlay(
                            Text("\(level)")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 16)
                }

                VStack(spacing: 6) {
                    Text("Level Up!")
                        .font(.title.bold())
                    Text("You reached level \(level). Keep going.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("Nice")
                        .font(.headline)
                        .frame(minWidth: 140, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(32)
            .scaleEffect(didAppear ? 1 : 0.85)
            .opacity(didAppear ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: didAppear)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.75)) {
                didAppear = true
            }
            burstTrigger += 1
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Level up. You reached level \(level).")
        .accessibilityAction(named: "Dismiss", onDismiss)
    }
}
