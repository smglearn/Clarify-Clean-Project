//
//  WorkflowStepView.swift
//  Clarify
//
//  Renders a single WorkflowStep: title, plain-English instruction,
//  optional immersive visual, and any jargon flip cards it references.
//  This is the only content `FocusPagerView` ever shows — one step,
//  one screen, no exceptions.
//

import SwiftUI

struct WorkflowStepView: View {
    let step: WorkflowStep
    /// The parent workflow's provider, if any — threaded down just so
    /// the console-overlay mock can look like *that* company's console
    /// rather than a single generic gray browser window reused for
    /// every guide regardless of who it's actually about.
    var company: Company? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(step.title)
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)

            Text(step.instruction)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            visual

            JargonCardRow(termNames: step.jargonTerms)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var visual: some View {
        switch step.visual {
        case .dnsVisualizer:
            InteractiveDNSCanvas(letters: sampleLetters)
        case .engineRoom:
            let kit = EngineRoomSample.kit(for: step.engineRoomKit ?? .google)
            EngineRoomAssemblyView(parts: kit.parts, slots: kit.slots)
        case .consoleOverlay:
            ConsoleOverlayPreview(targetLabel: step.overlayTargetLabel ?? "Highlighted Element", company: company)
        case .plain:
            EmptyView()
        }
    }

    /// Turns whichever jargon terms this step references into a small
    /// set of "letters" for the DNS canvas, so the visual always lines
    /// up with the words actually being explained on screen.
    private var sampleLetters: [DNSLetter] {
        let palette: [Color] = [.indigo, .teal, .orange, .pink]
        return step.jargonTerms.enumerated().map { index, name in
            let initials = name
                .split(separator: " ")
                .compactMap(\.first)
                .map(String.init)
                .joined()
                .uppercased()
            return DNSLetter(label: initials.isEmpty ? "•" : initials, tint: palette[index % palette.count])
        }
    }
}

/// A self-contained demo of the console spotlight overlay: a small mock
/// console UI plus a "Show Me Where" button that reveals the spotlight
/// around the exact element the step is pointing at.
private struct ConsoleOverlayPreview: View {
    let targetLabel: String
    let company: Company?
    @State private var isActive = false

    private var tint: Color { company?.tint ?? .accentColor }

    /// A plausible-looking address for the mock browser chrome below —
    /// never a real screenshot or logo, just enough of a hint that
    /// "this step happens over there" reads differently per provider.
    private var mockHost: String {
        switch company {
        case .google: return "console.cloud.google.com"
        case .apple: return "developer.apple.com"
        case .microsoft: return "portal.azure.com"
        case .amazon: return "console.aws.amazon.com"
        case .facebook: return "developers.facebook.com"
        case nil: return "your provider's console"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ConsoleGuidanceOverlayHost(
                targetLabel: targetLabel,
                message: "Tap this in the real console to continue.",
                isActive: $isActive
            ) {
                mockConsole
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                isActive = true
            } label: {
                Label("Show Me Where", systemImage: "viewfinder")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
            .tint(tint)
            .sensoryFeedback(.selection, trigger: isActive)
        }
    }

    private var mockConsole: some View {
        VStack(spacing: 0) {
            // Address bar — this is the part that actually changes per
            // company, so the same mechanic doesn't feel like the same
            // exact screenshot reused across nine different guides.
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(mockHost)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .overlay(Rectangle().fill(tint.opacity(0.5)).frame(height: 2), alignment: .bottom)

            HStack(spacing: 8) {
                Circle().fill(Color.secondary.opacity(0.3)).frame(width: 10, height: 10)
                Circle().fill(Color.secondary.opacity(0.3)).frame(width: 10, height: 10)
                Circle().fill(Color.secondary.opacity(0.3)).frame(width: 10, height: 10)
                Spacer()
                Text(targetLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.18), in: Capsule())
                    .spotlightTarget()
                Spacer()
                Circle().fill(Color.secondary.opacity(0.15)).frame(width: 22, height: 22)
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))

            Spacer()
            Text("Rest of the console")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .background(Color(.secondarySystemBackground))
    }
}
