//
//  EngineRoomAssemblyView.swift
//  Clarify
//
//  Turns "set up a compute instance, a bucket, and a firewall rule"
//  into dragging labeled blocks into a chassis. Every part is also
//  reachable without dragging at all via `.accessibilityActions`, so
//  VoiceOver users get a first-class equivalent flow rather than a
//  drag gesture they can't perform.
//

import SwiftUI

struct EnginePart: Identifiable, Hashable {
    let id: UUID
    let name: String
    let symbolName: String
    let tint: Color
}

struct EngineSlot: Identifiable, Hashable {
    let id: UUID
    let label: String
    let acceptsPartNamed: String
}

struct EngineRoomAssemblyView: View {
    let parts: [EnginePart]
    let slots: [EngineSlot]
    var onFullyAssembled: (() -> Void)?

    @State private var placements: [UUID: UUID] = [:]      // slot.id -> part.id
    @State private var dragOffsets: [UUID: CGSize] = [:]    // part.id -> live drag offset
    @State private var slotFrames: [UUID: CGRect] = [:]     // slot.id -> on-screen frame
    @State private var successPulse = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var unplacedParts: [EnginePart] {
        let placedPartIDs = Set(placements.values)
        return parts.filter { !placedPartIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 20) {
            chassis

            if unplacedParts.isEmpty {
                ZStack {
                    ParticleBurstView(trigger: successPulse, colors: parts.map(\.tint))
                        .frame(height: 60)
                    Label("Engine Room Assembled", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                tray
            }
        }
        .coordinateSpace(name: "engineRoom")
        .sensoryFeedback(.success, trigger: successPulse)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.8),
            value: placements
        )
    }

    // MARK: Chassis

