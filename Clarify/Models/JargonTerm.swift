//
//  JargonTerm.swift
//  Clarify
//
//  Local, offline glossary that maps technical phrases to plain-English
//  analogies. No network calls, no remote config — the glossary ships
//  with the app binary.
//

import Foundation

/// A single technical term paired with a plain-English analogy.
///
/// `JargonTerm` is intentionally a plain `Codable` struct (not a class)
/// so it can be freely copied, cached to disk as JSON, and diffed by
/// SwiftUI without any reference-identity surprises.
struct JargonTerm: Identifiable, Codable, Hashable {
    let id: UUID
    /// The raw technical phrase as it appears in a workflow, e.g. "A Record".
    let term: String
    /// The plain-English analogy, e.g. "Address Sign".
    let analogy: String
    /// SF Symbol name used on the front/back of the flip card.
    let symbolName: String
    /// One or two sentences explaining the analogy in human terms.
    let explanation: String
    /// Short accessibility-friendly description used by VoiceOver when the
    /// card is collapsed, so screen reader users get the same context
    /// sighted users get from the icon + term.
    var accessibilitySummary: String {
        "\(term). Tap to reveal the plain-English meaning: \(analogy)."
    }

    init(
        id: UUID? = nil,
        term: String,
        analogy: String,
        symbolName: String,
        explanation: String
    ) {
        self.id = id ?? StableIdentifier.uuid("jargon-term", term)
        self.term = term
        self.analogy = analogy
        self.symbolName = symbolName
        self.explanation = explanation
    }
}

