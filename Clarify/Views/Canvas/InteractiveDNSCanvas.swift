//
//  InteractiveDNSCanvas.swift
//  Clarify
//
//  Replaces a wall of DNS jargon with a tactile animation: letters
//  (DNS records) fly from a Post Office (nameserver) to a Mailbox
//  (the browser resolving your domain). Two animation systems work
//  together here on purpose:
//
//   1. The flight arcs are driven by `AnimatableVector`, so a single
//      interruptible spring animates every letter's position at once
//      and can be re-triggered mid-flight without glitching.
//   2. The dashed route line is driven by `TimelineView(.animation)`,
//      so the path always feels alive even when nothing is flying —
//      it isn't tied to the spring at all.
//

import SwiftUI

/// One piece of "mail" flying from the Post Office to the Mailbox,
/// representing a single DNS record being resolved.
struct DNSLetter: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let tint: Color
}

struct InteractiveDNSCanvas: View {
    let letters: [DNSLetter]
    /// Called once a full flight has visually settled, so a parent
    /// workflow step can react (e.g. unlock the "Next Step" button).
    var onFlightComplete: (() -> Void)?

    @State private var progress: AnimatableVector = .zero
    @State private var hasLaunched = false
    @State private var arrivalBurst = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetProgress: AnimatableVector {
        AnimatableVector(Array(repeating: 1.0, count: letters.count))
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { proxy in
                ZStack {
                    FlightCanvas(letters: letters, progress: progress)
                    ParticleBurstView(trigger: arrivalBurst, colors: letters.map(\.tint))
                        .frame(width: 90, height: 90)
                        .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.55)
                }
            }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color("CanvasBackground"), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityRepresentation {
                    AccessibleFlightSummary(letters: letters, progress: progress)
                }

            Button {
                launch()
            } label: {
                Label(hasLaunched ? "Send Again" : "Send the Mail", systemImage: "paperplane.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .sensoryFeedback(.selection, trigger: hasLaunched)
        }
        .onAppear { launch() }
    }

    private func launch() {
        hasLaunched.toggle()
        progress = .zero
        let animation: Animation = reduceMotion
            ? .easeInOut(duration: 0.5)
            : .interpolatingSpring(stiffness: 110, damping: 13)
        withAnimation(animation) {
            progress = targetProgress
        }
        let settleDelay = reduceMotion ? 0.6 : 1.1
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
            arrivalBurst += 1
            onFlightComplete?()
        }
    }
}

/// The actual pixel-drawing layer. Conforming to `Animatable` is what
/// makes SwiftUI re-invoke `body` at every interpolated frame of the
/// spring driving `progress`, without any manual timer of our own.
private struct FlightCanvas: View, Animatable {
    let letters: [DNSLetter]
    var progress: AnimatableVector

