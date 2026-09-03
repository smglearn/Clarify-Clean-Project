# Clarify

Clarify is a native SwiftUI learning app that turns technical setup tasks into guided, plain-English workflows. All guide progress, XP, streaks, badges, onboarding state, and the optional local profile are stored on the device.

## Current catalog

- 300 workflows: 50 each for Universal, Google, Apple, Microsoft, Amazon/AWS, and Facebook/Meta
- 517 glossary terms
- 23 badges
- iOS and iPadOS deployment target: 17.0
- Bundle identifier: `com.glennsgaming.Clarify`
- Version: 1.0 (build 1)

## Open and run

1. On a Mac with Xcode, open `Clarify.xcodeproj`.
2. Select the **Clarify** scheme.
3. Open the Clarify target's **Signing & Capabilities** tab.
4. Select your Apple Developer team and confirm **Automatically manage signing** is enabled.
5. Confirm the **Sign in with Apple** capability is present. If a free Personal Team cannot provision it, temporarily remove that capability and the related entitlement for local testing.
6. Choose an iPhone simulator or a connected iPhone, then press **Run**.

## Validation completed during reconstruction

- Both source archives passed ZIP integrity tests.
- A prior ARM64 Debug-iPhoneOS build product was present in the supplied DerivedData archive.
- All 300 workflow titles are unique.
- All 517 glossary terms are unique.
- Every one of the 972 workflow-to-glossary references resolves.
- The app icon is a valid 1024 x 1024 RGB PNG.
- No `TODO`, `FIXME`, `fatalError`, forced casts, forced tries, or custom network calls were found.

## Before TestFlight or App Store submission

- Run a clean Debug and Release build in the current Xcode version.
- Add unit tests for stable identifiers, workflow persistence, XP awards, levels, badges, streaks, and reset behavior.
- Add UI tests for onboarding, completing a guide, glossary flips, account settings, and destructive reset confirmation.
- Test Dynamic Type, VoiceOver, Reduce Motion, dark mode, iPhone, and iPad layouts.
- Fact-check provider instructions against their current official interfaces and documentation.
- Configure the production App ID and Sign in with Apple entitlement in the Apple Developer portal.
- Prepare the privacy policy, support URL, screenshots, age rating, category, description, and App Privacy answers in App Store Connect.
- Archive a Release build, validate it in Xcode Organizer, and distribute it to TestFlight before review.

Generated build caches (`DerivedData`) and machine-specific `xcuserdata` are intentionally excluded from this package.
