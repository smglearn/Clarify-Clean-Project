//
//  GuideLevel.swift
//  Tech Unknotted (project: Clarify)
//
//  How hard a guide is, on a five-step scale from "anyone can do this
//  in a minute" to "you'll want a developer or IT admin nearby". Every
//  bundled guide carries exactly one level, so the Guides tab can sort
//  easiest-first and let someone filter down to what matches their
//  comfort with technology.
//
//  Levels describe the *reader's* experience, not the task's importance:
//  resetting a forgotten password is Very Easy even though it matters a
//  lot; wiring a server-side webhook is Very Hard even if it's short.
//

import SwiftUI

enum GuideLevel: Int, Codable, Hashable, CaseIterable, Identifiable, Comparable {
    case veryEasy = 1
    case easy
    case medium
    case hard
    case veryHard

    var id: Int { rawValue }

    static func < (lhs: GuideLevel, rhs: GuideLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .veryEasy: return "Very Easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }

    /// One plain-English line saying who the level is for, shown in the
    /// level picker so nobody has to guess what "Medium" means.
    var audience: String {
        switch self {
        case .veryEasy: return "Everyday fixes like login trouble. No tech experience needed."
        case .easy: return "Simple settings anyone can change on their own accounts."
        case .medium: return "Running a website, a small team, or a business page."
        case .hard: return "Admin and developer setup with several moving parts."
        case .veryHard: return "Cloud infrastructure and code-level configuration."
        }
    }

    /// A filled-dots meter (●●○○○) that reads at a glance and doesn't rely
    /// on color alone, so it still works for color-blind users.
    var meter: String {
        String(repeating: "●", count: rawValue) + String(repeating: "○", count: GuideLevel.allCases.count - rawValue)
    }

    var tint: Color {
        switch self {
        case .veryEasy: return .green
        case .easy: return .mint
        case .medium: return .blue
        case .hard: return .orange
        case .veryHard: return .red
        }
    }

    /// Spoken by VoiceOver in place of the dots meter.
    var accessibilityLabel: String {
        "Difficulty: \(displayName), level \(rawValue) of \(GuideLevel.allCases.count)"
    }
}

/// A small capsule badge showing a guide's level. Shared by every guide
/// card and the step screen header so the level always looks the same.
struct GuideLevelBadge: View {
    let level: GuideLevel
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if !compact {
                Text(level.meter)
                    .font(.system(size: 7))
                    .tracking(1)
            }
            Text(level.displayName)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(level.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(level.tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.accessibilityLabel)
    }
}