    private var chassis: some View {
        VStack(spacing: 12) {
            Text("Chassis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                ForEach(slots) { slot in
                    slotView(slot)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private func slotView(_ slot: EngineSlot) -> some View {
        let placedPart = placements[slot.id].flatMap { partID in parts.first { $0.id == partID } }

        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(
                placedPart == nil ? Color.secondary.opacity(0.4) : Color.clear,
                style: StrokeStyle(lineWidth: 2, dash: placedPart == nil ? [5, 5] : [])
            )
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(placedPart?.tint.opacity(0.18) ?? Color.clear)
            )
            .frame(width: 80, height: 80)
            .overlay {
                if let placedPart {
                    Image(systemName: placedPart.symbolName)
                        .font(.title2)
                        .foregroundStyle(placedPart.tint)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    Text(slot.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(4)
                }
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { slotFrames[slot.id] = proxy.frame(in: .named("engineRoom")) }
                        .onChange(of: proxy.size) { _, _ in
                            slotFrames[slot.id] = proxy.frame(in: .named("engineRoom"))
                        }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                placedPart != nil
                    ? "\(slot.label) slot, filled with \(placedPart!.name)"
                    : "\(slot.label) slot, empty"
            )
    }

    // MARK: Tray

    private var tray: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drag each part into its matching slot.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ForEach(unplacedParts) { part in
                    partView(part)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func partView(_ part: EnginePart) -> some View {
        let offset = dragOffsets[part.id] ?? .zero

        VStack(spacing: 6) {
            Image(systemName: part.symbolName)
                .font(.title)
                .foregroundStyle(.white)
                // 64pt block on a 16pt-padded card comfortably clears the
                // HIG minimum tap target even before the label is added.
                .frame(width: 64, height: 64)
                .background(part.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(part.name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .offset(offset)
        .gesture(
            DragGesture(coordinateSpace: .named("engineRoom"))
                .onChanged { value in
                    dragOffsets[part.id] = value.translation
                }
                .onEnded { value in
                    handleDrop(of: part, at: value.location)
                    // A successful drop is already covered by the view's
                    // `.animation(value: placements)` — the part leaves the
                    // tray entirely once `placements` updates. A *missed*
                    // drop only ever changes `dragOffsets`, which that
                    // modifier doesn't watch, so without an explicit
                    // animation here the part would snap back to the tray
                    // instantly instead of springing back like everything
                    // else in this view does.
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffsets[part.id] = .zero
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(part.name)
        .accessibilityHint("Choose which slot to place this part in.")
        .accessibilityActions {
            // The accessible equivalent of dragging: VoiceOver users pick
            // a destination slot from the rotor instead of performing a
            // gesture that assumes precise on-screen coordinates.
            ForEach(availableSlots(for: part)) { slot in
                Button("Place in \(slot.label)") {
                    place(part, in: slot)
                }
            }
        }
    }

    // MARK: Placement logic

    private func availableSlots(for part: EnginePart) -> [EngineSlot] {
        slots.filter { $0.acceptsPartNamed == part.name && placements[$0.id] == nil }
    }

    private func handleDrop(of part: EnginePart, at location: CGPoint) {
        guard let targetSlot = slots.first(where: { slot in
            guard placements[slot.id] == nil, let frame = slotFrames[slot.id] else { return false }
            return frame.insetBy(dx: -24, dy: -24).contains(location)
        }) else { return }
        place(part, in: targetSlot)
    }

    private func place(_ part: EnginePart, in slot: EngineSlot) {
        guard slot.acceptsPartNamed == part.name, placements[slot.id] == nil else { return }
        placements[slot.id] = part.id
        successPulse += 1
        if unplacedParts.isEmpty {
            onFullyAssembled?()
        }
    }
}

/// Bundled sample data for every `.engineRoom` step across the workflow
/// library. Each provider gets its own kit — same mechanic, same three
/// slot roles, provider-appropriate part names — so the drag-to-assemble
/// interaction never feels copy-pasted between guides.
enum EngineRoomSample {
    struct Kit {
        let parts: [EnginePart]
        let slots: [EngineSlot]
    }

    static func kit(for id: EngineRoomKit) -> Kit {
        switch id {
        case .google: return googleKit
        case .azure: return azureKit
        case .aws: return awsKit
        }
    }

    private static let googleKit = Kit(
        parts: [
            EnginePart(id: UUID(), name: "Compute Instance", symbolName: "engine.combustion.fill", tint: .orange),
            EnginePart(id: UUID(), name: "Bucket", symbolName: "shippingbox.fill", tint: .blue),
            EnginePart(id: UUID(), name: "Firewall Rule", symbolName: "shield.lefthalf.filled", tint: .red)
        ],
        slots: [
            EngineSlot(id: UUID(), label: "Engine", acceptsPartNamed: "Compute Instance"),
            EngineSlot(id: UUID(), label: "Storage", acceptsPartNamed: "Bucket"),
            EngineSlot(id: UUID(), label: "Bouncer", acceptsPartNamed: "Firewall Rule")
        ]
    )

    private static let azureKit = Kit(
        parts: [
            EnginePart(id: UUID(), name: "Compute Instance", symbolName: "engine.combustion.fill", tint: .teal),
            EnginePart(id: UUID(), name: "Bucket", symbolName: "shippingbox.fill", tint: .indigo),
            EnginePart(id: UUID(), name: "Firewall Rule", symbolName: "shield.lefthalf.filled", tint: .pink)
        ],
        slots: [
            EngineSlot(id: UUID(), label: "Engine", acceptsPartNamed: "Compute Instance"),
            EngineSlot(id: UUID(), label: "Storage", acceptsPartNamed: "Bucket"),
            EngineSlot(id: UUID(), label: "Bouncer", acceptsPartNamed: "Firewall Rule")
        ]
    )

    private static let awsKit = Kit(
        parts: [
            EnginePart(id: UUID(), name: "Compute Instance", symbolName: "engine.combustion.fill", tint: .orange),
            EnginePart(id: UUID(), name: "Bucket", symbolName: "shippingbox.fill", tint: .yellow),
            EnginePart(id: UUID(), name: "Firewall Rule", symbolName: "shield.lefthalf.filled", tint: .red)
        ],
        slots: [
            EngineSlot(id: UUID(), label: "Engine", acceptsPartNamed: "Compute Instance"),
            EngineSlot(id: UUID(), label: "Storage", acceptsPartNamed: "Bucket"),
            EngineSlot(id: UUID(), label: "Bouncer", acceptsPartNamed: "Firewall Rule")
        ]
    )
}
