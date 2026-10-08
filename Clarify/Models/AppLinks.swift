//
//  AppLinks.swift
//  Tech Unknotted (project: Clarify)
//
//  Public web pages the Settings screen links to. Left as `nil` until a
//  page is publicly reachable without a login; Settings hides the Help
//  section entirely while both are `nil`, so there's never a dead link.
//
//  To turn them on, set each to the live address, for example:
//  URL(string: "https://www.example.com/privacy")
//

import Foundation

enum AppLinks {
    static let support: URL? = nil
    static let privacyPolicy: URL? = nil
}
