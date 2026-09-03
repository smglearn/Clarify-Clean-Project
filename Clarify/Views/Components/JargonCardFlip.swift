//
//  JargonCardFlip.swift
//  Clarify
//
//  A tappable card that physically flips in 3D to swap a technical term
//  for its plain-English analogy. Built from two overlaid faces rather
//  than one view with swapped text, so the "back" face can be
//  pre-rotated 180° — that's what stops the analogy text from reading
//  as mirrored once the flip completes.
//

import SwiftUI

struct JargonCardFlip: View {
    let jargonTerm: JargonTerm

    @State private var isFlipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(GamificationManager.self) private var gamification

    var body: some View {
        Button {
            isFlipped.toggle()
            if isFlipped {
                gamification.recordJargonFlip(termID: jargonTerm.id)
            }
        } label: {
            ZStack {
                face(front: true)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 90 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                face(front: false)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -90),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.45, dampingFraction: 0.75),
            value: isFlipped
        )
        .sensoryFeedback(.selection, trigger: isFlipped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? jargonTerm.analogy : jargonTerm.term)
        .accessibilityValue(isFlipped ? jargonTerm.explanation : "Double-tap to reveal the plain-English meaning.")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func face(front: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: front ? "questionmark.circle.fill" : jargonTerm.symbolName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(front ? .secondary : Color.accentColor)

            Text(front ? jargonTerm.term : jargonTerm.analogy)
                .font(.headline)
                .multilineTextAlignment(.center)

            if !front {
                // Deliberately no `.lineLimit` here — this is the one
                // place the full explanation actually needs to be
                // readable. A fixed line limit on the back face was
                // silently truncating longer explanations (and anything
                // at larger Dynamic Type sizes) with no way to see the
                // rest, which defeats the point of a glossary someone is
                // tapping into specifically to read the explanation.
                Text(jargonTerm.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Tap to translate")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(front ? Color(.secondarySystemBackground) : Color.accentColor.opacity(0.12))
        )
        .overlay(
            // A faint diagonal sheen, purely decorative, that gives the
            // card a touch of physical "glossy plastic" presence instead
            // of reading as a flat rectangle.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(front ? 0.10 : 0.06), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(front ? Color.clear : Color.accentColor.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(front ? 0.06 : 0.1), radius: front ? 4 : 8, y: 3)
    }
}

/// A horizontally-scrolling row of flip cards for every jargon term
/// referenced by a workflow step. Falls back to nothing (not a
/// placeholder string) when a step references no jargon at all.
struct JargonCardRow: View {
    let termNames: [String]

    private var resolvedTerms: [JargonTerm] {
        termNames.compactMap(JargonGlossary.term(named:))
    }

    var body: some View {
        if !resolvedTerms.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(resolvedTerms) { term in
                        JargonCardFlip(jargonTerm: term)
                            .frame(width: 200)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}
