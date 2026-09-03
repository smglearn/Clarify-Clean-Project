//
//  OnboardingView.swift
//  Clarify
//
//  A short, skippable welcome carousel shown once on first launch.
//  Unlike FocusPagerView (which deliberately blocks free swiping so a
//  workflow step can't be skipped), this is pure introduction with
//  nothing to gate — a standard swipeable page view is the right,
//  lighter-weight tool here.
//

import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbolName: String
    let title: String
    let message: String
    let tint: Color
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbolName: "bubble.left.and.text.bubble.right.fill",
        title: "Welcome to Clarify",
        message: "No accounts, no sign-in, nothing sent anywhere. Just clear, guided steps for setup tasks that are usually full of jargon.",
        tint: .indigo
    ),
    OnboardingPage(
        symbolName: "checklist",
        title: "One Step at a Time",
        message: "Every guide shows a single, focused step on screen. Tap a highlighted word to flip it into a plain-English explanation.",
        tint: .teal
    ),
    OnboardingPage(
        symbolName: "globe.americas.fill",
        title: "Guides for Major Platforms",
        message: "Google, Apple, Microsoft, Amazon, and Facebook all have their own setup quirks. Clarify has guides for each, written in plain English.",
        tint: .orange
    ),
    OnboardingPage(
        symbolName: "star.circle.fill",
        title: "Learn, Earn, Level Up",
        message: "Finish steps to earn XP, level up, and unlock badges. Progress lives right on your device — check the Journey tab any time.",
        tint: .pink
    )
]

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var pageIndex = 0

    private var isLastPage: Bool { pageIndex == onboardingPages.count - 1 }

    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                if !isLastPage {
                    HStack {
                        Spacer()
                        Button("Skip", action: finish)
                            .font(.subheadline.weight(.semibold))
                            .padding()
                            .frame(minWidth: 44, minHeight: 44)
                    }
                } else {
                    Color.clear.frame(height: 44)
                }

                TabView(selection: $pageIndex) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(action: advance) {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(onboardingPages[pageIndex].tint)
                .padding(20)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func advance() {
        if isLastPage {
            finish()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                pageIndex += 1
            }
        }
    }

    private func finish() {
        OnboardingStore().markCompleted()
        onFinish()
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Shrinks the decorative icon at accessibility Dynamic Type sizes
    /// so the text — the part that actually carries meaning — always
    /// has room to breathe instead of getting squeezed by a fixed-size
    /// graphic above it.
    private var iconDiameter: CGFloat { dynamicTypeSize.isAccessibilitySize ? 96 : 160 }
    private var iconFontSize: CGFloat { dynamicTypeSize.isAccessibilitySize ? 40 : 64 }

    var body: some View {
        // Wrapped in a GeometryReader + ScrollView (rather than a plain
        // VStack with Spacers) so this still centers nicely at ordinary
        // text sizes but never clips or overlaps at the largest
        // accessibility Dynamic Type sizes — it scrolls instead.
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 12)

                    ZStack {
                        Circle()
                            .fill(page.tint.opacity(0.15))
                            .frame(width: iconDiameter, height: iconDiameter)
                        Image(systemName: page.symbolName)
                            .font(.system(size: iconFontSize))
                            .foregroundStyle(page.tint)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 12) {
                        Text(page.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text(page.message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 12)
                }
                .frame(minHeight: proxy.size.height)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.message)")
    }
}
