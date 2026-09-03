//
//  ParticleBurstView.swift
//  Clarify
//
//  A small, reusable celebration effect: a ring of colored dots bursts
//  outward from center and fades. Shared by the level-up celebration,
//  the DNS canvas's mailbox arrival, and the engine room's slot snap,
//  so "something good just happened" always reads the same way.
//
//  Driven by `TimelineView(.animation(paused:))` rather than a
//  `withAnimation` spring: a burst is a one-shot particle simulation
//  (each dot has its own radial path and its own fade curve), which
//  needs per-frame position math, not a single interpolated value.
//

import SwiftUI

struct ParticleBurstView: View {
    /// Increment this from the caller to fire a new burst. Using a
    /// counter (rather than a Bool) means two bursts back-to-back both
    /// register, even if the value briefly looks "unchanged" to a
    /// naive comparison.
    let trigger: Int
    var colors: [Color] = [.yellow, .orange, .pink, .indigo, .teal]
    var particleCount: Int = 18
    var duration: Double = 0.85

    @State private var burstStart: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: burstStart == nil)) { timeline in
            Canvas { context, size in
                guard let burstStart else { return }
                let elapsed = timeline.date.timeIntervalSince(burstStart)
                guard elapsed >= 0, elapsed < duration else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let progress = elapsed / duration
                // Guard against a caller passing an empty palette (e.g. a
                // DNS canvas with zero letters) — fall back rather than
                // divide by zero.
                let palette = colors.isEmpty ? [Color.yellow, .orange, .pink, .indigo, .teal] : colors

                for index in 0..<particleCount {
                    let angle = (Double(index) / Double(particleCount)) * 2 * .pi
                    let wobble = sin(Double(index) * 1.7) * 0.15
                    let speed = 70.0 + Double(index % 5) * 22
                    let distance = speed * progress
                    let x = center.x + CGFloat(cos(angle + wobble) * distance)
                    let y = center.y + CGFloat(sin(angle + wobble) * distance)
                    let opacity = max(0, 1 - progress)
                    let radius: CGFloat = 3 + CGFloat(index % 3)
                    let color = palette[index % palette.count]
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            burstStart = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                burstStart = nil
            }
        }
    }
}
