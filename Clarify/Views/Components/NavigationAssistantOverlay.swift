//
//  NavigationAssistantOverlay.swift
//  Clarify
//
//  A translucent spotlight overlay for third-party console guidance
//  (e.g. "find this button in the GCP console"). Everything except the
//  target element dims under `.ultraThinMaterial`; the target itself
//  sits inside a cutout produced by a reverse mask.
//
//  The cutout's frame is discovered dynamically via a PreferenceKey —
//  callers mark the real on-screen element with `.spotlightTarget()`
//  rather than hardcoding coordinates, so this stays correct across
//  device sizes and Dynamic Type.
//

import SwiftUI

private struct SpotlightFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

extension View {
    /// Marks this view as the thing a `NavigationAssistantOverlay`
    /// hosted by an ancestor `ConsoleGuidanceOverlayHost` should spotlight.
    func spotlightTarget() -> some View {
        overlay {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SpotlightFramePreferenceKey.self,
                    value: proxy.frame(in: .named("consoleGuidanceSpace"))
                )
            }
        }
    }

    /// Masks `self` using the *inverse* of `mask` — punches a
    /// transparent hole wherever `mask` is opaque.
    @ViewBuilder
    fileprivate func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask().blendMode(.destinationOut)
                }
                .compositingGroup()
        }
    }
}

/// Hosts arbitrary console-guidance content (a screenshot, a WebView, a
/// mock preview) and overlays the spotlight once the target element's
/// frame is known.
struct ConsoleGuidanceOverlayHost<Content: View>: View {
    let targetLabel: String
    let message: String
    /// Whether the spotlight is currently showing. Left as an explicit
    /// binding (rather than always-on) so a caller can offer a "Show Me
    /// Where" button instead of dimming the console immediately.
    @Binding var isActive: Bool
    @ViewBuilder var content: () -> Content

    @State private var spotlightFrame: CGRect = .zero

    var body: some View {
        ZStack {
            content()

            if isActive && spotlightFrame != .zero {
                NavigationAssistantOverlay(
                    targetLabel: targetLabel,
                    spotlightFrame: spotlightFrame,
                    message: message,
                    onDismiss: { isActive = false }
                )
            }
        }
        .coordinateSpace(name: "consoleGuidanceSpace")
        .onPreferenceChange(SpotlightFramePreferenceKey.self) { spotlightFrame = $0 }
    }
}

struct NavigationAssistantOverlay: View {
    let targetLabel: String
    let spotlightFrame: CGRect
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .reverseMask {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .frame(width: spotlightFrame.width + 12, height: spotlightFrame.height + 12)
                        .position(x: spotlightFrame.midX, y: spotlightFrame.midY)
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                // The callout's own "Got It" button is the primary way to
                // dismiss, but the host that presents this overlay is a
                // fixed-height, clipped container (see ConsoleOverlayPreview)
                // — at large Dynamic Type sizes the callout's text can grow
                // tall enough to push that button past the visible, tappable
                // area. Tapping anywhere on the dimmed backdrop is a second,
                // always-reachable way out so a large-text user never gets
                // visually stuck with no way to close the spotlight.
                .onTapGesture(perform: onDismiss)
                // The dimming layer is purely decorative — the spotlight
                // ring below carries the actual accessible description.
                .accessibilityHidden(true)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: 3)
                .frame(width: spotlightFrame.width + 12, height: spotlightFrame.height + 12)
                .position(x: spotlightFrame.midX, y: spotlightFrame.midY)
                .accessibilityHidden(true)

            calloutBubble
                .position(calloutPosition)
        }
        .accessibilityElement(children: .contain)
    }

    private var calloutPosition: CGPoint {
        let preferredY = spotlightFrame.minY - 90
        return CGPoint(x: spotlightFrame.midX, y: max(preferredY, 90))
    }

    private var calloutBubble: some View {
        VStack(spacing: 8) {
            Text(targetLabel)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Got It", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 100, minHeight: 44)
        }
        .padding(16)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Look for \(targetLabel). \(message)")
    }
}
