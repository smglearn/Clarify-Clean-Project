//
//  LevelFilterBar.swift
//  Tech Unknotted (project: Clarify)
//
//  A horizontal row of chips — All, Very Easy, Easy, Medium, Hard,
//  Very Hard — that narrows the guide catalog to one difficulty. `nil`
//  means "All". Each chip shows its dots meter as well as its name so
//  the scale reads at a glance and doesn't depend on color.
//

import SwiftUI

struct LevelFilterBar: View {
    @Binding var selection: GuideLevel?
    /// How many guides sit at each level for whatever is currently being
    /// browsed, so a chip can show "(6)" and dim when it would be empty.
    var counts: [GuideLevel: Int] = [:]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", meter: nil, tint: .accentColor, isSelected: selection == nil, count: nil) {
                    selection = nil
                }
                ForEach(GuideLevel.allCases) { level in
                    chip(
                        title: level.displayName,
                        meter: level.meter,
                        tint: level.tint,
                        isSelected: selection == level,
                        count: counts.isEmpty ? nil : counts[level, default: 0]
                    ) {
                        selection = (selection == level) ? nil : level
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(
        title: String,
        meter: String?,
        tint: Color,
        isSelected: Bool,
        count: Int?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let meter {
                    Text(meter)
                        .font(.system(size: 7))
                        .tracking(1)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .opacity(0.75)
                }
            }
            .foregroundStyle(isSelected ? Color.white : tint)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(
                Capsule().fill(isSelected ? tint : tint.opacity(0.12))
            )
            .opacity(count == 0 && !isSelected ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0) guides" } ?? title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
