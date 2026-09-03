//
//  AdaptiveStack.swift
//  Clarify
//
//  At the largest accessibility Dynamic Type sizes, side-by-side
//  controls stop having room to breathe — labels wrap, buttons overlap,
//  or text truncates. AdaptiveHStack switches to a vertical layout once
//  the environment's type size crosses into the accessibility range, so
//  every control stays fully legible and fully tappable no matter how
//  large the user's text setting is.
//

import SwiftUI

struct AdaptiveHStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = 14, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: spacing) { content() }
        } else {
            HStack(spacing: spacing) { content() }
        }
    }
}
