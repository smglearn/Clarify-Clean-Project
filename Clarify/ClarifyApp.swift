//
//  ClarifyApp.swift
//  Clarify
//
//  App entry point. Deliberately minimal: no account/session
//  bootstrapping, no remote config fetch, no analytics SDK init —
//  Clarify has none of those, by design (see PrivacyInfo.xcprivacy).
//

import SwiftUI

@main
struct ClarifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