    // Reduce Motion applies to the *ambient* animation only (the
    // marching-ants route line and the mailbox's idle breathing pulse
    // both use `date`, ticking forever whether or not anything is
    // flying) — not to the letter flight itself, which is meaningful
    // motion tied to a user action and already dampens to an ease
    // curve under Reduce Motion in `InteractiveDNSCanvas.launch()`.
    // Pausing the TimelineView just freezes the wall-clock ticks;
    // SwiftUI still re-renders this view on every spring frame via
    // `Animatable`, so the flight animates regardless.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: AnimatableVector {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, date: timeline.date)
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, date: Date) {
        let postOffice = CGPoint(x: size.width * 0.16, y: size.height * 0.55)
        let mailbox = CGPoint(x: size.width * 0.84, y: size.height * 0.55)

        // Continuous "marching ants" route — driven by wall-clock time via
        // TimelineView, intentionally independent of the letters' spring.
        var route = Path()
        route.move(to: postOffice)
        route.addLine(to: mailbox)
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) * -12
        context.stroke(
            route,
            with: .color(.secondary.opacity(0.3)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8], dashPhase: phase)
        )

        drawNode(&context, at: postOffice, symbol: "building.columns.fill", tint: .indigo, label: "Post Office")
        drawNode(&context, at: mailbox, symbol: "envelope.fill", tint: .teal, label: "Mailbox", pulseDate: date)

        for (index, letter) in letters.enumerated() {
            let raw = index < progress.values.count ? progress.values[index] : 0
            let t = min(max(raw, 0), 1)
            guard t > 0.001 else { continue }

            let arcHeight: CGFloat = 70
            let x = postOffice.x + (mailbox.x - postOffice.x) * CGFloat(t)
            let arc = sin(.pi * t) * arcHeight
            let y = postOffice.y - CGFloat(arc)
            drawLetter(&context, at: CGPoint(x: x, y: y), letter: letter, opacity: min(1, t * 4))
        }
    }

    private func drawNode(
        _ context: inout GraphicsContext,
        at point: CGPoint,
        symbol: String,
        tint: Color,
        label: String,
        radius: CGFloat = 28,
        pulseDate: Date? = nil
    ) {
        // A slow, ambient "ready and waiting" breathing ring — only
        // drawn for nodes that pass a `pulseDate` (currently just the
        // Mailbox), so it reads as "this is where mail is headed"
        // rather than decorating every node identically.
        if let pulseDate {
            let cycle = pulseDate.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
            let pulseRadius = radius + CGFloat(cycle) * 14
            let pulseOpacity = (1 - cycle) * 0.35
            let pulseRect = CGRect(x: point.x - pulseRadius, y: point.y - pulseRadius, width: pulseRadius * 2, height: pulseRadius * 2)
            context.stroke(Path(ellipseIn: pulseRect), with: .color(tint.opacity(pulseOpacity)), lineWidth: 2)
        }

        let backdrop = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: backdrop), with: .color(tint.opacity(0.18)))
        context.stroke(Path(ellipseIn: backdrop), with: .color(tint), lineWidth: 2)

        // NOTE: chaining ANY view modifier (.font, .foregroundColor, etc.)
        // onto an `Image` here widens its type to `some View`, which
        // `GraphicsContext.draw` won't accept — it needs an actual `Image`.
        // So this stays a bare, unmodified `Image`, and size is controlled
        // via the destination rect on `draw(_:in:)` instead of `.font()`.
        // The tinted circle behind the glyph carries the color instead;
        // the symbol itself renders in its default style.
        let image = Image(systemName: symbol)
        let iconSide = radius * 0.9
        let iconRect = CGRect(
            x: point.x - iconSide / 2,
            y: point.y - iconSide / 2,
            width: iconSide,
            height: iconSide
        )
        context.draw(image, in: iconRect)

        context.draw(
            Text(label).font(.caption2.weight(.semibold)).foregroundColor(.secondary),
            at: CGPoint(x: point.x, y: point.y + radius + 16)
        )
    }

    private func drawLetter(
        _ context: inout GraphicsContext,
        at point: CGPoint,
        letter: DNSLetter,
        opacity: Double
    ) {
        var ctx = context
        ctx.opacity = opacity
        let radius: CGFloat = 17
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(letter.tint))
        ctx.draw(
            Text(letter.label).font(.caption.bold()).foregroundColor(.white),
            at: point
        )
    }
}

/// The VoiceOver-facing stand-in for `FlightCanvas`. Sighted users get an
/// animated arc; VoiceOver users get an ordered, textual account of the
/// same information — which letter, how far along, and where it's headed.
/// See `.accessibilityRepresentation` in `InteractiveDNSCanvas.body`.
private struct AccessibleFlightSummary: View {
    let letters: [DNSLetter]
    let progress: AnimatableVector

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mail route from Post Office to Mailbox.")
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(letters.enumerated()), id: \.element.id) { index, letter in
                let raw = index < progress.values.count ? progress.values[index] : 0
                let percent = Int((min(max(raw, 0), 1) * 100).rounded())
                Text("\(letter.label) record: \(percent) percent of the way to the Mailbox.")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
