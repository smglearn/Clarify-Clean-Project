//
//  PressableButtonStyle.swift
//  Clarify
//
//  A tiny, purely visual button style: scale down slightly on press,
//  spring back on release. Used anywhere a `.plain`-styled tappable
//  card (a workflow card, a badge) would otherwise give zero feedback
//  between "not pressed" and "navigated away" — the kind of small
//  touch that makes a gamified app feel responsive rather than static.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