/// Static, local-only glossary. Because Clarify never phones home, this
/// array is the single source of truth for every jargon translation in
/// the app — no server sync, no A/B-tested copy.
enum JargonGlossary {
    static let allTerms: [JargonTerm] = [
        JargonTerm(
            term: "A Record",
            analogy: "Address Sign",
            symbolName: "signpost.right.fill",
            explanation: "An A Record points your domain's name at a numeric address, the same way a street sign points visitors to a physical address."
        ),
        JargonTerm(
            term: "MX Record",
            analogy: "Mail Sorter",
            symbolName: "envelope.badge.fill",
            explanation: "An MX Record tells the internet which post office should sort and deliver mail sent to your domain."
        ),
        JargonTerm(
            term: "CNAME",
            analogy: "Nickname Tag",
            symbolName: "tag.fill",
            explanation: "A CNAME lets one address answer to another name, like a nickname that still points back to the same person."
        ),
        JargonTerm(
            term: "Nameserver",
            analogy: "Post Office",
            symbolName: "building.columns.fill",
            explanation: "A nameserver is the post office that knows where every piece of mail for your domain should be routed."
        ),
        JargonTerm(
            term: "Bucket",
            analogy: "Storage Box",
            symbolName: "shippingbox.fill",
            explanation: "A bucket is a labeled storage box in the cloud where your files live until you need them again."
        ),
        JargonTerm(
            term: "API Key",
            analogy: "Secret Password",
            symbolName: "key.fill",
            explanation: "An API key is a secret password that proves your app is allowed to ask a service for help."
        ),
        JargonTerm(
            term: "SSL Certificate",
            analogy: "Wax Seal",
            symbolName: "checkmark.seal.fill",
            explanation: "An SSL certificate is a wax seal that proves a message truly came from who it says it did, unopened along the way."
        ),
        JargonTerm(
            term: "DNS",
            analogy: "Phone Book",
            symbolName: "book.closed.fill",
            explanation: "DNS is the phone book of the internet, turning names you can remember into numbers computers can use."
        ),
        JargonTerm(
            term: "Propagation",
            analogy: "Word Spreading",
            symbolName: "antenna.radiowaves.left.and.right",
            explanation: "Propagation is the time it takes for news of a change to spread to every phone book copy around the world."
        ),
        JargonTerm(
            term: "TTL",
            analogy: "Expiration Timer",
            symbolName: "timer",
            explanation: "TTL is an expiration timer that tells other computers how long they may trust a cached answer before asking again."
        ),
        JargonTerm(
            term: "Compute Instance",
            analogy: "Engine",
            symbolName: "engine.combustion.fill",
            explanation: "A compute instance is the engine that actually does the work your app needs done."
        ),
        JargonTerm(
            term: "Firewall Rule",
            analogy: "Bouncer",
            symbolName: "shield.lefthalf.filled",
            explanation: "A firewall rule is a bouncer at the door, deciding who is allowed in and who gets turned away."
        ),
        JargonTerm(
            term: "Load Balancer",
            analogy: "Traffic Cop",
            symbolName: "arrow.triangle.branch",
            explanation: "A load balancer is a traffic cop directing visitors evenly across every open lane so no single lane gets overwhelmed."
        ),
        JargonTerm(
            term: "Environment Variable",
            analogy: "Sticky Note",
            symbolName: "note.text",
            explanation: "An environment variable is a sticky note the app can read at startup, without that value being baked into the code itself."
        ),

        // MARK: Google

        JargonTerm(
            term: "TXT Record",
            analogy: "Verification Note",
            symbolName: "checkmark.rectangle.stack.fill",
            explanation: "A TXT record is a short note left in your domain's phone book entry, proving to a company that you really do own the domain."
        ),
        JargonTerm(
            term: "OAuth Consent Screen",
            analogy: "Front Desk Sign-In",
            symbolName: "person.badge.shield.checkmark.fill",
            explanation: "The consent screen is the front desk sign-in sheet a visitor sees before they're allowed to hand over their badge to your app."
        ),
        JargonTerm(
            term: "Service Account",
            analogy: "Robot Employee",
            symbolName: "gearshape.2.fill",
            explanation: "A service account is a robot employee your app can log in as, so a real person's password is never baked into the code."
        ),
        JargonTerm(
            term: "IAM Role",
            analogy: "Job Badge",
            symbolName: "person.text.rectangle.fill",
            explanation: "An IAM role is a job badge that lists exactly what its holder is allowed to touch, nothing more."
        ),
        JargonTerm(
            term: "Search Console",
            analogy: "Report Card",
            symbolName: "chart.bar.doc.horizontal.fill",
            explanation: "Search Console is a report card showing how a search engine sees and ranks your site."
        ),

        // MARK: Apple

        JargonTerm(
            term: "Provisioning Profile",
            analogy: "Backstage Pass",
            symbolName: "person.crop.rectangle.stack.fill",
            explanation: "A provisioning profile is a backstage pass that proves your app, your device, and your developer account are all cleared to work together."
        ),
        JargonTerm(
            term: "App ID",
            analogy: "Name Tag",
            symbolName: "tag.circle.fill",
            explanation: "An App ID is the permanent name tag that identifies your app to Apple's systems, even before it ever ships."
        ),
        JargonTerm(
            term: "TestFlight",
            analogy: "Dress Rehearsal",
            symbolName: "figure.run.circle.fill",
            explanation: "TestFlight is a dress rehearsal space where testers try your app before it opens to the public."
        ),
        JargonTerm(
            term: "Developer Team",
            analogy: "Crew Roster",
            symbolName: "person.3.fill",
            explanation: "A developer team is the crew roster listing everyone allowed to build and ship under your organization's name."
        ),
        JargonTerm(
            term: "Push Notification Certificate",
            analogy: "Walkie-Talkie License",
            symbolName: "antenna.radiowaves.left.and.right.circle.fill",
            explanation: "A push certificate is the license that lets Apple's servers relay your messages to a user's device, like a walkie-talkie channel only you can broadcast on."
        ),

        // MARK: Microsoft

        JargonTerm(
            term: "Tenant",
            analogy: "Office Building",
            symbolName: "building.2.fill",
            explanation: "A tenant is the whole office building your organization rents inside Microsoft's cloud — every user and resource lives inside it."
        ),
        JargonTerm(
            term: "Resource Group",
            analogy: "Filing Cabinet",
            symbolName: "archivebox.fill",
            explanation: "A resource group is a filing cabinet that keeps everything for one project together, so it can be managed or deleted as a single unit."
        ),
        JargonTerm(
            term: "App Registration",
            analogy: "Visitor Badge Request",
            symbolName: "person.badge.plus.fill",
            explanation: "An app registration is the paperwork that requests a visitor badge for your app before it's allowed inside the building."
        ),
        JargonTerm(
            term: "Subscription",
            analogy: "Billing Account",
            symbolName: "creditcard.fill",
            explanation: "A subscription is the billing account everything in the building is ultimately charged to."
        ),
        JargonTerm(
            term: "Entra ID",
            analogy: "Front Desk Directory",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "Entra ID is the front desk directory that checks every visitor's identity before letting them further into the building."
        ),

        // MARK: Amazon

        JargonTerm(
            term: "IAM Policy",
            analogy: "Rulebook",
            symbolName: "list.bullet.rectangle.fill",
            explanation: "An IAM policy is the rulebook spelling out exactly what a badge holder may and may not do."
        ),
        JargonTerm(
            term: "Bucket Policy",
            analogy: "Storage Box Lock",
            symbolName: "lock.rectangle.fill",
            explanation: "A bucket policy is the lock on a storage box, deciding who is allowed to open it and from where."
        ),
        JargonTerm(
            term: "Route 53",
            analogy: "Phone Book Operator",
            symbolName: "phone.circle.fill",
            explanation: "Route 53 is the phone book operator that answers when the internet asks where your domain lives."
        ),
        JargonTerm(
            term: "EC2 Instance",
            analogy: "Rented Workshop",
            symbolName: "wrench.and.screwdriver.fill",
            explanation: "An EC2 instance is a rented workshop that's yours alone to use for as long as you keep paying rent on it."
        ),
        JargonTerm(
            term: "Access Key",
            analogy: "Keycard",
            symbolName: "key.horizontal.fill",
            explanation: "An access key is a keycard your app swipes to prove it's allowed into a specific room, without ever using your master password."
        ),
        JargonTerm(
            term: "CloudFront Distribution",
            analogy: "Delivery Network",
            symbolName: "network.badge.shield.half.filled",
            explanation: "A CloudFront distribution is a delivery network with local depots everywhere, so visitors always get your content from somewhere nearby."
        ),

        // MARK: Universal (expansion)

        JargonTerm(
            term: "Two-Factor Authentication",
            analogy: "Double Lock",
            symbolName: "lock.shield.fill",
            explanation: "Two-Factor Authentication is a second lock on your door — even if someone copies your key, they still need the second one to get in."
        ),
        JargonTerm(
            term: "Authenticator App",
            analogy: "Code Generator Keychain",
            symbolName: "key.fill",
            explanation: "An Authenticator App is a little keychain on your phone that prints a fresh, one-time code every few seconds — only you have it, so it proves you're really you."
        ),
        JargonTerm(
            term: "Password Manager",
            analogy: "Locked Filing Cabinet",
            symbolName: "key.horizontal.fill",
            explanation: "A Password Manager is a locked filing cabinet that remembers every password for you, so you never have to reuse the same weak one everywhere."
        ),
        JargonTerm(
            term: "Master Password",
            analogy: "The One Key",
            symbolName: "key.fill",
            explanation: "Your Master Password is the single key that opens your entire password vault — strong, memorized, and never written down or reused."
        ),
        JargonTerm(
            term: "VPN",
            analogy: "Private Tunnel",
            symbolName: "bolt.shield.fill",
            explanation: "A VPN wraps your internet traffic in a private tunnel, so people sharing the same network can't peek at what you're sending."
        ),
        JargonTerm(
            term: "SSID",
            analogy: "Network's Name Tag",
            symbolName: "wifi",
            explanation: "Your SSID is simply the name your Wi-Fi network wears in the list of nearby networks, like a name tag at a party."
        ),
        JargonTerm(
            term: "Guest Network",
            analogy: "Separate Entrance",
            symbolName: "wifi",
            explanation: "A Guest Network gives visitors their own separate entrance to the internet, without ever letting them wander into the room where your own devices live."
        ),
        JargonTerm(
            term: "Firmware",
            analogy: "Router's Operating Instructions",
            symbolName: "gearshape.fill",
            explanation: "Firmware is the built-in instruction manual running inside your router — updating it patches the locks before troublemakers find the old gaps."
        ),
        JargonTerm(
            term: "Selective Sync",
            analogy: "Pick What You Carry",
            symbolName: "cloud.fill",
            explanation: "Selective Sync lets you choose which cloud folders actually download onto a device, keeping everything else safely stored online instead of filling up your hard drive."
        ),
        JargonTerm(
            term: "Sync Conflict",
            analogy: "Two Cooks, One Recipe Card",
            symbolName: "arrow.triangle.2.circlepath",
            explanation: "A Sync Conflict happens when the same file gets changed in two places before they can compare notes, so the app saves both versions and lets you pick the keeper."
        ),
        JargonTerm(
            term: "Browser Sync",
            analogy: "Shared Notebook",
            symbolName: "arrow.triangle.2.circlepath",
            explanation: "Browser Sync keeps a shared notebook of your bookmarks, tabs, and passwords updated across every device you sign into."
        ),
        JargonTerm(
            term: "Bookmark",
            analogy: "Saved Page Marker",
            symbolName: "star.fill",
            explanation: "A Bookmark is a saved marker for a page you want to find again, like folding the corner of a page in a book."
        ),
        JargonTerm(
            term: "SPF Record",
            analogy: "Approved Sender List",
            symbolName: "envelope.badge.fill",
            explanation: "An SPF Record is a published list of exactly which mail servers are allowed to send email pretending to be from your domain — anyone not on the list gets flagged."
        ),
        JargonTerm(
            term: "DKIM Record",
            analogy: "Tamper-Proof Seal",
            symbolName: "checkmark.seal.fill",
            explanation: "A DKIM Record lets every email you send carry an invisible wax seal, proving the message wasn't altered after it left your hands."
        ),
        JargonTerm(
            term: "DMARC Record",
            analogy: "Instructions for the Bouncer",
            symbolName: "shield.lefthalf.filled",
            explanation: "A DMARC Record tells other mail providers what to do with messages that fail your checks — quarantine them, reject them, or let them through — like written instructions left for a bouncer."
        ),
        JargonTerm(
            term: "Sitemap",
            analogy: "Site's Table of Contents",
            symbolName: "list.bullet.rectangle.fill",
            explanation: "A Sitemap is a simple list of every page on your site, handed to search engines so they don't have to guess what exists."
        ),
        JargonTerm(
            term: "Robots.txt",
            analogy: "House Rules Sign",
            symbolName: "doc.text.fill",
            explanation: "Robots.txt is a short note posted at your site's front door, telling visiting search engines which rooms they're welcome to explore and which are off-limits."
        ),
        JargonTerm(
            term: "Favicon",
            analogy: "Tiny Tab Logo",
            symbolName: "photo.fill",
            explanation: "A Favicon is the small icon that shows up in a browser tab or bookmarks list — your site's logo, shrunk down to fingernail size."
        ),
        JargonTerm(
            term: "QR Code",
            analogy: "Scannable Shortcut",
            symbolName: "camera.fill",
            explanation: "A QR Code is a pattern of squares that packs in a link or message, letting any phone camera skip the typing and jump straight there."
        ),
        JargonTerm(
            term: "CAPTCHA",
            analogy: "Are You Human? Check",
            symbolName: "checkmark.shield.fill",
            explanation: "A CAPTCHA is a quick puzzle that's easy for a person to solve and hard for a script, sorting real visitors from automated spam."
        ),
        JargonTerm(
            term: "Honeypot Field",
            analogy: "Invisible Trap",
            symbolName: "xmark.shield.fill",
            explanation: "A Honeypot Field is a form field hidden from real visitors but visible to bots — anything that fills it in outs itself as automated spam."
        ),
        JargonTerm(
            term: "Health Check",
            analogy: "Watchman's Knock",
            symbolName: "stopwatch.fill",
            explanation: "A Health Check is a quick knock on your website's door at set intervals, confirming someone's still home and answering."
        ),
        JargonTerm(
            term: "Downtime",
            analogy: "Lights Out",
            symbolName: "exclamationmark.triangle.fill",
            explanation: "Downtime is any stretch when your website's lights are off and visitors can't get in, even though they're trying the right address."
        ),

        // MARK: Google (expansion)

        JargonTerm(
            term: "Admin Console",
            analogy: "Office Front Desk",
            symbolName: "gearshape.2.fill",
            explanation: "The admin console is the front desk of your company's office — the one place where you check in new employees, hand out keys, and manage who has access to what."
        ),
        JargonTerm(
            term: "Analytics Property",
            analogy: "Store Counter",
            symbolName: "chart.bar.fill",
            explanation: "An Analytics property is the counter by the store's front door, quietly tallying who comes in and what they browse."
        ),
        JargonTerm(
            term: "Measurement ID",
            analogy: "Counter's Name Tag",
            symbolName: "tag.fill",
            explanation: "The measurement ID is the name tag pinned to your counter, making sure every visit it counts gets credited to the right store."
        ),
        JargonTerm(
            term: "Tracking Snippet",
            analogy: "Counter's Wiring",
            symbolName: "terminal.fill",
            explanation: "The tracking snippet is the wire that connects your counter to the register — a few lines of code that send visit data back to Analytics."
        ),
        JargonTerm(
            term: "Conversion Action",
            analogy: "Checkout Bell",
            symbolName: "bell.fill",
            explanation: "A conversion action is the bell above your shop door — it rings every time someone finishes something you care about, like a purchase or a sign-up."
        ),
        JargonTerm(
            term: "Conversion Tag",
            analogy: "Bell Wire",
            symbolName: "tag.circle.fill",
            explanation: "The conversion tag is the wire connecting that bell to the register, letting Ads know exactly when it rang."
        ),
        JargonTerm(
            term: "User License",
            analogy: "Starter Kit",
            symbolName: "checkmark.rectangle.stack.fill",
            explanation: "A user license is the starter kit you hand a new teammate — it unlocks their email, documents, and the rest of the shared toolbox."
        ),
        JargonTerm(
            term: "Share Link",
            analogy: "Spare Key",
            symbolName: "key.horizontal.fill",
            explanation: "A share link is a spare key to a specific drawer — anyone holding it can get in, so hand it out carefully."
        ),
        JargonTerm(
            term: "Permission Level",
            analogy: "What the Key Opens",
            symbolName: "lock.fill",
            explanation: "The permission level decides what a spare key actually opens — just a peek inside, the ability to rearrange things, or a master key to change anything."
        ),
        JargonTerm(
            term: "Firebase Project",
            analogy: "Fresh Toolbox",
            symbolName: "cube.fill",
            explanation: "A Firebase project is a fresh toolbox with your app's name on it, ready to be filled with the pieces your app needs to run."
        ),
        JargonTerm(
            term: "Authentication",
            analogy: "Front Door Guard",
            symbolName: "person.badge.shield.checkmark.fill",
            explanation: "Authentication is the guard standing at your app's front door, checking IDs before letting anyone sign in."
        ),
        JargonTerm(
            term: "Firestore",
            analogy: "Filing Cabinet",
            symbolName: "archivebox.fill",
            explanation: "Firestore is the filing cabinet where your app's information lives, organized into folders you can open from anywhere."
        ),
        JargonTerm(
            term: "Security Rules",
            analogy: "House Rules",
            symbolName: "checklist",
            explanation: "Security rules are the house rules posted on the filing cabinet, spelling out exactly who's allowed to open which drawers."
        ),
        JargonTerm(
            term: "Store Listing",
            analogy: "Display Window",
            symbolName: "storefront.fill",
            explanation: "The store listing is the display window shoppers see before they ever walk into your app — the pictures and words that make them want to come in."
        ),
        JargonTerm(
            term: "Feature Graphic",
            analogy: "Window Poster",
            symbolName: "photo.fill",
            explanation: "The feature graphic is the big poster hung in that display window, the first image that catches a shopper's eye."
        ),
        JargonTerm(
            term: "API Restriction",
            analogy: "Leash",
            symbolName: "lock.shield.fill",
            explanation: "An API restriction is a leash on your key, making sure it only works for your app even if someone else finds it lying around."
        ),
        JargonTerm(
            term: "Channel Art",
            analogy: "Storefront Banner",
            symbolName: "photo.fill",
            explanation: "Channel art is the banner stretched across the top of your storefront, giving visitors a sense of who you are before they watch a single video."
        ),
        JargonTerm(
            term: "Channel Watermark",
            analogy: "Signature Stamp",
            symbolName: "checkmark.seal.fill",
            explanation: "A channel watermark is your signature stamped in the corner of every video, so viewers recognize your work at a glance."
        ),
        JargonTerm(
            term: "Tag Manager Container",
            analogy: "Labeled Toolbox",
            symbolName: "shippingbox.fill",
            explanation: "A Tag Manager container is a labeled toolbox that holds every tracking tag your website uses, so you're not digging through code every time something changes."
        ),
        JargonTerm(
            term: "Tag",
            analogy: "Tracking Sticker",
            symbolName: "tag.fill",
            explanation: "A tag is a tracking sticker placed on a specific action, telling Tag Manager what to record when it fires."
        ),
        JargonTerm(
            term: "Trigger",
            analogy: "Tripwire",
            symbolName: "bolt.fill",
            explanation: "A trigger is a tripwire for automation — some event, like a click, a new file, or an incoming email, sets it off and everything downstream starts moving on its own."
        ),
        JargonTerm(
            term: "Variable",
            analogy: "Fill-in-the-Blank",
            symbolName: "doc.badge.gearshape.fill",
            explanation: "A variable is a fill-in-the-blank space that grabs a detail, like a page name or button label, and hands it to a tag when needed."
        ),
        JargonTerm(
            term: "Business Profile",
            analogy: "Mailbox Nameplate",
            symbolName: "building.columns.fill",
            explanation: "A Business Profile is the nameplate on your shop's mailbox, telling Google Maps and Search where you are and when you're open."
        ),
        JargonTerm(
            term: "Verification Code",
            analogy: "Secret Handshake",
            symbolName: "key.fill",
            explanation: "A verification code is a secret handshake Google sends you — by postcard, call, or email — to prove the shop is really yours."
        ),
        JargonTerm(
            term: "reCAPTCHA",
            analogy: "Polite Door Guard",
            symbolName: "checkmark.shield.fill",
            explanation: "reCAPTCHA is a polite guard standing at your form's door, quietly checking whether a visitor is a real person or a bot trying to sneak in."
        ),
        JargonTerm(
            term: "Site Key",
            analogy: "Guard's Badge",
            symbolName: "key.fill",
            explanation: "The site key is the guard's badge you post publicly on your page, letting the guard know which door to watch."
        ),
        JargonTerm(
            term: "Secret Key",
            analogy: "Backroom Key",
            symbolName: "key.horizontal.fill",
            explanation: "The secret key stays locked in your back room, letting your server double-check the guard's work without ever showing it to visitors."
        ),

        // MARK: Apple (expansion)

        JargonTerm(
            term: "App Store Connect",
            analogy: "Backstage Office",
            symbolName: "macwindow",
            explanation: "App Store Connect is the backstage office where you manage everything about your app's life on the App Store, from its listing to its testers to its payments."
        ),
        JargonTerm(
            term: "Metadata",
            analogy: "Sales Pitch",
            symbolName: "doc.text.fill",
            explanation: "Metadata is the sales pitch text — your app's name, subtitle, and description — that shoppers read before deciding whether to download."
        ),
        JargonTerm(
            term: "Localization",
            analogy: "Local Storefront",
            symbolName: "book.fill",
            explanation: "Localization is giving your app's storefront a separate, translated copy for each language, like swapping the sign in a shop window for every neighborhood you open in."
        ),
        JargonTerm(
            term: "In-App Purchase",
            analogy: "Menu Item",
            symbolName: "cart.fill",
            explanation: "An In-App Purchase is an item you add to your app's menu — a one-time unlock, consumable, or subscription — that people can buy without leaving the app."
        ),
        JargonTerm(
            term: "Sign in with Apple",
            analogy: "Universal Keycard",
            symbolName: "person.crop.circle.fill",
            explanation: "Sign in with Apple is a universal keycard people can use to log into your app with their Apple ID instead of creating yet another password."
        ),
        JargonTerm(
            term: "App Preview",
            analogy: "Movie Trailer",
            symbolName: "video.fill",
            explanation: "An App Preview is a short trailer-style video that shows your app in action right on its App Store page, instead of just still pictures."
        ),
        JargonTerm(
            term: "Xcode Cloud",
            analogy: "Automatic Assembly Line",
            symbolName: "cloud.fill",
            explanation: "Xcode Cloud is an automatic assembly line that builds and tests your app on Apple's servers every time you push new code, instead of you doing it by hand."
        ),
        JargonTerm(
            term: "App Privacy Label",
            analogy: "Nutrition Label",
            symbolName: "doc.text.fill",
            explanation: "An App Privacy label is a nutrition label for your app, listing exactly what data it collects before anyone downloads it."
        ),
        JargonTerm(
            term: "Associated Domain",
            analogy: "Signed Trust Note",
            symbolName: "network",
            explanation: "An Associated Domain is a signed note your website publishes proving it trusts your app, which is what allows web links to open directly inside the app."
        ),
        JargonTerm(
            term: "Universal Link",
            analogy: "Direct Doorway",
            symbolName: "iphone",
            explanation: "A Universal Link is a regular web link that opens straight into your app instead of a browser tab, as long as your app has already proven it owns that address."
        ),
        JargonTerm(
            term: "CloudKit Container",
            analogy: "Storage Locker",
            symbolName: "tray.full.fill",
            explanation: "A CloudKit Container is a private storage locker in iCloud set aside just for your app's data, separate from every other app's locker."
        ),
        JargonTerm(
            term: "Subscription Group",
            analogy: "Membership Shelf",
            symbolName: "rectangle.3.group.fill",
            explanation: "A Subscription Group is a shared shelf holding every tier of your subscription, making sure a person is only ever signed up for one level at a time."
        ),

        // MARK: Microsoft (expansion)

        JargonTerm(
            term: "Team",
            analogy: "Clubhouse",
            symbolName: "person.3.fill",
            explanation: "A team is a clubhouse built just for your group, where chats, meetings, and files all live behind one shared door."
        ),
        JargonTerm(
            term: "Channel",
            analogy: "Room in a Clubhouse",
            symbolName: "message.fill",
            explanation: "A channel is a separate room inside your team's clubhouse, so conversations about one topic don't spill into another."
        ),
        JargonTerm(
            term: "Guest Access",
            analogy: "Visitor Pass",
            symbolName: "person.badge.plus.fill",
            explanation: "Guest access is a visitor pass that lets someone outside your company step into a specific channel without handing them a full key to the building."
        ),
        JargonTerm(
            term: "SharePoint Site",
            analogy: "Shared Filing Room",
            symbolName: "folder.fill",
            explanation: "A SharePoint site is a shared filing room with its own address, where your team's documents and pages are kept together."
        ),
        JargonTerm(
            term: "Document Library",
            analogy: "Labeled Shelf",
            symbolName: "doc.fill",
            explanation: "A document library is a labeled shelf inside your filing room, keeping one project's files separate from another's."
        ),
        JargonTerm(
            term: "Sharing Link",
            analogy: "Spare Key",
            symbolName: "key.fill",
            explanation: "A sharing link is a spare key you hand out, letting whoever holds it open the file without you standing at the door."
        ),
        JargonTerm(
            term: "Link Expiration",
            analogy: "Timed Key",
            symbolName: "timer",
            explanation: "Link expiration is a timer built into a spare key, so it stops working on its own once the date you picked arrives."
        ),
        JargonTerm(
            term: "Conditional Access Policy",
            analogy: "Checkpoint Rule",
            symbolName: "checkmark.shield.fill",
            explanation: "A conditional access policy is a checkpoint rule that watches how and where someone is signing in, and decides what to do if something looks off."
        ),
        JargonTerm(
            term: "Multi-Factor Authentication",
            analogy: "Second Lock on the Door",
            symbolName: "lock.fill",
            explanation: "Multi-factor authentication is a second lock on the door, asking for proof beyond just a password before anyone gets in."
        ),
        JargonTerm(
            term: "Key Vault",
            analogy: "Safe Deposit Box",
            symbolName: "lock.shield.fill",
            explanation: "A key vault is a safe deposit box for your app's secrets, opened only by the exact keys you've approved."
        ),
        JargonTerm(
            term: "Storage Account",
            analogy: "Warehouse",
            symbolName: "archivebox.fill",
            explanation: "A storage account is a warehouse with its own unique name, built to hold your app's files, backups, and other data."
        ),
        JargonTerm(
            term: "Redundancy",
            analogy: "Backup Copies",
            symbolName: "arrow.triangle.2.circlepath",
            explanation: "Redundancy is keeping backup copies of your warehouse in other locations, so a single fire doesn't wipe out everything you stored."
        ),
        JargonTerm(
            term: "Power BI Workspace",
            analogy: "Shared Drafting Table",
            symbolName: "chart.bar.fill",
            explanation: "A Power BI workspace is a shared drafting table where your team builds, reviews, and polishes reports together before anyone else sees them."
        ),
        JargonTerm(
            term: "Data Source",
            analogy: "Water Supply",
            symbolName: "cloud.fill",
            explanation: "A data source is the water supply feeding your report, the spreadsheet or database that all its numbers actually come from."
        ),
        JargonTerm(
            term: "Power Automate Flow",
            analogy: "Row of Dominoes",
            symbolName: "gearshape.2.fill",
            explanation: "A Power Automate flow is a row of dominoes you've set up in advance, so one action automatically tips off the next without you lifting a finger."
        ),
        JargonTerm(
            term: "Connector",
            analogy: "Plug Adapter",
            symbolName: "square.grid.2x2.fill",
            explanation: "A connector is a plug adapter that lets your flow talk to a specific app, so the two can pass information back and forth."
        ),
        JargonTerm(
            term: "Safe Attachments",
            analogy: "Mail Scanner",
            symbolName: "envelope.badge.shield.half.filled.fill",
            explanation: "Safe attachments is a mail scanner that checks incoming files for danger before they're ever allowed to land in an inbox."
        ),
        JargonTerm(
            term: "Endpoint Protection",
            analogy: "Guard at Every Door",
            symbolName: "shield.lefthalf.filled",
            explanation: "Endpoint protection posts a guard at every laptop and phone's door, not just the front entrance to your network."
        ),
        JargonTerm(
            term: "Security Score",
            analogy: "Report Card",
            symbolName: "gauge.with.dots.needle.67percent",
            explanation: "A security score is a report card that grades how well-guarded your setup currently is, and points out where to improve."
        ),
        JargonTerm(
            term: "DevOps Project",
            analogy: "Labeled Toolbox",
            symbolName: "wrench.and.screwdriver.fill",
            explanation: "A DevOps project is a labeled toolbox that holds everything for one piece of work, from code to tasks to plans."
        ),
        JargonTerm(
            term: "Repository",
            analogy: "Shelf Inside the Toolbox",
            symbolName: "archivebox.fill",
            explanation: "A repository is the shelf inside your toolbox where the actual code lives, with a record of every change ever made to it."
        ),
        JargonTerm(
            term: "Branch Policy",
            analogy: "Second Pair of Eyes",
            symbolName: "checkmark.rectangle.stack.fill",
            explanation: "A branch policy is a rule requiring a second pair of eyes to check any change before it's allowed onto the main shelf."
        ),
        JargonTerm(
            term: "Mail Flow Rule",
            analogy: "Sorting Clerk",
            symbolName: "envelope.fill",
            explanation: "A mail flow rule is a sorting clerk who inspects every letter passing through and handles it differently based on what they find."
        ),
        JargonTerm(
            term: "Autopilot Profile",
            analogy: "Setup Instructions Card",
            symbolName: "laptopcomputer",
            explanation: "An Autopilot profile is a setup instructions card attached to a new laptop, telling it exactly how to introduce itself and what to install."
        ),
        JargonTerm(
            term: "Zero-Touch Deployment",
            analogy: "Self-Assembling Furniture",
            symbolName: "sparkles",
            explanation: "Zero-touch deployment is self-assembling furniture for laptops, finishing its own setup the moment it's powered on and connected."
        ),

        // MARK: Amazon (expansion)

        JargonTerm(
            term: "RDS Database",
            analogy: "Full-Service Database Rental",
            symbolName: "cylinder.fill",
            explanation: "An RDS database is a full-service database rental — Amazon handles the maintenance, patching, and upkeep, so you just move in and start storing things."
        ),
        JargonTerm(
            term: "Automated Backup",
            analogy: "Nightly Photocopier",
            symbolName: "arrow.triangle.2.circlepath",
            explanation: "An automated backup is a nightly photocopier for your data — it quietly makes a fresh copy every night so you're never starting from scratch after a mistake."
        ),
        JargonTerm(
            term: "Database Endpoint",
            analogy: "Unlisted Phone Number",
            symbolName: "network",
            explanation: "A database endpoint is the unlisted phone number your app dials to reach your database — it's the address, not the database itself."
        ),
        JargonTerm(
            term: "Lambda Function",
            analogy: "On-Call Handyman",
            symbolName: "bolt.fill",
            explanation: "A Lambda function is an on-call handyman who shows up only when needed, does the one job, and leaves — you're never paying for idle time."
        ),
        JargonTerm(
            term: "Execution Role",
            analogy: "Work Badge",
            symbolName: "checkmark.seal.fill",
            explanation: "An execution role is the work badge you hand your Lambda function — it only opens the doors the job actually requires, nothing more."
        ),
        JargonTerm(
            term: "SQS Queue",
            analogy: "Waiting Line",
            symbolName: "tray.full.fill",
            explanation: "An SQS queue is a waiting line for tasks — each one waits its turn so nothing gets skipped or lost when things get busy."
        ),
        JargonTerm(
            term: "Queue Policy",
            analogy: "Guest List",
            symbolName: "list.bullet.clipboard.fill",
            explanation: "A queue policy is the guest list for your waiting line — it spells out exactly who's allowed to drop off or pick up tasks."
        ),
        JargonTerm(
            term: "Visibility Timeout",
            analogy: "Do Not Disturb Sign",
            symbolName: "timer",
            explanation: "A visibility timeout is a Do Not Disturb sign — once a worker grabs a task, it hangs one up so nobody else grabs that same task at the same time."
        ),
        JargonTerm(
            term: "SNS Topic",
            analogy: "Megaphone Broadcast",
            symbolName: "bell.badge.fill",
            explanation: "An SNS topic is a megaphone broadcast — one announcement goes out, and everyone who's signed up hears it at once."
        ),
        JargonTerm(
            term: "SNS Subscription",
            analogy: "Newsletter Sign-up",
            symbolName: "envelope.fill",
            explanation: "An SNS subscription is a newsletter sign-up for a topic — once you're on the list, every announcement lands straight in your inbox or phone."
        ),
        JargonTerm(
            term: "Metric",
            analogy: "Vital Sign",
            symbolName: "chart.line.uptrend.xyaxis",
            explanation: "A metric is a vital sign for your system, like a pulse or temperature reading, that tells you how it's doing moment to moment."
        ),
        JargonTerm(
            term: "CloudWatch Alarm",
            analogy: "Smoke Detector",
            symbolName: "waveform.path.ecg",
            explanation: "A CloudWatch alarm is a smoke detector for your system — it stays silent until a vital sign crosses a dangerous line, then it goes off."
        ),
        JargonTerm(
            term: "DynamoDB Table",
            analogy: "Self-Expanding Filing Cabinet",
            symbolName: "folder.fill",
            explanation: "A DynamoDB table is a self-expanding filing cabinet — it quietly grows extra drawers the moment you need more room, with no need to buy a bigger cabinet yourself."
        ),
        JargonTerm(
            term: "Partition Key",
            analogy: "Folder Tab",
            symbolName: "tag.fill",
            explanation: "A partition key is the folder tab you always search by — pick a good one and you can find any record in the cabinet almost instantly."
        ),
        JargonTerm(
            term: "Capacity Mode",
            analogy: "Pay-as-You-Go Meter",
            symbolName: "gauge.with.dots.needle.67percent",
            explanation: "Capacity mode is choosing between a pay-as-you-go meter for unpredictable traffic or a flat monthly rate for traffic you can count on."
        ),
        JargonTerm(
            term: "VPC",
            analogy: "Private Neighborhood",
            symbolName: "network",
            explanation: "A VPC is your own private neighborhood carved out inside Amazon's data center, fenced off from everyone else's servers."
        ),
        JargonTerm(
            term: "Subnet",
            analogy: "Street Block",
            symbolName: "house.fill",
            explanation: "A subnet is a single street block within your private neighborhood, where you decide which servers live on which block."
        ),
        JargonTerm(
            term: "Route Table",
            analogy: "Street Signs",
            symbolName: "arrow.triangle.branch",
            explanation: "A route table is the set of street signs in your neighborhood, telling traffic exactly which road to take to get where it's going."
        ),
        JargonTerm(
            term: "Internet Gateway",
            analogy: "Neighborhood Gate",
            symbolName: "shield.lefthalf.filled",
            explanation: "An internet gateway is the gate at the entrance to your neighborhood, letting approved traffic in and out to the wider internet."
        ),
        JargonTerm(
            term: "Elastic Beanstalk Environment",
            analogy: "Turnkey Storefront",
            symbolName: "shippingbox.fill",
            explanation: "An Elastic Beanstalk environment is a turnkey storefront — you hand over your code and Amazon builds and manages everything else around it."
        ),
        JargonTerm(
            term: "Secrets Manager Secret",
            analogy: "Bank Vault Deposit",
            symbolName: "key.horizontal.fill",
            explanation: "A Secrets Manager secret is a bank vault deposit for your passwords and keys, kept locked away instead of sitting out in your code."
        ),
        JargonTerm(
            term: "Secret Rotation",
            analogy: "Changing the Locks on a Schedule",
            symbolName: "arrow.triangle.2.circlepath",
            explanation: "Secret rotation is changing the locks on a schedule automatically, so even an old, leaked password stops working before it can be misused."
        ),
        JargonTerm(
            term: "CloudTrail Trail",
            analogy: "Security Camera Log",
            symbolName: "doc.text.magnifyingglass",
            explanation: "A CloudTrail trail is a security camera log for your account, recording every action so you can review exactly who did what and when."
        ),
        JargonTerm(
            term: "Launch Template",
            analogy: "Staff Uniform and Instructions",
            symbolName: "doc.badge.gearshape.fill",
            explanation: "A launch template is the staff uniform and instruction sheet handed to every new server, so each one starts out set up exactly the same way."
        ),
        JargonTerm(
            term: "Auto Scaling Group",
            analogy: "Staffing Roster",
            symbolName: "person.3.fill",
            explanation: "An auto scaling group is a staffing roster that hires extra servers when things get busy and sends them home when it's quiet, keeping headcount within limits you set."
        ),

        // MARK: Universal (round 2 expansion)
        JargonTerm(
            term: "Passkey",
            analogy: "Digital House Key",
            symbolName: "key.viewfinder",
            explanation: "A passkey is like a house key that only your device can use — it proves who you are without you ever typing a password that could be stolen."
        ),
        JargonTerm(
            term: "Security Key",
            analogy: "Physical Ignition Key",
            symbolName: "key.fill",
            explanation: "A security key is a small physical device you plug in or tap, like a car's ignition key — without it in hand, no one can start the sign-in process."
        ),
        JargonTerm(
            term: "3-2-1 Backup Rule",
            analogy: "Three Copies, Two Places, One Far Away",
            symbolName: "square.stack.3d.up.fill",
            explanation: "Keeping three copies of your files across two kinds of storage, with one copy somewhere else entirely, means no single accident can wipe out everything."
        ),
        JargonTerm(
            term: "Extension Permission",
            analogy: "Guest House Key List",
            symbolName: "list.bullet.rectangle",
            explanation: "An extension permission is like a list of rooms a house guest is allowed into — it spells out exactly what a browser add-on can see or change."
        ),
        JargonTerm(
            term: "Cookie Consent Banner",
            analogy: "Doorstep Question",
            symbolName: "hand.raised.square.fill",
            explanation: "A cookie consent banner is like someone asking at the door before they're let inside — it gives visitors the choice to allow tracking before it happens."
        ),
        JargonTerm(
            term: "Email Alias",
            analogy: "Nickname Mailbox",
            symbolName: "at.badge.plus",
            explanation: "An email alias is a nickname address that quietly forwards into your real inbox, so you can hand it out without exposing your main address."
        ),
        JargonTerm(
            term: "Catch-All Address",
            analogy: "Lost and Found Bin",
            symbolName: "tray.and.arrow.down.fill",
            explanation: "A catch-all address scoops up mail sent to any made-up or mistyped address at your domain instead of letting it bounce back undelivered."
        ),
        JargonTerm(
            term: "Auto-Lock",
            analogy: "Self-Closing Door",
            symbolName: "lock.fill",
            explanation: "Auto-lock is a door that swings shut and locks itself after you walk away, so a device left unattended doesn't stay open to anyone nearby."
        ),
        JargonTerm(
            term: "Session Timeout",
            analogy: "Automatic Sign-Out Clock",
            symbolName: "clock.badge.xmark",
            explanation: "A session timeout is a clock that quietly signs you out of an account after you've been away for a while, so a forgotten login can't be misused."
        ),
        JargonTerm(
            term: "Screen Time Limit",
            analogy: "Kitchen Timer for Devices",
            symbolName: "hourglass",
            explanation: "A screen time limit is like a kitchen timer that cuts off device use once the allotted minutes run out, no reminders needed."
        ),
        JargonTerm(
            term: "Content Filter",
            analogy: "Bouncer at the Door",
            symbolName: "checkmark.shield.fill",
            explanation: "A content filter checks what's trying to get onto the screen and turns away anything that doesn't belong, like a bouncer checking IDs at a club."
        ),
        JargonTerm(
            term: "Short Link",
            analogy: "Nickname for a Long Address",
            symbolName: "link.circle.fill",
            explanation: "A short link is a brief, easy-to-share nickname that quietly redirects to a much longer web address behind the scenes."
        ),
        JargonTerm(
            term: "RSS Feed",
            analogy: "Newspaper Delivery List",
            symbolName: "dot.radiowaves.up.forward",
            explanation: "An RSS feed is like a subscription list that automatically delivers a copy of every new post straight to a reader's app the moment it's published."
        ),
        JargonTerm(
            term: "Feed Reader",
            analogy: "Personal Newsstand",
            symbolName: "newspaper.fill",
            explanation: "A feed reader is an app that gathers every site you subscribe to into one personal newsstand, so you don't have to check each one by hand."
        ),

        // MARK: Google (round 2 expansion)
        JargonTerm(
            term: "Campaign Goal",
            analogy: "Destination",
            symbolName: "flag.checkered",
            explanation: "Like picking a destination before a road trip, this tells Google what result you actually want — sales, calls, or visits — so it can steer your ads there."
        ),
        JargonTerm(
            term: "Campaign Budget",
            analogy: "Daily Allowance",
            symbolName: "dollarsign.circle.fill",
            explanation: "The most you're willing to spend on ads in a single day, like a daily allowance you hand yourself before you leave the house."
        ),
        JargonTerm(
            term: "Bidding Strategy",
            analogy: "Auction Playbook",
            symbolName: "hammer.fill",
            explanation: "The rules Google follows when competing against other advertisers for your ad spot, like a playbook for how aggressively to bid at an auction."
        ),
        JargonTerm(
            term: "Keyword Match Type",
            analogy: "Search Net",
            symbolName: "text.magnifyingglass",
            explanation: "Controls how closely someone's search has to match your keyword before your ad shows up, like choosing a wide net or a narrow one."
        ),
        JargonTerm(
            term: "Ad Group",
            analogy: "Folder of Related Ads",
            symbolName: "folder.fill.badge.plus",
            explanation: "A bundle of ads and keywords about the same theme, kept together like a labeled folder so related ads share the same targeting."
        ),
        JargonTerm(
            term: "Booking Page",
            analogy: "Open Appointment Book",
            symbolName: "calendar.badge.plus",
            explanation: "A public page showing your open time slots, like an appointment book visitors can flip through and claim a slot from themselves."
        ),
        JargonTerm(
            term: "Question Type",
            analogy: "Answer Shape",
            symbolName: "checklist",
            explanation: "Decides what kind of answer a question accepts — typed text, a checkbox, or a multiple choice pick — like choosing the shape of the blank to fill in."
        ),
        JargonTerm(
            term: "Response Destination",
            analogy: "Mailbox for Answers",
            symbolName: "tray.full.fill",
            explanation: "The spot, usually a spreadsheet, where every submitted answer automatically lands, like a mailbox that catches everything people send in."
        ),
        JargonTerm(
            term: "Sign-In Provider",
            analogy: "Door Chosen at the Entrance",
            symbolName: "door.left.hand.open",
            explanation: "The specific way someone proves who they are — email and password, or a button from Google or Apple — like picking which door to walk through."
        ),
        JargonTerm(
            term: "Cloud Messaging",
            analogy: "Notification Post Office",
            symbolName: "envelope.badge.fill",
            explanation: "The delivery service that carries your alert from Firebase to a person's phone, like a post office routing mail to the right address."
        ),
        JargonTerm(
            term: "Group Membership",
            analogy: "Roster",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "The list of people counted as part of a mailing group, like a roster that decides whose inbox gets the group's mail."
        ),
        JargonTerm(
            term: "Merchant Center",
            analogy: "Storefront Registry",
            symbolName: "building.2.fill",
            explanation: "Google's directory of legitimate online stores and their products, like a registry that vouches your shop is real before it lists your goods."
        ),
        JargonTerm(
            term: "Product Feed",
            analogy: "Price Tag File",
            symbolName: "tag.fill",
            explanation: "A single file listing every product you sell along with its price and photo, like a giant sheet of price tags Google reads all at once."
        ),
        JargonTerm(
            term: "Quota",
            analogy: "Ration Limit",
            symbolName: "gauge.with.dots.needle.67percent",
            explanation: "The number of requests your app is allowed to make to a service in a given day, like a ration that runs out if you use it too fast."
        ),
        JargonTerm(
            term: "Container Image",
            analogy: "Packed Moving Box",
            symbolName: "shippingbox.fill",
            explanation: "Your app and everything it needs to run, sealed into one package, like a moving box packed so it works the same wherever it's opened."
        ),
        JargonTerm(
            term: "Cloud CDN",
            analogy: "Chain of Corner Stores",
            symbolName: "network",
            explanation: "Copies of your files stored in locations around the world, like a chain of corner stores so nobody has to travel far to get what they need."
        ),
        JargonTerm(
            term: "Budget",
            analogy: "Spending Cap",
            symbolName: "chart.pie.fill",
            explanation: "A dollar limit you set for cloud spending in a given period, like a spending cap on a card that flags you before you go over."
        ),
        JargonTerm(
            term: "Alert Threshold",
            analogy: "Tripwire",
            symbolName: "bell.and.waves.left.and.right.fill",
            explanation: "The percentage of your budget that triggers a warning, like a tripwire set partway across a room so you get notice before reaching the end."
        ),

        // MARK: Apple (round 2 expansion)
        JargonTerm(term: "Apple Developer Program", analogy: "Business License", symbolName: "person.badge.key.fill", explanation: "It's the paid membership that lets you publish apps and use Apple's developer tools — like a business license that says you're allowed to operate."),
        JargonTerm(term: "Certificate Signing Request", analogy: "Notarized Request Letter", symbolName: "doc.text.magnifyingglass", explanation: "It's a file that proves a specific key is yours, which you hand to Apple so they can issue you a matching certificate — like mailing in a notarized request before getting an official seal."),
        JargonTerm(term: "Distribution Certificate", analogy: "Official Seal", symbolName: "seal.fill", explanation: "It's Apple's proof that a build really came from you, stamped onto every app you send out for testing or the App Store."),
        JargonTerm(term: "Signing Identity", analogy: "ID Badge and Key Together", symbolName: "person.text.rectangle.fill", explanation: "It's the paired certificate and private key that let your Mac prove, cryptographically, that it's really you signing the app."),
        JargonTerm(term: "Pass Type ID", analogy: "Pass Category Label", symbolName: "tag.fill", explanation: "It's the unique label that tells Wallet which app owns a pass, similar to how a barcode prefix tells a scanner which store issued a coupon."),
        JargonTerm(term: "Widget Extension", analogy: "Mini App-Within-an-App", symbolName: "square.grid.2x2", explanation: "It's a small, separate piece of your app that the system runs on its own just to draw the widget, like a satellite office that only handles one task."),
        JargonTerm(term: "Timeline Provider", analogy: "Broadcast Schedule", symbolName: "clock.arrow.circlepath", explanation: "It's the code that tells the system what your widget should show and when to refresh it, like a TV station's programming schedule."),
        JargonTerm(term: "App Clip", analogy: "Sample-Size App", symbolName: "bolt.circle", explanation: "It's a tiny, fast-loading slice of your full app that people can try instantly without installing anything, like a free sample at a store counter."),
        JargonTerm(term: "Invocation URL", analogy: "Trigger Link", symbolName: "link.circle.fill", explanation: "It's the specific web address that tells the phone to launch your App Clip instead of opening a regular browser page."),
        JargonTerm(term: "Game Center", analogy: "Arcade Scoreboard Network", symbolName: "gamecontroller.fill", explanation: "It's Apple's built-in system for player profiles, scores, and achievements, like a shared scoreboard wall that every game in an arcade can post to."),
        JargonTerm(term: "Leaderboard", analogy: "High Score List", symbolName: "list.number", explanation: "It's a ranked list of player scores that Apple stores and displays for you, just like the high score list on an arcade cabinet."),
        JargonTerm(term: "Achievement", analogy: "Merit Badge", symbolName: "rosette", explanation: "It's a milestone Apple tracks and displays for a player, like a merit badge earned for reaching a goal in your game."),
        JargonTerm(term: "Family Sharing", analogy: "Shared Household Account", symbolName: "person.3.fill", explanation: "It lets one person's purchase — including a subscription — be used by up to five family members for free, like a household streaming plan."),
        JargonTerm(term: "Offer Code", analogy: "Redeemable Coupon Code", symbolName: "gift.fill", explanation: "It's a code you generate and hand out that unlocks a special subscription deal when someone types it in, like a coupon code at checkout."),
        JargonTerm(term: "Pre-Order", analogy: "Reserve-Your-Copy Line", symbolName: "calendar.badge.clock", explanation: "It lets people reserve your app before it's released, so it downloads automatically the moment it launches, like reserving a copy of a book before its release date."),
        JargonTerm(term: "Notification Category", analogy: "Notification Template", symbolName: "bell.square.fill", explanation: "It's a named group of buttons you define once, then attach to any notification that needs those same quick actions, like a form template you reuse."),
        JargonTerm(term: "Notification Action", analogy: "Quick-Reply Button", symbolName: "hand.tap.fill", explanation: "It's a single tappable button — like Reply or Mark Done — that shows up right on a notification banner so people don't have to open the app."),
        JargonTerm(term: "Record Type", analogy: "Spreadsheet Template", symbolName: "tablecells.fill", explanation: "It defines what fields a piece of data has in CloudKit, similar to setting up column headers before you start filling in a spreadsheet."),
        JargonTerm(term: "Queryable Index", analogy: "Book's Index Page", symbolName: "text.magnifyingglass", explanation: "It marks a field as fast to search, similar to how a book's index lets you jump straight to a topic instead of reading every page."),

        // MARK: Microsoft (round 2 expansion)
        JargonTerm(
            term: "Security Group",
            analogy: "Group Locker",
            symbolName: "person.3.fill",
            explanation: "A security group is one locker that holds a whole team, so you can hand every member the same key at once instead of cutting a new one each time."
        ),
        JargonTerm(
            term: "Dynamic Membership Rule",
            analogy: "Auto-Sorting Mailroom",
            symbolName: "wand.and.stars",
            explanation: "A dynamic membership rule sorts people into a group automatically based on facts like their department, so nobody has to add them by hand."
        ),
        JargonTerm(
            term: "Shared Mailbox",
            analogy: "Team Inbox",
            symbolName: "envelope.fill",
            explanation: "A shared mailbox is one inbox the whole team can open, like a front desk phone everyone can answer, without anyone owning or sharing a password."
        ),
        JargonTerm(
            term: "Send As Permission",
            analogy: "Signing Authority",
            symbolName: "signature",
            explanation: "Send As permission lets someone reply from a shared address as if it were their own, the way an assistant might sign a boss's name on a letter."
        ),
        JargonTerm(
            term: "App Service Plan",
            analogy: "Apartment Building Lease",
            symbolName: "building.2.fill",
            explanation: "An App Service Plan is the lease that decides how much space and power your web app's building gets, and how much it costs each month."
        ),
        JargonTerm(
            term: "Deployment Slot",
            analogy: "Rehearsal Stage",
            symbolName: "theatermasks.fill",
            explanation: "A deployment slot is a practice copy of your site where you can run a dress rehearsal before swapping it in front of the real audience."
        ),
        JargonTerm(
            term: "Log Analytics Workspace",
            analogy: "Flight Recorder",
            symbolName: "waveform.path.ecg.rectangle.fill",
            explanation: "A Log Analytics workspace is the black box that quietly records everything happening in your app, so you can play it back when something goes wrong."
        ),
        JargonTerm(
            term: "Alert Rule",
            analogy: "Tripwire",
            symbolName: "bell.badge.fill",
            explanation: "An alert rule is a tripwire you set across a metric, so the moment something crosses the line you set, it sounds an alarm."
        ),
        JargonTerm(
            term: "Action Group",
            analogy: "Phone Tree",
            symbolName: "person.2.wave.2.fill",
            explanation: "An action group is the phone tree an alert calls down, the list of people and methods used to spread the word fast."
        ),
        JargonTerm(
            term: "Compliance Policy",
            analogy: "Bouncer's Checklist",
            symbolName: "checkmark.seal.fill",
            explanation: "A compliance policy is the checklist a bouncer runs down before letting a device in the door, like requiring a passcode or up-to-date software."
        ),
        JargonTerm(
            term: "Redirect URI",
            analogy: "Return Address",
            symbolName: "arrow.uturn.backward.circle.fill",
            explanation: "A redirect URI is the return address you give Microsoft so it knows exactly where to send someone back after they finish signing in."
        ),
        JargonTerm(
            term: "Client Secret",
            analogy: "Secret Handshake",
            symbolName: "key.fill",
            explanation: "A client secret is a private handshake your app uses to prove to Microsoft that it's really the app it claims to be."
        ),
        JargonTerm(
            term: "Canvas App",
            analogy: "Blank Poster Board",
            symbolName: "square.and.pencil",
            explanation: "A canvas app starts as a blank poster board you can arrange freely, dragging on buttons and boxes wherever you want them."
        ),
        JargonTerm(
            term: "Virtual Network",
            analogy: "Gated Neighborhood",
            symbolName: "network",
            explanation: "A virtual network is a gated neighborhood in the cloud where only the houses inside can talk to each other directly."
        ),
        JargonTerm(
            term: "Network Security Group",
            analogy: "Neighborhood Watch List",
            symbolName: "shield.lefthalf.filled",
            explanation: "A network security group is the watch list that decides exactly which visitors are allowed to knock on which doors in your neighborhood."
        ),
        JargonTerm(
            term: "Container Registry",
            analogy: "Shipping Container Depot",
            symbolName: "shippingbox.fill",
            explanation: "A container registry is a depot that stores packaged, ready-to-ship copies of your app so they can be picked up and run anywhere."
        ),
        JargonTerm(
            term: "Calling Plan",
            analogy: "Phone Line Subscription",
            symbolName: "phone.circle.fill",
            explanation: "A calling plan is the subscription that connects your Teams app to the regular phone network, the same way a phone line plugs into a wall."
        ),
        JargonTerm(
            term: "Auto Attendant",
            analogy: "Robot Receptionist",
            symbolName: "questionmark.bubble.fill",
            explanation: "An auto attendant is a robot receptionist that greets callers and routes them to the right person without a human picking up first."
        ),
        JargonTerm(
            term: "Retention Label",
            analogy: "Keep-or-Shred Sticker",
            symbolName: "tag.fill",
            explanation: "A retention label is a sticker put on a file or email that says how long to keep it before it's automatically shredded or locked in place."
        ),
        JargonTerm(
            term: "Retention Policy",
            analogy: "Filing Cabinet Rule",
            symbolName: "clock.arrow.circlepath",
            explanation: "A retention policy is the standing rule for a whole filing cabinet, applying the same keep-or-delete timeline to everything inside automatically."
        ),

        // MARK: Amazon (round 2 expansion)
        JargonTerm(
            term: "Origin",
            analogy: "Warehouse Behind the Storefront",
            symbolName: "building.columns.fill",
            explanation: "The origin is where your website's real files actually live; CloudFront is just the storefront that hands out fast copies of what's kept in the warehouse."
        ),
        JargonTerm(
            term: "Hosted Zone",
            analogy: "Domain's Filing Folder",
            symbolName: "folder.fill",
            explanation: "A hosted zone is the folder Route 53 keeps all of one domain's DNS records in, so everything about that domain lives in one place."
        ),
        JargonTerm(
            term: "Deployment Stage",
            analogy: "Published Edition",
            symbolName: "arrow.up.doc.fill",
            explanation: "A stage is a live, published version of your API, like 'production' — changes you make don't affect visitors until you deploy to that stage."
        ),
        JargonTerm(
            term: "User Pool",
            analogy: "Sign-In Directory",
            symbolName: "person.3.fill",
            explanation: "A user pool is the directory that stores every account created for your app, along with their passwords and profile details."
        ),
        JargonTerm(
            term: "App Client",
            analogy: "App's Access Badge",
            symbolName: "rectangle.badge.checkmark",
            explanation: "An app client is the specific badge you register for each app or website so it's allowed to ask the user pool to sign people in."
        ),
        JargonTerm(
            term: "Stack Template",
            analogy: "Build Blueprint",
            symbolName: "ruler.fill",
            explanation: "A stack template is a written blueprint listing every resource you want built, so CloudFormation can follow it exactly instead of you clicking through each one."
        ),
        JargonTerm(
            term: "CloudFormation Stack",
            analogy: "Completed Build",
            symbolName: "building.2.crop.circle.fill",
            explanation: "A stack is the finished set of resources CloudFormation created from your template, managed together as one unit you can update or delete at once."
        ),
        JargonTerm(
            term: "Verified Identity",
            analogy: "Confirmed Return Address",
            symbolName: "checkmark.seal.fill",
            explanation: "A verified identity is a domain or email address you've proven you own, so SES will trust you to send mail as that sender."
        ),
        JargonTerm(
            term: "Sandbox Mode",
            analogy: "Training Wheels",
            symbolName: "figure.walk",
            explanation: "Sandbox mode limits a brand-new SES account to only emailing addresses you've personally verified, until AWS confirms you're a legitimate sender."
        ),
        JargonTerm(
            term: "Event Bus",
            analogy: "Delivery Conveyor Belt",
            symbolName: "arrow.left.arrow.right.circle.fill",
            explanation: "An event bus is the conveyor belt that carries events from wherever they happen to whatever's waiting to react to them."
        ),
        JargonTerm(
            term: "Event Pattern",
            analogy: "Description on a Wanted Poster",
            symbolName: "doc.text.magnifyingglass",
            explanation: "An event pattern describes exactly what an event has to look like to match, so only the events you care about trigger your rule."
        ),
        JargonTerm(
            term: "Spending Threshold",
            analogy: "Tripwire on Your Wallet",
            symbolName: "exclamationmark.triangle.fill",
            explanation: "A spending threshold is the dollar line that, once crossed, sends you a warning before your bill gets any bigger."
        ),
        JargonTerm(
            term: "Target Group",
            analogy: "Roster of On-Duty Servers",
            symbolName: "list.bullet.rectangle.fill",
            explanation: "A target group is the list of servers a load balancer is allowed to send traffic to, so it knows exactly who's available to help."
        ),
        JargonTerm(
            term: "SSM Parameter",
            analogy: "Labeled Settings Card",
            symbolName: "note.text",
            explanation: "An SSM parameter is a single named setting stored outside your code, so you can change it without touching or redeploying your app."
        ),
        JargonTerm(
            term: "Web ACL",
            analogy: "Bouncer's Rulebook",
            symbolName: "list.clipboard.fill",
            explanation: "A web ACL is the rulebook a firewall checks every incoming request against before deciding to let it through or turn it away."
        ),
        JargonTerm(
            term: "Task Definition",
            analogy: "Container's Instruction Card",
            symbolName: "doc.plaintext.fill",
            explanation: "A task definition spells out exactly which container to run and how much memory and power to give it, like an instruction card for the machine running it."
        ),
        JargonTerm(
            term: "ECS Cluster",
            analogy: "Shared Loading Dock",
            symbolName: "square.grid.3x3.fill",
            explanation: "A cluster is the shared space where your containers actually run, whether that's servers you manage or ones AWS manages for you."
        ),
        JargonTerm(
            term: "Organizational Unit",
            analogy: "Department Folder",
            symbolName: "square.stack.3d.up.fill",
            explanation: "An organizational unit groups related AWS accounts together, like a department folder, so you can apply the same rules to all of them at once."
        ),
        JargonTerm(
            term: "Service Control Policy",
            analogy: "House Rules for Every Account",
            symbolName: "checkmark.shield.fill",
            explanation: "A service control policy sets hard limits on what any account in the group is allowed to do, even if that account's own admin says yes."
        ),

        // MARK: Universal (round 3 expansion)
        JargonTerm(
            term: "Full-Disk Encryption",
            analogy: "Whole-House Safe",
            symbolName: "lock.laptopcomputer",
            explanation: "Scrambles everything on your drive so it's unreadable without the right key, like putting your entire house inside a safe instead of just one drawer."
        ),
        JargonTerm(
            term: "Recovery Key",
            analogy: "Spare House Key",
            symbolName: "key.fill",
            explanation: "A backup key that unlocks your encrypted drive if you ever forget your password, the same way a spare key gets you back into a locked house."
        ),
        JargonTerm(
            term: "Filter Rule",
            analogy: "Mailroom Instruction Card",
            symbolName: "line.3.horizontal.decrease.circle",
            explanation: "A custom instruction that tells your inbox what to do with mail matching certain words or senders, like a note left for the mailroom."
        ),
        JargonTerm(
            term: "Blocklist",
            analogy: "Do Not Admit List",
            symbolName: "hand.raised.slash",
            explanation: "A list of senders or sites that are automatically turned away, the same way a bouncer keeps troublemakers off the guest list."
        ),
        JargonTerm(
            term: "Safe Sender List",
            analogy: "VIP Guest List",
            symbolName: "checkmark.seal",
            explanation: "A list of senders who are always let straight through, like guests who skip the line because they're on the VIP list."
        ),
        JargonTerm(
            term: "404 Error",
            analogy: "Wrong Address Notice",
            symbolName: "exclamationmark.magnifyingglass",
            explanation: "The message a website shows when a visitor asks for a page that doesn't exist, like a delivery notice saying no such address."
        ),
        JargonTerm(
            term: "Broken Link",
            analogy: "Dead-End Street Sign",
            symbolName: "link.badge.plus",
            explanation: "A link that points to a page that's moved or disappeared, leaving visitors at a dead end."
        ),
        JargonTerm(
            term: "Status Page",
            analogy: "Storefront Hours Sign",
            symbolName: "chart.bar.xaxis",
            explanation: "A public page that shows whether your service is running normally, like the sign in a shop window announcing open or closed."
        ),
        JargonTerm(
            term: "Incident Update",
            analogy: "Bulletin Board Notice",
            symbolName: "megaphone",
            explanation: "A short public note posted when something breaks, keeping users informed the way a bulletin board keeps a building's tenants updated."
        ),
        JargonTerm(
            term: "Clipboard Sync",
            analogy: "Shared Notepad",
            symbolName: "doc.on.clipboard",
            explanation: "A feature that copies whatever you last cut or copied to all your signed-in devices, like leaving the same note on every desk you work at."
        ),
        JargonTerm(
            term: "Paste History",
            analogy: "Notepad's Torn-Off Pages",
            symbolName: "list.clipboard",
            explanation: "A running log of things you've recently copied, so you can pull one back even after copying something new, like flipping back through torn-off notepad pages."
        ),
        JargonTerm(
            term: "Tracker",
            analogy: "Hidden Tail",
            symbolName: "eye.trianglebadge.exclamationmark",
            explanation: "A small piece of code that quietly follows what you do across websites, like someone tailing you from store to store."
        ),
        JargonTerm(
            term: "Content Blocker",
            analogy: "Doorman",
            symbolName: "shield.checkerboard",
            explanation: "A browser add-on that stops ads and trackers from loading in the first place, acting like a doorman who turns away unwanted visitors before they get inside."
        ),
        JargonTerm(
            term: "Backup Code",
            analogy: "Spare Set Of Keys In A Drawer",
            symbolName: "list.number",
            explanation: "A one-time-use code you generate ahead of time so you can still get into an account if you lose access to your usual second-factor device."
        ),
        JargonTerm(
            term: "End-to-End Encryption",
            analogy: "Sealed Envelope",
            symbolName: "envelope.badge.shield.half.filled",
            explanation: "Scrambles your notes so only you can read them, even the company storing them, like mailing a letter in a sealed envelope only you hold the key to."
        ),
        JargonTerm(
            term: "Zero-Knowledge Encryption",
            analogy: "Blind Storage Locker Attendant",
            symbolName: "eye.slash",
            explanation: "A setup where even the app maker can't see your content, like a storage facility attendant who holds your locker key but never has one of their own."
        ),
        JargonTerm(
            term: "Open Graph Tag",
            analogy: "Shipping Label",
            symbolName: "tag",
            explanation: "A hidden bit of code on a webpage that tells apps what title, image, and description to show when the link is shared, like a shipping label describing what's inside a box before it's opened."
        ),
        JargonTerm(
            term: "Meta Tag",
            analogy: "Book Jacket Blurb",
            symbolName: "text.book.closed",
            explanation: "A short snippet of hidden text describing a page's content, similar to the summary printed on the back of a book's jacket."
        ),
        JargonTerm(
            term: "Payment Link",
            analogy: "Tip Jar On The Counter",
            symbolName: "link.circle",
            explanation: "A single shareable web address that opens a simple checkout for sending money, like setting a tip jar on the counter for anyone to drop something in."
        ),
        JargonTerm(
            term: "Payout Account",
            analogy: "Cash Register Drawer",
            symbolName: "banknote",
            explanation: "The bank or card account connected to a payment service so money collected actually lands somewhere you can use it, like the drawer a cash register empties into."
        ),
        JargonTerm(
            term: "Patch",
            analogy: "Fabric Patch Over A Tear",
            symbolName: "bandage",
            explanation: "A small update that fixes a specific bug or security hole in software, the same way a fabric patch mends a tear without replacing the whole garment."
        ),
        JargonTerm(
            term: "Background Update",
            analogy: "Overnight Restocking",
            symbolName: "moon.zzz",
            explanation: "An update that installs itself quietly while you're not using the device, like a store restocking its shelves overnight before customers arrive."
        ),
        JargonTerm(
            term: "WPA3",
            analogy: "Newest Lock Model",
            symbolName: "wifi.circle",
            explanation: "The current standard for scrambling Wi-Fi traffic so nearby strangers can't read it, like upgrading your front door to the newest, hardest-to-pick lock model."
        ),
        JargonTerm(
            term: "Remote Management",
            analogy: "Off-Site Control Panel",
            symbolName: "antenna.radiowaves.left.and.right",
            explanation: "A setting that lets a router's controls be reached from outside your home network, similar to an off-site panel that could let someone adjust your building's systems from anywhere."
        ),
        JargonTerm(
            term: "Storage Quota",
            analogy: "Storage Unit Size",
            symbolName: "internaldrive",
            explanation: "The total amount of space an account is allowed to fill before it's full, like the size limit stamped on a rented storage unit."
        ),
        JargonTerm(
            term: "Dormant Account",
            analogy: "Abandoned Storage Unit",
            symbolName: "moon.zzz.fill",
            explanation: "An account you signed up for but haven't used in a long time, sitting around like a storage unit nobody's opened in years yet still holds your stuff."
        ),

        // MARK: Google (round 3 expansion)
        JargonTerm(
            term: "Event Parameter",
            analogy: "Detail Tag",
            symbolName: "tag",
            explanation: "An Event Parameter is an extra detail attached to a tracked event, like noting which button color someone clicked instead of just recording that a click happened."
        ),
        JargonTerm(
            term: "Custom Event",
            analogy: "Custom Alarm",
            symbolName: "bell.badge",
            explanation: "A Custom Event is a specific action you define for Analytics to watch for, such as a signup or a video play, instead of relying only on automatic page views."
        ),
        JargonTerm(
            term: "URL Inspection Tool",
            analogy: "Page X-Ray",
            symbolName: "doc.text.magnifyingglass",
            explanation: "The URL Inspection Tool checks exactly how Google currently sees one specific page, including when it was last crawled and whether it's indexed."
        ),
        JargonTerm(
            term: "Crawl",
            analogy: "Google's Visit",
            symbolName: "figure.walk",
            explanation: "A Crawl is an automated visit where Google's software reads through your page to understand what's on it before deciding whether to index it."
        ),
        JargonTerm(
            term: "Testing Track",
            analogy: "Rehearsal Stage",
            symbolName: "theatermasks",
            explanation: "A Testing Track is a private release channel that lets a small group try your app before it ever reaches the public store listing."
        ),
        JargonTerm(
            term: "Tester List",
            analogy: "Guest List",
            symbolName: "person.2.badge.gearshape",
            explanation: "A Tester List is the group of email addresses allowed into a testing track, similar to a guest list for a private event."
        ),
        JargonTerm(
            term: "App Bundle",
            analogy: "Master Package",
            symbolName: "shippingbox",
            explanation: "An App Bundle is the single packaged file you upload to Play Console, which then splits it into optimized installers for each type of device."
        ),
        JargonTerm(
            term: "Pub/Sub Topic",
            analogy: "Announcement Board",
            symbolName: "megaphone",
            explanation: "A Pub/Sub Topic is a central place where messages get posted so any number of other services can pick them up without talking to each other directly."
        ),
        JargonTerm(
            term: "Publisher",
            analogy: "Announcer",
            symbolName: "person.wave.2",
            explanation: "A Publisher is whichever part of your system posts messages to a topic, like a person making an announcement over a loudspeaker."
        ),
        JargonTerm(
            term: "Pub/Sub Subscription",
            analogy: "Mailing List Signup",
            symbolName: "envelope.badge",
            explanation: "A Pub/Sub Subscription is a listener's registered way of receiving every message posted to a topic, similar to signing up for a mailing list."
        ),
        JargonTerm(
            term: "Cloud SQL Instance",
            analogy: "Rented Database Server",
            symbolName: "cylinder.split.1x2",
            explanation: "A Cloud SQL Instance is a fully managed database server you rent, so you don't have to install or maintain the database software yourself."
        ),
        JargonTerm(
            term: "Connection Name",
            analogy: "Mailing Address",
            symbolName: "at",
            explanation: "A Connection Name is the unique address your app uses to find and connect to one specific database instance."
        ),
        JargonTerm(
            term: "Scheduled Job",
            analogy: "Alarm Clock Task",
            symbolName: "clock.badge",
            explanation: "A Scheduled Job is a task that runs itself automatically on a timer, without anyone needing to kick it off by hand."
        ),
        JargonTerm(
            term: "Cron Expression",
            analogy: "Alarm Clock Code",
            symbolName: "timer",
            explanation: "A Cron Expression is a compact pattern of numbers and symbols that describes exactly when a scheduled job should fire."
        ),
        JargonTerm(
            term: "Document Path",
            analogy: "File Path",
            symbolName: "folder",
            explanation: "A Document Path is the address that points to one specific record inside a Firestore database, similar to a file path on a computer."
        ),
        JargonTerm(
            term: "Remote Config Parameter",
            analogy: "Remote Dial",
            symbolName: "slider.horizontal.3",
            explanation: "A Remote Config Parameter is a named setting your app checks in on, letting you change its behavior remotely without shipping a new update."
        ),
        JargonTerm(
            term: "Targeting Condition",
            analogy: "Guest List Rule",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "A Targeting Condition decides which users get a particular value for a setting, such as only people on a newer version of the app."
        ),
        JargonTerm(
            term: "Vault Matter",
            analogy: "Case File",
            symbolName: "folder.badge.person.crop",
            explanation: "A Vault Matter is a folder that groups together all the content related to one specific investigation, audit, or legal case."
        ),
        JargonTerm(
            term: "Legal Hold",
            analogy: "Do Not Delete Order",
            symbolName: "hand.raised",
            explanation: "A Legal Hold preserves content automatically, even if a user or IT admin tries to delete it, because it may be relevant to a case."
        ),
        JargonTerm(
            term: "Remarketing Audience",
            analogy: "Recognized Visitor List",
            symbolName: "person.crop.circle.badge.clock",
            explanation: "A Remarketing Audience is a list of people who already visited your site, so you can show them ads instead of starting over with strangers."
        ),
        JargonTerm(
            term: "Frequency Cap",
            analogy: "Repeat Limit",
            symbolName: "repeat.circle",
            explanation: "A Frequency Cap limits how many times a single person can be shown the same ad in a given period, so it doesn't wear out its welcome."
        ),
        JargonTerm(
            term: "Backend Service",
            analogy: "Server Group",
            symbolName: "server.rack",
            explanation: "A Backend Service is the group of servers a load balancer spreads incoming requests across so no single machine gets overwhelmed."
        ),
        JargonTerm(
            term: "Forwarding Rule",
            analogy: "Traffic Sign",
            symbolName: "signpost.right",
            explanation: "A Forwarding Rule tells incoming requests which address and port should lead them to your load balancer."
        ),
        JargonTerm(
            term: "Client ID",
            analogy: "App's ID Badge",
            symbolName: "person.text.rectangle",
            explanation: "A Client ID is the public identifier your app uses to tell Google which app is asking to sign someone in."
        ),
        JargonTerm(
            term: "ID Token",
            analogy: "Signed ID Card",
            symbolName: "checkmark.seal",
            explanation: "An ID Token is a signed proof of identity handed back after sign-in, which your server checks before trusting that the login is genuine."
        ),
        JargonTerm(
            term: "Calculated Field",
            analogy: "Formula Column",
            symbolName: "function",
            explanation: "A Calculated Field is a custom column built from a formula that combines or transforms other fields, like turning raw counts into a percentage."
        ),
        JargonTerm(
            term: "Filter Control",
            analogy: "Dashboard Dial",
            symbolName: "slider.horizontal.below.rectangle",
            explanation: "A Filter Control is an interactive widget on a dashboard that lets a viewer narrow down what data is shown, like picking a date range."
        ),

        // MARK: Apple (round 3 expansion)
        JargonTerm(
            term: "Crash Report",
            analogy: "Accident Report",
            symbolName: "exclamationmark.triangle",
            explanation: "A crash report is a record of exactly what your app was doing the moment it broke, so you can figure out what went wrong."
        ),
        JargonTerm(
            term: "Symbolication",
            analogy: "Translating Code Names Back to Real Names",
            symbolName: "text.magnifyingglass",
            explanation: "Symbolication turns a crash report's cryptic memory addresses back into the actual function and file names from your code."
        ),
        JargonTerm(
            term: "Beta Feedback",
            analogy: "Sticky Notes from Testers",
            symbolName: "text.bubble",
            explanation: "Beta feedback is the notes and screenshots testers send you straight from TestFlight when something looks off."
        ),
        JargonTerm(
            term: "Transaction Receipt",
            analogy: "Digital Sales Slip",
            symbolName: "doc.text",
            explanation: "A transaction receipt is Apple's proof that a specific purchase really happened, which your server can check before unlocking anything."
        ),
        JargonTerm(
            term: "JWS Signature",
            analogy: "Wax Seal on a Letter",
            symbolName: "seal",
            explanation: "A JWS signature is a cryptographic seal Apple stamps on data so you can be sure it wasn't altered or faked along the way."
        ),
        JargonTerm(
            term: "Server Notification",
            analogy: "Text Alert from the Bank",
            symbolName: "bell.badge",
            explanation: "A server notification is a message Apple sends straight to your backend the moment a subscription event happens, like a renewal or cancellation."
        ),
        JargonTerm(
            term: "Webhook Endpoint",
            analogy: "Mailbox for Automatic Messages",
            symbolName: "envelope.badge",
            explanation: "A webhook endpoint is a URL on your own server built to automatically receive messages from another service, like Apple, the moment something happens."
        ),
        JargonTerm(
            term: "HealthKit",
            analogy: "Shared Medical Filing Cabinet",
            symbolName: "heart.text.square",
            explanation: "HealthKit is the system on iPhone that stores a person's health data so different apps can read and add to it with permission."
        ),
        JargonTerm(
            term: "Entitlement",
            analogy: "Backstage Pass",
            symbolName: "checkmark.seal",
            explanation: "An entitlement is a special permission you switch on in Xcode that unlocks access to a protected system feature, like HealthKit or Handoff."
        ),
        JargonTerm(
            term: "Health Record Type",
            analogy: "Category on a Medical Chart",
            symbolName: "list.clipboard",
            explanation: "A health record type is one specific kind of health data, like step count or sleep hours, that you can ask permission to read or write."
        ),
        JargonTerm(
            term: "App Intent",
            analogy: "Menu Item Siri Can Order For You",
            symbolName: "mic.circle",
            explanation: "An App Intent is a specific action your app exposes so Siri, Shortcuts, and Spotlight can trigger it on the user's behalf."
        ),
        JargonTerm(
            term: "Shortcuts App",
            analogy: "Universal Remote for Your Apps",
            symbolName: "square.stack.3d.up",
            explanation: "The Shortcuts app lets people chain together actions from different apps, including yours, into one tap or voice command."
        ),
        JargonTerm(
            term: "Live Activity",
            analogy: "Scoreboard That Updates Itself",
            symbolName: "bolt.badge.clock",
            explanation: "A Live Activity is a small, live-updating view on the Lock Screen that shows an ongoing event without the person opening your app."
        ),
        JargonTerm(
            term: "Dynamic Island",
            analogy: "Pop-Up Status Window",
            symbolName: "circle.grid.2x2",
            explanation: "The Dynamic Island is the shape-shifting area at the top of newer iPhones where Live Activities can show a compact live status."
        ),
        JargonTerm(
            term: "ActivityKit",
            analogy: "Toolkit for Building Live Activities",
            symbolName: "wrench.and.screwdriver",
            explanation: "ActivityKit is the set of tools Apple provides for building, starting, and updating a Live Activity from your app."
        ),
        JargonTerm(
            term: "Push Token",
            analogy: "Return Address for Push Messages",
            symbolName: "arrow.up.message",
            explanation: "A push token is a unique address Apple hands your app so your server knows exactly where to deliver a remote update."
        ),
        JargonTerm(
            term: "Age Rating Questionnaire",
            analogy: "Movie Rating Form",
            symbolName: "person.2.badge.gearshape",
            explanation: "The age rating questionnaire is a form you fill out about your app's content so the App Store can assign it an appropriate age rating."
        ),
        JargonTerm(
            term: "Content Descriptor",
            analogy: "Warning Label on the Box",
            symbolName: "exclamationmark.bubble",
            explanation: "A content descriptor is a specific flag, like mild violence or user-generated content, that explains why an app received its age rating."
        ),
        JargonTerm(
            term: "In-App Event",
            analogy: "Flyer for What's Happening Now",
            symbolName: "calendar.badge.clock",
            explanation: "An in-app event is a scheduled happening inside your app, like a tournament or premiere, that you can promote directly on the App Store."
        ),
        JargonTerm(
            term: "Event Card",
            analogy: "Poster in the Store Window",
            symbolName: "rectangle.stack.badge.play",
            explanation: "An event card is the image, title, and short description that represents your in-app event when people see it in the App Store."
        ),
        JargonTerm(
            term: "Custom Product Page",
            analogy: "Alternate Storefront Display",
            symbolName: "rectangle.on.rectangle",
            explanation: "A custom product page is a variant of your App Store listing with different screenshots or text, used to test what convinces more people to download."
        ),
        JargonTerm(
            term: "Product Page Optimization",
            analogy: "Split Test at the Storefront",
            symbolName: "chart.bar.xaxis",
            explanation: "Product page optimization is a built-in A/B test that shows different visitors different versions of your listing to see which one performs better."
        ),
        JargonTerm(
            term: "Apple Business Manager",
            analogy: "Company IT Front Desk",
            symbolName: "building.2",
            explanation: "Apple Business Manager is the web portal companies use to buy apps in bulk and set up devices for employees automatically."
        ),
        JargonTerm(
            term: "Managed Apple ID",
            analogy: "Work Badge Instead of a Personal Key",
            symbolName: "person.badge.key",
            explanation: "A managed Apple ID is an account an organization creates and controls for an employee, kept separate from that person's personal Apple ID."
        ),
        JargonTerm(
            term: "MDM",
            analogy: "Remote Control for Company Devices",
            symbolName: "gearshape.2",
            explanation: "MDM, short for mobile device management, is software that lets a company configure, monitor, and lock down devices from a distance."
        ),
        JargonTerm(
            term: "MapKit JS",
            analogy: "Apple Maps Widget for Your Website",
            symbolName: "map",
            explanation: "MapKit JS is Apple's toolkit for embedding a real, interactive Apple Maps view directly into a webpage."
        ),
        JargonTerm(
            term: "Maps Token",
            analogy: "Timed Visitor Badge",
            symbolName: "ticket",
            explanation: "A maps token is a temporary, signed pass your website presents to prove it's allowed to load an Apple Maps view."
        ),
        JargonTerm(
            term: "Handoff",
            analogy: "Baton Pass Between Devices",
            symbolName: "arrow.triangle.2.circlepath.circle",
            explanation: "Handoff lets someone start a task on one Apple device and continue it instantly on another, without saving or emailing anything to themselves."
        ),
        JargonTerm(
            term: "iCloud Account",
            analogy: "Shared Household Key",
            symbolName: "icloud",
            explanation: "An iCloud account is the single sign-in that links a person's Apple devices together so features like Handoff know they belong to the same owner."
        ),
        JargonTerm(
            term: "Notification Type",
            analogy: "Category of Mail in the Inbox",
            symbolName: "tray.full",
            explanation: "A notification type is the specific kind of event, like a new review or a canceled subscription, that a webhook can be set up to receive."
        ),

        // MARK: Microsoft (round 3 expansion)
        JargonTerm(
            term: "Cloud Discovery",
            analogy: "Security Camera Sweep",
            symbolName: "magnifyingglass.circle.fill",
            explanation: "Cloud Discovery scans your network traffic to reveal every app people are using, even the ones nobody officially approved."
        ),
        JargonTerm(
            term: "Shadow IT",
            analogy: "Unlisted Side Door",
            symbolName: "eye.slash.fill",
            explanation: "Shadow IT is any app or service employees use without IT's knowledge or approval, creating a blind spot for security."
        ),
        JargonTerm(
            term: "Activity Policy",
            analogy: "Tripwire Alarm",
            symbolName: "doc.text.magnifyingglass",
            explanation: "An Activity Policy watches for a specific kind of behavior and automatically takes action, like blocking a suspicious download, the moment it happens."
        ),
        JargonTerm(
            term: "Anomaly Detection",
            analogy: "Odd-One-Out Spotter",
            symbolName: "waveform.path.ecg",
            explanation: "Anomaly Detection compares new activity against normal patterns and flags anything that looks out of place, like an impossible travel sign-in."
        ),
        JargonTerm(
            term: "Function App",
            analogy: "Rental Kitchen",
            symbolName: "app.badge",
            explanation: "A Function App is the lightweight container that hosts and runs your code, without you ever managing the underlying server."
        ),
        JargonTerm(
            term: "Serverless",
            analogy: "Taxi Instead of Owning a Car",
            symbolName: "cloud.fill",
            explanation: "Serverless means your code runs on-demand in the cloud, and you never have to set up or maintain a server yourself."
        ),
        JargonTerm(
            term: "Consumption Plan",
            analogy: "Pay-Per-Ride Ticket",
            symbolName: "dollarsign.circle.fill",
            explanation: "A Consumption Plan charges you only for the exact time your code is running, instead of a flat fee for a server sitting idle."
        ),
        JargonTerm(
            term: "Function Trigger",
            analogy: "Doorbell",
            symbolName: "bolt.fill",
            explanation: "A Function Trigger is the event, like a new file or a timer, that wakes your code up and tells it to run."
        ),
        JargonTerm(
            term: "Logic App",
            analogy: "Domino Chain",
            symbolName: "arrow.triangle.merge",
            explanation: "A Logic App is a visual, no-code workflow where you snap steps together instead of writing a program line by line."
        ),
        JargonTerm(
            term: "Action Step",
            analogy: "Recipe Instruction",
            symbolName: "list.number",
            explanation: "An Action Step is one task in a Logic App's sequence, running automatically after the step before it finishes."
        ),
        JargonTerm(
            term: "Loop Workspace",
            analogy: "Shared Whiteboard Room",
            symbolName: "square.stack.3d.up.fill",
            explanation: "A Loop Workspace is a shared space where a team's pages and components all live together and stay in sync."
        ),
        JargonTerm(
            term: "Loop Component",
            analogy: "Magic Sticky Note",
            symbolName: "square.on.square",
            explanation: "A Loop Component is a piece of content, like a table or list, that updates everywhere it's been pasted the instant anyone edits it."
        ),
        JargonTerm(
            term: "Viva Engage Community",
            analogy: "Town Square",
            symbolName: "bubble.left.and.text.bubble.right.fill",
            explanation: "A Viva Engage Community is a shared space where employees across the company can post, ask questions, and connect."
        ),
        JargonTerm(
            term: "Community Leader",
            analogy: "Group Moderator",
            symbolName: "star.circle.fill",
            explanation: "A Community Leader keeps a Viva Engage Community active and on-topic, welcoming new members and guiding discussion."
        ),
        JargonTerm(
            term: "Storyline Feed",
            analogy: "Neighborhood Bulletin Board",
            symbolName: "list.bullet.rectangle.fill",
            explanation: "The Storyline Feed is the running stream of posts and updates that everyone in a community sees when they open it."
        ),
        JargonTerm(
            term: "Front Door Profile",
            analogy: "Building's Front Entrance",
            symbolName: "door.left.hand.open",
            explanation: "A Front Door Profile is the single entry point that greets every visitor before deciding which server should handle their request."
        ),
        JargonTerm(
            term: "Backend Pool",
            analogy: "Bank of Available Tellers",
            symbolName: "server.rack",
            explanation: "A Backend Pool is the group of real servers that Front Door can send traffic to, picking whichever is closest and healthiest."
        ),
        JargonTerm(
            term: "Routing Rule",
            analogy: "Traffic Cop Instructions",
            symbolName: "arrow.triangle.turn.up.right.diamond.fill",
            explanation: "A Routing Rule tells Front Door exactly which incoming web addresses should be sent to which backend pool."
        ),
        JargonTerm(
            term: "Point of Presence",
            analogy: "Neighborhood Branch Office",
            symbolName: "antenna.radiowaves.left.and.right",
            explanation: "A Point of Presence is a location near the visitor that can answer their request quickly instead of routing everything to one distant server."
        ),
        JargonTerm(
            term: "API Management Instance",
            analogy: "Reception Desk",
            symbolName: "shippingbox.fill",
            explanation: "An API Management Instance sits in front of your API, checking every visitor and enforcing the rules before letting a request through."
        ),
        JargonTerm(
            term: "API Product",
            analogy: "Menu Bundle",
            symbolName: "cube.box.fill",
            explanation: "An API Product groups related endpoints into one package that you can offer to developers with a single set of rules."
        ),
        JargonTerm(
            term: "API Policy",
            analogy: "House Rules",
            symbolName: "doc.badge.gearshape.fill",
            explanation: "An API Policy automatically enforces a rule on every request, like limiting how many calls someone can make per minute."
        ),
        JargonTerm(
            term: "Subscription Key",
            analogy: "Membership Card",
            symbolName: "key.fill",
            explanation: "A Subscription Key is the credential developers include with every request to prove they're allowed to use your API."
        ),
        JargonTerm(
            term: "Custom Permission Level",
            analogy: "Tailored Access Badge",
            symbolName: "slider.horizontal.3",
            explanation: "A Custom Permission Level is a hand-built bundle of abilities, created by copying and adjusting a default level to fit exactly what a group needs."
        ),
        JargonTerm(
            term: "SharePoint Group",
            analogy: "Roster List",
            symbolName: "person.2.fill",
            explanation: "A SharePoint Group is a named list of people that you can assign a permission level to all at once, instead of one person at a time."
        ),
        JargonTerm(
            term: "Site Collection",
            analogy: "Office Building",
            symbolName: "square.stack.fill",
            explanation: "A Site Collection is a group of related SharePoint sites that share the same top-level settings and structure."
        ),
        JargonTerm(
            term: "Bastion Subnet",
            analogy: "Reserved Parking Section",
            symbolName: "network",
            explanation: "A Bastion Subnet is a dedicated slice of your virtual network set aside just to host the Azure Bastion service."
        ),
        JargonTerm(
            term: "Bastion Host",
            analogy: "Doorman",
            symbolName: "shield.checkerboard",
            explanation: "A Bastion Host is a managed doorway that lets you securely reach a virtual machine through the browser, without exposing it to the open internet."
        ),
        JargonTerm(
            term: "Public IP Address",
            analogy: "Publicly Listed Street Address",
            symbolName: "number.circle.fill",
            explanation: "A Public IP Address is a reachable-from-anywhere address on the internet, which is exactly what you want to avoid giving a private server."
        ),
        JargonTerm(
            term: "Conversation Topic",
            analogy: "Menu Section",
            symbolName: "text.bubble.fill",
            explanation: "A Conversation Topic is a self-contained chunk of a bot's script dedicated to handling one specific question or task."
        ),
        JargonTerm(
            term: "Trigger Phrase",
            analogy: "Magic Word",
            symbolName: "quote.bubble.fill",
            explanation: "A Trigger Phrase is a sample thing a person might type that tells the bot which topic to jump into."
        ),
        JargonTerm(
            term: "Entity Slot",
            analogy: "Fill-in-the-Blank",
            symbolName: "textformat.abc",
            explanation: "An Entity Slot is a placeholder that lets a bot pull a useful detail, like a date or an order number, out of what someone typed."
        ),
        JargonTerm(
            term: "Publish Channel",
            analogy: "Broadcast Station",
            symbolName: "megaphone.fill",
            explanation: "A Publish Channel is the place, like Teams or a website, where a finished bot actually goes live for people to use."
        ),
        JargonTerm(
            term: "Cosmos DB Account",
            analogy: "Master Storage Facility",
            symbolName: "globe.americas.fill",
            explanation: "A Cosmos DB Account is the top-level container that holds every database you create inside Azure's globally distributed database service."
        ),
        JargonTerm(
            term: "Database Container",
            analogy: "Labeled Storage Bin",
            symbolName: "archivebox.fill",
            explanation: "A Database Container is where your actual records live inside a Cosmos DB database, similar to a table in other database systems."
        ),
        JargonTerm(
            term: "Consistency Level",
            analogy: "How Fast Everyone Hears the News",
            symbolName: "checkmark.seal.fill",
            explanation: "A Consistency Level controls how quickly every copy of your data agrees with each other, trading a bit of speed for a bit of certainty, or vice versa."
        ),
        JargonTerm(
            term: "Request Unit",
            analogy: "Arcade Token",
            symbolName: "gauge.with.dots.needle.50percent",
            explanation: "A Request Unit is the currency Cosmos DB uses to measure the cost of every read or write, and it's what you're really paying for."
        ),
        JargonTerm(
            term: "Cloud PC",
            analogy: "Desktop You Can Beam Anywhere",
            symbolName: "pc",
            explanation: "A Cloud PC is a full Windows desktop that runs in the cloud and streams to whatever device an employee happens to be using."
        ),
        JargonTerm(
            term: "Provisioning Policy",
            analogy: "Standard Furniture Order",
            symbolName: "doc.badge.plus",
            explanation: "A Provisioning Policy decides what Windows image and settings every new Cloud PC gets built with automatically."
        ),
        JargonTerm(
            term: "Restore Point",
            analogy: "Save Game Checkpoint",
            symbolName: "clock.arrow.circlepath",
            explanation: "A Restore Point is a snapshot of a Cloud PC that lets you roll it back to a working state if something goes wrong."
        ),
        JargonTerm(
            term: "Alert Rule Template",
            analogy: "Pre-Written Recipe",
            symbolName: "doc.on.doc.fill",
            explanation: "An Alert Rule Template is a ready-made starting point for a detection rule, so you don't have to write the logic completely from scratch."
        ),
        JargonTerm(
            term: "Analytics Rule",
            analogy: "Detective's Checklist",
            symbolName: "chart.line.uptrend.xyaxis",
            explanation: "An Analytics Rule is the query and conditions Sentinel uses to decide whether a pattern in your logs counts as a real threat."
        ),
        JargonTerm(
            term: "Security Incident",
            analogy: "Case File",
            symbolName: "exclamationmark.triangle.fill",
            explanation: "A Security Incident is a bundle of related alerts grouped together so your team investigates one case instead of a flood of duplicates."
        ),

        // MARK: Amazon (round 3 expansion)
        JargonTerm(
            term: "X-Ray Trace",
            analogy: "Delivery Tracking Number",
            symbolName: "location.fill",
            explanation: "An X-Ray Trace is like a delivery tracking number that follows one request as it hops between every service, so you can see exactly which stop slowed it down."
        ),
        JargonTerm(
            term: "Segment",
            analogy: "Tracking Checkpoint",
            symbolName: "mappin.and.ellipse",
            explanation: "A Segment is like one checkpoint stamp on that tracking number, recording how long a single hop took before the request moved on."
        ),
        JargonTerm(
            term: "Service Map",
            analogy: "Delivery Route Map",
            symbolName: "map.fill",
            explanation: "A Service Map is like a route map drawn from thousands of tracking numbers, showing which stops run smoothly and which ones are causing traffic jams."
        ),
        JargonTerm(
            term: "Sampling Rule",
            analogy: "Spot-Check Policy",
            symbolName: "slider.horizontal.3",
            explanation: "A Sampling Rule is like a spot-check policy that decides what share of requests get tracked in detail instead of tracking every single one."
        ),
        JargonTerm(
            term: "Cache Engine",
            analogy: "House Recipe",
            symbolName: "flame.fill",
            explanation: "A Cache Engine is like the house recipe your express kitchen follows, deciding how orders get stored and handed back quickly."
        ),
        JargonTerm(
            term: "Cache Cluster",
            analogy: "Express Pickup Counter",
            symbolName: "takeoutbag.and.cup.and.straw.fill",
            explanation: "A Cache Cluster is like an express pickup counter set up in front of the main kitchen, handing back popular orders instantly instead of cooking them from scratch."
        ),
        JargonTerm(
            term: "Cache Node",
            analogy: "One Pickup Window",
            symbolName: "square.grid.2x2.fill",
            explanation: "A Cache Node is like a single pickup window at that counter — add more windows and more customers can be served at the same time."
        ),
        JargonTerm(
            term: "Eviction Policy",
            analogy: "Shelf-Clearing Rule",
            symbolName: "trash.fill",
            explanation: "An Eviction Policy is like a shelf-clearing rule that decides which items get tossed first once the pickup counter runs out of room."
        ),
        JargonTerm(
            term: "State Machine",
            analogy: "Flowchart on the Wall",
            symbolName: "arrow.triangle.turn.up.right.diamond.fill",
            explanation: "A State Machine is like a flowchart pinned to the wall, showing every step a process goes through from start to finish and what happens if one step fails."
        ),
        JargonTerm(
            term: "State",
            analogy: "One Box on the Flowchart",
            symbolName: "checkmark.square.fill",
            explanation: "A State is like one box on that flowchart — it does a single job, then passes things along to whatever box comes next."
        ),
        JargonTerm(
            term: "Task State",
            analogy: "Box With a Job Attached",
            symbolName: "list.bullet.rectangle.fill",
            explanation: "A Task State is like a flowchart box that's actually wired up to a real worker — a Lambda function or another service that does the work when the flow reaches it."
        ),
        JargonTerm(
            term: "Execution History",
            analogy: "Play-by-Play Replay",
            symbolName: "clock.arrow.circlepath",
            explanation: "Execution History is like a play-by-play replay of one run through the flowchart, showing exactly which boxes ran, in what order, and how long each one took."
        ),
        JargonTerm(
            term: "Backup Vault",
            analogy: "Locked Storage Room",
            symbolName: "archivebox.fill",
            explanation: "A Backup Vault is like a locked storage room where every recovery point your backup plan creates gets kept safe."
        ),
        JargonTerm(
            term: "Backup Plan",
            analogy: "Standing Cleaning Schedule",
            symbolName: "calendar.badge.clock",
            explanation: "A Backup Plan is like a standing cleaning schedule that says what gets backed up, how often, and how long to hang onto each copy."
        ),
        JargonTerm(
            term: "Backup Rule",
            analogy: "One Line on the Schedule",
            symbolName: "doc.text.fill",
            explanation: "A Backup Rule is like one line on that cleaning schedule, spelling out the exact timing and retention for one group of resources."
        ),
        JargonTerm(
            term: "Recovery Point",
            analogy: "Dated Copy on the Shelf",
            symbolName: "arrow.uturn.backward.circle.fill",
            explanation: "A Recovery Point is like a dated copy sitting on the shelf in the storage room, ready to be pulled down and restored if you ever need it."
        ),
        JargonTerm(
            term: "Config Rule",
            analogy: "Inspection Checklist Item",
            symbolName: "checkmark.shield.fill",
            explanation: "A Config Rule is like one item on an inspector's checklist, automatically re-checked against your resources any time something changes."
        ),
        JargonTerm(
            term: "Configuration Recorder",
            analogy: "Security Camera on Your Setup",
            symbolName: "record.circle.fill",
            explanation: "A Configuration Recorder is like a security camera pointed at your resources, constantly logging what changed and when."
        ),
        JargonTerm(
            term: "Compliance Status",
            analogy: "Pass or Fail Stamp",
            symbolName: "checkmark.seal.fill",
            explanation: "Compliance Status is like the pass or fail stamp an inspector leaves behind, telling you at a glance whether a resource meets the rule you set."
        ),
        JargonTerm(
            term: "Resource Inventory",
            analogy: "Full Warehouse Count",
            symbolName: "shippingbox.fill",
            explanation: "A Resource Inventory is like a full warehouse count — a running list of every resource the recorder currently knows about."
        ),
        JargonTerm(
            term: "Kinesis Data Stream",
            analogy: "Conveyor Belt for Data",
            symbolName: "waveform.path",
            explanation: "A Kinesis Data Stream is like a conveyor belt that keeps moving — data gets placed on one end and picked up by whoever's watching the other end."
        ),
        JargonTerm(
            term: "Shard",
            analogy: "One Lane on the Belt",
            symbolName: "square.split.2x2",
            explanation: "A Shard is like one lane on that conveyor belt — add more lanes and more items can move through at the same time."
        ),
        JargonTerm(
            term: "Data Record",
            analogy: "One Item on the Belt",
            symbolName: "doc.text.fill",
            explanation: "A Data Record is like one item placed on the conveyor belt — a single piece of data moving through the stream."
        ),
        JargonTerm(
            term: "Producer",
            analogy: "Person Loading the Belt",
            symbolName: "arrow.up.doc.fill",
            explanation: "A Producer is like the person standing at one end of the belt, placing new items onto it as they're created."
        ),
        JargonTerm(
            term: "Consumer",
            analogy: "Person Unloading the Belt",
            symbolName: "arrow.down.doc.fill",
            explanation: "A Consumer is like the person at the other end of the belt, picking items off as soon as they arrive and doing something with them."
        ),
        JargonTerm(
            term: "Amplify App",
            analogy: "Project Folder Amplify Watches",
            symbolName: "app.badge.fill",
            explanation: "An Amplify App is like the project folder Amplify keeps an eye on, ready to build and publish it every time you push new code."
        ),
        JargonTerm(
            term: "Build Spec",
            analogy: "Assembly Instructions",
            symbolName: "hammer.fill",
            explanation: "A Build Spec is like assembly instructions left for the builder, listing the exact steps to turn your raw code into a finished site."
        ),
        JargonTerm(
            term: "Amplify Branch",
            analogy: "Named Version of the Project",
            symbolName: "arrow.triangle.branch",
            explanation: "An Amplify Branch is like a named version of your project — each one can be built and published on its own, separately from the others."
        ),
        JargonTerm(
            term: "Preview Deployment",
            analogy: "Dress Rehearsal",
            symbolName: "eye.fill",
            explanation: "A Preview Deployment is like a dress rehearsal — a live look at your changes before they're allowed in front of a real audience."
        ),
        JargonTerm(
            term: "Permission Set",
            analogy: "Badge That Opens Certain Doors",
            symbolName: "key.fill",
            explanation: "A Permission Set is like a badge that opens a specific set of doors once you're inside an account — nothing more, nothing less."
        ),
        JargonTerm(
            term: "Account Assignment",
            analogy: "Badge Handed to a Specific Person",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "An Account Assignment is like handing that badge to a specific person for a specific building, so they can get in without a separate key for every door."
        ),
        JargonTerm(
            term: "Identity Source",
            analogy: "Master Employee Directory",
            symbolName: "person.text.rectangle.fill",
            explanation: "An Identity Source is like the master employee directory everything else checks against to confirm who someone actually is."
        ),
        JargonTerm(
            term: "SSO Portal",
            analogy: "Lobby With One Front Desk",
            symbolName: "door.left.hand.open",
            explanation: "An SSO Portal is like a lobby with a single front desk — sign in there once, and you get pointed to every building you're allowed into."
        ),
        JargonTerm(
            term: "EFS File System",
            analogy: "Shared Network Drive",
            symbolName: "externaldrive.fill",
            explanation: "An EFS File System is like a shared network drive that multiple computers can open at the same time, growing on its own as you add files."
        ),
        JargonTerm(
            term: "Mount Target",
            analogy: "Doorway Into the Shared Drive",
            symbolName: "point.3.connected.trianglepath.dotted",
            explanation: "A Mount Target is like a doorway into the shared drive placed in a specific part of the building, so servers nearby can walk right in."
        ),
        JargonTerm(
            term: "Throughput Mode",
            analogy: "Width of the Doorway",
            symbolName: "speedometer",
            explanation: "Throughput Mode is like choosing how wide that doorway is — a wider one lets more data move through at once, for a higher price."
        ),
        JargonTerm(
            term: "Access Point",
            analogy: "Keycard for One Specific Room",
            symbolName: "arrow.right.to.line",
            explanation: "An Access Point is like a keycard scoped to one specific room on the shared drive, so an app only ever sees the folder it's meant to use."
        ),
        JargonTerm(
            term: "Customer Gateway",
            analogy: "Your Office's Front Desk",
            symbolName: "building.2.fill",
            explanation: "A Customer Gateway is like your office's front desk being registered with the other building, so the two sides know exactly who they're talking to."
        ),
        JargonTerm(
            term: "Virtual Private Gateway",
            analogy: "AWS's Side of the Front Desk",
            symbolName: "cloud.fill",
            explanation: "A Virtual Private Gateway is like the front desk on the AWS side, set up to answer calls coming in from your office's gateway."
        ),
        JargonTerm(
            term: "VPN Tunnel",
            analogy: "Private Hallway Between Buildings",
            symbolName: "arrow.left.arrow.right.circle.fill",
            explanation: "A VPN Tunnel is like a private, locked hallway connecting your office to AWS, so traffic between them never has to step outside onto the open internet."
        ),
        JargonTerm(
            term: "Dataset",
            analogy: "Prepared Ingredient Tray",
            symbolName: "tablecells.fill",
            explanation: "A Dataset is like a prepared tray of ingredients — your raw data cleaned up and organized so it's ready to be turned into charts."
        ),
        JargonTerm(
            term: "Analysis",
            analogy: "Chef's Working Counter",
            symbolName: "chart.line.uptrend.xyaxis",
            explanation: "An Analysis is like a chef's working counter — the space where you experiment with a dataset before anything gets plated up for guests."
        ),
        JargonTerm(
            term: "Visual",
            analogy: "One Plated Dish",
            symbolName: "chart.pie.fill",
            explanation: "A Visual is like one plated dish on that counter — a single chart or graph built from your dataset and ready to be served on a dashboard."
        ),
        JargonTerm(
            term: "Node Type",
            analogy: "Engine Size You Order",
            symbolName: "cpu.fill",
            explanation: "A Node Type is like the engine size you order for your warehouse cluster — bigger engines crunch through more data, faster, for more money."
        ),
        JargonTerm(
            term: "Redshift Cluster",
            analogy: "Warehouse Full of Filing Clerks",
            symbolName: "cylinder.split.1x2.fill",
            explanation: "A Redshift Cluster is like a warehouse full of filing clerks working together, built specifically to sort through mountains of data fast."
        ),
        JargonTerm(
            term: "Query Editor",
            analogy: "Order Slip Window",
            symbolName: "text.magnifyingglass",
            explanation: "A Query Editor is like the order slip window at the warehouse — write down what you want to know, and the clerks go dig it up."
        ),
        JargonTerm(
            term: "Cluster Snapshot",
            analogy: "Photograph of the Whole Warehouse",
            symbolName: "camera.fill",
            explanation: "A Cluster Snapshot is like a photograph of the entire warehouse at one moment, so you can rebuild it exactly as it was if something goes wrong."
        ),
        JargonTerm(
            term: "SSM Agent",
            analogy: "Intercom Installed on the Server",
            symbolName: "network",
            explanation: "The SSM Agent is like a small intercom installed on your server, letting you talk to it without ever handing out a physical key."
        ),
        JargonTerm(
            term: "Managed Instance",
            analogy: "Server on the Intercom System",
            symbolName: "checkmark.circle.fill",
            explanation: "A Managed Instance is like a server that's been wired into the building's intercom system, reachable without anyone visiting in person or holding a key."
        ),
        JargonTerm(
            term: "Session Manager",
            analogy: "Intercom Control Panel",
            symbolName: "terminal.fill",
            explanation: "Session Manager is like the intercom control panel you use to open a live conversation with any connected server, right from your browser."
        ),

        // MARK: Round 4 additions (new terms from top-up + Facebook batches)

        JargonTerm(
            term: "Stolen Device Protection",
            analogy: "Extra Lock Away From Home",
            symbolName: "lock.iphone",
            explanation: "Stolen Device Protection adds extra checks and waiting periods for sensitive settings changes when your device is away from familiar places, the same way a store adds an extra lock that only opens after closing hours."
        ),
        JargonTerm(
            term: "Data Breach",
            analogy: "Break-In Alert",
            symbolName: "exclamationmark.triangle.fill",
            explanation: "A Data Breach is an incident where a company's stored information gets stolen or leaked, the same way a break-in alert tells you someone got into a building that was supposed to be locked."
        ),
        JargonTerm(
            term: "CAA Record",
            analogy: "Approved Vendor List",
            symbolName: "checklist",
            explanation: "A CAA Record is a DNS entry that lists which certificate authorities are allowed to issue SSL certificates for your domain, the same way an approved vendor list says which companies are allowed to do business under your name."
        ),
        JargonTerm(
            term: "Certificate Authority",
            analogy: "Notary",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "A Certificate Authority is an organization that verifies a website's identity and vouches for it with a certificate, the same way a notary verifies your identity before stamping a document."
        ),
        JargonTerm(
            term: "Masked Email",
            analogy: "Disposable Mailbox",
            symbolName: "envelope.circle",
            explanation: "A Masked Email is a stand-in address that forwards to your real inbox, the same way a disposable mailbox lets you receive mail without giving out your home address."
        ),
        JargonTerm(
            term: "Legacy Contact",
            analogy: "Named Heir",
            symbolName: "person.badge.clock",
            explanation: "A Legacy Contact is a person you designate in advance to access or manage your account after you're gone, the same way a named heir is chosen ahead of time to inherit what's yours."
        ),
        JargonTerm(
            term: "Cookieless Analytics",
            analogy: "Anonymous Headcount",
            symbolName: "chart.bar.xaxis",
            explanation: "Cookieless Analytics counts visits and trends without planting a tracking file on each visitor's device, the same way an anonymous headcount tells you how many people showed up without writing down who they were."
        ),


        JargonTerm(
            term: "Custom Role",
            analogy: "Custom Toolbelt",
            symbolName: "wrench.and.screwdriver",
            explanation: "A Custom Role is a bundle of permissions you hand-pick yourself, the same way a custom toolbelt carries only the tools a specific job needs."
        ),
        JargonTerm(
            term: "Principal",
            analogy: "Name Tag",
            symbolName: "person.text.rectangle",
            explanation: "A Principal is whoever is asking to do something, whether a person, a group, or a service account, the same way a name tag identifies who's in the room."
        ),
        JargonTerm(
            term: "Build Trigger",
            analogy: "Tripwire",
            symbolName: "bolt.horizontal.circle",
            explanation: "A Build Trigger automatically starts a build when something changes, the same way a tripwire sets off an alarm the moment it's crossed."
        ),
        JargonTerm(
            term: "Build Config File",
            analogy: "Recipe Card",
            symbolName: "doc.text",
            explanation: "A Build Config File lists the exact steps to turn your code into a finished package, the same way a recipe card lists steps to turn ingredients into a dish."
        ),
        JargonTerm(
            term: "Artifact Repository",
            analogy: "Warehouse Shelf",
            symbolName: "archivebox",
            explanation: "An Artifact Repository is a storage space for your finished, packaged builds, the same way a warehouse shelf holds finished products ready to ship."
        ),
        JargonTerm(
            term: "BigQuery Dataset",
            analogy: "Filing Cabinet",
            symbolName: "cabinet",
            explanation: "A BigQuery Dataset is a container that groups related tables together, the same way a filing cabinet groups related folders in one place."
        ),
        JargonTerm(
            term: "Table Schema",
            analogy: "Column Labels",
            symbolName: "tag",
            explanation: "A Table Schema defines what kind of data belongs in each column, the same way labels on folders tell you what's supposed to be filed inside."
        ),
        JargonTerm(
            term: "Upload Key",
            analogy: "Delivery Key",
            symbolName: "key",
            explanation: "An Upload Key is what you use to sign a build before sending it to the store, the same way a delivery key proves a package came from the right sender."
        ),
        JargonTerm(
            term: "App Signing Key",
            analogy: "Wax Seal",
            symbolName: "seal",
            explanation: "An App Signing Key is the permanent key that proves an app update is genuinely yours, the same way a wax seal proves a letter really came from its sender."
        ),
        JargonTerm(
            term: "Debug Symbols",
            analogy: "Decoder Ring",
            symbolName: "questionmark.circle",
            explanation: "Debug Symbols translate a crash's raw gibberish back into readable code locations, the same way a decoder ring turns a coded message back into plain words."
        ),
        JargonTerm(
            term: "Attestation Provider",
            analogy: "Bouncer",
            symbolName: "figure.stand",
            explanation: "An Attestation Provider checks that a request truly comes from your real, untampered app, the same way a bouncer checks IDs before letting anyone through the door."
        ),
        JargonTerm(
            term: "Debug Token",
            analogy: "Guest Pass",
            symbolName: "person.crop.circle.badge.checkmark",
            explanation: "A Debug Token is a temporary pass that lets a test device skip normal verification, the same way a guest pass lets a visitor in without a full background check."
        ),
        JargonTerm(
            term: "Digital Asset Links File",
            analogy: "Ownership Certificate",
            symbolName: "doc.badge.gearshape",
            explanation: "A Digital Asset Links File proves your website and your app belong to the same owner, the same way an ownership certificate proves a car and its title match."
        ),
        JargonTerm(
            term: "Managed Zone",
            analogy: "Neighborhood Map",
            symbolName: "map",
            explanation: "A Managed Zone is the container holding all of one domain's DNS records, the same way a neighborhood map holds every address within one area."
        ),

        JargonTerm(
            term: "Public Link",
            analogy: "Open Door Invite",
            symbolName: "door.left.hand.open",
            explanation: "A Public Link is a single shareable URL that lets anyone request into your beta, the same way an open house lets any visitor walk in without a personal invitation."
        ),
        JargonTerm(
            term: "App Store Connect Role",
            analogy: "Job Badge",
            symbolName: "person.text.rectangle.fill",
            explanation: "An App Store Connect Role is a preset bundle of permissions assigned to a teammate, the same way a job badge only opens the doors that match someone's actual job."
        ),
        JargonTerm(
            term: "StoreKit 2",
            analogy: "Built-In Cashier",
            symbolName: "cart.fill",
            explanation: "StoreKit 2 is Apple's modern purchase framework that verifies transactions for you right inside the app, the same way a built-in cashier rings up and checks a sale without calling a manager over."
        ),
        JargonTerm(
            term: "Resolution Center",
            analogy: "Complaint Window",
            symbolName: "bubble.left.and.bubble.right.fill",
            explanation: "The Resolution Center is the message thread where you and a reviewer discuss a rejection, the same way a complaint window is where you go to sort out a dispute face to face."
        ),
        JargonTerm(
            term: "App Review Board",
            analogy: "Appeals Court",
            symbolName: "building.columns.fill",
            explanation: "The App Review Board is a separate panel of reviewers who take a fresh look at a disputed decision, the same way an appeals court reconsiders a case a lower court already ruled on."
        ),
        JargonTerm(
            term: "Start Condition",
            analogy: "Trigger Switch",
            symbolName: "bolt.circle.fill",
            explanation: "A Start Condition is the specific event that kicks off an automated build, the same way a trigger switch fires a device the instant it's flipped."
        ),
        JargonTerm(
            term: "Notarization",
            analogy: "Security Screening",
            symbolName: "magnifyingglass.circle.fill",
            explanation: "Notarization is Apple's automated scan of your Mac app for malicious code before it reaches anyone, the same way airport security screening checks bags before passengers board."
        ),
        JargonTerm(
            term: "Notarization Ticket",
            analogy: "Inspection Sticker",
            symbolName: "checkmark.seal.fill",
            explanation: "A Notarization Ticket is the proof Apple attaches to your app once it passes its scan, the same way an inspection sticker on a car shows it already passed a safety check."
        ),
        JargonTerm(
            term: "Gatekeeper",
            analogy: "Bouncer at the Door",
            symbolName: "hand.raised.fill",
            explanation: "Gatekeeper is macOS's built-in check that blocks unrecognized software from opening, the same way a bouncer stops anyone without the right credentials from walking in."
        ),
        JargonTerm(
            term: "App Sandbox",
            analogy: "Fenced Play Area",
            symbolName: "square.dashed",
            explanation: "App Sandbox is a restricted environment that keeps your Mac app from touching files or hardware it wasn't given permission to use, the same way a fenced play area keeps kids safely contained to one yard."
        ),
        JargonTerm(
            term: "iCloud Key-Value Store",
            analogy: "Shared Sticky Note",
            symbolName: "note.text",
            explanation: "The iCloud Key-Value Store is a small pool of settings-sized data that syncs across a user's devices, the same way a sticky note left on a shared fridge shows the same message no matter who reads it."
        ),
        JargonTerm(
            term: "Apple School Manager",
            analogy: "School Supply Closet",
            symbolName: "backpack.fill",
            explanation: "Apple School Manager is the portal schools use to buy and hand out apps and devices to students in bulk, the same way a supply closet lets a teacher hand out textbooks to a whole class at once."
        ),
        JargonTerm(
            term: "Editorial Pitch",
            analogy: "Elevator Pitch to an Editor",
            symbolName: "megaphone.fill",
            explanation: "An Editorial Pitch is a direct note to Apple's App Store editors explaining why your app deserves a featured spot, the same way a writer pitches a story idea straight to a magazine editor."
        ),


        JargonTerm(
            term: "External Tenant",
            analogy: "Visitor Lobby",
            symbolName: "door.left.hand.open",
            explanation: "An external tenant is a separate identity space set aside for customers or partners, the same way a visitor lobby keeps guests apart from the employee floors."
        ),
        JargonTerm(
            term: "User Flow",
            analogy: "Sign-In Storyboard",
            symbolName: "rectangle.stack.person.crop",
            explanation: "A user flow is a pre-built sequence of screens for signing up, signing in, or resetting a password, the same way a storyboard maps out every scene before filming starts."
        ),
        JargonTerm(
            term: "Identity Provider",
            analogy: "Trusted ID Checker",
            symbolName: "checkmark.seal",
            explanation: "An identity provider is an outside service that vouches for who someone is, the same way a trusted ID checker at one venue lets you skip re-registering at another."
        ),
        JargonTerm(
            term: "Sensitivity Label",
            analogy: "Confidential Stamp",
            symbolName: "seal",
            explanation: "A sensitivity label is a tag you apply to a document to mark how protected it should be, the same way a confidential stamp tells everyone how carefully to handle a paper file."
        ),
        JargonTerm(
            term: "Encryption",
            analogy: "Locked Briefcase",
            symbolName: "lock.rectangle",
            explanation: "Encryption is a process that scrambles data so only authorized people can read it, the same way a locked briefcase keeps papers hidden from anyone without the key."
        ),
        JargonTerm(
            term: "Label Policy",
            analogy: "Rollout Plan",
            symbolName: "list.bullet.clipboard",
            explanation: "A label policy is the setting that pushes your sensitivity labels out to everyone's apps, the same way a rollout plan gets new equipment onto every desk at once."
        ),
        JargonTerm(
            term: "Sensitive Information Type",
            analogy: "Pattern Detector",
            symbolName: "magnifyingglass.circle",
            explanation: "A sensitive information type is a built-in pattern, like a credit card number, that scanning tools watch for, the same way a pattern detector flags a familiar shape in a crowd."
        ),
        JargonTerm(
            term: "Policy Definition",
            analogy: "House Rule",
            symbolName: "doc.text.magnifyingglass",
            explanation: "A policy definition is a single written rule describing what's allowed or required, the same way a house rule spells out one specific expectation for everyone living there."
        ),
        JargonTerm(
            term: "Initiative",
            analogy: "Rulebook Bundle",
            symbolName: "books.vertical",
            explanation: "An initiative is a bundle of related policy rules grouped together, the same way a rulebook bundles many individual house rules into one handbook."
        ),
        JargonTerm(
            term: "Policy Effect",
            analogy: "Consequence Setting",
            symbolName: "exclamationmark.triangle",
            explanation: "A policy effect is what happens when a rule is broken, whether that's blocking it, logging it, or fixing it automatically, the same way a consequence setting decides whether a violation gets a warning or a lockout."
        ),
        JargonTerm(
            term: "Cost Alert Threshold",
            analogy: "Gas Gauge Warning",
            symbolName: "gauge.with.needle",
            explanation: "A cost alert threshold is the point at which spending triggers a warning, the same way a gas gauge warning light comes on before the tank actually runs dry."
        ),
        JargonTerm(
            term: "Distribution List",
            analogy: "Mailing List",
            symbolName: "envelope.badge",
            explanation: "A distribution list is a simple group email address that forwards messages to everyone on the list, the same way a mailing list sends one newsletter to every subscriber."
        ),
        JargonTerm(
            term: "Microsoft 365 Group",
            analogy: "All-In-One Team Kit",
            symbolName: "shippingbox",
            explanation: "A Microsoft 365 Group is a shared identity that comes bundled with a mailbox, calendar, and file library, the same way an all-in-one kit arrives with every tool a new team needs already inside."
        ),
        JargonTerm(
            term: "Inbox Rule",
            analogy: "Mail Sorting Instruction",
            symbolName: "envelope.arrow.triangle.branch",
            explanation: "An inbox rule is an automatic instruction that acts on incoming mail matching certain conditions, the same way a mail sorting instruction tells a mailroom clerk exactly where to route certain letters."
        ),
        JargonTerm(
            term: "Build Configuration",
            analogy: "Assembly Instructions",
            symbolName: "hammer",
            explanation: "A build configuration tells a deployment tool which folder holds your source files and which command turns them into a finished site, the same way assembly instructions tell a builder which parts go where."
        ),
        JargonTerm(
            term: "Service Bus Namespace",
            analogy: "Dedicated Post Office",
            symbolName: "building.columns",
            explanation: "A Service Bus namespace is a dedicated container for your app's messaging traffic, the same way a dedicated post office handles only one organization's mail instead of the whole city's."
        ),
        JargonTerm(
            term: "Queue",
            analogy: "Drop-Off Box",
            symbolName: "tray.full",
            explanation: "A queue is a holding area where messages wait until something is ready to process them, the same way a drop-off box lets a sender leave a package without the recipient needing to be there at that exact moment."
        ),
        JargonTerm(
            term: "API Permission",
            analogy: "Access Badge Scope",
            symbolName: "person.badge.key",
            explanation: "An API permission is a specific capability an app is allowed to use, like reading calendars, the same way an access badge scope limits which doors a badge will actually open."
        ),
        JargonTerm(
            term: "Admin Consent",
            analogy: "Manager Sign-Off",
            symbolName: "checkmark.seal.text.page",
            explanation: "Admin consent is an administrator's one-time approval that covers an entire organization, the same way a manager's sign-off clears a purchase so no individual employee has to ask permission again."
        ),
        JargonTerm(
            term: "Managed Identity",
            analogy: "Self-Renewing ID Badge",
            symbolName: "person.badge.clock",
            explanation: "A managed identity is an automatically created and rotated identity for an app or resource, the same way a self-renewing ID badge never expires or needs to be reissued by hand."
        ),


        JargonTerm(
            term: "Glue Crawler",
            analogy: "Data Detective",
            symbolName: "magnifyingglass",
            explanation: "A Glue Crawler is an automated scout that pokes through your files to figure out their structure, the same way a detective inspects a scene and writes up notes on what they found."
        ),
        JargonTerm(
            term: "Data Catalog",
            analogy: "Card Catalog",
            symbolName: "books.vertical",
            explanation: "A Data Catalog is a searchable table of contents for your data that tools can read instead of opening every file themselves, the same way a library's card catalog tells you where a book lives without browsing every shelf."
        ),
        JargonTerm(
            term: "Broker Engine",
            analogy: "Translator",
            symbolName: "character.bubble",
            explanation: "A Broker Engine is the messaging language a broker speaks, like ActiveMQ or RabbitMQ, the same way choosing a translator's language determines who they can talk to."
        ),
        JargonTerm(
            term: "Aurora Capacity Unit",
            analogy: "Adjustable Dimmer",
            symbolName: "dial.low",
            explanation: "An Aurora Capacity Unit is the increment a serverless database scales up or down by, the same way a dimmer switch lets you dial a light brighter or darker instead of just on or off."
        ),
        JargonTerm(
            term: "Patch Baseline",
            analogy: "Approved Shopping List",
            symbolName: "checklist",
            explanation: "A Patch Baseline is the rulebook for which software updates are approved and when, the same way a shopping list decides what actually goes in the cart versus what stays on the shelf."
        ),
        JargonTerm(
            term: "Patch Group",
            analogy: "Study Group",
            symbolName: "person.3",
            explanation: "A Patch Group is a batch of servers tagged to get updates together on the same schedule, the same way a study group meets and works through material as one unit."
        ),
        JargonTerm(
            term: "Job Definition",
            analogy: "Recipe Card",
            symbolName: "doc.text",
            explanation: "A Job Definition is the recipe describing what to run, what it needs, and how to run it, the same way a recipe card lists ingredients and steps before anyone starts cooking."
        ),
        JargonTerm(
            term: "Job Queue",
            analogy: "Deli Counter Line",
            symbolName: "list.number",
            explanation: "A Job Queue is the waiting line jobs sit in until there's capacity to run them, the same way a deli counter line works through customers one ticket number at a time."
        ),
        JargonTerm(
            term: "Graph Edge",
            analogy: "Friendship Line",
            symbolName: "link",
            explanation: "A Graph Edge is the labeled connection drawn between two related pieces of data, the same way a line on a friendship chart shows how two people know each other."
        ),


        JargonTerm(
            term: "Facebook App Secret",
            analogy: "Secret House Key",
            symbolName: "key.fill",
            explanation: "A Facebook App Secret is a private credential your server uses to prove it truly owns an app, the same way a spare house key proves you belong inside without having to ask a neighbor."
        ),
        JargonTerm(
            term: "User Access Token",
            analogy: "Temporary Visitor Badge",
            symbolName: "person.text.rectangle.fill",
            explanation: "A User Access Token is a short-lived pass that lets your app act on a specific person's behalf, the same way a visitor badge lets a guest into a building for just one day."
        ),
        JargonTerm(
            term: "Long-Lived Token",
            analogy: "60-Day Hotel Keycard",
            symbolName: "calendar.badge.clock",
            explanation: "A Long-Lived Token is an access pass extended to last around two months instead of a couple of hours, the same way a hotel might issue a 60-day keycard to a long-term guest instead of a nightly one."
        ),
        JargonTerm(
            term: "Facebook App Domain",
            analogy: "Approved Home Address",
            symbolName: "house.fill",
            explanation: "A Facebook App Domain is the website address you register as your app's official home, the same way a business lists a verified address so mail actually gets delivered there."
        ),
        JargonTerm(
            term: "App Review",
            analogy: "Bouncer Checklist",
            symbolName: "checklist",
            explanation: "App Review is Meta's process of checking that your app genuinely needs and correctly uses the permissions it's requesting, the same way a bouncer checks a guest list before waving someone past the rope."
        ),
        JargonTerm(
            term: "Test User",
            analogy: "Crash Test Dummy",
            symbolName: "person.crop.circle.badge.questionmark",
            explanation: "A Test User is a fake sandbox account created just for your app, the same way a crash test dummy stands in for a real passenger during a risky trial run."
        ),
        JargonTerm(
            term: "Verify Token",
            analogy: "Secret Handshake",
            symbolName: "hand.wave.fill",
            explanation: "A Verify Token is a shared phrase Facebook and your server exchange once to confirm a webhook really belongs to you, the same way a secret handshake confirms someone belongs in the club before you let them in."
        ),
        JargonTerm(
            term: "Graph API",
            analogy: "App's Front Desk",
            symbolName: "tray.and.arrow.up.and.arrow.down.fill",
            explanation: "The Graph API is the single front desk you go through for almost everything on Facebook's platform, the same way a hotel front desk handles every request instead of you tracking down each department yourself."
        ),
        JargonTerm(
            term: "Facebook Permission Scope",
            analogy: "Keyring Label",
            symbolName: "tag.fill",
            explanation: "A Facebook Permission Scope is one specific, named slice of access your app can request, the same way a labeled key on a keyring only opens one particular door instead of the whole building."
        ),
        JargonTerm(
            term: "Live Mode",
            analogy: "Open For Business Sign",
            symbolName: "flag.fill",
            explanation: "Live Mode is the switch that opens your app to everyday Facebook users instead of just your team, the same way flipping a shop's sign from Closed to Open lets any customer walk in."
        ),


        JargonTerm(
            term: "Meta Business Manager",
            analogy: "Shared Office Building",
            symbolName: "building.2.fill",
            explanation: "Meta Business Manager is a shared office building that houses your company's Pages, ad accounts, and teammates under one locked front door, the same way an office building keeps every department's stuff under one roof instead of scattered across employees' desks."
        ),
        JargonTerm(
            term: "System User",
            analogy: "Robot Employee",
            symbolName: "cpu.fill",
            explanation: "A System User is a robot employee that logs in on behalf of your software instead of a real person, the same way a factory keeps a machine running the night shift without needing to print it a badge."
        ),
        JargonTerm(
            term: "Partner Business",
            analogy: "Trusted Neighbor",
            symbolName: "person.2.badge.key.fill",
            explanation: "A Partner Business is a trusted neighbor company you loop into one specific asset without making them a full member of your team, the same way you'd hand a neighbor a spare house key without also giving them a copy of your car key."
        ),
        JargonTerm(
            term: "Asset Assignment",
            analogy: "Handing Over a Room Key",
            symbolName: "key.fill",
            explanation: "Asset Assignment is handing someone the key to one specific room, like a Page or ad account, without giving them keys to the whole building, the same way a hotel issues a guest a keycard for their room only."
        ),
        JargonTerm(
            term: "Business Verification",
            analogy: "Notarized ID Check",
            symbolName: "checkmark.seal.fill",
            explanation: "Business Verification is a notarized ID check where Meta confirms your company is real using official documents, the same way a bank verifies your identity with paperwork before opening an account."
        ),
        JargonTerm(
            term: "Domain Verification",
            analogy: "Proof of Address",
            symbolName: "checkmark.shield.fill",
            explanation: "Domain Verification is proof of address for your website, showing Meta you actually control the domain by placing a special file or code there, the same way a utility bill proves you live where you say you do."
        ),
        JargonTerm(
            term: "Standard Access",
            analogy: "General Admission Ticket",
            symbolName: "ticket.fill",
            explanation: "Standard Access is the general-admission ticket every feature starts with, letting it work only for the small circle of people already on your own team's account."
        ),
        JargonTerm(
            term: "Advanced Access",
            analogy: "VIP Backstage Pass",
            symbolName: "star.circle.fill",
            explanation: "Advanced Access is a VIP backstage pass that lets a feature work for all of your real customers instead of just your own test crew, the same way a backstage pass gets you past the rope that stops regular ticket holders."
        ),


        JargonTerm(
            term: "Meta Pixel",
            analogy: "Security Camera",
            symbolName: "video.fill",
            explanation: "A Meta Pixel is a small snippet of tracking code that watches what visitors do on your site, the same way a security camera in a store notices who walks in and what they browse."
        ),
        JargonTerm(
            term: "Conversions API",
            analogy: "Direct Radio Line",
            symbolName: "antenna.radiowaves.left.and.right",
            explanation: "A Conversions API is a direct server-to-server channel for reporting what happened, the same way a direct radio line still gets the message through even when the phone lines are jammed."
        ),
        JargonTerm(
            term: "Custom Audience",
            analogy: "Sorted Guest List",
            symbolName: "list.bullet.rectangle.portrait",
            explanation: "A Custom Audience is a saved group of people built from your own data, like a guest list you compiled yourself from everyone who's already visited your store."
        ),
        JargonTerm(
            term: "Lookalike Audience",
            analogy: "Matchmaker's Picks",
            symbolName: "person.crop.circle.badge.plus",
            explanation: "A Lookalike Audience is a fresh group of strangers who share traits with people you already know, the same way a matchmaker introduces you to new friends who resemble the ones you already like."
        ),
        JargonTerm(
            term: "Data Deletion Callback",
            analogy: "Scheduled Pickup Call",
            symbolName: "person.crop.circle.badge.xmark",
            explanation: "A Data Deletion Callback is a web address you provide that Facebook pings whenever someone removes your app, the same way a moving company calls ahead to schedule pickup of everything you agreed to take away."
        ),


        JargonTerm(
            term: "Ad Set",
            analogy: "Recipe Card",
            symbolName: "list.bullet.rectangle",
            explanation: "An Ad Set is the middle layer of a campaign that holds the audience, budget, schedule, and placement decisions, the same way a recipe card lists exactly who it serves and what ingredients and timing to use before you get to plating the dish."
        ),
        JargonTerm(
            term: "Ad Account",
            analogy: "Shared Company Wallet",
            symbolName: "wallet.pass.fill",
            explanation: "An Ad Account is the container that ties your campaigns, payment method, and permissions together under one roof, the same way a shared company wallet holds the funds and access rules everyone on a team draws from."
        ),
        JargonTerm(
            term: "Custom Conversion",
            analogy: "Saved Search Filter",
            symbolName: "line.3.horizontal.decrease.circle",
            explanation: "A Custom Conversion is a rule you build on top of an existing Pixel event to isolate a specific action worth tracking, the same way a saved search filter narrows a big pile of results down to just the ones you actually care about."
        ),
        JargonTerm(
            term: "Events Manager",
            analogy: "Mission Control Room",
            symbolName: "gauge.with.dots.needle.67percent",
            explanation: "Events Manager is the dashboard where you monitor and troubleshoot every event your Pixel and app are sending in, the same way a mission control room keeps every incoming signal on one set of screens where problems get spotted fast."
        ),
        JargonTerm(
            term: "Commerce Manager",
            analogy: "Warehouse Back Office",
            symbolName: "shippingbox.fill",
            explanation: "Commerce Manager is the hub where you build catalogs, launch shops, and manage orders, the same way a warehouse back office is where inventory gets organized before anything reaches the sales floor."
        ),
        JargonTerm(
            term: "Product Catalog",
            analogy: "Master Inventory Binder",
            symbolName: "book.closed.fill",
            explanation: "A Product Catalog is the structured list of everything you sell, complete with images, prices, and details, the same way a master inventory binder gives every item in a store a single, consistent entry to be looked up from."
        ),
        JargonTerm(
            term: "Event Match Quality",
            analogy: "Report Card Score",
            symbolName: "checkmark.seal.fill",
            explanation: "Event Match Quality is a score showing how confidently Meta can tie an incoming event to a real person based on the customer details it includes, the same way a report card score sums up how well something is performing at a glance."
        ),
        JargonTerm(
            term: "Billing Threshold",
            analogy: "Bar Tab Limit",
            symbolName: "dollarsign.circle.fill",
            explanation: "A Billing Threshold is the dollar amount your ad spend can reach before you're automatically charged, the same way a bar tab limit triggers a charge to your card once your running total hits a set ceiling."
        ),
        JargonTerm(
            term: "Advantage+ Placements",
            analogy: "Autopilot Mode",
            symbolName: "airplane.circle.fill",
            explanation: "Advantage+ Placements is the setting that lets Meta automatically decide which surfaces show your ads based on real-time performance, the same way autopilot mode takes over the fine-grained adjustments so you don't have to steer manually the whole way."
        ),
        JargonTerm(
            term: "Advantage Campaign Budget",
            analogy: "Shared Team Pool",
            symbolName: "chart.pie.fill",
            explanation: "Advantage Campaign Budget is a single budget set at the campaign level that Meta automatically distributes across your Ad Sets based on where it sees the best opportunity, the same way a shared team pool of funds gets allocated to whichever project needs it most instead of being split evenly upfront."
        ),


    JargonTerm(
        term: "Messenger Platform",
        analogy: "Automated Front Desk",
        symbolName: "bubble.left.and.bubble.right",
        explanation: "The Messenger Platform is a set of tools that lets your software send and receive Facebook Messenger chats automatically, the same way an automated front desk greets and routes visitors without a receptionist standing there."
    ),
    JargonTerm(
        term: "WhatsApp Business Platform",
        analogy: "Industrial Kitchen",
        symbolName: "phone.bubble.left",
        explanation: "The WhatsApp Business Platform is the API-driven version of WhatsApp built for software to send messages at scale, the same way an industrial kitchen produces meals in volume instead of one home stovetop dinner at a time."
    ),
    JargonTerm(
        term: "Instagram Professional Account",
        analogy: "Business Nameplate",
        symbolName: "person.crop.square.badge.camera",
        explanation: "An Instagram Professional Account is a free upgrade from a personal profile that unlocks business tools and insights, the same way adding a nameplate to a mailbox marks it as a business address entitled to business services."
    ),
    JargonTerm(
        term: "Instagram Graph API",
        analogy: "Programmatic Doorway",
        symbolName: "chevron.left.slash.chevron.right",
        explanation: "The Instagram Graph API is the programmatic doorway that lets approved apps read and manage a linked Instagram account's data, the same way a service entrance lets authorized staff in without going through the main lobby."
    ),
    JargonTerm(
        term: "Handover Protocol",
        analogy: "Relay Race Baton",
        symbolName: "arrow.left.arrow.right",
        explanation: "The Handover Protocol is a system for passing control of a conversation between a bot and a human agent, the same way a relay race baton is handed off cleanly from one runner to the next without ever being dropped."
    ),
    JargonTerm(
        term: "Meta Verified",
        analogy: "Passport Office Visit",
        symbolName: "checkmark.seal",
        explanation: "Meta Verified is a paid subscription that confirms your real identity and adds a verified badge plus account protections, the same way a passport office visit proves who you are once and issues a credential that's hard to fake."
    ),
    JargonTerm(
        term: "Meta Business Suite",
        analogy: "Shared Control Room",
        symbolName: "tray.2",
        explanation: "Meta Business Suite is a shared control room dashboard that manages your Page and linked Instagram account together, the same way a single control room lets one operator watch and respond to signals from multiple stations at once."
    ),
    JargonTerm(
        term: "Meta Pixel Helper",
        analogy: "Website Stethoscope",
        symbolName: "wand.and.rays",
        explanation: "Meta Pixel Helper is a free browser extension that checks whether your tracking pixel is firing correctly on a page, the same way a stethoscope lets someone listen for a heartbeat to confirm it's actually there."
    ),
    ]

    /// Fast lookup by the exact term string, used when a workflow step
    /// references jargon by name rather than by UUID.
    static func term(named name: String) -> JargonTerm? {
        allTerms.first { $0.term.compare(name, options: .caseInsensitive) == .orderedSame }
    }

    static func term(id: UUID) -> JargonTerm? {
        allTerms.first { $0.id == id }
    }
}
