//
//  AmbientBackground.swift
//  Clarify
//
//  A quiet, slow-drifting gradient wash used behind a few screens that
//  otherwise read as flat and static (the Journey tab, workflow
//  completion). Three soft blurred blobs drift on independent sine
//  curves via `TimelineView(.animation)` — cheap to draw, and paused
//  entirely under Reduce Motion so it never becomes a distraction.
//

import SwiftUI

struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawBlob(&context, size: size, phase: t * 0.15, radiusFraction: 0.55, color: .indigo, offset: (0.2, 0.25))
                drawBlob(&context, size: size, phase: t * 0.12 + 2, radiusFraction: 0.5, color: .pink, offset: (0.8, 0.2))
                drawBlob(&context, size: size, phase: t * 0.1 + 4, radiusFraction: 0.6, color: .orange, offset: (0.5, 0.85))
            }
        }
        .background(Color(.systemBackground))
        .opacity(0.35)
    }

    private func drawBlob(
        _ context: inout GraphicsContext,
        size: CGSize,
        phase: Double,
        radiusFraction: CGFloat,
        color: Color,
        offset: (Double, Double)
    ) {
        let centerX = size.width * (offset.0 + 0.08 * sin(phase))
        let centerY = size.height * (offset.1 + 0.06 * cos(phase * 1.3))
        let radius = size.width * radiusFraction
        let rect = CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2)
        context.opacity = 0.5
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                center: CGPoint(x: centerX, y: centerY),
                startRadius: 0,
                endRadius: radius
            )
        )
    }
}
