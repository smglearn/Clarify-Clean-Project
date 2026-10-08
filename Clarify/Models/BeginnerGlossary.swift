//
//  BeginnerGlossary.swift
//  Tech Unknotted (project: Clarify)
//
//  Plain-English flip cards for the everyday words used in the Very Easy
//  and Easy guides — the vocabulary someone meets when they're locked out
//  of an account or their phone is out of space, long before they ever
//  hear the word "nameserver".
//

import Foundation

extension JargonGlossary {
    static let beginnerTerms: [JargonTerm] = [
        JargonTerm(
            term: "Password Reset",
            analogy: "Spare Key Request",
            symbolName: "key.fill",
            explanation: "A password reset lets you set a brand-new password after proving the account is yours, like asking the building manager for a new key instead of guessing the old lock."
        ),
        JargonTerm(
            term: "Account Recovery",
            analogy: "Locksmith Visit",
            symbolName: "person.badge.key.fill",
            explanation: "Account recovery is the slower, more careful process a service uses when a normal reset won't work. Like a locksmith, it checks who you are before letting you back in."
        ),
        JargonTerm(
            term: "Phishing",
            analogy: "Fake Delivery Note",
            symbolName: "envelope.badge.fill",
            explanation: "Phishing is a message pretending to be from a company you trust so you'll type your password or a code into a fake page, like a forged delivery note asking for your house key."
        ),
        JargonTerm(
            term: "Router",
            analogy: "Neighborhood Mail Carrier",
            symbolName: "wifi",
            explanation: "A router is the box that shares your internet connection with every device in your home, like a mail carrier who brings each house its own letters."
        ),
        JargonTerm(
            term: "Device Storage",
            analogy: "Closet Space",
            symbolName: "internaldrive.fill",
            explanation: "Device storage is the room on your phone or computer for apps, photos, and files. When the closet is full, nothing new fits until something comes out."
        ),
        JargonTerm(
            term: "Cloud Backup",
            analogy: "Safe-Deposit Box",
            symbolName: "icloud.and.arrow.up.fill",
            explanation: "A cloud backup keeps a copy of your phone or computer on a company's servers, like a safe-deposit box that still has your valuables if your house is flooded."
        ),
        JargonTerm(
            term: "Force Restart",
            analogy: "Unplug and Plug Back In",
            symbolName: "power",
            explanation: "A force restart turns a frozen device off and on even when the screen won't respond. It's the button-press version of unplugging something and plugging it back in."
        ),
        JargonTerm(
            term: "Software Update",
            analogy: "Free Tune-Up",
            symbolName: "arrow.down.circle.fill",
            explanation: "A software update is a free improvement from the company that made your device. It fixes bugs and closes security holes, like a tune-up that also changes the locks."
        ),
        JargonTerm(
            term: "Active Session",
            analogy: "Door Left Unlocked",
            symbolName: "lock.open.fill",
            explanation: "An active session is a device that's still signed in to your account. Each one is a door that stays unlocked until you sign that device out."
        ),
        JargonTerm(
            term: "Find My",
            analogy: "Lost-and-Found Beacon",
            symbolName: "location.circle.fill",
            explanation: "Find My is a feature that shows a lost device on a map and can lock it or play a sound, like a beacon that keeps calling out where it is."
        ),
        JargonTerm(
            term: "Recovery Contact",
            analogy: "Neighbor With a Spare Key",
            symbolName: "person.2.fill",
            explanation: "A recovery contact is a trusted person who can help you prove who you are if you're locked out. Like a neighbor holding a spare key, they can't get into your home themselves."
        ),
        JargonTerm(
            term: "Two-Step Verification",
            analogy: "Door Code After the Key",
            symbolName: "lock.shield.fill",
            explanation: "Two-step verification is another name for two-factor authentication: after your password, you also enter a code or approve a prompt, like punching in a door code after using your key."
        ),
        JargonTerm(
            term: "Privacy Checkup",
            analogy: "Home Safety Walkthrough",
            symbolName: "checklist",
            explanation: "A privacy checkup is a guided tour of the settings that control who sees your information, like walking room to room checking that the windows are locked."
        ),
        JargonTerm(
            term: "Impersonation",
            analogy: "Costume Trick",
            symbolName: "theatermasks.fill",
            explanation: "Impersonation is when someone makes an account using your name and photos to fool your friends, like a stranger in a costume knocking on doors as you."
        ),
        JargonTerm(
            term: "Auto-Renewal",
            analogy: "Standing Order",
            symbolName: "arrow.clockwise.circle.fill",
            explanation: "Auto-renewal means a membership charges your card again on its own each month or year until you turn it off, like a standing order at the bakery."
        ),
    ]
}
