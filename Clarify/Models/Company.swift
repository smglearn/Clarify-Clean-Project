//
//  Company.swift
//  Clarify
//
//  The provider sections Clarify ships guides for. This is presentation
//  metadata only (name, SF Symbol, accent tint) — never a logo asset,
//  never fetched or trademarked artwork. Keeping it to a symbol + tint
//  keeps the app fully offline and avoids bundling any third-party
//  brand assets.
//

import SwiftUI

enum Company: String, Codable, Hashable, CaseIterable, Identifiable {
    case google
    case apple
    case microsoft
    case amazon
    case facebook

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: return "Google"
        case .apple: return "Apple"
        case .microsoft: return "Microsoft"
        case .amazon: return "Amazon"
        case .facebook: return "Facebook"
        }
    }

    /// A short, plain-English description of the kind of setup work
    /// this company's guides cover.
    var tagline: String {
        switch self {
        case .google: return "Cloud projects, Workspace, and Search tools"
        case .apple: return "Developer accounts, TestFlight, and App Store Connect"
        case .microsoft: return "Azure resources and Microsoft 365 domains"
        case .amazon: return "AWS storage, permissions, and web hosting"
        case .facebook: return "Meta Business tools, the Graph API, and Facebook Login"
        }
    }

    /// A neutral SF Symbol standing in for the brand — deliberately not
    /// a logo. Sized and tinted like every other icon in the app.
    var symbolName: String {
        switch self {
        case .google: return "magnifyingglass.circle.fill"
        // Deliberately not "apple.logo" — that symbol renders the actual
        // bitten-apple mark, which breaks the "neutral, non-logo" rule
        // this whole enum is built around. Google, Microsoft, and Amazon
        // all get a symbol that's merely evocative of what their guides
        // cover; Apple's guides are about developer accounts, TestFlight,
        // and App Store Connect, so a hammer (building/shipping an app)
        // fits the same register.
        case .apple: return "hammer.fill"
        case .microsoft: return "square.grid.2x2.fill"
        case .amazon: return "cart.fill"
        // Facebook's guides are about connecting apps, businesses, and
        // audiences to Meta's platforms — a network glyph fits without
        // touching the actual "f" mark.
        case .facebook: return "person.2.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .google: return .blue
        case .apple: return .gray
        case .microsoft: return .teal
        case .amazon: return .orange
        case .facebook: return .indigo
        }
    }
}
