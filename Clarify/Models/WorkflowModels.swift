//
//  WorkflowModels.swift
//  Clarify
//
//  Value types describing a guided setup. These are pure data — no
//  business logic lives here. WorkflowManager owns the state machine
//  that walks a user through them.
//

import Foundation

/// Which immersive visual, if any, a step should render above its
/// instructions.
enum StepVisual: String, Codable, Hashable {
    case dnsVisualizer
    case engineRoom
    case consoleOverlay
    case plain
}

/// Which bundled set of parts/slots an `.engineRoom` step should render.
/// Lets several workflows reuse the same drag-to-assemble mechanic with
/// provider-appropriate pieces instead of one hardcoded kit.
enum EngineRoomKit: String, Codable, Hashable {
    case google
    case azure
    case aws
}

/// A single, atomic action within a workflow. Steps are strictly linear —
/// there is no branching and no "skip ahead" affordance anywhere in the UI.
struct WorkflowStep: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let instruction: String
    /// Term strings (matched against `JargonGlossary`) that should render
    /// as tappable flip cards inside this step's instruction text.
    let jargonTerms: [String]
    let visual: StepVisual
    /// Name of the specific on-screen element a console overlay should
    /// spotlight, only used when `visual == .consoleOverlay`.
    let overlayTargetLabel: String?
    /// Which parts/slots kit an `.engineRoom` step renders. Ignored for
    /// every other visual.
    let engineRoomKit: EngineRoomKit?
    /// Points awarded when this step is completed. Defaults to a flat
    /// value so most steps can omit it; steps that end an entire
    /// workflow or involve a hands-on visual are worth more.
    let xpValue: Int

    init(
        id: UUID? = nil,
        title: String,
        instruction: String,
        jargonTerms: [String] = [],
        visual: StepVisual = .plain,
        overlayTargetLabel: String? = nil,
        engineRoomKit: EngineRoomKit? = nil,
        xpValue: Int = 10
    ) {
        self.id = id ?? StableIdentifier.uuid("unscoped-workflow-step", title, instruction)
        self.title = title
        self.instruction = instruction
        self.jargonTerms = jargonTerms
        self.visual = visual
        self.overlayTargetLabel = overlayTargetLabel
        self.engineRoomKit = engineRoomKit
        self.xpValue = xpValue
    }

    /// WorkflowLibrary owns the persisted identity of bundled steps.
    /// Keeping the copy operation here ensures every field stays intact
    /// when a workflow replaces the construction-time UUID with a stable
    /// one scoped to that guide and step position.
    fileprivate func identified(as id: UUID) -> WorkflowStep {
        WorkflowStep(
            id: id,
            title: title,
            instruction: instruction,
            jargonTerms: jargonTerms,
            visual: visual,
            overlayTargetLabel: overlayTargetLabel,
            engineRoomKit: engineRoomKit,
            xpValue: xpValue
        )
    }
}

/// A complete guided setup, made up of ordered `WorkflowStep`s.
struct Workflow: Identifiable, Codable, Hashable {
    static let completionBonusXP = 30

    let id: UUID
    let title: String
    let summary: String
    let symbolName: String
    /// The provider this guide belongs to, or `nil` for a universal guide
    /// (e.g. domain DNS, which isn't specific to any one company).
    let company: Company?
    let steps: [WorkflowStep]

    /// Total XP a full, uninterrupted run of this workflow is worth —
    /// used by `ProgressHubView` and completion celebrations.
    var totalXPValue: Int {
        steps.reduce(Self.completionBonusXP) { $0 + $1.xpValue }
    }

    init(
        id: UUID? = nil,
        title: String,
        summary: String,
        symbolName: String,
        company: Company? = nil,
        steps: [WorkflowStep]
    ) {
        let providerKey = company?.rawValue ?? "universal"
        let workflowID = id ?? StableIdentifier.uuid("workflow", providerKey, title)

        self.id = workflowID
        self.title = title
        self.summary = summary
        self.symbolName = symbolName
        self.company = company
        self.steps = steps.enumerated().map { index, step in
            step.identified(
                as: StableIdentifier.uuid(
                    "workflow-step",
                    workflowID.uuidString,
                    String(index)
                )
            )
        }
    }
}

/// Bundled, local-only sample workflows. A real deployment would grow
/// this list; nothing here is fetched remotely. Every workflow here is
/// original Clarify content — plain-English steps for common setup
/// tasks — never text copied from any provider's own documentation.
enum WorkflowLibrary {

    // MARK: Universal

    static let dnsSetup = Workflow(
        title: "Point Your Domain at Your Website",
        summary: "Connect the name people type to the place your website actually lives.",
        symbolName: "network",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Your Domain's Settings",
                instruction: "Open your domain registrar's dashboard and look for a section called DNS settings or Nameservers.",
                jargonTerms: ["Nameserver", "DNS"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add the Address Sign",
                instruction: "Create a new A Record that points your domain at your website's numeric address.",
                jargonTerms: ["A Record"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Set Up Mail Delivery",
                instruction: "Add an MX Record so email sent to your domain reaches the right mail sorter.",
                jargonTerms: ["MX Record"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Wait for the Word to Spread",
                instruction: "Changes take time to reach every phone book copy worldwide. This is normal — check back shortly.",
                jargonTerms: ["Propagation", "TTL"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let twoFactorAuthSetup = Workflow(
        title: "Add a Second Lock to Your Accounts",
        summary: "Make sure a stolen password alone isn't enough for someone to break into your accounts.",
        symbolName: "lock.shield.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Security Settings",
                instruction: "Head into your account's settings and find the section usually labeled Security or Login. This is where the extra lock lives.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On the Second Lock",
                instruction: "Switch on Two-Factor Authentication. From now on, your password alone won't be enough to walk through the door.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Up Your Second Key",
                instruction: "Scan the code shown on screen with an Authenticator App on your phone. It's sturdier than a text message, which can be intercepted.",
                jargonTerms: ["Authenticator App"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Save Your Backup Codes",
                instruction: "Write down or print the backup codes you're given. They're spare keys for if your phone is ever lost, stolen, or dead.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let passwordManagerSetup = Workflow(
        title: "Stop Reusing the Same Password Everywhere",
        summary: "Let one trusted vault remember every password for you, so you never have to reuse a weak one again.",
        symbolName: "key.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Pick Your Vault",
                instruction: "Choose a Password Manager app and install it — think of it as a locked filing cabinet just for your passwords.",
                jargonTerms: ["Password Manager"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set One Strong Master Key",
                instruction: "Create a Master Password that's long, memorable, and used nowhere else. It's the single key that opens the whole cabinet, so make it count.",
                jargonTerms: ["Master Password"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Move Your Passwords In",
                instruction: "Import your saved browser passwords or add them one by one, filing every account safely inside the vault.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Let It Auto-Fill and Generate",
                instruction: "Turn on autofill so the vault hands over the right password instantly, and let it invent fresh, hard-to-guess passwords for any new account you open.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let vpnSetup = Workflow(
        title: "Browse Through a Private Tunnel",
        summary: "Wrap your internet traffic so no one else on the network can peek at what you're sending.",
        symbolName: "bolt.shield.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Choose a Trusted Provider",
                instruction: "Pick a reputable VPN service and install its app on your device. This app is what builds the tunnel for you.",
                jargonTerms: ["VPN"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Sign In and Connect",
                instruction: "Log in and tap Connect. Your internet traffic now travels through a locked, private tunnel instead of the open road everyone else uses.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick a Server Location",
                instruction: "Choose which country's tunnel entrance to use. This is also where the internet will think you're browsing from.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Auto-Connect for Public Wi-Fi",
                instruction: "Set the tunnel to open automatically whenever you join public networks like coffee shops and airports, where snoopers are most common.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let wifiRouterSetup = Workflow(
        title: "Set Up Your Home Wi-Fi Router",
        summary: "Get your home network up, named, and locked down so only your household can use it.",
        symbolName: "wifi",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Plug In and Power Up",
                instruction: "Connect your router to the internet box on the wall, then give it a minute to wake up and start broadcasting.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Rename Your Network",
                instruction: "Change your Wi-Fi's SSID to something you'll recognize — think of it as the name tag your network wears in the list of nearby networks.",
                jargonTerms: ["SSID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set a Strong Wi-Fi Password",
                instruction: "Replace the router's default password with your own. The default one is printed on a sticker that anyone standing nearby can read.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On a Guest Network",
                instruction: "Create a separate Guest Network so visitors can get online without ever wandering into the room where your own devices live.",
                jargonTerms: ["Guest Network"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Keep the Firmware Updated",
                instruction: "Let the router install its Firmware updates automatically — these are the patches that fix the locks before new break-in tricks are discovered.",
                jargonTerms: ["Firmware"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let cloudStorageSyncSetup = Workflow(
        title: "Keep Your Files Updated on Every Device",
        summary: "Keep the same files current across every device automatically, without emailing anything to yourself.",
        symbolName: "cloud.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Install the Sync App",
                instruction: "Download your cloud storage provider's app onto each computer or phone you use. It's the courier that keeps copies matching everywhere.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Your Sync Folder",
                instruction: "Pick a specific folder to sync. Anything placed inside gets automatically copied to the cloud and every other linked device.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Selective Sync",
                instruction: "If storage is tight, use Selective Sync to choose which folders download fully to this device, keeping the rest safely parked in the cloud.",
                jargonTerms: ["Selective Sync"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Resolve Any Sync Conflicts",
                instruction: "If the same file gets edited in two places at once, the app keeps both copies and flags a Sync Conflict so you can pick the winner.",
                jargonTerms: ["Sync Conflict"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let browserSyncSetup = Workflow(
        title: "Carry Your Bookmarks to Every Device",
        summary: "Save the pages you love once and have them waiting on every device you own.",
        symbolName: "star.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Sign In to Your Browser",
                instruction: "Log into your browser with your account instead of using it as a guest. This is what links your devices together.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Browser Sync",
                instruction: "Switch on Browser Sync so your Bookmarks, open tabs, and saved passwords travel with you from laptop to phone.",
                jargonTerms: ["Browser Sync", "Bookmark"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Organize Your Bookmarks Into Folders",
                instruction: "Group your Bookmarks into folders the way you'd file papers into labeled binders, so favorites stay easy to find.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Check Sync on a Second Device",
                instruction: "Open the browser on another device and confirm the same Bookmarks appear — proof the courier line is working.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let emailDeliverabilitySetup = Workflow(
        title: "Make Sure Your Emails Don't Land in Spam",
        summary: "Prove to other mail providers that emails from your domain really are from you, not an impersonator.",
        symbolName: "envelope.badge.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Your Domain's Settings",
                instruction: "Log into your domain registrar and open the DNS settings, the same phone book that already points people to your website.",
                jargonTerms: ["DNS"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your Sender Permission Slip",
                instruction: "Add an SPF Record, a special TXT Record that lists exactly which mail servers are allowed to send email as your domain.",
                jargonTerms: ["SPF Record", "TXT Record"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Add Your Tamper-Proof Seal",
                instruction: "Add a DKIM Record so every email you send carries an invisible signature proving it wasn't altered along the way.",
                jargonTerms: ["DKIM Record"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Tell Mailboxes What to Do With Fakes",
                instruction: "Add a DMARC Record telling other mail providers what to do if a message claims to be from you but fails the checks above — like written instructions left for a bouncer.",
                jargonTerms: ["DMARC Record"],
                visual: .dnsVisualizer,
                xpValue: 25
            )
        ]
    )

    static let searchEngineVisibilitySetup = Workflow(
        title: "Help Search Engines Find Your Site",
        summary: "Give search engines a map of your site and clear instructions on what to explore.",
        symbolName: "magnifyingglass.circle.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Create Your Site's Map",
                instruction: "Generate a Sitemap, a simple list of every page on your site, so search engines don't have to guess what exists.",
                jargonTerms: ["Sitemap"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write Your Ground Rules",
                instruction: "Add a Robots.txt file at your site's front door telling visiting search engines which areas are open to explore and which are off-limits.",
                jargonTerms: ["Robots.txt"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Register With Search Console",
                instruction: "Verify ownership of your site in Search Console and submit your Sitemap directly, like handing the map straight to the librarian instead of hoping they find it.",
                jargonTerms: ["Search Console"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch for Crawl Errors",
                instruction: "Check back periodically for pages search engines couldn't reach, and fix the broken links before they hurt how easily people find you.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let faviconSetup = Workflow(
        title: "Give Your Website Its Own Little Icon",
        summary: "Add the tiny logo that shows up in browser tabs so your site looks finished and trustworthy.",
        symbolName: "photo.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Design a Simple Square Icon",
                instruction: "Create a small, simple square image that represents your brand — this Favicon needs to stay recognizable even at the size of a fingernail.",
                jargonTerms: ["Favicon"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Export It in Multiple Sizes",
                instruction: "Save your icon in several sizes so it looks crisp whether it's shown in a browser tab, a phone's home screen, or a bookmarks bar.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Upload It to Your Site's Root",
                instruction: "Place the icon files in your website's main folder, exactly where browsers automatically look for them first.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Link It in Your Page Code",
                instruction: "Add a short line in your site's header pointing to the icon file, just in case a browser doesn't find it automatically.",
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let qrCodeSetup = Workflow(
        title: "Create a QR Code People Can Scan",
        summary: "Turn a link, menu, or contact card into a pattern anyone's camera can scan in a second.",
        symbolName: "camera.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Decide What It Should Open",
                instruction: "Pick the destination — a website, menu, or contact card — that people should land on the moment they scan.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Generate the Code",
                instruction: "Use a QR Code generator to turn that destination into a scannable pattern of squares, like a barcode packed with extra information.",
                jargonTerms: ["QR Code"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test It With Your Own Phone",
                instruction: "Scan the code yourself with a phone camera before printing or publishing it, to make sure it opens exactly where you intended.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Print or Share It at Full Size",
                instruction: "Display the code large enough, with clear space around it, that a phone camera can focus and read it easily, even from a few feet away.",
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let contactFormSpamProtection = Workflow(
        title: "Keep Bots From Flooding Your Contact Form",
        summary: "Add a few quiet trip-wires so real visitors get through but automated spam doesn't.",
        symbolName: "hand.raised.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Add a Human Check",
                instruction: "Turn on a CAPTCHA so submitters prove they're a person, not a script mass-mailing every form it can find.",
                jargonTerms: ["CAPTCHA"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set an Invisible Trap Field",
                instruction: "Add a Honeypot Field that's hidden from real visitors but visible to bots, so anything that fills it in outs itself instantly.",
                jargonTerms: ["Honeypot Field"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Rate-Limit Rapid Submissions",
                instruction: "Block a form from being submitted dozens of times a second from the same visitor, the way a bouncer stops one person from cutting the line repeatedly.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Review What Lands in Spam",
                instruction: "Check your spam folder occasionally for real messages that got caught by mistake, so genuine customers never go unanswered.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let uptimeMonitoringSetup = Workflow(
        title: "Get Alerted the Moment Your Site Goes Down",
        summary: "Have a tireless watcher check that your website is alive, so you hear about outages before your customers do.",
        symbolName: "chart.line.uptrend.xyaxis",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Choose a Monitoring Service",
                instruction: "Sign up for an uptime monitoring service — it acts like a night watchman who checks your front door on a set schedule.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Point It at Your Website",
                instruction: "Enter your website's address so the watchman knows exactly which door to check.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Check-In Schedule",
                instruction: "Choose how often the watchman knocks with a Health Check — every minute for something critical, every few minutes for everything else.",
                jargonTerms: ["Health Check"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Instant Alerts",
                instruction: "Turn on push or text alerts so you find out about Downtime the second it happens, not the next time you happen to check.",
                jargonTerms: ["Downtime"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let passkeySetup = Workflow(
        title: "Sign In Without a Password",
        summary: "Use your face, fingerprint, or screen lock instead of typing a password that can be stolen.",
        symbolName: "faceid",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Your Account's Sign-In Settings",
                instruction: "Open the security or sign-in settings for the account you want to upgrade — most apps keep this under Account or Security.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Security Settings"
            ),
            WorkflowStep(
                title: "Turn On Passkey Sign-In",
                instruction: "Choose the option to create a passkey. Your device will ask you to confirm with your face, fingerprint, or screen lock instead of typing anything.",
                jargonTerms: ["Passkey"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Save It to Your Device",
                instruction: "Your passkey is stored securely on your phone or computer, not on some far-away server, so it can't be stolen in a password leak.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test Signing In",
                instruction: "Sign out and back in to confirm your face or fingerprint unlocks the account without ever asking for a password again.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let securityKeySetup = Workflow(
        title: "Protect Your Accounts With a Physical Key",
        summary: "Add a small physical device that has to be present before anyone can sign in as you.",
        symbolName: "key.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Buy a Compatible Security Key",
                instruction: "Pick up a small USB or NFC security key from a trusted retailer — it plugs into or taps against your device to prove it's really you.",
                jargonTerms: ["Security Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Open Your Account's Two-Factor Settings",
                instruction: "Head to the security section of the account you want to protect and look for the option to add a security key.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Two-Factor Authentication"
            ),
            WorkflowStep(
                title: "Register the Key",
                instruction: "Insert or tap your key when prompted, then press its button to confirm it's physically present.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Backup Key",
                instruction: "Register a second key and store it somewhere safe, like a drawer at home, so you're not locked out if you lose the first one.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let guestWifiSetup = Workflow(
        title: "Set Up a Separate Wi-Fi for Guests",
        summary: "Let visitors get online without giving them a way onto your own devices.",
        symbolName: "wifi.circle.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Router's Settings",
                instruction: "Type your router's address into a browser (often printed on the router itself) and sign in to its admin page.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Router Admin Page"
            ),
            WorkflowStep(
                title: "Turn On the Guest Network",
                instruction: "Find the guest network option and switch it on — this creates a separate Wi-Fi that keeps visitors off your main network.",
                jargonTerms: ["Guest Network", "SSID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Give It a Name and Password",
                instruction: "Choose a network name and password just for guests, different from the one you use for your own devices.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn Off Access to Your Other Devices",
                instruction: "Make sure the guest network setting for reaching your other devices is switched off, so visitors can browse the internet but can't see your computers or smart devices.",
                jargonTerms: ["Guest Access"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let personalBackupStrategySetup = Workflow(
        title: "Back Up Your Files the Smart Way",
        summary: "Protect your photos and documents so one bad accident can never take everything at once.",
        symbolName: "externaldrive.fill.badge.checkmark",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Keep Three Copies of Anything That Matters",
                instruction: "Make sure any file you can't afford to lose exists in at least three places: the original plus two backups.",
                jargonTerms: ["3-2-1 Backup Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Use Two Different Kinds of Storage",
                instruction: "Save one backup to a physical drive and another to a cloud service, so a single type of failure can't wipe out everything.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Keep One Copy Somewhere Else Entirely",
                instruction: "Store at least one backup offsite — in the cloud or at a different location — so a fire, theft, or flood at home doesn't take out every copy.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Automate the Backups",
                instruction: "Turn on automatic, scheduled backups so you're not relying on remembering to do it yourself.",
                jargonTerms: ["Automated Backup"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let browserExtensionAuditSetup = Workflow(
        title: "Clean Up What Your Browser Extensions Can See",
        summary: "Trim down browser add-ons so fewer of them have a window into your browsing.",
        symbolName: "puzzlepiece.extension.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Browser's Extensions List",
                instruction: "Go to your browser's menu and find the page that lists every extension you've installed.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Extensions Menu"
            ),
            WorkflowStep(
                title: "Remove What You Don't Use",
                instruction: "Delete any extension you don't recognize or haven't used in months — each one is a possible way for someone to peek at your browsing.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Check What Each One Can See",
                instruction: "Open the permissions for each remaining extension and see whether it can read or change data on every website you visit.",
                jargonTerms: ["Extension Permission"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Limit Access When You Can",
                instruction: "Where your browser allows it, switch an extension's access from every website to only the sites you actually use it on.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let cookieConsentBannerSetup = Workflow(
        title: "Add a Cookie Consent Banner to Your Website",
        summary: "Ask visitors before tracking them, and stay on the right side of privacy rules.",
        symbolName: "hand.raised.square.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Decide What You're Tracking",
                instruction: "List out the cookies your site actually sets, like analytics or advertising ones, so you know what to ask visitors about.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Consent Banner",
                instruction: "Add a banner or plugin that asks first-time visitors to accept or decline non-essential cookies before they load.",
                jargonTerms: ["Cookie Consent Banner"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Block Cookies Until Someone Agrees",
                instruction: "Configure the banner so tracking cookies stay off until a visitor actually clicks accept, not just by continuing to browse.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Give Visitors a Way to Change Their Mind",
                instruction: "Add a small link or button visitors can use later to update their cookie choices whenever they want.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let xmlSitemapSubmissionSetup = Workflow(
        title: "Create and Submit a Sitemap for Your Site",
        summary: "Hand search engines a map of your site so they can find and index every page.",
        symbolName: "map.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Generate Your Sitemap",
                instruction: "Use your website platform or a free tool to create a Sitemap — a simple file listing every page you want search engines to know about.",
                jargonTerms: ["Sitemap"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Upload It to Your Site",
                instruction: "Place the sitemap file at your website's root address so it's easy for search engines to find.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point Robots.txt at It",
                instruction: "Add a line to your Robots.txt file that tells visiting search engines exactly where your sitemap lives.",
                jargonTerms: ["Robots.txt"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Submit It to Search Consoles",
                instruction: "Paste your sitemap's address into each search engine's webmaster tool so they start crawling it right away.",
                jargonTerms: ["Search Console"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let emailAliasSetup = Workflow(
        title: "Set Up an Email Alias for Your Domain",
        summary: "Hand out extra addresses that all land safely in your one real inbox.",
        symbolName: "envelope.badge.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Domain's Email Settings",
                instruction: "Log in to wherever you manage email for your domain and find the section for aliases or forwarding addresses.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Email Settings"
            ),
            WorkflowStep(
                title: "Create an Alias",
                instruction: "Set up an Email Alias, like info@yourdomain.com, that quietly forwards to your real inbox without needing its own separate mailbox.",
                jargonTerms: ["Email Alias"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On a Catch-All Address",
                instruction: "Enable a Catch-All Address so any typo'd or made-up address at your domain still lands in your inbox instead of bouncing.",
                jargonTerms: ["Catch-All Address"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm Mail Routing Records",
                instruction: "Double check your MX Record still points to the right mail service so forwarded messages actually arrive.",
                jargonTerms: ["MX Record"],
                visual: .dnsVisualizer,
                xpValue: 20
            )
        ]
    )

    static let smartHomeDeviceSetup = Workflow(
        title: "Add a New Smart Home Device Safely",
        summary: "Get a new gadget online without giving it a straight line to your other devices.",
        symbolName: "house.and.flag.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Put New Devices on Their Own Network",
                instruction: "Before pairing a new smart device, connect it to a separate Guest Network instead of the one your computers and phones use.",
                jargonTerms: ["Guest Network"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Follow the Device's Pairing Steps",
                instruction: "Open the device's companion app and follow its instructions to connect it to that separate network for the first time.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Change the Default Password",
                instruction: "Replace any default password the device shipped with using one that's unique to that device.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Automatic Updates",
                instruction: "Enable automatic firmware updates so the device keeps getting security fixes without you having to remember.",
                jargonTerms: ["Firmware"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let sessionTimeoutSetup = Workflow(
        title: "Make Your Accounts Lock Themselves",
        summary: "Set devices and accounts to sign out on their own so a forgotten login can't be misused.",
        symbolName: "lock.badge.clock.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Device's Lock Settings",
                instruction: "Go to your phone or computer's security settings and find the option for automatic locking.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Lock Screen Settings"
            ),
            WorkflowStep(
                title: "Shorten the Auto-Lock Time",
                instruction: "Set your device to lock itself after a short period of inactivity, like one or two minutes, instead of leaving it open indefinitely.",
                jargonTerms: ["Auto-Lock"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Session Timeout for Important Accounts",
                instruction: "In the security settings of accounts like banking or email, enable Session Timeout so you're automatically signed out after a period of inactivity.",
                jargonTerms: ["Session Timeout"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Require Unlocking to Get Back In",
                instruction: "Make sure a passcode, fingerprint, or face scan is required to unlock again, not just a swipe.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let parentalControlsSetup = Workflow(
        title: "Set Up Screen Time Limits for Your Kids",
        summary: "Give your child a device they can enjoy inside limits you're comfortable with.",
        symbolName: "hourglass.badge.plus",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Create a Child Account",
                instruction: "Set up a separate account for your child instead of letting them share yours, so limits apply only to them.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Screen Time Limits",
                instruction: "Choose how many hours per day your child can use the device, and pick times of day it locks automatically, like bedtime.",
                jargonTerms: ["Screen Time Limit"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On a Content Filter",
                instruction: "Enable a Content Filter to block apps and websites that aren't appropriate for your child's age.",
                jargonTerms: ["Content Filter"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Require Approval for Purchases and Downloads",
                instruction: "Turn on a setting that sends you a request to approve before your child can install a new app or spend money.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let customShortLinkSetup = Workflow(
        title: "Create a Short Link for Sharing",
        summary: "Turn a long, messy web address into something short and memorable you can hand out anywhere.",
        symbolName: "link.circle.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Pick a Link Shortening Service",
                instruction: "Choose a URL shortener, either a free public one or one tied to your own domain, that will stand in for your long link.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Paste In Your Long Link",
                instruction: "Paste the full web address you want to share into the shortener to generate a Short Link.",
                jargonTerms: ["Short Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Customize the Short Link's Ending",
                instruction: "Edit the last part of the short link to something memorable, like yourdomain.com/summer-sale, instead of a random string.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test It Before Sharing",
                instruction: "Open the short link yourself to confirm it lands on the right page before you send it out.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let rssFeedSetup = Workflow(
        title: "Set Up an RSS Feed for Your Site",
        summary: "Let readers subscribe once and automatically get every new post you publish.",
        symbolName: "dot.radiowaves.up.forward",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Check If Your Site Already Has One",
                instruction: "Many blogging platforms create an RSS Feed automatically — check for an address ending in /feed or /rss.",
                jargonTerms: ["RSS Feed"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Feed Generation",
                instruction: "If your site doesn't have one yet, turn on the RSS feed option in your platform's settings or add a plugin that creates one.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm New Posts Appear Automatically",
                instruction: "Publish a test post and check that it shows up in your feed without any extra steps.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the Feed Link",
                instruction: "Add a visible link to your feed on your site so people can subscribe with their favorite Feed Reader.",
                jargonTerms: ["Feed Reader"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let diskEncryptionSetup = Workflow(
        title: "Turn On Full-Disk Encryption",
        summary: "Lock your entire hard drive so a lost or stolen computer can't be read by anyone else.",
        symbolName: "lock.laptopcomputer",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Security Settings",
                instruction: "Head into your computer's system settings and find the section about privacy and security.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Full-Disk Encryption",
                instruction: "Flip the switch to encrypt your entire startup drive. It scrambles everything so it's unreadable without your login.",
                jargonTerms: ["Full-Disk Encryption"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Encryption toggle",
                xpValue: 20
            ),
            WorkflowStep(
                title: "Save Your Recovery Key",
                instruction: "Your computer will generate a recovery key. Write it down or store it somewhere you'll actually find it later.",
                jargonTerms: ["Recovery Key"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Store It Somewhere Separate From Your Computer",
                instruction: "Put the recovery key in a password manager or a printed note kept away from the encrypted device itself.",
                jargonTerms: ["Password Manager"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Let Encryption Finish In The Background",
                instruction: "Encrypting your whole drive can take a while. Keep the computer plugged in and let it run.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let emailSpamFilterSetup = Workflow(
        title: "Set Up Junk Mail Filtering Rules",
        summary: "Teach your inbox to catch spam automatically and stop trusted senders from getting buried.",
        symbolName: "envelope.badge.shield.half.filled",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Mail Settings",
                instruction: "Go into your email account's settings and find the filtering or junk mail section.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On The Built-In Spam Filter",
                instruction: "Make sure automatic junk detection is switched on so obvious spam gets sorted for you.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Block Repeat Offenders",
                instruction: "Add senders who keep getting through to your blocklist so their mail is turned away automatically.",
                jargonTerms: ["Blocklist"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Protect Senders You Trust",
                instruction: "Add important senders to your safe sender list so their mail never accidentally lands in junk.",
                jargonTerms: ["Safe Sender List"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write A Custom Filter Rule",
                instruction: "Create a rule that moves, labels, or deletes mail matching a certain word, sender, or subject line.",
                jargonTerms: ["Filter Rule"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Check Your Junk Folder Weekly",
                instruction: "Skim your junk folder now and then so real mail that got miscaught doesn't slip away for good.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let custom404PageSetup = Workflow(
        title: "Design A Custom Page Not Found Screen",
        summary: "Replace the default broken-link error with a friendly page that helps lost visitors find their way.",
        symbolName: "questionmark.folder",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Understand What Visitors See",
                instruction: "When someone follows a broken link, your site shows a plain 404 error by default. Let's make it more helpful.",
                jargonTerms: ["404 Error", "Broken Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find Your Site's Error Page Setting",
                instruction: "Look in your website builder or hosting dashboard for a setting labeled custom error pages or 404 page.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Design A Helpful Replacement Page",
                instruction: "Add a friendly message, a search box, and a few links back to popular pages so visitors aren't stuck.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Upload It As Your Site's 404 Page",
                instruction: "Save your new page and set it as the one shown whenever a visitor hits a 404 error.",
                jargonTerms: ["404 Error"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Test It With A Broken Link",
                instruction: "Type in a web address on your domain that doesn't exist and confirm your new page shows up instead of the default one.",
                jargonTerms: ["Broken Link"],
                visual: .plain
            )
        ]
    )

    static let publicStatusPageSetup = Workflow(
        title: "Publish A Public Status Page",
        summary: "Give users one place to check whether your service is up, so they don't have to guess or email you.",
        symbolName: "chart.bar.xaxis",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Choose A Status Page Tool",
                instruction: "Sign up for a status page service that will host a simple public page showing your service's state.",
                jargonTerms: ["Status Page"],
                visual: .plain
            ),
            WorkflowStep(
                title: "List The Parts Of Your Service",
                instruction: "Add each piece worth tracking separately, like your website, your app, and your email delivery.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Automatic Health Checks",
                instruction: "Set up a health check that pings each part of your service regularly and flags downtime the moment it happens.",
                jargonTerms: ["Health Check", "Downtime"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Post An Incident Update When Something Breaks",
                instruction: "Write a short incident update explaining what's wrong and when you expect it fixed, so people aren't left guessing.",
                jargonTerms: ["Incident Update"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share The Link With Your Users",
                instruction: "Put your status page link in your footer, support emails, and social bio so people know where to look.",
                jargonTerms: ["Status Page"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let clipboardSyncSetup = Workflow(
        title: "Sync Your Clipboard Across Devices",
        summary: "Copy something on your phone and paste it straight onto your computer, no email-to-yourself required.",
        symbolName: "doc.on.clipboard",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Sign In With The Same Account Everywhere",
                instruction: "Make sure your phone and computer are signed into the same account so they can talk to each other.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Clipboard Sync",
                instruction: "Find the clipboard sync setting on both devices and switch it on.",
                jargonTerms: ["Clipboard Sync"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Clipboard sync toggle",
                xpValue: 15
            ),
            WorkflowStep(
                title: "Turn On Paste History",
                instruction: "Enable paste history so you can grab something you copied a few steps back, not just the very last thing.",
                jargonTerms: ["Paste History"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Copy Something On One Device",
                instruction: "Select some text or an image on your phone and copy it like you normally would.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Paste It On The Other",
                instruction: "Switch to your computer and paste. It should appear instantly without any file transfer or email needed.",
                jargonTerms: ["Clipboard Sync"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let adTrackerBlockerSetup = Workflow(
        title: "Install An Ad And Tracker Blocker",
        summary: "Stop ads and hidden trackers from following you around the web, right inside your browser.",
        symbolName: "shield.lefthalf.filled",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Understand What Trackers Do",
                instruction: "Many sites load invisible trackers that watch what you click and carry that data to advertisers elsewhere.",
                jargonTerms: ["Tracker"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Install A Content Blocker Extension",
                instruction: "Add a reputable content blocker extension to your browser from its official add-on store.",
                jargonTerms: ["Content Blocker"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn It On For All Sites",
                instruction: "Confirm the blocker is enabled everywhere so it protects you by default rather than site by site.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Blocker enabled switch"
            ),
            WorkflowStep(
                title: "Add Sites To Your Blocklist Or Allowlist",
                instruction: "Fine-tune things by adding especially pushy sites to your blocklist for extra strictness.",
                jargonTerms: ["Blocklist"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Whitelist Sites That Break Without Ads",
                instruction: "Some sites depend on ad revenue and may look broken with blocking on. Add trusted ones as exceptions.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let twoFactorBackupCodesSetup = Workflow(
        title: "Generate And Store Your 2FA Backup Codes",
        summary: "Create a safety net so you can still get into your account if you ever lose your phone.",
        symbolName: "key.viewfinder",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Account's Security Settings",
                instruction: "Go to the section where you manage two-factor authentication for this account.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find The Backup Codes Option",
                instruction: "Look for a link or button offering backup codes, sometimes labeled recovery codes.",
                jargonTerms: ["Backup Code"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Generate A New Set Of Codes",
                instruction: "Create a fresh batch of one-time-use backup codes you can use if your phone is ever lost or dead.",
                jargonTerms: ["Backup Code"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Store Them Somewhere Safe",
                instruction: "Save the codes in a password manager or print them and keep the paper somewhere secure, not on your desktop.",
                jargonTerms: ["Password Manager"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Retire Old Codes When You Make New Ones",
                instruction: "Each time you generate a new set of backup codes, the old ones stop working. Update your saved copy too.",
                jargonTerms: ["Backup Code"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let encryptedNoteVaultSetup = Workflow(
        title: "Set Up An Encrypted Vault For Sensitive Notes",
        summary: "Keep passwords, ID numbers, and private thoughts in a notes app that only you can unlock.",
        symbolName: "note.text.badge.plus",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Choose A Notes App With Encryption",
                instruction: "Pick a notes app that offers end-to-end encryption, not just a regular password lock on top of plain text.",
                jargonTerms: ["End-to-End Encryption"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand Zero-Knowledge Encryption",
                instruction: "Look for apps that advertise zero-knowledge encryption, meaning even the company can't peek at your notes.",
                jargonTerms: ["Zero-Knowledge Encryption"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set A Master Password",
                instruction: "Choose a strong master password for the vault. If you forget it, your notes may be unrecoverable by design.",
                jargonTerms: ["Master Password"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Turn On Auto-Lock",
                instruction: "Set the vault to auto-lock after a short period so it stays sealed if you walk away from your device.",
                jargonTerms: ["Auto-Lock"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Move Sensitive Notes Into The Vault",
                instruction: "Transfer any passwords, ID numbers, or private notes out of regular apps and into the encrypted vault.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let openGraphPreviewSetup = Workflow(
        title: "Make Your Links Preview Nicely When Shared",
        summary: "Add a few hidden tags so your website shows a title, image, and description when pasted into a chat or post.",
        symbolName: "rectangle.and.text.magnifyingglass",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Understand What Open Graph Tags Do",
                instruction: "Open Graph tags are hidden bits of code that tell apps what to show when someone shares your link.",
                jargonTerms: ["Open Graph Tag", "Meta Tag"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick A Preview Image",
                instruction: "Choose a clear, wide image that represents your page well at a small size.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add The Tags To Your Page's Header",
                instruction: "Add the Open Graph tags for title, description, and image to the hidden header section of your page.",
                jargonTerms: ["Open Graph Tag"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Write A Short Preview Description",
                instruction: "Keep your meta tag description short and inviting, since most apps cut it off after a sentence or two.",
                jargonTerms: ["Meta Tag"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test The Preview Before Sharing",
                instruction: "Paste your link into a preview-testing tool to confirm the image and text look right before you share it widely.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let tipJarSetup = Workflow(
        title: "Set Up A Tip Jar For Your Fans",
        summary: "Give supporters a simple link where they can send you a few dollars, no storefront required.",
        symbolName: "cup.and.saucer.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Choose A Tip Jar Service",
                instruction: "Sign up for a service built for one-off tips and small donations rather than a full online store.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect A Payout Account",
                instruction: "Link a bank account or card so tips you receive actually land somewhere you can use them.",
                jargonTerms: ["Payout Account"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Create Your Payment Link",
                instruction: "Generate your personal payment link that anyone can open to send you a tip.",
                jargonTerms: ["Payment Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Customize The Page With Your Name And Photo",
                instruction: "Add your name, photo, and a short thank-you message so the page feels personal.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share The Link In Your Bio Or Videos",
                instruction: "Put your payment link in your social media bio or at the end of your videos so fans can find it easily.",
                jargonTerms: ["Payment Link"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let autoUpdateSetup = Workflow(
        title: "Turn On Automatic Updates",
        summary: "Let your devices quietly install security fixes in the background instead of you remembering to check.",
        symbolName: "arrow.triangle.2.circlepath.circle",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Software Update Settings",
                instruction: "Find the update settings for your operating system and check what's currently turned on.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand What A Patch Fixes",
                instruction: "Most updates are patches, small fixes for a specific bug or security hole rather than a whole new version.",
                jargonTerms: ["Patch"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Automatic Installation",
                instruction: "Switch on automatic updates so patches install as background updates without you having to click anything.",
                jargonTerms: ["Background Update"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Automatic Updates toggle",
                xpValue: 15
            ),
            WorkflowStep(
                title: "Choose A Time That Won't Interrupt You",
                instruction: "Set updates to install overnight or during a time you're unlikely to be mid-task.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Restart When Prompted",
                instruction: "Some patches need a restart to finish installing. Don't put it off for too many days in a row.",
                jargonTerms: ["Patch"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let routerHardeningSetup = Workflow(
        title: "Harden Your Home Router's Security",
        summary: "Close the easy doors into your home network by updating firmware, changing default passwords, and locking down remote access.",
        symbolName: "lock.shield",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Log Into Your Router's Admin Page",
                instruction: "Type your router's address into a browser and sign in with its admin login.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Update The Firmware",
                instruction: "Check for a firmware update and install it. This patches known security holes in the router's own software.",
                jargonTerms: ["Firmware"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Change The Default Admin Password",
                instruction: "Replace the factory-set admin password with a strong, unique one. Default passwords are public knowledge.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Turn Off Remote Management",
                instruction: "Disable remote management so the router's controls can only be reached from inside your home network.",
                jargonTerms: ["Remote Management"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Remote management switch"
            ),
            WorkflowStep(
                title: "Switch Encryption To WPA3",
                instruction: "Set your Wi-Fi encryption to WPA3 if your router supports it, for the strongest available protection.",
                jargonTerms: ["WPA3"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let digitalDeclutterSetup = Workflow(
        title: "Declutter Your Cloud Storage And Old Accounts",
        summary: "Clear out duplicate files and shut down accounts you no longer use before they become a security risk.",
        symbolName: "externaldrive.badge.minus",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Check Your Storage Quota",
                instruction: "Open your cloud storage settings and see how close you are to your storage quota.",
                jargonTerms: ["Storage Quota"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find And Remove Duplicate Files",
                instruction: "Search for duplicate photos and documents taking up space and delete the extra copies.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "List Accounts You Haven't Used In A Year",
                instruction: "Think through old signups, trial accounts, and apps you no longer open. Each dormant account is a lingering risk.",
                jargonTerms: ["Dormant Account"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Close Or Downgrade Dormant Accounts",
                instruction: "Delete or downgrade dormant accounts you've confirmed you no longer need, starting with the oldest ones.",
                jargonTerms: ["Dormant Account"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Empty Trash And Confirm Space Freed",
                instruction: "Empty your storage's trash or recycle bin and check that your storage quota usage actually dropped.",
                jargonTerms: ["Storage Quota"],
                visual: .plain
            )
        ]
    )

    // MARK: Google

    static let googleCloudSetup = Workflow(
        title: "Set Up Your Cloud Engine Room",
        summary: "Assemble the building blocks a Google Cloud app needs to run.",
        symbolName: "server.rack",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Find the Console",
                instruction: "Open the Google Cloud console in your browser and locate the project selector at the top of the screen.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Project Selector"
            ),
            WorkflowStep(
                title: "Assemble Your Engine Room",
                instruction: "Drag each part — the engine, the storage box, and the bouncer — into your chassis to build your digital engine room.",
                jargonTerms: ["Compute Instance", "Bucket", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Hire a Robot Employee",
                instruction: "Create a service account so your app can log in on its own, without ever using your personal password.",
                jargonTerms: ["Service Account", "IAM Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write Down Your Secret Password",
                instruction: "Generate an API key and store it somewhere safe. You'll need it to let your app talk to this project.",
                jargonTerms: ["API Key"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleSearchConsoleSetup = Workflow(
        title: "Verify Your Site with Google",
        summary: "Prove a site is yours so Google will show you how it performs in Search.",
        symbolName: "checkmark.seal.text.page.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Add Your Property",
                instruction: "Open Search Console and add your website's address as a new property.",
                jargonTerms: ["Search Console"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Property"
            ),
            WorkflowStep(
                title: "Leave a Verification Note",
                instruction: "Add the TXT record Google gives you to your domain's DNS settings, proving you own the domain.",
                jargonTerms: ["TXT Record", "DNS"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Let Visitors Sign In Safely",
                instruction: "If your app needs to read Search data on someone's behalf, set up the consent screen they'll see first.",
                jargonTerms: ["OAuth Consent Screen"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let gmailCustomDomainSetup = Workflow(
        title: "Connect Gmail to Your Own Domain",
        summary: "Route your company's email through Gmail using a domain name you already own.",
        symbolName: "envelope.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Add Your Domain",
                instruction: "Open the Google Workspace admin console and type in the web address you already own, like registering your street address with the post office.",
                jargonTerms: ["Admin Console"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Domain"
            ),
            WorkflowStep(
                title: "Prove You Own the Address",
                instruction: "Add the TXT record Google gives you to your domain's DNS settings, showing everyone you're the rightful owner.",
                jargonTerms: ["TXT Record", "DNS"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Redirect Your Mail",
                instruction: "Add Google's mail records to your DNS settings, like telling the post office to start delivering your mail to a new sorting facility.",
                jargonTerms: ["MX Record", "DNS"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Wait for the Mail to Reroute",
                instruction: "Give it some time for the change to spread across the internet before you start sending mail from your new address.",
                jargonTerms: ["Propagation", "TTL"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleAnalyticsSetup = Workflow(
        title: "Set Up Google Analytics",
        summary: "Start counting who visits your website and what they do while they're there.",
        symbolName: "chart.bar.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create Your Property",
                instruction: "Open Analytics and create a property, like putting a new counter by your store's front door.",
                jargonTerms: ["Analytics Property"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Property"
            ),
            WorkflowStep(
                title: "Give Your Site Its ID Tag",
                instruction: "Copy the measurement ID Analytics gives you — it's the name tag your counter wears so data comes back to the right store.",
                jargonTerms: ["Measurement ID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Stick the Counter on Your Pages",
                instruction: "Paste the tracking snippet into your website's code so every page reports back to your counter.",
                jargonTerms: ["Tracking Snippet"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Check the Counter Is Ticking",
                instruction: "Visit your own site and watch Analytics' real-time report to confirm the visit got counted.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleAdsConversionTracking = Workflow(
        title: "Track Conversions in Google Ads",
        summary: "Find out which ads actually lead to a sale or a sign-up.",
        symbolName: "target",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a Conversion Action",
                instruction: "Open Google Ads and set up a conversion action, like installing a bell that rings every time someone finishes checkout.",
                jargonTerms: ["Conversion Action"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Conversion Action"
            ),
            WorkflowStep(
                title: "Grab the Conversion Tag",
                instruction: "Copy the small snippet of code Ads gives you for this bell.",
                jargonTerms: ["Conversion Tag"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hang the Bell on Your Site",
                instruction: "Paste the conversion tag onto your thank-you or confirmation page so it fires at just the right moment.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Test the Bell Rings",
                instruction: "Make a test purchase or sign-up and confirm the conversion shows up in your Ads account.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleWorkspaceUserSetup = Workflow(
        title: "Add a New Teammate to Workspace",
        summary: "Set up email and tools for a new hire without touching anyone else's account.",
        symbolName: "person.badge.plus.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open the Roster",
                instruction: "In the Workspace admin console, click to add a new user, like adding a new name to the office directory.",
                jargonTerms: ["Admin Console"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add User"
            ),
            WorkflowStep(
                title: "Fill Out Their Name Badge",
                instruction: "Enter their name and choose their new email address.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Hand Them a Starter Kit",
                instruction: "Assign a license so they get access to Gmail, Docs, and the rest of the shared toolkit.",
                jargonTerms: ["User License"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Front Door Key",
                instruction: "Give them a temporary password and require them to change it the first time they sign in.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleDriveSharingSetup = Workflow(
        title: "Share a Drive Folder Safely",
        summary: "Let the right people see or edit your files without handing over the whole cabinet.",
        symbolName: "folder.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open the Folder's Lock",
                instruction: "Right-click the folder in Drive and choose Share, like unlocking one drawer of a filing cabinet instead of the whole cabinet.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Share"
            ),
            WorkflowStep(
                title: "Choose Who Gets a Key",
                instruction: "Add people by email, or turn on a link anyone can use to get in.",
                jargonTerms: ["Share Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide What They're Allowed to Do",
                instruction: "Set each person's permission level — just look, suggest changes, or fully edit.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Double-Check the Guest List",
                instruction: "Review who has access before you close the folder back up, especially if the link is public.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let firebaseProjectSetup = Workflow(
        title: "Set Up Your Firebase Project",
        summary: "Assemble the app-building blocks Firebase offers before you write a line of code.",
        symbolName: "cube.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create the Project",
                instruction: "Open the Firebase console and create a new project, like opening a fresh toolbox for your app.",
                jargonTerms: ["Firebase Project"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Project"
            ),
            WorkflowStep(
                title: "Assemble Your App's Toolkit",
                instruction: "Drag in the pieces your app needs — the sign-in guard, the filing cabinet, and the storage box — to build out your Firebase toolkit.",
                jargonTerms: ["Authentication", "Firestore", "Bucket"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Connect Your App",
                instruction: "Register your iOS or Android app inside the project so it knows where to find its new toolkit.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Ground Rules",
                instruction: "Write security rules so only the right people can read or write your data.",
                jargonTerms: ["Security Rules"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googlePlayConsoleListingSetup = Workflow(
        title: "Publish Your App's Store Listing",
        summary: "Put together the storefront page people see right before they download your app.",
        symbolName: "storefront.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Your App's Storefront",
                instruction: "In Play Console, open the store listing page for your app, like setting up a display window.",
                jargonTerms: ["Store Listing"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Store Listing"
            ),
            WorkflowStep(
                title: "Write the Sign in the Window",
                instruction: "Add your app's title, short description, and full description so shoppers know what they're getting.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Hang Up Photos",
                instruction: "Upload your app icon, screenshots, and a feature graphic — the pictures that make people stop and look.",
                jargonTerms: ["Feature Graphic"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Price Tag and Send It Out",
                instruction: "Choose your app's category and pricing, then send your listing off for review.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleMapsApiKeySetup = Workflow(
        title: "Get a Google Maps API Key",
        summary: "Unlock the ability to show maps inside your own app or website.",
        symbolName: "map.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Turn On the Maps Toolkit",
                instruction: "In the Cloud console, enable the Maps API for your project, like flipping the switch on a tool before you're allowed to use it.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Enable APIs"
            ),
            WorkflowStep(
                title: "Get Your Key",
                instruction: "Generate an API key so your app is allowed to ask Google for map data.",
                jargonTerms: ["API Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Put the Key on a Leash",
                instruction: "Restrict the key to your app or website only, so no one else can use it if they stumble across it.",
                jargonTerms: ["API Restriction"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Drop the Map Into Your App",
                instruction: "Paste the key into your app's code where the map is supposed to appear.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let youTubeChannelBrandingSetup = Workflow(
        title: "Brand Your YouTube Channel",
        summary: "Give your channel a consistent look before you publish your first video.",
        symbolName: "video.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Your Channel's Dressing Room",
                instruction: "In YouTube Studio, open the Customization tab, like stepping backstage to get your channel ready before the show.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Customization"
            ),
            WorkflowStep(
                title: "Hang Up the Banner",
                instruction: "Upload channel art, the wide banner image that stretches across the top of your page.",
                jargonTerms: ["Channel Art"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick Your Profile Picture",
                instruction: "Add a profile picture and a short description so viewers know who's talking.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your Signature",
                instruction: "Upload a watermark that appears in the corner of every video, like a little signature stamped on each page.",
                jargonTerms: ["Channel Watermark"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleTagManagerSetup = Workflow(
        title: "Build Your Tag Manager Container",
        summary: "Organize all your website's tracking tags in one tidy toolbox.",
        symbolName: "list.bullet.rectangle.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create Your Container",
                instruction: "Open Tag Manager and create a container for your website, like getting a toolbox with your site's name stamped on it.",
                jargonTerms: ["Tag Manager Container"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Container"
            ),
            WorkflowStep(
                title: "Assemble Your Tags",
                instruction: "Drag in the pieces you need — the tag that fires, the trigger that sets it off, and the variable that fills in the details.",
                jargonTerms: ["Tag", "Trigger", "Variable"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Install the Toolbox",
                instruction: "Paste the container snippet into your website's code so it can start running your tags.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish Your Changes",
                instruction: "Preview your setup to make sure everything fires correctly, then publish it live.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleBusinessProfileSetup = Workflow(
        title: "Verify Your Google Business Profile",
        summary: "Prove your business is real so it can show up on Google Maps and Search.",
        symbolName: "building.columns.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Claim Your Storefront",
                instruction: "Search for your business on Google and claim it, like putting your name on the mailbox outside your shop.",
                jargonTerms: ["Business Profile"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Business"
            ),
            WorkflowStep(
                title: "Fill In the Shop Details",
                instruction: "Add your address, hours, and phone number so customers know when and where to find you.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Prove It's Really Yours",
                instruction: "Choose a verification method — a postcard, phone call, or email — and complete the steps Google sends you.",
                jargonTerms: ["Verification Code"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Open the Doors",
                instruction: "Once verified, your profile goes live on Maps and Search for customers to find.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleRecaptchaSetup = Workflow(
        title: "Add reCAPTCHA to Your Site",
        summary: "Keep bots out of your forms without making real visitors jump through hoops.",
        symbolName: "checkmark.shield.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Register Your Site",
                instruction: "Open the reCAPTCHA admin console and register your website's address.",
                jargonTerms: ["reCAPTCHA"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Register Site"
            ),
            WorkflowStep(
                title: "Collect Your Two Keys",
                instruction: "Copy the site key and secret key Google gives you — one goes on your page, the other stays hidden on your server.",
                jargonTerms: ["Site Key", "Secret Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Post the Guard at the Door",
                instruction: "Add the site key to your form's code so the guard appears right where visitors sign up or check out.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Teach Your Server to Check ID",
                instruction: "Use the secret key on your server to double-check that each submission actually passed the guard.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleAdsCampaignSetup = Workflow(
        title: "Launch a Google Ads Campaign",
        summary: "Put your business in front of people searching for exactly what you sell.",
        symbolName: "megaphone.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Pick Your Goal",
                instruction: "Tell Google what you want the ad to do — get more sales, more phone calls, or more visits to your website — so it can steer your campaign toward that result.",
                jargonTerms: ["Campaign Goal"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set a Daily Budget",
                instruction: "Decide the most you're willing to spend per day, and choose how Google should bid for your ads to stay within that limit.",
                jargonTerms: ["Campaign Budget", "Bidding Strategy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Your Keywords",
                instruction: "List the words and phrases people might type into Google when they're looking for what you offer — these are what trigger your ad to appear.",
                jargonTerms: ["Keyword Match Type"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Keywords Tab"
            ),
            WorkflowStep(
                title: "Write Your Ad",
                instruction: "Write a short headline and description that tells people what you offer and why they should click, then publish your campaign.",
                jargonTerms: ["Ad Group"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleCalendarSharingSetup = Workflow(
        title: "Share Your Calendar & Take Bookings",
        summary: "Let others see when you're free and grab a slot without the back-and-forth emails.",
        symbolName: "calendar.badge.clock",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Calendar Settings",
                instruction: "In Google Calendar, find the calendar you want to share in the sidebar and open its settings.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Settings and Sharing"
            ),
            WorkflowStep(
                title: "Decide Who Can See It",
                instruction: "Choose whether to share your calendar with everyone, just people in your organization, or specific people by email.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Build a Booking Page",
                instruction: "Turn on appointment scheduling and set the hours you're available, so people can pick an open slot themselves.",
                jargonTerms: ["Booking Page"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Send the Link",
                instruction: "Copy your booking page link and share it anywhere — email, text, or your website — so people can book time with you instantly.",
                jargonTerms: ["Share Link"],
                visual: .plain
            )
        ]
    )

    static let googleFormsSetup = Workflow(
        title: "Build a Form to Collect Info",
        summary: "Gather answers, sign-ups, or feedback from anyone with a simple shareable form.",
        symbolName: "list.clipboard.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Start a New Form",
                instruction: "Open Google Forms and start a blank form, then give it a title that tells people what it's for.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Blank Form"
            ),
            WorkflowStep(
                title: "Add Your Questions",
                instruction: "Add each question you want answered, choosing whether people type a short answer, pick from a list, or select multiple choices.",
                jargonTerms: ["Question Type"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Response Collection",
                instruction: "Decide where answers should go — a spreadsheet works well — so every submission lands somewhere you can review later.",
                jargonTerms: ["Response Destination"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the Form",
                instruction: "Send the form's link by email or post it on your site, and watch responses roll in automatically.",
                jargonTerms: ["Share Link"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let firebaseAuthSetup = Workflow(
        title: "Let People Sign Into Your App",
        summary: "Give your app's users a safe way to create accounts and log back in.",
        symbolName: "person.badge.key.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Authentication",
                instruction: "In your Firebase project, open the Authentication section where you'll manage how people sign in.",
                jargonTerms: ["Firebase Project"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Authentication"
            ),
            WorkflowStep(
                title: "Turn On a Sign-In Method",
                instruction: "Choose how people will sign in — email and password, or a button for Google, Apple, or another service — and switch it on.",
                jargonTerms: ["Sign-In Provider"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Rules for New Accounts",
                instruction: "Decide whether new users need to verify their email before they can use the app, keeping out fake sign-ups.",
                jargonTerms: ["Verification Code"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test With a Real Account",
                instruction: "Create a test account and sign in from your app to make sure the whole login process works end to end.",
                jargonTerms: ["Authentication"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let firebaseCloudMessagingSetup = Workflow(
        title: "Send Push Notifications with Firebase",
        summary: "Reach your app's users with alerts even when they're not inside the app.",
        symbolName: "bell.badge.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Connect Your App",
                instruction: "In Firebase, register your app under Cloud Messaging so it knows where to deliver notifications.",
                jargonTerms: ["Firebase Project"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Cloud Messaging"
            ),
            WorkflowStep(
                title: "Add the Messaging Piece",
                instruction: "Add the Cloud Messaging library to your app's code so it can receive notifications sent from Firebase.",
                jargonTerms: ["Cloud Messaging"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Get Permission to Notify",
                instruction: "Make sure your app asks the person's permission before sending notifications — most phones require this before anything can be delivered.",
                jargonTerms: ["Push Notification Certificate"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Send a Test Notification",
                instruction: "Write a short test message in Firebase and send it to your own device to confirm notifications are arriving.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleGroupsSetup = Workflow(
        title: "Create a Team Mailing List",
        summary: "Give your team one email address that reaches everyone on it at once.",
        symbolName: "person.3.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a New Group",
                instruction: "In the Admin Console, create a group and give it an email address, like sales@yourcompany.com.",
                jargonTerms: ["Admin Console"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Group"
            ),
            WorkflowStep(
                title: "Add Members",
                instruction: "Add the people who should receive mail sent to this address, so messages to the group land in every one of their inboxes.",
                jargonTerms: ["Group Membership"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Who Can Post",
                instruction: "Choose whether anyone can email the group or only members, to keep spam and outsiders out of the conversation.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Try It Out",
                instruction: "Send a test email to the group address and confirm it reaches every member's inbox.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleMerchantCenterSetup = Workflow(
        title: "List Your Products for Google Shopping",
        summary: "Get your products showing up when shoppers search for what you sell.",
        symbolName: "cart.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create Your Merchant Account",
                instruction: "Sign up for Merchant Center and tell Google a bit about your business and where you ship.",
                jargonTerms: ["Merchant Center"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Business Info"
            ),
            WorkflowStep(
                title: "Prove the Store Is Yours",
                instruction: "Verify and claim your website so Google knows the products you list actually belong to your store.",
                jargonTerms: ["DNS", "TXT Record"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Build Your Product Feed",
                instruction: "Upload a file listing every product you sell, with its price, photo, and description, so Google can show it to shoppers.",
                jargonTerms: ["Product Feed"],
                visual: .plain,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Turn On Shopping Ads",
                instruction: "Link your Merchant Center account to Google Ads so your products can appear as shopping ads in search results.",
                visual: .plain
            )
        ]
    )

    static let youTubeDataApiKeySetup = Workflow(
        title: "Get a Key to Pull YouTube Data",
        summary: "Let your app or script fetch video stats and playlists straight from YouTube.",
        symbolName: "play.rectangle.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Turn On the YouTube API",
                instruction: "In your Google Cloud project, find the YouTube Data API in the library and turn it on.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Enable API"
            ),
            WorkflowStep(
                title: "Create Your API Key",
                instruction: "Generate an API key so your app can request video and channel data on your behalf.",
                jargonTerms: ["API Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Lock the Key Down",
                instruction: "Restrict your new key so it only works for the YouTube API and only from your app, keeping it useless to anyone who steals it.",
                jargonTerms: ["API Restriction"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Make a Test Request",
                instruction: "Use your key to fetch details about a single video and confirm you get real data back, keeping an eye on how much of your daily allowance it uses.",
                jargonTerms: ["Quota"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleTagSetup = Workflow(
        title: "Add the Google Tag to Your Site",
        summary: "Install one snippet that lets Google's tools measure what happens on your site.",
        symbolName: "chevron.left.forwardslash.chevron.right",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Get Your Tag ID",
                instruction: "Create a Google Tag and copy the small ID it gives you — this identifies your site to Google's tools.",
                jargonTerms: ["Measurement ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Tag ID"
            ),
            WorkflowStep(
                title: "Paste the Snippet",
                instruction: "Paste the tag's code into every page of your site, right near the top, so it loads before anything else.",
                jargonTerms: ["Tracking Snippet"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Your Tools",
                instruction: "Link the tag to Google Ads or Analytics so the data it collects flows into the reports you actually look at.",
                jargonTerms: ["Analytics Property"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm It's Firing",
                instruction: "Visit your own site and check the tag's live status to make sure it's actually sending data.",
                jargonTerms: ["Tag"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let cloudRunDeploySetup = Workflow(
        title: "Deploy Your App to Cloud Run",
        summary: "Get your app live on the internet without managing a single server.",
        symbolName: "shippingbox.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Package Your App",
                instruction: "Wrap your app in a container image — a self-contained box holding your code and everything it needs to run.",
                jargonTerms: ["Container Image"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble Your Service",
                instruction: "Drag your container image, a service, and a scaling rule into place to build the machine that will run your app.",
                jargonTerms: ["Container Image", "Compute Instance", "Auto Scaling Group"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Choose Who Can Reach It",
                instruction: "Decide whether anyone on the internet can open your app or only people you approve, before you let the world in.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Go Live",
                instruction: "Deploy your service and get a public web address you can share right away.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let cloudStorageCdnSetup = Workflow(
        title: "Put a Speed Booster in Front of Your Files",
        summary: "Serve images and downloads fast to visitors anywhere in the world.",
        symbolName: "bolt.horizontal.circle.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a Storage Bucket",
                instruction: "Make a bucket to hold your files — images, videos, downloads — and upload what you want people to access.",
                jargonTerms: ["Bucket"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Bucket"
            ),
            WorkflowStep(
                title: "Make It Public (Carefully)",
                instruction: "Set a bucket policy that allows anyone to view the files, without giving them the power to change or delete anything.",
                jargonTerms: ["Bucket Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Speed Booster",
                instruction: "Turn on Cloud CDN in front of your bucket so copies of your files are cached closer to visitors, loading much faster.",
                jargonTerms: ["Cloud CDN"],
                visual: .plain,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Point Your Domain at It",
                instruction: "Add a DNS record pointing your own domain at the CDN, so files load from a friendly address instead of a long Google URL.",
                jargonTerms: ["DNS", "CNAME"],
                visual: .dnsVisualizer
            )
        ]
    )

    static let googleWorkspaceSharedDriveSetup = Workflow(
        title: "Set Up a Team Shared Drive",
        summary: "Give your whole team one shared home for files that doesn't disappear when someone leaves.",
        symbolName: "externaldrive.fill.badge.person.crop",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create the Shared Drive",
                instruction: "In Google Drive, create a new shared drive and give it a name your team will recognize.",
                visual: .consoleOverlay,
                overlayTargetLabel: "New Shared Drive"
            ),
            WorkflowStep(
                title: "Add Your Team",
                instruction: "Add the people who need access and decide whether each person can just view files or also edit and organize them.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Organize With Folders",
                instruction: "Set up folders for each project or topic so files land somewhere sensible instead of one giant pile.",
                jargonTerms: ["Document Library"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Ground Rules",
                instruction: "Decide whether members can remove files or only managers can, protecting the drive from accidental deletions.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleCloudBudgetAlertsSetup = Workflow(
        title: "Get Warned Before You Overspend",
        summary: "Have Google Cloud tap you on the shoulder before a surprise bill shows up.",
        symbolName: "exclamationmark.triangle.fill",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Billing",
                instruction: "In the console, open the Billing section for your project to see where budgets and alerts live.",
                jargonTerms: ["Subscription"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Billing"
            ),
            WorkflowStep(
                title: "Set a Spending Limit",
                instruction: "Create a budget and enter the dollar amount you don't want to go over in a month.",
                jargonTerms: ["Budget"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose When to Be Warned",
                instruction: "Set alert thresholds, like 50%, 90%, and 100% of your budget, so you get a heads-up well before you hit the limit.",
                jargonTerms: ["Alert Threshold"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Who Gets Notified",
                instruction: "Add the email addresses that should receive the warning, so the right person sees it, not just you.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleAnalyticsEventTrackingSetup = Workflow(
        title: "Track Custom Events in Analytics",
        summary: "Teach your Analytics property to notice specific actions people take, like button clicks or form submissions, instead of just page views.",
        symbolName: "chart.bar.xaxis",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Your Analytics Property",
                instruction: "Sign in to Analytics and select the property tied to your site or app — everything you set up next will report into this one bucket of data.",
                jargonTerms: ["Analytics Property", "Measurement ID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide What Counts as an Event",
                instruction: "Pick one meaningful action to track first, like 'newsletter signup' or 'video played,' rather than trying to track everything at once.",
                jargonTerms: ["Custom Event"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Name the Event and Its Details",
                instruction: "Give your event a clear name and attach extra details that describe what happened, such as which button was clicked or which video played.",
                jargonTerms: ["Event Parameter"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add the Tracking Code to Your Site",
                instruction: "Drop the small snippet of tracking code onto the page or screen where the action happens so it fires the event at the right moment.",
                jargonTerms: ["Tracking Snippet"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Watch It Happen in Real Time",
                instruction: "Trigger the action yourself and confirm the event shows up on the realtime report before you trust the data long-term.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Realtime",
                xpValue: 20
            ),
            WorkflowStep(
                title: "Mark It as a Key Event",
                instruction: "Flag the event as a key event so it gets highlighted in reports and can be used as a goal for ad campaigns later.",
                jargonTerms: ["Custom Event"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let googleSearchConsoleIndexingRequestSetup = Workflow(
        title: "Ask Google to Re-Crawl a Page",
        summary: "Nudge Google to revisit a page you just published or fixed, instead of waiting for it to notice on its own.",
        symbolName: "magnifyingglass",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Search Console",
                instruction: "Sign in to Search Console and select the verified property that owns the page you want re-crawled.",
                jargonTerms: ["Search Console"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Paste the Page URL",
                instruction: "Paste the exact web address of the page into the inspection box at the top of the screen.",
                jargonTerms: ["URL Inspection Tool"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Check the Current Status",
                instruction: "Review whether Google has crawled this page before, when it last visited, and whether it found any problems.",
                jargonTerms: ["Crawl"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Request Indexing",
                instruction: "Tap the request button to ask Google to add this page to its crawl queue soon, instead of waiting for its normal schedule.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Request Indexing",
                xpValue: 20
            ),
            WorkflowStep(
                title: "Double-Check Your Sitemap",
                instruction: "Make sure the page is also listed in your sitemap so Google keeps finding it automatically in the future.",
                jargonTerms: ["Sitemap"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let googlePlayInternalTestingSetup = Workflow(
        title: "Set Up an Internal Testing Track",
        summary: "Get your app in front of a small trusted group before it ever reaches the public Play Store listing.",
        symbolName: "checkmark.shield",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create the Testing Track",
                instruction: "Inside Play Console, create a new internal testing track — a private lane your app can travel through before going public.",
                jargonTerms: ["Testing Track"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Upload Your App Bundle",
                instruction: "Upload the packaged build of your app so Play Console can prepare it for your testers' devices.",
                jargonTerms: ["App Bundle"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Add Your Testers",
                instruction: "Add the email addresses of the people who should get early access, either one by one or as a group list.",
                jargonTerms: ["Tester List"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the Opt-In Link",
                instruction: "Send testers the opt-in link — they'll need to accept it once before the app shows up for them in the Play Store.",
                jargonTerms: ["Share Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Roll Out the Build",
                instruction: "Publish the build to the testing track so it starts reaching everyone on your tester list within a few hours.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleCloudPubSubSetup = Workflow(
        title: "Connect Two Systems with Pub/Sub",
        summary: "Set up a messaging channel where one part of your system can announce events and other parts can listen in, without talking to each other directly.",
        symbolName: "antenna.radiowaves.left.and.right",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a Topic",
                instruction: "Create a topic to act as the announcement board where messages get posted.",
                jargonTerms: ["Pub/Sub Topic"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Identify Your Publisher",
                instruction: "Decide which part of your system will post messages to the topic — this is your publisher.",
                jargonTerms: ["Publisher"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Subscription",
                instruction: "Create a subscription so a listening service can receive a copy of every message posted to the topic.",
                jargonTerms: ["Pub/Sub Subscription"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose a Delivery Method",
                instruction: "Pick whether messages get pushed to your service automatically or pulled in whenever your service checks for them.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Assemble and Test the Pipeline",
                instruction: "Wire the publisher, topic, and subscription together, then send a test message and confirm it arrives on the other end.",
                jargonTerms: ["Pub/Sub Topic", "Pub/Sub Subscription"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            )
        ]
    )

    static let googleCloudSqlSetup = Workflow(
        title: "Launch a Managed Database",
        summary: "Spin up a fully managed database server so you don't have to install, patch, or babysit the database software yourself.",
        symbolName: "cylinder.split.1x2",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a Cloud SQL Instance",
                instruction: "Create a new database instance and choose how much processing power and storage it should have.",
                jargonTerms: ["Cloud SQL Instance"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose the Database Engine",
                instruction: "Pick which database software should run on the instance, matching whatever your app was built to talk to.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Root Password",
                instruction: "Set a strong root password now — you'll need it any time you connect with full administrative access.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Note the Connection Name",
                instruction: "Copy down the connection name — it's the unique address your app will use to find this exact database instance.",
                jargonTerms: ["Connection Name"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn on Automated Backups",
                instruction: "Enable automated backups so a recent copy of your data is always saved somewhere safe, even if something goes wrong.",
                jargonTerms: ["Automated Backup"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Connection",
                instruction: "Connect your app to the instance using the connection name and credentials, then confirm a test query returns data.",
                jargonTerms: ["Cloud SQL Instance"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 20
            )
        ]
    )

    static let googleCloudSchedulerSetup = Workflow(
        title: "Automate a Recurring Task with Cloud Scheduler",
        summary: "Set up a job that runs itself on a timer, like a cloud version of setting an alarm clock for your code.",
        symbolName: "clock.arrow.circlepath",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Create a Scheduled Job",
                instruction: "Create a new scheduled job and give it a name that describes what it does, like 'nightly report' or 'weekly cleanup.'",
                jargonTerms: ["Scheduled Job"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Cron Expression",
                instruction: "Enter a cron expression to describe exactly when the job should run, such as every day at 2 a.m.",
                jargonTerms: ["Cron Expression"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose the Target",
                instruction: "Point the job at whatever it should trigger when it fires, such as a web address or a piece of backend code.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set a Time Zone",
                instruction: "Set the time zone the schedule should follow so 'every day at 2 a.m.' means what you actually expect.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Run It Once to Test",
                instruction: "Trigger the job manually once and confirm it did what it was supposed to before letting it run on its own.",
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let firestoreSecurityRulesSetup = Workflow(
        title: "Write Basic Firestore Security Rules",
        summary: "Decide who is allowed to read and write your app's data before anyone else can peek at or edit it.",
        symbolName: "lock.doc",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open the Rules Editor",
                instruction: "Open the security rules editor for your database — this is where you write the permissions that guard every record.",
                jargonTerms: ["Security Rules"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand the Document Path",
                instruction: "Look at the document path pattern, which describes the address of the records you're about to write rules for.",
                jargonTerms: ["Document Path"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write a Read Rule",
                instruction: "Write a rule that decides who's allowed to read a given record, such as only the user who owns it.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Write a Write Rule",
                instruction: "Write a matching rule for who's allowed to create or edit a record, keeping it just as strict as the read rule.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Require Sign-In",
                instruction: "Make sure your rules check that someone is actually signed in before granting any access at all.",
                jargonTerms: ["Authentication"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test the Rules Before Publishing",
                instruction: "Run the built-in simulator with a few sample requests to confirm the rules block what they should and allow what they should.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let firebaseRemoteConfigSetup = Workflow(
        title: "Add Feature Flags with Remote Config",
        summary: "Change how your app behaves for users who already have it installed, without shipping a brand-new app update.",
        symbolName: "flag.checkered",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Your Firebase Project",
                instruction: "Open the Firebase project connected to your app — this is where the remote settings for that app live.",
                jargonTerms: ["Firebase Project"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Remote Config Parameter",
                instruction: "Create a parameter with a name your app's code will check, like 'show_holiday_banner.'",
                jargonTerms: ["Remote Config Parameter"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set a Default Value",
                instruction: "Give the parameter a safe default value so the app behaves sensibly even if it can't reach Remote Config.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Create a Targeting Condition",
                instruction: "Optionally add a condition so only certain users, like those on a newer app version, get a different value.",
                jargonTerms: ["Targeting Condition"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish the Change",
                instruction: "Publish your changes so they start rolling out to devices the next time the app checks in.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Publish changes",
                xpValue: 20
            )
        ]
    )

    static let googleWorkspaceVaultSetup = Workflow(
        title: "Set Up Google Vault for Records Retention",
        summary: "Preserve emails and files for as long as your company or a legal case requires, even if someone tries to delete them.",
        symbolName: "archivebox",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Vault from the Admin Console",
                instruction: "Sign in to the admin console and open Vault — the tool that governs how long your organization's data sticks around.",
                jargonTerms: ["Admin Console"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Retention Rule",
                instruction: "Set a retention rule that decides how long email or file content should be kept before it's eligible for deletion.",
                jargonTerms: ["Retention Policy"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Open a Matter",
                instruction: "Create a matter to group together everything related to one specific investigation, audit, or legal case.",
                jargonTerms: ["Vault Matter"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Place a Legal Hold",
                instruction: "Apply a legal hold on the matter so relevant content is preserved automatically, even if a user tries to delete it.",
                jargonTerms: ["Legal Hold"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Search and Export",
                instruction: "Search within the matter for the specific content you need, then export the results for review.",
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let googleAdsRemarketingSetup = Workflow(
        title: "Build a Remarketing Audience in Google Ads",
        summary: "Show ads specifically to people who already visited your site, instead of starting from scratch with strangers.",
        symbolName: "person.crop.circle.badge.clock",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Add the Ads Tag to Your Site",
                instruction: "Place the tag on your site so Ads can start recognizing visitors as they browse around.",
                jargonTerms: ["Tag"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create the Remarketing Audience",
                instruction: "Build an audience made up of people who visited a specific page, like your pricing page or shopping cart.",
                jargonTerms: ["Remarketing Audience"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Audience Duration",
                instruction: "Choose how many days someone stays in the audience after their visit before they age back out.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set a Frequency Cap",
                instruction: "Limit how many times a single person can see your remarketing ad in a day, so you don't wear out your welcome.",
                jargonTerms: ["Frequency Cap"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Launch the Campaign",
                instruction: "Create a campaign that targets your new audience and set the budget you're comfortable spending on it.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let googleCloudLoadBalancingSetup = Workflow(
        title: "Spread Traffic with a Cloud Load Balancer",
        summary: "Set up a traffic director that sends visitors to whichever server has room, so no single machine gets overwhelmed.",
        symbolName: "arrow.triangle.branch",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Define a Backend Service",
                instruction: "Group the servers that should handle traffic into a backend service, which the load balancer will spread requests across.",
                jargonTerms: ["Backend Service"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Attach a Health Check",
                instruction: "Attach a health check so the load balancer keeps polling each server and stops sending traffic to any that stop responding.",
                jargonTerms: ["Health Check"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Forwarding Rule",
                instruction: "Create a forwarding rule that tells incoming requests which address and port should lead to your load balancer.",
                jargonTerms: ["Forwarding Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point Your Domain at It",
                instruction: "Update your domain's records to point at the load balancer's address instead of at a single server.",
                jargonTerms: ["Load Balancer"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Assemble and Verify",
                instruction: "Connect the backend service, health check, and forwarding rule together, then confirm traffic reaches your servers from the new address.",
                jargonTerms: ["Backend Service", "Forwarding Rule"],
                visual: .engineRoom,
                engineRoomKit: .google,
                xpValue: 25
            )
        ]
    )

    static let googleIdentityServicesSetup = Workflow(
        title: "Add Sign In with Google to Your Website",
        summary: "Let visitors log into your site using their existing Google account instead of creating yet another password.",
        symbolName: "person.badge.key",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Configure the Consent Screen",
                instruction: "Fill out the consent screen so visitors see your app's name and logo when Google asks permission to share their info.",
                jargonTerms: ["OAuth Consent Screen"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Client ID",
                instruction: "Create a client ID, which is the public identifier your website uses to tell Google which app is asking to sign someone in.",
                jargonTerms: ["Client ID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Redirect URI",
                instruction: "Register the exact web address Google should send people back to once they finish signing in.",
                jargonTerms: ["Redirect URI"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add the Sign-In Button",
                instruction: "Drop the official Sign in with Google button onto your page so visitors have a one-tap way to log in.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Verify the Token on Your Server",
                instruction: "Check the signed token Google hands back on your server before trusting that the sign-in is genuine.",
                jargonTerms: ["ID Token"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let lookerStudioDashboardSetup = Workflow(
        title: "Build a Shareable Dashboard in Looker Studio",
        summary: "Turn raw spreadsheet or analytics numbers into a live report you can hand to anyone, without them needing a login to your data.",
        symbolName: "chart.pie",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Connect a Data Source",
                instruction: "Connect the spreadsheet, database, or analytics account you want the dashboard to pull its numbers from.",
                jargonTerms: ["Data Source"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your First Chart",
                instruction: "Drag a chart onto the canvas and point it at the fields you want to visualize.",
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Create a Calculated Field",
                instruction: "Build a calculated field to combine or transform existing data, like turning raw counts into a percentage.",
                jargonTerms: ["Calculated Field"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Filter Control",
                instruction: "Add a filter control so anyone viewing the dashboard can narrow the numbers down, like picking a date range.",
                jargonTerms: ["Filter Control"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the Report",
                instruction: "Share the finished dashboard with a link so others can view live numbers without ever touching your original data source.",
                jargonTerms: ["Share Link"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    // MARK: Apple

    static let appleTestFlightSetup = Workflow(
        title: "Get Your App Ready for TestFlight",
        summary: "Take a build from your computer to testers' devices.",
        symbolName: "airplane.circle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Give Your App a Name Tag",
                instruction: "Register an App ID in your developer account so Apple's systems can recognize this app going forward.",
                jargonTerms: ["App ID", "Developer Team"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create the Backstage Pass",
                instruction: "Generate a provisioning profile that links your app, your team, and your test devices together.",
                jargonTerms: ["Provisioning Profile"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Provisioning Profiles"
            ),
            WorkflowStep(
                title: "Send It to the Rehearsal Space",
                instruction: "Upload your build to App Store Connect, then add it to a TestFlight group so testers can install it.",
                jargonTerms: ["TestFlight"],
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let applePushSetup = Workflow(
        title: "Set Up Push Notifications",
        summary: "Let your app send timely alerts, the right way.",
        symbolName: "bell.badge.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Request the License",
                instruction: "Create a push notification certificate for your App ID in your developer account.",
                jargonTerms: ["Push Notification Certificate", "App ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Certificates"
            ),
            WorkflowStep(
                title: "Test on the Practice Channel",
                instruction: "Send a few test notifications through the sandbox environment before your app goes live.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleAppStoreListingSetup = Workflow(
        title: "Build Your App Store Listing",
        summary: "Turn your app into something people want to tap on.",
        symbolName: "list.bullet.rectangle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Open Your App's Storefront",
                instruction: "Create your app's record in App Store Connect — think of it as reserving the storefront window your app will live in before anything else gets built out.",
                jargonTerms: ["App Store Connect"],
                visual: .consoleOverlay,
                overlayTargetLabel: "My Apps"
            ),
            WorkflowStep(
                title: "Write the Sales Pitch",
                instruction: "Fill in your app's name, subtitle, and description — the words that convince someone browsing to stop scrolling and tap Get.",
                jargonTerms: ["Metadata"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Speak Your Customers' Language",
                instruction: "Add translations for each language you support, since App Store Connect keeps a separate storefront copy for every localization.",
                jargonTerms: ["Localization"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Localizations"
            ),
            WorkflowStep(
                title: "Pick Your Category",
                instruction: "Choose the primary and secondary categories that decide which charts and search results your app can show up in.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Send It Out for a Look",
                instruction: "Submit the listing for review so Apple can check it before it goes live to shoppers.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Submit for Review",
                xpValue: 25
            )
        ]
    )

    static let appleInAppPurchaseSetup = Workflow(
        title: "Set Up an In-App Purchase",
        summary: "Let people pay for something extra without ever leaving your app.",
        symbolName: "cart.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Decide What You're Selling",
                instruction: "Choose whether you're offering a one-time unlock, something consumable like coins, or a recurring subscription — this decides which kind of In-App Purchase you'll create.",
                jargonTerms: ["In-App Purchase"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add It to the Menu",
                instruction: "Create the product in App Store Connect with its own reference name and price, like adding a new item to a restaurant menu.",
                visual: .consoleOverlay,
                overlayTargetLabel: "In-App Purchases"
            ),
            WorkflowStep(
                title: "Write the Price Tag",
                instruction: "Set a display name and description shoppers will see on the purchase screen, plus the price tier it sells for.",
                jargonTerms: ["Metadata"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test With Play Money",
                instruction: "Use a sandbox tester account to buy the item for free and confirm the unlock actually works before real money is involved.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Get the Green Light",
                instruction: "Submit the purchase alongside your app build so Apple's reviewers can approve it before it goes live.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Submit for Review",
                xpValue: 25
            )
        ]
    )

    static let appleSignInWithAppleSetup = Workflow(
        title: "Add Sign in with Apple",
        summary: "Give people a one-tap, privacy-friendly way to log in.",
        symbolName: "person.crop.circle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Flip the Switch on Your App ID",
                instruction: "Turn on the Sign in with Apple capability for your App ID, like unlocking a feature on a hotel key card.",
                jargonTerms: ["App ID", "Sign in with Apple"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Capabilities"
            ),
            WorkflowStep(
                title: "Set Up the Front Desk",
                instruction: "Configure a Services ID if you also need Sign in with Apple to work on a website, giving your web login its own name tag.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Identifiers"
            ),
            WorkflowStep(
                title: "Cut the Backstage Key",
                instruction: "Generate a private key so your server can verify that sign-in requests really came from Apple.",
                jargonTerms: ["API Key"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Keys"
            ),
            WorkflowStep(
                title: "Add the Button and Test the Handshake",
                instruction: "Drop the Sign in with Apple button into your app and confirm a real sign-in round-trips correctly between your app and your server.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleScreenshotsPreviewSetup = Workflow(
        title: "Add Screenshots and Preview Videos",
        summary: "Show off your app before anyone has even opened it.",
        symbolName: "photo.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Capture Every Screen Size",
                instruction: "Take screenshots on each device size Apple requires, since the App Store shows a differently-sized storefront on an iPhone versus an iPad.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Film a Quick Trailer",
                instruction: "Record a short App Preview video that shows your app actually being used, like a movie trailer instead of a poster.",
                jargonTerms: ["App Preview"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hang Them in the Window",
                instruction: "Upload your screenshots and preview videos in App Store Connect and arrange them in the order shoppers will see them.",
                visual: .consoleOverlay,
                overlayTargetLabel: "App Previews and Screenshots"
            ),
            WorkflowStep(
                title: "Preview the Storefront",
                instruction: "Check how everything looks on the actual App Store product page before you submit, since text can wrap differently than expected.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleTestFlightExternalGroupSetup = Workflow(
        title: "Open TestFlight to Outside Testers",
        summary: "Bring in testers beyond your own team.",
        symbolName: "person.3.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Build the Guest List",
                instruction: "Create an external testing group in TestFlight, separate from your internal team, for testers outside your company.",
                jargonTerms: ["TestFlight"],
                visual: .consoleOverlay,
                overlayTargetLabel: "External Testing"
            ),
            WorkflowStep(
                title: "Invite the Guests",
                instruction: "Add testers by email so they receive an invitation to install your build through TestFlight.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Explain What They're Testing",
                instruction: "Write test notes describing what changed and what you want feedback on, like a note left for a house-sitter.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Pass the Front Desk Check",
                instruction: "Submit the build for Apple's beta app review, which is required before external testers can install it.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Submit for Beta Review",
                xpValue: 20
            )
        ]
    )

    static let appleXcodeCloudSetup = Workflow(
        title: "Set Up Xcode Cloud",
        summary: "Let Apple's servers build and test your app automatically.",
        symbolName: "cloud.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Connect the Assembly Line",
                instruction: "Link your source code repository to Xcode Cloud so it always knows where the latest version of your app lives.",
                jargonTerms: ["Xcode Cloud"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write the Recipe",
                instruction: "Create a workflow that defines what should happen automatically — build, test, or both — and which branch triggers it.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Workflows"
            ),
            WorkflowStep(
                title: "Set the Triggers",
                instruction: "Choose what kicks off a run, like every time someone pushes new code or on a nightly schedule.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch the First Run",
                instruction: "Kick off a build manually and watch it move through each step, catching any errors before you rely on it automatically.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleAPIKeySetup = Workflow(
        title: "Create an App Store Connect API Key",
        summary: "Let your tools talk to App Store Connect without typing a password.",
        symbolName: "key.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Decide Who Gets the Key",
                instruction: "Choose the right access level for the key, since a key can open just a few doors or the whole building depending on what you pick.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Cut the Key",
                instruction: "Generate a new API Key in App Store Connect, which gives you a private file used to prove requests are really from you.",
                jargonTerms: ["API Key"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Keys"
            ),
            WorkflowStep(
                title: "Store It Somewhere Safe",
                instruction: "Download the key once — Apple won't let you download it again — and store it somewhere your tools can read it without anyone else finding it.",
                jargonTerms: ["Environment Variable"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Take It for a Test Drive",
                instruction: "Use the key from a script or CI tool to confirm it can successfully reach App Store Connect before you rely on it.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let applePrivacyLabelSetup = Workflow(
        title: "Fill Out Your App's Privacy Label",
        summary: "Tell people exactly what data your app collects, up front.",
        symbolName: "lock.shield.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Take Inventory",
                instruction: "List out every kind of data your app actually collects, from email addresses to location, before you fill anything in.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Explain the Why",
                instruction: "For each data type, choose what it's used for, like App Functionality or Analytics, so people understand the reason it's collected.",
                visual: .consoleOverlay,
                overlayTargetLabel: "App Privacy"
            ),
            WorkflowStep(
                title: "Note What's Tied to a Person",
                instruction: "Mark which data is linked to someone's identity versus collected anonymously, since that changes how it's displayed on the label.",
                jargonTerms: ["App Privacy Label"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish the Label",
                instruction: "Save and publish your answers so the nutrition-label-style summary appears on your App Store product page.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Publish",
                xpValue: 20
            )
        ]
    )

    static let appleUniversalLinksSetup = Workflow(
        title: "Set Up Universal Links",
        summary: "Make a website link open straight into your app.",
        symbolName: "network",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On the Capability",
                instruction: "Enable Associated Domains for your App ID so your app is allowed to claim ownership of a website's links.",
                jargonTerms: ["App ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Capabilities"
            ),
            WorkflowStep(
                title: "Leave Proof on the Website",
                instruction: "Publish an apple-app-site-association file on your web server, like a signed note proving your website and app trust each other.",
                jargonTerms: ["Associated Domain"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point the Signpost",
                instruction: "Confirm your domain's DNS records point to the right web server, since Apple has to be able to actually fetch that proof file.",
                jargonTerms: ["DNS", "CNAME"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Click and Confirm",
                instruction: "Tap a real link to your website from another app, like Messages or Safari, and confirm it opens your app instead of a browser tab.",
                jargonTerms: ["Universal Link"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleCloudKitContainerSetup = Workflow(
        title: "Set Up a CloudKit Container",
        summary: "Give your app its own private storage locker in iCloud.",
        symbolName: "cloud.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Reserve the Storage Unit",
                instruction: "Add the iCloud capability to your App ID and create a CloudKit Container, a dedicated space where your app's data will live in iCloud.",
                jargonTerms: ["App ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "iCloud"
            ),
            WorkflowStep(
                title: "Draw Up the Shelving Plan",
                instruction: "Define the record types your app will store, like Notes or Photos, and what fields each one holds.",
                jargonTerms: ["CloudKit Container"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Schema"
            ),
            WorkflowStep(
                title: "Decide Who Can Peek Inside",
                instruction: "Set security roles so you control which parts of the container are private to each user versus shared publicly.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Move Out of the Sandbox",
                instruction: "Deploy your schema from the development environment to production once everything works, so real users' data has somewhere to go.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Deploy to Production",
                xpValue: 20
            )
        ]
    )

    static let appleSubscriptionGroupSetup = Workflow(
        title: "Build a Subscription Group",
        summary: "Offer tiers of a subscription without confusing anyone.",
        symbolName: "creditcard.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Set Up the Membership Tiers",
                instruction: "Create a Subscription Group, a shared shelf that holds every tier of your subscription so a person can only be on one level at a time.",
                jargonTerms: ["Subscription Group"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Subscription Groups"
            ),
            WorkflowStep(
                title: "Add Each Plan",
                instruction: "Create each subscription level inside the group, like Basic and Pro, and set what makes each one worth upgrading to.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Price and the Length",
                instruction: "Choose a price and billing period, like monthly or yearly, for every subscription level you offer.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Offer a Free Sample",
                instruction: "Add an introductory offer or free trial if you want to let new subscribers try before they're charged.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Introductory Offer"
            ),
            WorkflowStep(
                title: "Send Everything for Review",
                instruction: "Submit the subscription group along with your app build so Apple can review pricing and terms before it goes live.",
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let appleUserRolesSetup = Workflow(
        title: "Add Teammates in App Store Connect",
        summary: "Give your team the right keys without handing over everything.",
        symbolName: "person.2.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Decide Who Needs What",
                instruction: "Figure out what each teammate actually needs to do — write copy, upload builds, or manage money — before you add anyone.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Send the Invitation",
                instruction: "Invite each person by email to join your team in App Store Connect.",
                jargonTerms: ["App Store Connect"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Users and Access"
            ),
            WorkflowStep(
                title: "Hand Them the Right Badge",
                instruction: "Assign each person a role, like Admin or Developer, that acts like a badge deciding which doors they can open.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Roles"
            ),
            WorkflowStep(
                title: "Limit the Sensitive Rooms",
                instruction: "Restrict access to specific apps for teammates who only need to work on one product instead of your whole account.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleDeveloperProgramEnrollmentSetup = Workflow(
        title: "Join the Apple Developer Program",
        summary: "Get the paid membership that unlocks App Store distribution and all of Apple's developer tools.",
        symbolName: "person.badge.key.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Pick Individual or Organization",
                instruction: "Decide whether you're enrolling as yourself or as a company — organizations need a legal business entity, individuals just need their own legal name.",
                jargonTerms: ["Apple Developer Program"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm Your Legal Name",
                instruction: "Apple checks the name on your enrollment against official records, so make sure it's spelled exactly right before you submit it.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Pay the Membership Fee",
                instruction: "Enroll and pay the yearly fee — this is what lets you publish apps, run TestFlight builds, and use Apple's developer tools.",
                jargonTerms: ["TestFlight"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Wait for Apple's Approval",
                instruction: "Apple reviews every enrollment by hand, so it can take a day or two before your Developer Team is active and ready to use.",
                jargonTerms: ["Developer Team"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleManualSigningCertificateSetup = Workflow(
        title: "Set Up Certificates and Profiles by Hand",
        summary: "Take manual control of the certificate and profile that let your app run on real devices and ship to the store.",
        symbolName: "key.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Generate a Signing Request",
                instruction: "Use Keychain Access on your Mac to create a request file that proves a specific key belongs to you.",
                jargonTerms: ["Certificate Signing Request"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Request a Distribution Certificate",
                instruction: "Upload your request file in the Apple Developer portal and Apple will issue you a certificate tied to your account.",
                jargonTerms: ["Distribution Certificate"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Certificates"
            ),
            WorkflowStep(
                title: "Create a Provisioning Profile",
                instruction: "Link your App ID, your new certificate, and the devices you want to test on into a single profile.",
                jargonTerms: ["Provisioning Profile", "App ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Profiles"
            ),
            WorkflowStep(
                title: "Install Everything in Xcode",
                instruction: "Download the certificate and profile, then let Xcode pick them up so it can properly sign your app before it runs anywhere.",
                jargonTerms: ["Signing Identity"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleRatingPromptSetup = Workflow(
        title: "Ask Users to Rate Your App",
        summary: "Prompt happy users for a star rating at the right moment, without being annoying about it.",
        symbolName: "star.bubble.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Pick the Right Moment",
                instruction: "Choose a spot right after something good happens — finishing a task or hitting a milestone — to ask for a rating.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Add the Built-In Prompt",
                instruction: "Trigger Apple's standard rating popup from that moment in your code, instead of building your own review screen.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Respect Apple's Yearly Limit",
                instruction: "Apple only actually shows the popup a handful of times per year per person, no matter how often you ask, so don't over-trigger it.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch Your Rating Trend",
                instruction: "Check your average rating and recent reviews regularly in App Store Connect to see if the prompt is helping.",
                jargonTerms: ["App Store Connect"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Ratings and Reviews",
                xpValue: 20
            )
        ]
    )

    static let appleKeywordOptimizationSetup = Workflow(
        title: "Optimize Your App Store Keywords",
        summary: "Choose the search terms that help the right people discover your app.",
        symbolName: "magnifyingglass",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Brainstorm Search Terms",
                instruction: "List every word or phrase someone might type when looking for an app like yours, not just your app's name.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Fill the Keyword Field",
                instruction: "Enter your best terms into the keyword field for your listing — you only get 100 characters, so make each word count.",
                jargonTerms: ["App Store Connect", "Store Listing"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Keywords"
            ),
            WorkflowStep(
                title: "Cut Repeats and Filler Words",
                instruction: "Drop words that already appear in your app's name or category — Apple already searches those, so repeating them wastes space.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Track and Adjust",
                instruction: "Check which searches actually lead people to your app, then swap out weak keywords for better ones over time.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleWalletPassSetup = Workflow(
        title: "Create an Apple Wallet Pass",
        summary: "Turn a ticket, card, or coupon into something people can save right in Wallet on their iPhone.",
        symbolName: "wallet.pass.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Register a Pass Type",
                instruction: "Create a unique identifier for your pass so Wallet knows which app it belongs to.",
                jargonTerms: ["Pass Type ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Identifiers"
            ),
            WorkflowStep(
                title: "Design the Pass Layout",
                instruction: "Pick a pass style — boarding pass, coupon, ticket, or card — and lay out the fields, colors, and logo.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Sign and Package the Pass",
                instruction: "Bundle your pass data into a file and sign it, proving to Wallet that it really came from you.",
                jargonTerms: ["Signing Identity"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Let People Add It to Wallet",
                instruction: "Share the pass through a link, an email attachment, or a QR Code so a single tap drops it into Wallet.",
                jargonTerms: ["QR Code"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleWidgetSetup = Workflow(
        title: "Add a Home Screen Widget",
        summary: "Give your app a bite-sized view that lives right on the user's Home Screen.",
        symbolName: "square.grid.2x2.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Add a Widget Extension",
                instruction: "Create a new widget target in Xcode — it runs alongside your main app but draws its own small view.",
                jargonTerms: ["Widget Extension"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Describe What It Shows",
                instruction: "Write the code that decides what content the widget displays and how often it should refresh.",
                jargonTerms: ["Timeline Provider"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick Your Widget Sizes",
                instruction: "Design small, medium, or large versions of your widget so people can choose the size that fits their Home Screen.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Preview It on a Home Screen",
                instruction: "Use Xcode's preview canvas to see exactly how your widget will look before anyone installs it.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleAppClipSetup = Workflow(
        title: "Set Up an App Clip",
        summary: "Let people try a tiny slice of your app instantly, without installing the whole thing.",
        symbolName: "bolt.circle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Add an App Clip Target",
                instruction: "Create a lightweight App Clip target in Xcode that shares code with your main app but launches much faster.",
                jargonTerms: ["App Clip"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect It to a Web Link",
                instruction: "Prove you own a web address and set the specific link that should open your App Clip instead of a browser page.",
                jargonTerms: ["Associated Domain", "Invocation URL"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Keep It Small and Focused",
                instruction: "Trim your App Clip down to one core task — Apple limits its size so it can load in a couple of seconds.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Test the Invocation",
                instruction: "Tap or scan your link on a real device to confirm the App Clip card pops up and launches correctly.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleGameCenterSetup = Workflow(
        title: "Set Up Game Center",
        summary: "Add leaderboards and achievements so players can compete and show off progress.",
        symbolName: "gamecontroller.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On Game Center",
                instruction: "Enable the Game Center capability for your app so it can talk to Apple's player and scoring system.",
                jargonTerms: ["Game Center"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Leaderboard",
                instruction: "Set up a leaderboard for a score you want players to compete over, like fastest time or highest points.",
                jargonTerms: ["Leaderboard"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Leaderboards"
            ),
            WorkflowStep(
                title: "Add an Achievement",
                instruction: "Define a milestone players can unlock, along with the points it's worth and the image that shows when they earn it.",
                jargonTerms: ["Achievement"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Achievements"
            ),
            WorkflowStep(
                title: "Let Players Sign In",
                instruction: "Prompt players to authenticate with Game Center when your game launches so their scores and achievements sync automatically.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleFamilySharingSetup = Workflow(
        title: "Turn On Family Sharing for Your Subscription",
        summary: "Let one subscriber share access with their whole family at no extra cost to them.",
        symbolName: "person.3.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Enable Family Sharing",
                instruction: "Turn on the Family Sharing toggle for your subscription so a single purchase can cover an entire family group.",
                jargonTerms: ["Family Sharing", "Subscription"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Family Sharing"
            ),
            WorkflowStep(
                title: "Know Who Pays",
                instruction: "Only the person who bought the subscription is billed — up to five family members get access for free through their shared account.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Check How Your App Reacts",
                instruction: "Make sure your app recognizes a shared purchase as fully valid, not just the original buyer's own transaction.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Test With a Family Group",
                instruction: "Set up a test family group in the sandbox and confirm a second family member actually unlocks your subscription features.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let applePromoOfferCodeSetup = Workflow(
        title: "Set Up Promotional Offer Codes",
        summary: "Hand out redeemable codes that give new or returning subscribers a special deal.",
        symbolName: "gift.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Create an Offer",
                instruction: "Open your subscription and set up a promotional offer with the discount or free period you want to give away.",
                jargonTerms: ["Subscription"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Offer Codes"
            ),
            WorkflowStep(
                title: "Choose the Discount and Length",
                instruction: "Decide how big the discount is and how many billing periods it lasts before switching to the regular price.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Generate the Codes",
                instruction: "Have Apple generate a batch of one-time codes that people can type in to unlock your offer.",
                jargonTerms: ["Offer Code"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share Codes With Your Audience",
                instruction: "Hand codes out through email, social posts, or in-app rewards, and watch redemptions roll in.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let applePreOrderSetup = Workflow(
        title: "Set Up an App Store Pre-Order",
        summary: "Let eager users reserve your app now so it lands on their phone the moment it launches.",
        symbolName: "calendar.badge.clock",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On Pre-Order",
                instruction: "Switch on pre-order for your upcoming version so it shows up as reservable in the App Store before it's finished.",
                jargonTerms: ["Pre-Order"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Pre-Order"
            ),
            WorkflowStep(
                title: "Pick Your Release Date",
                instruction: "Choose the date your app will automatically download to everyone who reserved it — you can push it back once if you need more time.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Finish the Listing Early",
                instruction: "Get your screenshots, description, and pricing ready ahead of time, since people will see your listing while they're still deciding to reserve.",
                jargonTerms: ["Store Listing"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Submit Before the Cutoff",
                instruction: "Send your finished build in with enough lead time before the release date so Apple can review it and it's ready to unlock on schedule.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let applePushCategoriesSetup = Workflow(
        title: "Add Buttons to Your Push Notifications",
        summary: "Give people quick actions — like Reply or Mark Done — right from a notification banner.",
        symbolName: "bell.badge.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Define a Notification Category",
                instruction: "Create a named group that describes a type of notification, like 'message' or 'reminder', which will hold your quick actions.",
                jargonTerms: ["Notification Category"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Actions to the Category",
                instruction: "Attach one or two buttons to that category, such as Reply or Mark Done, so they appear right on the banner.",
                jargonTerms: ["Notification Action"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Register Categories at Launch",
                instruction: "Tell the system about your categories when the app starts, so it knows which buttons to draw before a notification even arrives.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Tag Outgoing Notifications",
                instruction: "Mark each notification you send with the right category name so the correct buttons show up automatically.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleCloudKitSchemaSetup = Workflow(
        title: "Design Your CloudKit Dashboard Schema",
        summary: "Define the record types and fields your app's data will live in, before you write a line of syncing code.",
        symbolName: "externaldrive.fill.badge.icloud",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Open the CloudKit Dashboard",
                instruction: "Head to the schema section of your CloudKit Container's web dashboard, where you'll shape your data before any code touches it.",
                jargonTerms: ["CloudKit Container"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Schema"
            ),
            WorkflowStep(
                title: "Create a Record Type",
                instruction: "Add a new record type for each kind of thing your app stores, like a note, a photo, or a to-do item.",
                jargonTerms: ["Record Type"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Fields and Choose Their Types",
                instruction: "Give each record type the fields it needs — text, numbers, dates, or references — and set the type for each one.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Index the Fields You'll Search",
                instruction: "Mark any field you'll filter or sort by as searchable, so lookups stay fast as your data grows.",
                jargonTerms: ["Queryable Index"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Deploy Schema to Production",
                instruction: "Once everything looks right in development, push the schema to production so your live app can actually use it.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleTestFlightCrashReportingSetup = Workflow(
        title: "Read Your App's Crash Reports",
        summary: "Find out why your app is crashing for testers before it ever reaches real customers.",
        symbolName: "exclamationmark.triangle",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Open the Crashes Tab",
                instruction: "In App Store Connect, open your app's TestFlight tab and find the list of reported crashes.",
                jargonTerms: ["App Store Connect", "TestFlight", "Crash Report"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Crashes"
            ),
            WorkflowStep(
                title: "Pick a Crash to Investigate",
                instruction: "Sort by how often a crash happens and start with the one hitting the most testers.",
                jargonTerms: ["Crash Report"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Symbolicate the Crash Log",
                instruction: "Download the crash log and let Xcode match its raw addresses back to your actual function names.",
                jargonTerms: ["Symbolication"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Read What Testers Said",
                instruction: "Check for tester feedback attached to the crash — screenshots and notes often explain what they were doing.",
                jargonTerms: ["TestFlight", "Beta Feedback"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Reproduce and Fix It",
                instruction: "Follow the same steps on your own device until the crash happens for you, then fix the underlying bug.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Ship an Updated Build",
                instruction: "Upload a new build with the fix and confirm the crash count drops for testers on the latest version.",
                jargonTerms: ["TestFlight"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let appleStoreKitServerVerificationSetup = Workflow(
        title: "Verify Purchases on Your Own Server",
        summary: "Double-check every in-app purchase with Apple's servers so you never grant something that wasn't actually paid for.",
        symbolName: "checkmark.shield",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Get the Transaction from the Device",
                instruction: "After a purchase completes in your app, grab the signed transaction StoreKit hands you.",
                jargonTerms: ["In-App Purchase", "Transaction Receipt"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand the Signed Payload",
                instruction: "That transaction is a JWS Signature — a block of data Apple has cryptographically signed so it can't be faked.",
                jargonTerms: ["JWS Signature"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Call the App Store Server API",
                instruction: "From your own backend, send the transaction ID to Apple's server API to look up its full, trusted details.",
                jargonTerms: ["Transaction Receipt"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Verify the Signature Chain",
                instruction: "Check that the signature traces back to Apple's own root certificate before you trust anything in the payload.",
                jargonTerms: ["JWS Signature"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Unlock Content Only After Verification",
                instruction: "Only grant premium access once your server — not the device — confirms the purchase is real.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Test Everything in Sandbox First",
                instruction: "Run through the whole flow with a Sandbox Mode Apple ID before trusting it with real money.",
                jargonTerms: ["Sandbox Mode"],
                visual: .plain
            )
        ]
    )

    static let appleServerNotificationsSetup = Workflow(
        title: "Get Notified When a Subscription Changes",
        summary: "Have Apple ping your server the moment a subscriber renews, cancels, or asks for a refund.",
        symbolName: "bell.badge",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Build a Webhook Endpoint",
                instruction: "Stand up a URL on your server that can accept a POST request and respond quickly with a success code.",
                jargonTerms: ["Webhook Endpoint"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Register Your URL in App Store Connect",
                instruction: "Paste your endpoint into the App Store Server Notifications field so Apple knows where to send updates.",
                jargonTerms: ["App Store Connect", "Server Notification"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Store Server Notifications"
            ),
            WorkflowStep(
                title: "Choose a Notification Version",
                instruction: "Pick the current version of the notification format so you get the richer, more detailed payload.",
                jargonTerms: ["Server Notification"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Verify Incoming Signatures",
                instruction: "Check the JWS Signature on every notification you receive before acting on it, so no one can send you fake events.",
                jargonTerms: ["JWS Signature"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Handle Each Notification Type",
                instruction: "Write a handler for renewals, cancellations, refunds, and billing issues so your app's state always matches reality.",
                jargonTerms: ["Notification Type"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Test with a Sandbox Subscription",
                instruction: "Trigger a real renewal in Sandbox Mode and confirm the notification actually arrives and updates your database.",
                jargonTerms: ["Sandbox Mode"],
                visual: .plain
            )
        ]
    )

    static let appleHealthKitEntitlementSetup = Workflow(
        title: "Ask Permission to Read Health Data",
        summary: "Turn on HealthKit for your app and request only the health information you actually need.",
        symbolName: "heart.text.square",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On the HealthKit Entitlement",
                instruction: "In Xcode's Signing & Capabilities tab, add the HealthKit capability so your app is allowed to ask for health data at all.",
                jargonTerms: ["HealthKit", "Entitlement"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Capabilities"
            ),
            WorkflowStep(
                title: "Explain Why You Need It",
                instruction: "Write a clear usage description that will show up in the permission prompt, so people know exactly why you're asking.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Which Data Types to Request",
                instruction: "Pick only the specific health record types your feature actually uses, like steps or sleep, instead of asking for everything.",
                jargonTerms: ["Health Record Type"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Ask the User for Permission",
                instruction: "Trigger the HealthKit permission sheet and let the person approve or deny each data type individually.",
                jargonTerms: ["HealthKit"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Handle a \"No\" Gracefully",
                instruction: "Design your app so it still works, just with a reduced feature set, if someone declines to share their health data.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let appleAppIntentsSetup = Workflow(
        title: "Let Siri Trigger an Action in Your App",
        summary: "Turn a feature of your app into something people can ask Siri or the Shortcuts app to do for them.",
        symbolName: "mic.circle",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Define What the Action Does",
                instruction: "Create an App Intent that describes one specific thing your app can do, like starting a timer or logging a workout.",
                jargonTerms: ["App Intent"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Parameters the User Can Fill In",
                instruction: "Let the App Intent accept details, like a duration or a name, so the same action can be reused in different ways.",
                jargonTerms: ["App Intent"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Write a Friendly Phrase Suggestion",
                instruction: "Give Siri an example sentence, like \"Start a focus session in [app]\", so it knows how people might ask for this.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test It in the Shortcuts App",
                instruction: "Open the Shortcuts app, find your action, and run it on its own to confirm it behaves correctly outside your app.",
                jargonTerms: ["Shortcuts App"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Let Siri Suggest It Automatically",
                instruction: "Mark the intent as one Siri can proactively suggest, so it shows up at the right moment without the user asking first.",
                jargonTerms: ["App Intent"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let appleLiveActivitiesSetup = Workflow(
        title: "Show Live Progress on the Lock Screen",
        summary: "Keep users updated in real time with a Live Activity that lives right on their Lock Screen and Dynamic Island.",
        symbolName: "bolt.badge.clock",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Design the Activity Layout",
                instruction: "Build a small, glanceable layout using ActivityKit that shows the most important status at a glance.",
                jargonTerms: ["Live Activity", "ActivityKit"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Start the Activity from Your App",
                instruction: "Kick off the Live Activity the moment the tracked event begins, like an order being placed or a ride starting.",
                jargonTerms: ["Live Activity"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Update It as Things Change",
                instruction: "Push fresh state to the activity as progress changes, so the Lock Screen view stays accurate without reopening the app.",
                jargonTerms: ["Live Activity"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Show It in the Dynamic Island",
                instruction: "Provide compact and expanded views so the activity fits neatly into the Dynamic Island on supported iPhones.",
                jargonTerms: ["Dynamic Island"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Push Remote Updates",
                instruction: "Use a push token to update the activity from your server even when your app isn't running in the foreground.",
                jargonTerms: ["Push Token"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "End the Activity When It's Done",
                instruction: "Close out the Live Activity with a final state once the tracked event finishes, so it doesn't linger forever.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let appleAgeRatingSetup = Workflow(
        title: "Fill Out Your App's Age Rating",
        summary: "Answer a short questionnaire so the App Store can show your app the right age rating for its content.",
        symbolName: "person.2.badge.gearshape",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Open the Age Rating Questionnaire",
                instruction: "In App Store Connect, find the age rating section for your app and start the questionnaire.",
                jargonTerms: ["App Store Connect", "Age Rating Questionnaire"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Age Rating"
            ),
            WorkflowStep(
                title: "Answer Honestly About Content",
                instruction: "Go through each question about violence, language, and other content types as accurately as you can.",
                jargonTerms: ["Content Descriptor"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Flag Any User-Generated Content",
                instruction: "If people can post their own content in your app, say so — it changes the descriptors your rating includes.",
                jargonTerms: ["Content Descriptor"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Review the Rating You're Given",
                instruction: "Check the age rating the questionnaire produces and make sure it matches what you'd expect for your app.",
                jargonTerms: ["Age Rating Questionnaire"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Save and Apply to Your Listing",
                instruction: "Save your answers so the rating shows up on your App Store listing before your next submission.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let appleInAppEventsSetup = Workflow(
        title: "Promote a Live Event Inside the App Store",
        summary: "Tell shoppers about a challenge, premiere, or limited-time event happening in your app right from its Store listing.",
        symbolName: "calendar.badge.clock",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Pick an Event Type",
                instruction: "Choose the category that best fits what's happening, like a challenge, a premiere, or a major update.",
                jargonTerms: ["In-App Event"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write the Event Card",
                instruction: "Add a short title, description, and image that will appear as the event card people see while browsing.",
                jargonTerms: ["Event Card"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set the Event's Start and End Time",
                instruction: "Schedule exactly when the in-app event begins and ends so it only appears while it's actually relevant.",
                jargonTerms: ["In-App Event"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Localized Versions",
                instruction: "Provide translated versions of the event card so it reads naturally for shoppers in other regions.",
                jargonTerms: ["Localization"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Submit for Review",
                instruction: "Send the event for review well before it's supposed to start, since it needs approval just like a new build.",
                jargonTerms: ["In-App Event"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Watch It Go Live",
                instruction: "Once approved, check that the event card is showing up in search and browse at the scheduled time.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let appleCustomProductPagesSetup = Workflow(
        title: "Test Different App Store Pages",
        summary: "Show different screenshots and text to different visitors, then keep whichever version convinces more people to download.",
        symbolName: "rectangle.on.rectangle.badge.gearshape",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Duplicate Your Default Product Page",
                instruction: "Create a custom product page based on your existing listing as a starting point for the variant.",
                jargonTerms: ["Custom Product Page"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Swap in New Screenshots",
                instruction: "Replace the screenshots or app preview on the variant with a different set to test against the original.",
                jargonTerms: ["App Preview", "Custom Product Page"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write Alternate Description Text",
                instruction: "Edit the metadata on the variant page, like the promotional text, to try a different pitch to shoppers.",
                jargonTerms: ["Metadata"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set Up a Product Page Optimization Test",
                instruction: "Create a product page optimization test that pits your original listing against one or more variants.",
                jargonTerms: ["Product Page Optimization"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Split Traffic Between Versions",
                instruction: "Let the test run and automatically divide visitors evenly between the original and each variant.",
                jargonTerms: ["Product Page Optimization"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Promote the Winner",
                instruction: "Once a version clearly performs better, apply it as your default listing for everyone.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let appleBusinessManagerSetup = Workflow(
        title: "Set Up Apple Business Manager",
        summary: "Get your company ready to buy apps in bulk and hand out preconfigured devices without touching each one by hand.",
        symbolName: "building.2",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Enroll Your Organization",
                instruction: "Sign up your company for Apple Business Manager using your official business details and a D-U-N-S number.",
                jargonTerms: ["Apple Business Manager"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Verify Your Company's Identity",
                instruction: "Complete Apple's verification checks confirming your organization is a real, legally registered business.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create Managed Apple IDs for Staff",
                instruction: "Set up managed Apple IDs for employees so their work accounts stay separate from personal ones.",
                jargonTerms: ["Managed Apple ID"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Connect an MDM Solution",
                instruction: "Link an MDM system to Apple Business Manager so you can push settings and apps to devices remotely.",
                jargonTerms: ["MDM"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assign Devices for Zero-Touch Setup",
                instruction: "Assign purchased devices to your MDM so new hires can unbox them and have everything configure itself automatically.",
                jargonTerms: ["MDM"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Buy and Assign Apps in Bulk",
                instruction: "Purchase app licenses in bulk through Apple Business Manager and assign them to devices or accounts as needed.",
                jargonTerms: ["Apple Business Manager"],
                visual: .plain
            )
        ]
    )

    static let appleMapKitApiKeySetup = Workflow(
        title: "Add an Interactive Apple Map to Your Website",
        summary: "Generate the key your website needs to show a real, interactive Apple Maps view instead of a static image.",
        symbolName: "map",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On MapKit JS in Your Account",
                instruction: "In your developer account, enable MapKit JS so you're allowed to embed Apple Maps on a website.",
                jargonTerms: ["MapKit JS"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Private Key",
                instruction: "Generate a private key specifically for MapKit JS, which you'll use to prove requests are coming from you.",
                jargonTerms: ["MapKit JS"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Generate a Signed Token",
                instruction: "Use your private key on your server to create a maps token that your website will present to load the map.",
                jargonTerms: ["Maps Token"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Restrict the Token to Your Domain",
                instruction: "Lock the maps token to only work on your own website's domain so it can't be reused elsewhere if it leaks.",
                jargonTerms: ["Maps Token"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Drop the Map into Your Site",
                instruction: "Add the MapKit JS script to your page and pass in your token to render a live, interactive map.",
                jargonTerms: ["MapKit JS"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Refresh the Token Before It Expires",
                instruction: "Set a reminder or automated job to issue a new maps token before the old one expires and the map stops loading.",
                jargonTerms: ["Maps Token"],
                visual: .plain
            )
        ]
    )

    static let appleHandoffContinuitySetup = Workflow(
        title: "Let Work Follow Someone Across Devices",
        summary: "Let a person start something on their iPhone and pick it up right where they left off on their iPad or Mac.",
        symbolName: "arrow.triangle.2.circlepath.circle",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On the Handoff Capability",
                instruction: "In Xcode's Signing & Capabilities tab, add Handoff so your app is allowed to broadcast what the user is doing.",
                jargonTerms: ["Handoff"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Capabilities"
            ),
            WorkflowStep(
                title: "Describe What the User Is Doing",
                instruction: "Create an activity that captures the current screen or task, like editing a document or viewing a specific item.",
                jargonTerms: ["Handoff"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Update It as They Work",
                instruction: "Keep the activity's details current as the user navigates, so Handoff always reflects exactly where they are.",
                jargonTerms: ["Handoff"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Make Sure Both Devices Share an iCloud Account",
                instruction: "Confirm both devices are signed into the same iCloud account with Handoff turned on in Settings.",
                jargonTerms: ["iCloud Account"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick Up the Activity on the Other Device",
                instruction: "Test the full handoff by starting on one device and swiping up on the Handoff icon on the other.",
                jargonTerms: ["Handoff"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let appleAppStoreConnectWebhooksSetup = Workflow(
        title: "Get Automatic Alerts from App Store Connect",
        summary: "Have App Store Connect notify your own systems the instant something important happens, like a new review or a build issue.",
        symbolName: "antenna.radiowaves.left.and.right",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Generate an API Key for Notifications",
                instruction: "Create an API key in App Store Connect with permission to manage notification subscriptions.",
                jargonTerms: ["App Store Connect", "API Key"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Integrations"
            ),
            WorkflowStep(
                title: "Create a Webhook Endpoint",
                instruction: "Set up a URL on your server that can receive a POST request and respond with a quick success status.",
                jargonTerms: ["Webhook Endpoint"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Subscribe to the Notification Types You Want",
                instruction: "Register for the specific notification types you care about, like new reviews or build processing results.",
                jargonTerms: ["Notification Type"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Verify Apple's Signature on Each Call",
                instruction: "Check the JWS signature on every incoming notification so you know it genuinely came from Apple.",
                jargonTerms: ["JWS Signature"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Route Alerts to Your Team",
                instruction: "Forward the incoming events into wherever your team already looks, like a chat channel or ticketing system.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Test with a Sample Event",
                instruction: "Trigger a real event, like submitting a build, and confirm the alert actually reaches your team.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    // MARK: Microsoft

    static let azureResourceSetup = Workflow(
        title: "Create Your Azure Engine Room",
        summary: "Assemble the pieces an Azure app needs, inside the right filing cabinet.",
        symbolName: "server.rack",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Find Your Office Building",
                instruction: "Sign in to the Azure portal and confirm you're working inside the right tenant for your organization.",
                jargonTerms: ["Tenant", "Subscription"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Directory Switcher"
            ),
            WorkflowStep(
                title: "Label a Filing Cabinet",
                instruction: "Create a resource group to keep everything for this project together.",
                jargonTerms: ["Resource Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble Your Engine Room",
                instruction: "Drag each part into your chassis to build the engine room this project runs on.",
                jargonTerms: ["Compute Instance", "Bucket", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Request a Visitor Badge",
                instruction: "Add an app registration in Entra ID so your app can prove who it is when it signs in.",
                jargonTerms: ["App Registration", "Entra ID"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let microsoft365DomainSetup = Workflow(
        title: "Verify Your Domain in Microsoft 365",
        summary: "Connect your own domain name to your Microsoft 365 mailboxes.",
        symbolName: "envelope.badge.shield.half.filled.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Add Your Domain",
                instruction: "In the Microsoft 365 admin center, add your domain and request a verification record.",
                jargonTerms: ["Tenant"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Domain"
            ),
            WorkflowStep(
                title: "Leave a Verification Note",
                instruction: "Add the TXT record you were given to your domain's DNS settings to prove ownership.",
                jargonTerms: ["TXT Record", "DNS"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Point Mail at Microsoft",
                instruction: "Update your MX Record so mail sent to your domain reaches your new mailboxes.",
                jargonTerms: ["MX Record"],
                visual: .dnsVisualizer,
                xpValue: 20
            )
        ]
    )

    static let microsoftTeamsSetup = Workflow(
        title: "Set Up Your Team's Home Base in Microsoft Teams",
        summary: "Build a shared clubhouse where your team chats, meets, and shares files in one place.",
        symbolName: "person.3.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create Your Team",
                instruction: "Create a new team, like opening a clubhouse just for your group.",
                jargonTerms: ["Team"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Organize with Channels",
                instruction: "Add channels to sort conversations into separate rooms, one for each topic.",
                jargonTerms: ["Channel"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Invite Your Coworkers",
                instruction: "Add your teammates to the tenant so everyone gets a key to the clubhouse.",
                jargonTerms: ["Tenant"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Members"
            ),
            WorkflowStep(
                title: "Set Guest Access Rules",
                instruction: "Decide whether people outside your company can be let in as visitors.",
                jargonTerms: ["Guest Access"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let sharePointSiteSetup = Workflow(
        title: "Create a SharePoint Team Site",
        summary: "Build a shared filing room your whole team can open from anywhere.",
        symbolName: "folder.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Choose Your Site Type",
                instruction: "Pick whether you're building a shared team filing room or a public bulletin board.",
                jargonTerms: ["SharePoint Site"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Site"
            ),
            WorkflowStep(
                title: "Name Your Site",
                instruction: "Give your filing room a name and an address so people can find it later.",
                jargonTerms: ["SharePoint Site"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Up Document Libraries",
                instruction: "Add labeled shelves, called document libraries, to keep files sorted by project.",
                jargonTerms: ["Document Library"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Invite Your Team",
                instruction: "Add the people who should have a key to this filing room.",
                jargonTerms: ["Tenant"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let oneDriveSharingSetup = Workflow(
        title: "Share Files Safely from OneDrive",
        summary: "Hand out the right keys to the right files without giving away the whole cabinet.",
        symbolName: "lock.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Pick What to Share",
                instruction: "Choose the file or folder you want to hand a copy of the key to.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Who Can See It",
                instruction: "Decide if the link goes to one person, your whole company, or anyone who has it.",
                jargonTerms: ["Sharing Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Edit or View Only",
                instruction: "Decide whether visitors can only look through the window or actually rearrange the furniture.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set an Expiration Date",
                instruction: "Give the key a timer so access automatically shuts off when the project ends.",
                jargonTerms: ["Link Expiration"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let conditionalAccessSetup = Workflow(
        title: "Set Up Conditional Access in Entra ID",
        summary: "Add smart rules that check who's knocking before your office door unlocks.",
        symbolName: "checkmark.shield.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Find the Security Checkpoint",
                instruction: "Sign in to Entra ID and open the area of your tenant where entry rules live.",
                jargonTerms: ["Entra ID", "Tenant"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Conditional Access"
            ),
            WorkflowStep(
                title: "Choose Who the Rule Watches",
                instruction: "Pick which people or apps this checkpoint rule keeps an eye on.",
                jargonTerms: ["Conditional Access Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Conditions",
                instruction: "Decide what raises a red flag, like signing in from an unfamiliar country or an unmanaged device.",
                jargonTerms: ["Conditional Access Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose What Happens Next",
                instruction: "Decide whether a flagged sign-in gets turned away or just asked to show a second form of ID.",
                jargonTerms: ["Multi-Factor Authentication"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureKeyVaultSetup = Workflow(
        title: "Store Secrets in an Azure Key Vault",
        summary: "Give your app's passwords and keys a safe deposit box instead of a sticky note.",
        symbolName: "lock.shield.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open the Right Filing Cabinet",
                instruction: "Pick the resource group where this vault will live, so it stays with the rest of the project.",
                jargonTerms: ["Resource Group"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Key Vault"
            ),
            WorkflowStep(
                title: "Assemble Your Vault",
                instruction: "Drag each part into place to build a vault sturdy enough to guard your secrets.",
                jargonTerms: ["Key Vault", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Store Your First Secret",
                instruction: "Drop an API key or password into the vault instead of leaving it sitting in your code.",
                jargonTerms: ["Key Vault", "API Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide Who Holds a Key",
                instruction: "Grant access only to the people and apps that truly need to open the vault.",
                jargonTerms: ["IAM Role"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureStorageAccountSetup = Workflow(
        title: "Set Up an Azure Storage Account",
        summary: "Build the warehouse where your app's files and backups will live.",
        symbolName: "archivebox.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Pick a Filing Cabinet",
                instruction: "Choose the resource group this storage account will belong to.",
                jargonTerms: ["Resource Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Name Your Warehouse",
                instruction: "Create a storage account, a warehouse with a unique name where your files will be kept.",
                jargonTerms: ["Storage Account"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Storage Account"
            ),
            WorkflowStep(
                title: "Choose How Sturdy It Should Be",
                instruction: "Pick a redundancy option to decide how many backup copies of your warehouse exist in case one burns down.",
                jargonTerms: ["Redundancy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Build Out Your Storage",
                instruction: "Drag each part into your chassis to build the warehouse this project stores its files in.",
                jargonTerms: ["Bucket", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 25
            )
        ]
    )

    static let powerBIWorkspaceSetup = Workflow(
        title: "Create a Power BI Workspace",
        summary: "Set up a shared drafting table where your team builds and reviews reports together.",
        symbolName: "chart.bar.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create Your Workspace",
                instruction: "Create a Power BI workspace, a shared drafting table for building reports as a team.",
                jargonTerms: ["Power BI Workspace"],
                visual: .consoleOverlay,
                overlayTargetLabel: "New Workspace"
            ),
            WorkflowStep(
                title: "Invite Collaborators",
                instruction: "Add teammates to the drafting table so they can build and edit reports with you.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect a Data Source",
                instruction: "Plug in the spreadsheet or database that your reports will pull their numbers from.",
                jargonTerms: ["Data Source"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish Your Dashboard",
                instruction: "Share the finished dashboard so others can view it without touching the drafting table.",
                jargonTerms: ["Power BI Workspace"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let powerAutomateFlowSetup = Workflow(
        title: "Build Your First Power Automate Flow",
        summary: "Set up a row of dominoes so one action automatically tips off the next.",
        symbolName: "bolt.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Pick What Starts the Flow",
                instruction: "Choose the trigger, the first domino, like an email arriving or a form being submitted.",
                jargonTerms: ["Trigger"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add What Happens Next",
                instruction: "Add actions, one for each domino that should tip over after the first.",
                jargonTerms: ["Power Automate Flow"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Your Apps",
                instruction: "Sign in to each app involved so the flow is allowed to act on your behalf.",
                jargonTerms: ["Connector"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Manage Connections"
            ),
            WorkflowStep(
                title: "Test and Turn It On",
                instruction: "Run the flow once to watch the dominoes fall, then switch it on for good.",
                jargonTerms: ["Power Automate Flow"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let microsoftDefenderSetup = Workflow(
        title: "Turn On Microsoft Defender Protections",
        summary: "Post a guard at every door instead of just locking the front one.",
        symbolName: "shield.lefthalf.filled",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open the Security Center",
                instruction: "Sign in to the Microsoft Defender portal, the guardhouse where your tenant's protection settings live.",
                jargonTerms: ["Tenant"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Security Center"
            ),
            WorkflowStep(
                title: "Turn On Email Protection",
                instruction: "Switch on filters that catch suspicious attachments and links before they reach an inbox.",
                jargonTerms: ["Safe Attachments"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Protect Your Devices",
                instruction: "Enroll your team's computers and phones so a guard is watching over them too.",
                jargonTerms: ["Endpoint Protection"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Review Your Security Score",
                instruction: "Check your security score, a report card that shows how well-guarded your setup currently is.",
                jargonTerms: ["Security Score"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureDevOpsRepoSetup = Workflow(
        title: "Set Up an Azure DevOps Repo",
        summary: "Build a shared toolbox where your team's code is stored and tracked.",
        symbolName: "terminal.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Project",
                instruction: "Create a project, a labeled toolbox that will hold your code and tasks.",
                jargonTerms: ["DevOps Project"],
                visual: .consoleOverlay,
                overlayTargetLabel: "New Project"
            ),
            WorkflowStep(
                title: "Set Up Your Repo",
                instruction: "Create a repository, the shelf inside the toolbox where your code actually lives.",
                jargonTerms: ["Repository"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Invite Your Team",
                instruction: "Add teammates so they can pick up tools from the same toolbox.",
                jargonTerms: ["IAM Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Protect Your Main Branch",
                instruction: "Add a branch policy so no one can rearrange the main shelf without someone else checking their work first.",
                jargonTerms: ["Branch Policy"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let exchangeMailFlowRuleSetup = Workflow(
        title: "Create a Mail Flow Rule in Exchange Online",
        summary: "Set up a sorting clerk who inspects every letter before it's delivered.",
        symbolName: "envelope.badge.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open the Mail Room",
                instruction: "Sign in to the Exchange admin center, the mail room where your tenant's delivery rules are managed.",
                jargonTerms: ["Tenant"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Mail Flow"
            ),
            WorkflowStep(
                title: "Decide What to Watch For",
                instruction: "Set the condition your rule looks for, like a certain word in the subject line or a specific sender.",
                jargonTerms: ["Mail Flow Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose What Happens Next",
                instruction: "Decide whether a flagged message gets forwarded, blocked, or stamped with a warning label.",
                jargonTerms: ["Mail Flow Rule"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let windowsAutopilotSetup = Workflow(
        title: "Enroll Devices with Windows Autopilot",
        summary: "Set up new laptops so they configure themselves the moment your team turns them on.",
        symbolName: "laptopcomputer",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Register Your Devices",
                instruction: "Add your new laptops' serial numbers to a registration list before they ship out.",
                jargonTerms: ["Autopilot Profile"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Devices"
            ),
            WorkflowStep(
                title: "Build a Setup Profile",
                instruction: "Create a profile that tells each laptop exactly how to introduce itself and what to install.",
                jargonTerms: ["Autopilot Profile"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assign the Profile",
                instruction: "Attach your profile to the group of devices so it applies to all of them automatically.",
                jargonTerms: ["Autopilot Profile"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Let It Configure Itself",
                instruction: "Hand the laptop to your teammate and let it finish setting itself up the first time it connects to Wi-Fi.",
                jargonTerms: ["Zero-Touch Deployment"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let entraSecurityGroupSetup = Workflow(
        title: "Create a Security Group in Entra ID",
        summary: "Bundle people together so you can hand out access once instead of one person at a time.",
        symbolName: "person.3.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open the Groups Page",
                instruction: "In the Entra ID admin center, go to Groups and start a new group.",
                jargonTerms: ["Entra ID"],
                visual: .consoleOverlay,
                overlayTargetLabel: "New Group"
            ),
            WorkflowStep(
                title: "Name Your Group",
                instruction: "Give the group a clear name like \"Marketing Team\" so anyone can tell what it's for at a glance.",
                jargonTerms: ["Security Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add the Right People",
                instruction: "Add each person who needs the same access, or set a rule so people are added automatically based on their job info.",
                jargonTerms: ["Dynamic Membership Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hand Out Access Once",
                instruction: "Assign the group to an app, a Teams channel, or a SharePoint site, and everyone inside the group gets access instantly.",
                jargonTerms: ["Permission Level"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let exchangeSharedMailboxSetup = Workflow(
        title: "Set Up a Shared Mailbox in Outlook",
        summary: "Give a whole team one inbox, like info@yourcompany.com, without sharing a single password.",
        symbolName: "envelope.badge.person.crop",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the Mailbox",
                instruction: "In the Exchange admin center, create a new shared mailbox and give it an address like info@yourcompany.com.",
                jargonTerms: ["Shared Mailbox"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add a Shared Mailbox"
            ),
            WorkflowStep(
                title: "Add the Team",
                instruction: "Add each teammate who should be able to read and reply from this inbox.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Let Them Reply as the Team",
                instruction: "Turn on Send As permission so replies show the shared address instead of a personal one.",
                jargonTerms: ["Send As Permission"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Open It in Outlook",
                instruction: "Each teammate can now open the shared mailbox right from their own Outlook, without ever knowing a password.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureAppServiceDeploySetup = Workflow(
        title: "Deploy a Website with Azure App Service",
        summary: "Put your web app online on Microsoft's servers without managing a single server yourself.",
        symbolName: "arrowshape.up.circle.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the App Service",
                instruction: "In the Azure portal, create a new App Service and choose the runtime your app is built with, like Node.js or Python.",
                jargonTerms: ["Resource Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Your Plan",
                instruction: "Pick an App Service Plan, which decides how much power, and how much cost, your app gets.",
                jargonTerms: ["App Service Plan"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish Your Code",
                instruction: "Connect your code repository or upload your app so Azure can build and run it.",
                jargonTerms: ["Repository"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test Before You Launch",
                instruction: "Deploy to a staging slot first so you can check everything works before it reaches real visitors.",
                jargonTerms: ["Deployment Slot"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Go Live",
                instruction: "Swap your staging slot into production, and your site is live at its new address.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let azureSqlDatabaseSetup = Workflow(
        title: "Set Up an Azure SQL Database",
        summary: "Give your app a reliable place to store and look up information, hosted by Microsoft.",
        symbolName: "cylinder.split.1x2.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a SQL Server",
                instruction: "In the Azure portal, create a logical SQL server, which is the address your database will live behind.",
                jargonTerms: ["Database Endpoint"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create the Database",
                instruction: "Add a new database on that server and choose how much performance it needs.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Open the Front Door",
                instruction: "Add a firewall rule so only your app's server, and nobody else, can reach the database.",
                jargonTerms: ["Firewall Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Your App",
                instruction: "Copy the connection string into your app's settings so it knows how to reach the database.",
                jargonTerms: ["Environment Variable"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureMonitorAlertSetup = Workflow(
        title: "Set Up Alerts with Azure Monitor",
        summary: "Get a text or email the moment something in your app starts acting up, instead of finding out from an angry customer.",
        symbolName: "waveform.path.ecg",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Log Analytics Workspace",
                instruction: "Set up a Log Analytics workspace, which is where Azure will collect the health data from your resources.",
                jargonTerms: ["Log Analytics Workspace"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch a Metric",
                instruction: "Pick something worth watching, like how often your app errors out or how slow it responds.",
                jargonTerms: ["Metric"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Tripwire",
                instruction: "Create an alert rule that defines exactly when a metric counts as a problem.",
                jargonTerms: ["Alert Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Who Gets Notified",
                instruction: "Add an action group with the emails or phone numbers that should hear about it first.",
                jargonTerms: ["Action Group"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let intuneCompliancePolicySetup = Workflow(
        title: "Set a Device Compliance Rule in Intune",
        summary: "Make sure only devices that meet your safety rules, like having a passcode, can reach company data.",
        symbolName: "checkmark.shield.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open Device Compliance",
                instruction: "In the Intune admin center, go to Devices and start a new compliance policy.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Policy"
            ),
            WorkflowStep(
                title: "Set the Ground Rules",
                instruction: "Choose the requirements devices must meet, like a passcode, encryption, or a minimum OS version.",
                jargonTerms: ["Compliance Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide What Happens to Stragglers",
                instruction: "Set an action for devices that don't pass, like marking them noncompliant and blocking access.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect It to Access Rules",
                instruction: "Pair this policy with a Conditional Access Policy so noncompliant devices are kept out automatically.",
                jargonTerms: ["Conditional Access Policy"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let entraAppRegistrationSetup = Workflow(
        title: "Register an App to Sign In with Microsoft",
        summary: "Let people log into your app with their Microsoft account instead of making up a new password.",
        symbolName: "person.badge.key.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Register the App",
                instruction: "In Entra ID, register a new app and give it a name your users will recognize.",
                jargonTerms: ["App Registration", "Entra ID"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Return Address",
                instruction: "Add a redirect URI, the web address Microsoft sends people back to after they sign in.",
                jargonTerms: ["Redirect URI"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Secret",
                instruction: "Generate a client secret so your app can prove it's really the one asking, not an imposter.",
                jargonTerms: ["Client Secret"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Ask for Permission",
                instruction: "Choose what your app is allowed to see, like the user's name and email, and nothing more.",
                jargonTerms: ["OAuth Consent Screen"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let powerAppsCanvasAppSetup = Workflow(
        title: "Build a Canvas App in Power Apps",
        summary: "Turn a spreadsheet or database into a real app with buttons and screens, without writing code.",
        symbolName: "square.and.pencil",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Start a Blank Canvas",
                instruction: "Open Power Apps and start a new canvas app, which gives you a blank screen to design freely.",
                jargonTerms: ["Canvas App"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Your Data",
                instruction: "Add a data source, like a spreadsheet or SharePoint list, so your app has something to show.",
                jargonTerms: ["Data Source", "Connector"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Screens and Buttons",
                instruction: "Drag in text boxes, buttons, and forms, then connect each one to the data it should show or save.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share It with Your Team",
                instruction: "Publish the app and share it with the people who should use it.",
                jargonTerms: ["User License"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let microsoftFormsSetup = Workflow(
        title: "Build a Form with Microsoft Forms",
        summary: "Collect answers, sign-ups, or feedback from anyone with a simple link, no spreadsheet setup required.",
        symbolName: "list.bullet.clipboard.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Start a New Form",
                instruction: "Open Microsoft Forms and create a new form or quiz.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your Questions",
                instruction: "Add each question and choose its type, like multiple choice, short answer, or a rating.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the Link",
                instruction: "Share the form's link or QR code with the people you want to hear from.",
                jargonTerms: ["QR Code", "Share Link"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Check the Results",
                instruction: "Watch responses roll in on the Responses tab, or send them straight to Excel for deeper digging.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureVirtualNetworkSetup = Workflow(
        title: "Set Up an Azure Virtual Network",
        summary: "Build a private, gated neighborhood in the cloud where your resources can talk to each other safely.",
        symbolName: "network",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the Network",
                instruction: "In the Azure portal, create a virtual network and give it a private range of addresses.",
                jargonTerms: ["Virtual Network"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Divide It into Subnets",
                instruction: "Split the network into subnets so different resources, like your web app and your database, stay in their own sections.",
                jargonTerms: ["Subnet"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set the Guard Rails",
                instruction: "Attach a network security group to control exactly which traffic is allowed in and out.",
                jargonTerms: ["Network Security Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect Your Resources",
                instruction: "Place your virtual machines or databases inside the network so they can reach each other without going out to the public internet.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureContainerRegistrySetup = Workflow(
        title: "Set Up an Azure Container Registry",
        summary: "Give your team a private shelf to store the packaged versions of your app, ready to deploy anywhere.",
        symbolName: "shippingbox.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the Registry",
                instruction: "In the Azure portal, create a container registry to hold your app's packaged images.",
                jargonTerms: ["Container Registry"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Build and Push an Image",
                instruction: "Package your app into a container image and upload it to the registry.",
                jargonTerms: ["Container Image"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Lock the Shelf",
                instruction: "Turn on access controls so only your team and your deployment tools can pull images from the registry.",
                jargonTerms: ["IAM Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Deploy from the Registry",
                instruction: "Point your App Service or container app at the registry so it always runs the latest packaged version.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let teamsPhoneCallingSetup = Workflow(
        title: "Turn On Calling with Teams Phone",
        summary: "Let your team make and receive real phone calls right from Microsoft Teams.",
        symbolName: "phone.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Get a Calling Plan",
                instruction: "Assign a calling plan to your organization so Teams can make and receive calls over the regular phone network.",
                jargonTerms: ["Calling Plan"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assign Phone Numbers",
                instruction: "Give each person or shared line its own phone number inside the Teams admin center.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Voice"
            ),
            WorkflowStep(
                title: "Set Up a Robot Receptionist",
                instruction: "Create an auto attendant so callers hear a greeting and get routed to the right person automatically.",
                jargonTerms: ["Auto Attendant"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test a Real Call",
                instruction: "Place a test call in and out to make sure everything connects the way it should.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let microsoft365RetentionPolicySetup = Workflow(
        title: "Set Up a Retention Policy in Microsoft 365",
        summary: "Decide automatically how long emails and files stick around, so nothing important gets deleted too soon or kept too long.",
        symbolName: "archivebox.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open the Compliance Center",
                instruction: "Go to the Microsoft Purview compliance portal, where all your organization's data rules live.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Retention Label",
                instruction: "Create a retention label that marks content as \"keep\" or \"delete after\" a set amount of time.",
                jargonTerms: ["Retention Label"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Apply a Retention Policy",
                instruction: "Create a retention policy that applies your rule automatically across mailboxes, Teams chats, or SharePoint sites.",
                jargonTerms: ["Retention Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Review Before It Applies",
                instruction: "Check which locations the policy covers, since it can take up to a day to take effect everywhere.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let microsoftDefenderCloudAppsSetup = Workflow(
        title: "Spot Risky Cloud Apps Automatically",
        summary: "Set up Microsoft Defender for Cloud Apps to flag risky sign-ins and block unapproved apps before they cause trouble.",
        symbolName: "shield.lefthalf.filled",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "See What Apps Your Team Actually Uses",
                instruction: "Turn on Cloud Discovery so it can scan your network traffic and reveal every app people are quietly using, including the ones IT never approved.",
                jargonTerms: ["Cloud Discovery", "Shadow IT"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Mark Apps as Approved or Risky",
                instruction: "Go through the discovered apps and label each one as sanctioned, tolerated, or blocked based on how much you trust it with company data.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Risk Score"
            ),
            WorkflowStep(
                title: "Build a Rule That Watches for Odd Behavior",
                instruction: "Set up anomaly detection so unusual activity, like a sign-in from two countries within minutes, gets flagged automatically.",
                jargonTerms: ["Anomaly Detection"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write a Policy That Reacts Automatically",
                instruction: "Create an activity policy that takes action on its own, such as blocking a mass file download the moment it starts.",
                jargonTerms: ["Activity Policy"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Test the Alert With a Practice Sign-In",
                instruction: "Trigger a harmless test event and confirm the alert fires and the right people get notified.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let azureFunctionSetup = Workflow(
        title: "Deploy Your First Serverless Function",
        summary: "Write a small piece of code and let Azure run it automatically without managing a server.",
        symbolName: "bolt.horizontal.circle.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Function App",
                instruction: "Set up a Function App — the lightweight container that will host and run your code, serverless style.",
                jargonTerms: ["Function App", "Serverless"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick How It Gets Billed",
                instruction: "Choose the Consumption Plan so you only pay for the split seconds your code is actually running.",
                jargonTerms: ["Consumption Plan"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose What Wakes Your Code Up",
                instruction: "Pick a function trigger — the event, like a new file arriving or a timer, that tells your code it's time to run.",
                jargonTerms: ["Function Trigger"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Pieces",
                instruction: "Connect the Function App, its trigger, and your code together into one working unit.",
                jargonTerms: [],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Write a Tiny Bit of Code",
                instruction: "Paste in a short starter script that just logs a message — enough to prove the whole pipeline works.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Run It and Watch the Logs",
                instruction: "Trigger the function manually and watch the live log stream to confirm it ran successfully.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let azureLogicAppSetup = Workflow(
        title: "Automate a Task With Logic Apps",
        summary: "Build a no-code workflow that watches for an event and automatically takes action.",
        symbolName: "arrow.triangle.branch",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Logic App",
                instruction: "Start a new Logic App — a visual canvas where you'll snap together steps instead of writing code.",
                jargonTerms: ["Logic App"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick What Starts the Workflow",
                instruction: "Choose the trigger that kicks everything off, like a new email arriving or a form being submitted.",
                jargonTerms: ["Trigger"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Connector to Another Service",
                instruction: "Add a connector so your workflow can talk to another app, like Outlook, Teams, or a spreadsheet.",
                jargonTerms: ["Connector"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Chain Together the Actions",
                instruction: "Add action steps one after another so each piece of the task runs in order, automatically.",
                jargonTerms: ["Action Step"],
                visual: .plain,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Turn It On and Watch It Run",
                instruction: "Save and enable the workflow, then check the run history to confirm it fired correctly.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Run History",
                xpValue: 15
            )
        ]
    )

    static let microsoftLoopWorkspaceSetup = Workflow(
        title: "Set Up a Shared Loop Workspace",
        summary: "Create a living workspace where your team can co-edit notes, tasks, and plans in real time.",
        symbolName: "arrow.triangle.2.circlepath",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the Workspace",
                instruction: "Start a new Loop workspace — a shared space that will hold every page your team builds together.",
                jargonTerms: ["Loop Workspace"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Invite Your Team",
                instruction: "Add teammates to the workspace so everyone can see and edit the same pages.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your First Loop Component",
                instruction: "Drop in a Loop component, like a table or task list, that stays perfectly in sync everywhere it's shared.",
                jargonTerms: ["Loop Component"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Drop the Component Into Teams or Email",
                instruction: "Paste the component into a chat or email — it keeps updating live in every place you pasted it, not just the original page.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Organize Pages Into Folders",
                instruction: "Group related pages together so the workspace stays easy to navigate as it grows.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let vivaEngageCommunitySetup = Workflow(
        title: "Start a Viva Engage Community",
        summary: "Create a company-wide space for employees to ask questions, share updates, and connect across teams.",
        symbolName: "person.3.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create the Community",
                instruction: "Set up a Viva Engage community around a topic, team, or interest that people can gather in.",
                jargonTerms: ["Viva Engage Community"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assign a Community Leader",
                instruction: "Pick a community leader who will keep discussions on track and welcome new members.",
                jargonTerms: ["Community Leader"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Who Can Join",
                instruction: "Decide whether the community is open to everyone in the company or invite-only, and whether guest access is allowed.",
                jargonTerms: ["Guest Access"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Post a Welcome Message to the Storyline",
                instruction: "Share an intro post to the storyline feed so members see something the moment they arrive.",
                jargonTerms: ["Storyline Feed"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Pin Important Resources",
                instruction: "Pin a welcome guide or FAQ to the top of the community so newcomers can find it instantly.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let azureFrontDoorSetup = Workflow(
        title: "Route Traffic Globally With Front Door",
        summary: "Set up Azure Front Door to send visitors to the closest, healthiest copy of your app anywhere in the world.",
        symbolName: "globe",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Front Door Profile",
                instruction: "Start a Front Door profile — the front-facing entry point that all your visitors will hit first.",
                jargonTerms: ["Front Door Profile"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your Origins as a Backend Pool",
                instruction: "Group the real servers hosting your app, called origins, into a backend pool that Front Door can choose from.",
                jargonTerms: ["Backend Pool", "Origin"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write a Routing Rule",
                instruction: "Create a routing rule that tells Front Door which incoming web addresses should go to which backend pool.",
                jargonTerms: ["Routing Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Global Path",
                instruction: "Connect the profile, backend pool, and routing rule into one working traffic path from visitor to server.",
                jargonTerms: [],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Understand the Edge Network",
                instruction: "Learn how a point of presence near the visitor answers requests fast, instead of every request traveling to one distant server.",
                jargonTerms: ["Point of Presence"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test From a Different Region",
                instruction: "Load your site from a different part of the world and confirm it's being served from a nearby location.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let azureApiManagementSetup = Workflow(
        title: "Publish an API Through API Management",
        summary: "Put a secure, managed front door in front of your API before you hand it to developers.",
        symbolName: "arrow.left.arrow.right.circle.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create an API Management Instance",
                instruction: "Set up an API Management instance — the gateway that will sit in front of your API and manage every request.",
                jargonTerms: ["API Management Instance"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Import Your API",
                instruction: "Point the instance at your existing API so it knows which addresses and actions to manage.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Group Endpoints Into a Product",
                instruction: "Bundle related endpoints into an API product so you can offer them to developers as one package.",
                jargonTerms: ["API Product"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Attach a Policy",
                instruction: "Add an API policy to enforce rules automatically, like limiting how many requests a user can make per minute.",
                jargonTerms: ["API Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Request Path",
                instruction: "Connect the instance, product, and policy so every incoming request flows through the right checks.",
                jargonTerms: [],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Hand Out a Subscription Key",
                instruction: "Give developers a subscription key so they can authenticate their calls to your published API.",
                jargonTerms: ["Subscription Key"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let sharePointPermissionLevelsSetup = Workflow(
        title: "Create Custom SharePoint Permission Levels",
        summary: "Build permission levels that give people exactly the access they need — no more, no less.",
        symbolName: "lock.shield",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Open Site Permissions",
                instruction: "Head into your site's permission settings to see who currently has access and how much.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand the Default Permission Level",
                instruction: "Review a built-in permission level, like Edit or Read, to see the exact bundle of abilities it grants.",
                jargonTerms: ["Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Copy a Level to Customize It",
                instruction: "Duplicate an existing level to create a custom permission level you can tailor without breaking the original.",
                jargonTerms: ["Custom Permission Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Uncheck the Abilities You Don't Want",
                instruction: "Go through the checklist and turn off anything you don't want this group to be able to do, like deleting items.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Permission Checklist",
                xpValue: 15
            ),
            WorkflowStep(
                title: "Apply It to a SharePoint Group",
                instruction: "Assign your new custom level to a SharePoint group so everyone in that group gets the same tailored access.",
                jargonTerms: ["SharePoint Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Roll It Out Across the Site Collection",
                instruction: "Apply the same permission level consistently across the whole site collection so access stays predictable everywhere.",
                jargonTerms: ["Site Collection"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let azureBastionSetup = Workflow(
        title: "Access a VM Securely Without a Public IP",
        summary: "Set up Azure Bastion so you can safely connect to a virtual machine straight from the browser — no exposed IP address needed.",
        symbolName: "network.badge.shield.half.filled",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Bastion Subnet",
                instruction: "Carve out a dedicated bastion subnet inside your virtual network to hold the Bastion service.",
                jargonTerms: ["Bastion Subnet", "Virtual Network"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Deploy the Bastion Host",
                instruction: "Deploy the Bastion host — a managed doorway that lets you reach your VM through the browser instead of the open internet.",
                jargonTerms: ["Bastion Host"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Understand Why You're Skipping the Public IP",
                instruction: "See why your VM no longer needs its own public IP address once Bastion is handling the connection for you.",
                jargonTerms: ["Public IP Address"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Secure Path",
                instruction: "Connect the virtual network, bastion subnet, and bastion host into one protected route to your VM.",
                jargonTerms: [],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Connect to Your VM From the Browser",
                instruction: "Open your VM straight from the Azure portal — no separate remote desktop app or exposed address required.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Connect Button",
                xpValue: 15
            )
        ]
    )

    static let copilotStudioBotSetup = Workflow(
        title: "Build a Simple Bot in Copilot Studio",
        summary: "Create a conversational bot that can answer common questions without writing any code.",
        symbolName: "bubble.left.and.bubble.right.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Start a New Bot",
                instruction: "Create a blank bot in Copilot Studio to begin building your conversation.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create Your First Topic",
                instruction: "Build a conversation topic — a self-contained chunk of the conversation dedicated to one question or task.",
                jargonTerms: ["Conversation Topic"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Trigger Phrases",
                instruction: "Add trigger phrases, the sample things a person might type, so the bot recognizes when to use this topic.",
                jargonTerms: ["Trigger Phrase"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Capture Details With an Entity Slot",
                instruction: "Add an entity slot so the bot can pull out useful details from what someone types, like a date or order number.",
                jargonTerms: ["Entity Slot"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Test It in the Chat Pane",
                instruction: "Try out your bot in the built-in test pane before anyone outside your team ever sees it.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Test Bot Pane",
                xpValue: 15
            ),
            WorkflowStep(
                title: "Publish to a Channel",
                instruction: "Publish your bot to a channel, like Teams or a website, so real people can start chatting with it.",
                jargonTerms: ["Publish Channel"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let azureCosmosDbSetup = Workflow(
        title: "Launch a Cosmos DB Database",
        summary: "Spin up a fast, globally distributed database that can handle huge amounts of traffic.",
        symbolName: "cylinder.split.1x2.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Cosmos DB Account",
                instruction: "Set up a Cosmos DB account — the top-level home for every database you'll build inside it.",
                jargonTerms: ["Cosmos DB Account"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add a Database and Container",
                instruction: "Create a database, then add a container inside it — the actual place your records will live.",
                jargonTerms: ["Database Container"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose a Consistency Level",
                instruction: "Pick a consistency level that balances how instantly every copy of your data agrees against how fast reads and writes are.",
                jargonTerms: ["Consistency Level"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Your Throughput",
                instruction: "Choose how many request units to reserve — the currency Cosmos DB uses to measure how much read and write power you get.",
                jargonTerms: ["Request Unit"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assemble the Database Stack",
                instruction: "Connect the account, database, and container together into one working database you can start using.",
                jargonTerms: [],
                visual: .engineRoom,
                engineRoomKit: .azure,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Insert Your First Item",
                instruction: "Add a single test record and confirm you can read it back out again.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let windows365CloudPcSetup = Workflow(
        title: "Provision a Windows 365 Cloud PC",
        summary: "Give an employee a full Windows desktop that streams from the cloud to any device they own.",
        symbolName: "desktopcomputer",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Pick a Cloud PC Size",
                instruction: "Choose the Cloud PC size that fits the employee's workload — a virtual computer with its own processor, memory, and storage.",
                jargonTerms: ["Cloud PC"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Provisioning Policy",
                instruction: "Set up a provisioning policy that decides which Windows image and settings every new Cloud PC starts with.",
                jargonTerms: ["Provisioning Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Assign the License to the Employee",
                instruction: "Assign a user license so the Cloud PC actually gets built and shows up for that employee.",
                jargonTerms: ["User License"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Wait for It to Build",
                instruction: "Give it a little time — Windows 365 needs to build and configure the Cloud PC behind the scenes before it's ready.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set a Restore Point Schedule",
                instruction: "Turn on regular restore points so the Cloud PC can be rolled back to a working state if something goes wrong.",
                jargonTerms: ["Restore Point"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Sign In From Any Device",
                instruction: "Open the Windows 365 app on any device and confirm the employee can reach their full desktop instantly.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Windows 365 App",
                xpValue: 15
            )
        ]
    )

    static let microsoftSentinelAlertRuleSetup = Workflow(
        title: "Create an Alert Rule in Microsoft Sentinel",
        summary: "Teach Sentinel to watch your logs for a specific danger sign and notify your team the moment it happens.",
        symbolName: "eye.trianglebadge.exclamationmark.fill",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Connect a Data Source",
                instruction: "Point Sentinel at a Log Analytics Workspace so it has a stream of activity logs to actually watch.",
                jargonTerms: ["Log Analytics Workspace"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Start From an Analytics Rule Template",
                instruction: "Pick an alert rule template as your starting point instead of building the detection logic completely from scratch.",
                jargonTerms: ["Alert Rule Template"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write the Query That Defines the Danger",
                instruction: "Fine-tune the analytics rule's query so it matches the exact pattern of activity you're worried about.",
                jargonTerms: ["Analytics Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set How Sentinel Groups Matches Into an Incident",
                instruction: "Decide how related alerts get bundled into a single security incident so your team isn't buried in duplicates.",
                jargonTerms: ["Security Incident"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Automate the Response",
                instruction: "Attach an automated action, like sending a notification or isolating an account, so the response starts the moment the rule fires.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Turn the Rule On",
                instruction: "Flip the rule to active and confirm it starts watching your logs in real time.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Enable Rule Toggle",
                xpValue: 15
            )
        ]
    )

    // MARK: Amazon

    static let awsS3HostingSetup = Workflow(
        title: "Host a Website on Amazon S3",
        summary: "Turn a storage box into a place the whole internet can visit.",
        symbolName: "globe.americas.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create a Storage Box",
                instruction: "Create an S3 bucket and give it the same name as your website's address.",
                jargonTerms: ["Bucket"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Bucket"
            ),
            WorkflowStep(
                title: "Assemble Your Engine Room",
                instruction: "Drag each part into your chassis — storage, compute, and the bouncer at the door.",
                jargonTerms: ["Compute Instance", "Bucket", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Unlock the Box, Carefully",
                instruction: "Add a bucket policy that lets visitors read your files, without letting them change or delete anything.",
                jargonTerms: ["Bucket Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hand It to the Delivery Network",
                instruction: "Put a CloudFront distribution in front of your bucket so visitors everywhere get fast delivery.",
                jargonTerms: ["CloudFront Distribution"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point Your Domain at It",
                instruction: "Use Route 53 to point your domain name at your new distribution.",
                jargonTerms: ["Route 53", "A Record"],
                visual: .dnsVisualizer,
                xpValue: 20
            )
        ]
    )

    static let awsIAMSetup = Workflow(
        title: "Lock Down Access with IAM",
        summary: "Hand out keycards instead of sharing one master password.",
        symbolName: "lock.shield.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Write the Rulebook",
                instruction: "Create an IAM policy that spells out exactly what your app is allowed to do.",
                jargonTerms: ["IAM Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Issue a Keycard",
                instruction: "Generate an access key for your app instead of using your own account's sign-in.",
                jargonTerms: ["Access Key"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Access Key"
            ),
            WorkflowStep(
                title: "Store It Somewhere Safe",
                instruction: "Save the key as an environment variable rather than typing it directly into your code.",
                jargonTerms: ["Environment Variable"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsRDSSetup = Workflow(
        title: "Set Up a Managed Database with RDS",
        summary: "Hire Amazon to run your database so you never touch a server rack.",
        symbolName: "cylinder.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Pick Your Filing System",
                instruction: "Choose an RDS database and pick the engine your app already speaks, like ordering the right filing system for your paperwork.",
                jargonTerms: ["RDS Database"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Database"
            ),
            WorkflowStep(
                title: "Lock the Front Door",
                instruction: "Add a firewall rule so only your app's address is allowed to knock, not the whole internet.",
                jargonTerms: ["Firewall Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On the Safety Net",
                instruction: "Enable automated backups so a nightly photocopy of your data is always sitting in a drawer, just in case.",
                jargonTerms: ["Automated Backup"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point Your App at It",
                instruction: "Grab the database's endpoint, like an unlisted phone number, and give it to your app so the two can talk.",
                jargonTerms: ["Database Endpoint"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsLambdaSetup = Workflow(
        title: "Run Code Without a Server, with Lambda",
        summary: "Hire a handyman who only shows up, and gets paid, when there's a job to do.",
        symbolName: "bolt.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Write the Job",
                instruction: "Create a Lambda function and upload the code for the one task you want handled.",
                jargonTerms: ["Lambda Function"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Function"
            ),
            WorkflowStep(
                title: "Give It a Work Badge",
                instruction: "Attach an execution role so the handyman can only open the doors your job actually requires.",
                jargonTerms: ["Execution Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Install a Doorbell",
                instruction: "Set a trigger, like a new file upload, so the handyman wakes up and starts working the moment it's needed.",
                jargonTerms: ["Trigger"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Ring It and Check the Work",
                instruction: "Test the function and read the logs to make sure the handyman actually did the job right.",
                jargonTerms: ["Lambda Function"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsSQSSetup = Workflow(
        title: "Queue Up Tasks with SQS",
        summary: "Give your app a waiting line so nothing gets lost in the rush.",
        symbolName: "tray.full.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create the Waiting Line",
                instruction: "Create an SQS queue, a single-file line where tasks wait patiently until someone's free to handle them.",
                jargonTerms: ["SQS Queue"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Queue"
            ),
            WorkflowStep(
                title: "Set the Guest List",
                instruction: "Add a queue policy that spells out exactly who's allowed to drop off or pick up tasks.",
                jargonTerms: ["Queue Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Put Up a Do Not Disturb Sign",
                instruction: "Set a visibility timeout so once a worker grabs a task, nobody else tries to grab that same one.",
                jargonTerms: ["Visibility Timeout"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hook Up the Workers",
                instruction: "Connect a Lambda function to poll the line and process tasks the moment they arrive.",
                jargonTerms: ["Lambda Function", "SQS Queue"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsSNSSetup = Workflow(
        title: "Send Alerts to Everyone with SNS",
        summary: "One announcement, broadcast instantly to every phone and inbox that's listening.",
        symbolName: "bell.badge.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Set Up the Megaphone",
                instruction: "Create an SNS topic, a single megaphone that anyone signed up can hear from.",
                jargonTerms: ["SNS Topic"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Topic"
            ),
            WorkflowStep(
                title: "Sign People Up",
                instruction: "Add a subscription for each email or phone number that should hear the announcements.",
                jargonTerms: ["SNS Subscription"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm You Want In",
                instruction: "Click the confirmation link that shows up, the same way you'd confirm a newsletter sign-up.",
                jargonTerms: ["SNS Subscription"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Send the First Announcement",
                instruction: "Publish a test message to the topic and watch it land everywhere at once.",
                jargonTerms: ["SNS Topic"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsCloudWatchAlarmSetup = Workflow(
        title: "Get Warned Before Things Break with CloudWatch",
        summary: "Post a lookout who shouts before the ship actually starts sinking.",
        symbolName: "waveform.path.ecg",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Pick What to Watch",
                instruction: "Choose a metric to keep an eye on, like a vital sign you're tracking on a patient.",
                jargonTerms: ["Metric"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Alarm"
            ),
            WorkflowStep(
                title: "Set the Tripwire",
                instruction: "Turn that metric into a CloudWatch alarm, a smoke detector that goes off once things cross the line.",
                jargonTerms: ["CloudWatch Alarm"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose Who Gets the Call",
                instruction: "Connect the alarm to an SNS topic so the right people actually hear it go off.",
                jargonTerms: ["CloudWatch Alarm", "SNS Topic"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Test the Smoke Detector",
                instruction: "Push the metric over the line on purpose and confirm the alert actually reaches you.",
                jargonTerms: ["CloudWatch Alarm"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsDynamoDBSetup = Workflow(
        title: "Store Data That Scales Itself with DynamoDB",
        summary: "A filing cabinet that grows extra drawers the moment you need them.",
        symbolName: "folder.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Build the Cabinet",
                instruction: "Create a DynamoDB table, a self-expanding filing cabinet that never runs out of drawer space.",
                jargonTerms: ["DynamoDB Table"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Table"
            ),
            WorkflowStep(
                title: "Pick the Label You'll Search By",
                instruction: "Choose a partition key, the folder tab you'll always use to find things fast.",
                jargonTerms: ["Partition Key"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide How You Pay",
                instruction: "Pick a capacity mode, either pay-as-you-go for unpredictable traffic or a flat rate for steady traffic.",
                jargonTerms: ["Capacity Mode"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your First Records",
                instruction: "Drop a few items into the table and confirm you can pull them back out by their label.",
                jargonTerms: ["DynamoDB Table", "Partition Key"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsVPCSetup = Workflow(
        title: "Build Your Own Private Network with a VPC",
        summary: "Fence off your own private neighborhood inside Amazon's data center.",
        symbolName: "network",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Draw the Property Line",
                instruction: "Create a VPC and give it an address range, marking out your own private neighborhood.",
                jargonTerms: ["VPC"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create VPC"
            ),
            WorkflowStep(
                title: "Assemble Your Engine Room",
                instruction: "Drag in the pieces of your neighborhood: streets, street signs, and the gate at the entrance.",
                jargonTerms: ["Subnet", "Route Table", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Decide Who Can Come In From Outside",
                instruction: "Attach an internet gateway, the neighborhood gate that lets approved traffic in and out.",
                jargonTerms: ["Internet Gateway"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Move a Server In",
                instruction: "Launch an EC2 instance inside your new neighborhood and confirm it can reach the outside world.",
                jargonTerms: ["EC2 Instance", "VPC"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsElasticBeanstalkSetup = Workflow(
        title: "Deploy an App Without Managing Servers, with Elastic Beanstalk",
        summary: "Hand Amazon your code and let it build the storefront around it.",
        symbolName: "shippingbox.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Hand Over Your App",
                instruction: "Create an Elastic Beanstalk environment and upload your code like handing keys to a turnkey storefront.",
                jargonTerms: ["Elastic Beanstalk Environment"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Application"
            ),
            WorkflowStep(
                title: "Let It Build the Scaffolding",
                instruction: "Sit back while it automatically sets up the compute instance and load balancer your app needs to run.",
                jargonTerms: ["EC2 Instance", "Load Balancer"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Set Your Environment Variables",
                instruction: "Add environment variables for things like database passwords instead of burying them in your code.",
                jargonTerms: ["Environment Variable"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Ship an Update",
                instruction: "Upload a new version and watch it roll out to the storefront with a single click.",
                jargonTerms: ["Elastic Beanstalk Environment"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsACMSetup = Workflow(
        title: "Get a Free SSL Certificate with ACM",
        summary: "Put a padlock on your website without paying a locksmith.",
        symbolName: "lock.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Request Your Certificate",
                instruction: "Request an SSL certificate for your domain, like ordering a padlock cut to fit your front door.",
                jargonTerms: ["SSL Certificate"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Request Certificate"
            ),
            WorkflowStep(
                title: "Prove You Own the House",
                instruction: "Add the DNS record Amazon gives you, proving to the internet that you really own this address.",
                jargonTerms: ["DNS"],
                visual: .dnsVisualizer
            ),
            WorkflowStep(
                title: "Wait for the Green Light",
                instruction: "Give it a few minutes while Amazon checks your proof and issues the certificate.",
                jargonTerms: ["SSL Certificate"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Attach It to Your Front Door",
                instruction: "Attach the certificate to your CloudFront distribution or load balancer so visitors see the padlock.",
                jargonTerms: ["CloudFront Distribution", "Load Balancer"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsSecretsManagerSetup = Workflow(
        title: "Stop Hardcoding Passwords with Secrets Manager",
        summary: "Keep your passwords in a vault instead of taped to the monitor.",
        symbolName: "key.horizontal.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Put the Secret in the Vault",
                instruction: "Store a password or key as a Secrets Manager secret instead of typing it into your code.",
                jargonTerms: ["Secrets Manager Secret"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Store a New Secret"
            ),
            WorkflowStep(
                title: "Decide Who Gets a Key",
                instruction: "Attach an IAM policy so only the app that actually needs the secret can open the vault.",
                jargonTerms: ["IAM Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Auto-Changing Locks",
                instruction: "Enable secret rotation so the locks get changed on a schedule, automatically, without you lifting a finger.",
                jargonTerms: ["Secret Rotation"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Fetch It in Your App",
                instruction: "Have your app pull the secret at startup instead of storing it in an environment variable.",
                jargonTerms: ["Secrets Manager Secret", "Environment Variable"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsCloudTrailSetup = Workflow(
        title: "Keep a Record of Every Move with CloudTrail",
        summary: "Install security cameras that log every visitor to your account.",
        symbolName: "doc.text.magnifyingglass",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Turn On the Cameras",
                instruction: "Create a CloudTrail trail so every action taken in your account gets written to a security log.",
                jargonTerms: ["CloudTrail Trail"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Trail"
            ),
            WorkflowStep(
                title: "Choose Where the Footage Goes",
                instruction: "Point the trail at a bucket so all that footage has somewhere safe to live.",
                jargonTerms: ["Bucket"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch for Trouble",
                instruction: "Set up a CloudWatch alarm that shouts if something suspicious shows up in the footage.",
                jargonTerms: ["CloudTrail Trail", "CloudWatch Alarm"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsAutoScalingSetup = Workflow(
        title: "Let Your App Grow and Shrink on Its Own with Auto Scaling",
        summary: "Hire extra staff automatically when the store gets busy, send them home when it's quiet.",
        symbolName: "arrow.triangle.2.circlepath",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Set the Blueprint",
                instruction: "Create a launch template describing exactly what each new server should look like, like a staff uniform and instructions.",
                jargonTerms: ["Launch Template"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Launch Template"
            ),
            WorkflowStep(
                title: "Assemble Your Engine Room",
                instruction: "Drag compute, a load balancer, and a firewall together to form the crew that greets every new hire.",
                jargonTerms: ["Compute Instance", "Load Balancer", "Firewall Rule"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 25
            ),
            WorkflowStep(
                title: "Set the Crowd Size Rules",
                instruction: "Define an auto scaling group with a minimum, maximum, and desired staffing level.",
                jargonTerms: ["Auto Scaling Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Tell It When to Hire",
                instruction: "Attach a scaling policy tied to a CloudWatch alarm, so it calls in extra help the moment things get busy.",
                jargonTerms: ["Auto Scaling Group", "CloudWatch Alarm"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsCloudFrontSetup = Workflow(
        title: "Speed Up Your Site Worldwide with CloudFront",
        summary: "Serve your website's files from servers close to each visitor, so pages load fast everywhere.",
        symbolName: "network",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Point CloudFront at Your Files",
                instruction: "Create a CloudFront distribution and tell it which S3 bucket (or server) holds your website's files — this is called the origin.",
                jargonTerms: ["CloudFront Distribution", "Origin"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Distribution Button",
                instruction: "Look for the button that starts a brand-new distribution in the CloudFront console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Distribution"
            ),
            WorkflowStep(
                title: "Decide How Long to Cache Pages",
                instruction: "Set a cache duration so CloudFront keeps a copy of your pages and doesn't have to ask your origin for every single visitor.",
                jargonTerms: ["TTL"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your Own Domain Name",
                instruction: "Attach your domain and an SSL certificate so visitors can reach your site at your own web address, securely.",
                jargonTerms: ["SSL Certificate", "CNAME"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsRoute53Setup = Workflow(
        title: "Point Your Domain to the Internet with Route 53",
        summary: "Buy or manage your domain name and tell the internet exactly where it should send visitors.",
        symbolName: "globe",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Register or Move In Your Domain",
                instruction: "Register a new domain through Route 53, or transfer in one you already own.",
                jargonTerms: ["Route 53"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Home for Your Records",
                instruction: "Route 53 groups all of a domain's settings into a hosted zone — create one for your domain.",
                jargonTerms: ["Hosted Zone"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Tell the Web Where Your Site Lives",
                instruction: "Add an A record pointing your domain at your website's address.",
                jargonTerms: ["A Record"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Record Button",
                instruction: "Look for the button that adds a new record inside your hosted zone.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Record"
            ),
            WorkflowStep(
                title: "Wait for the Change to Spread",
                instruction: "Give it a little time for the update to propagate to servers around the world before you test it.",
                jargonTerms: ["Propagation", "TTL"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsAPIGatewaySetup = Workflow(
        title: "Put a Front Door on Your Backend with API Gateway",
        summary: "Give apps a single, secure web address to call, instead of talking to your backend directly.",
        symbolName: "door.left.hand.open",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create Your API",
                instruction: "Set up a new API in API Gateway to act as the front door for requests coming from your app or website.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect It to Your Backend",
                instruction: "Wire up a route so incoming requests get forwarded to your Lambda function or server.",
                jargonTerms: ["Lambda Function"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Publish a Stage",
                instruction: "Deploy your API to a stage, like 'production,' so it has a real web address apps can call.",
                jargonTerms: ["Deployment Stage"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Deploy API Button",
                instruction: "Look for the button that publishes your changes to a live stage.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Deploy API"
            ),
            WorkflowStep(
                title: "Require a Key for Access",
                instruction: "Ask callers to include an API key so you can control and track who's using your API.",
                jargonTerms: ["API Key"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsCognitoSetup = Workflow(
        title: "Let People Sign In with Cognito",
        summary: "Give your app secure sign-up and sign-in screens without building your own password system.",
        symbolName: "person.badge.key.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create a User Pool",
                instruction: "Set up a Cognito user pool — the directory that will hold everyone who signs up for your app.",
                jargonTerms: ["User Pool"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose How People Sign In",
                instruction: "Decide whether people sign in with an email address, a username, or a phone number.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn On Extra Protection",
                instruction: "Require multi-factor authentication so a stolen password alone isn't enough to break in.",
                jargonTerms: ["Multi-Factor Authentication"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create User Pool Button",
                instruction: "Look for the button that starts a brand-new user pool in the Cognito console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create User Pool"
            ),
            WorkflowStep(
                title: "Connect Your App",
                instruction: "Register your app as an app client so it can send people to the sign-in screen and get back a verified identity.",
                jargonTerms: ["App Client"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsCloudFormationSetup = Workflow(
        title: "Build Your Infrastructure from a Recipe with CloudFormation",
        summary: "Describe all the AWS resources your app needs in one file, then let AWS build them automatically.",
        symbolName: "doc.text.magnifyingglass",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Write Your Template",
                instruction: "Create a stack template that lists every resource you want — like a shopping list AWS can read.",
                jargonTerms: ["Stack Template"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Launch a Stack",
                instruction: "Upload your template to create a stack, and CloudFormation builds everything in it for you, in order.",
                jargonTerms: ["CloudFormation Stack"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Stack Button",
                instruction: "Look for the button that starts a new stack from your uploaded template.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Stack"
            ),
            WorkflowStep(
                title: "Watch It Build",
                instruction: "Check the stack's events to see each resource get created, and fix anything that fails before moving on.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Update or Tear Down Safely",
                instruction: "Change your template and update the stack to adjust everything at once, or delete the stack to remove every resource it created.",
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let awsSESSetup = Workflow(
        title: "Send Real Emails from Your App with SES",
        summary: "Send confirmation emails, receipts, and alerts from your own domain without running a mail server.",
        symbolName: "envelope.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Verify Your Sending Identity",
                instruction: "Prove you own your domain or email address so SES will send mail on your behalf.",
                jargonTerms: ["Verified Identity"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Records So Mail Isn't Flagged as Spam",
                instruction: "Add the DKIM and SPF records SES gives you to your domain's DNS, so inboxes trust mail from you.",
                jargonTerms: ["DKIM Record", "SPF Record"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Ask to Leave the Sandbox",
                instruction: "Request production access to lift the sandbox limits that only let you email addresses you've personally verified.",
                jargonTerms: ["Sandbox Mode"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Request Production Access Button",
                instruction: "Look for the button that submits your request to send to anyone, not just verified addresses.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Request Production Access"
            ),
            WorkflowStep(
                title: "Send Your First Message",
                instruction: "Use SES to send a test email and confirm it lands in the inbox, not spam.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsEventBridgeSetup = Workflow(
        title: "React Automatically to Events with EventBridge",
        summary: "Have AWS watch for things happening — like a new file or a scheduled time — and kick off actions for you.",
        symbolName: "bolt.horizontal.circle.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Pick Your Event Bus",
                instruction: "Choose the event bus that will carry the events you want to react to.",
                jargonTerms: ["Event Bus"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Describe What You're Watching For",
                instruction: "Write an event pattern that matches the specific thing you want to trigger on, like a new order or a failed upload.",
                jargonTerms: ["Event Pattern"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Choose What Happens Next",
                instruction: "Set a target, such as a Lambda function or an SNS topic, that runs automatically when a matching event shows up.",
                jargonTerms: ["Lambda Function", "SNS Topic"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Rule Button",
                instruction: "Look for the button that starts a new rule tying your event pattern to its target.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Rule"
            ),
            WorkflowStep(
                title: "Test with a Sample Event",
                instruction: "Send a sample event through the rule to confirm the right thing fires before you rely on it.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsBudgetsSetup = Workflow(
        title: "Get Warned Before Your Bill Surprises You with Budgets",
        summary: "Set a spending limit and get an email the moment your AWS costs start creeping past it.",
        symbolName: "dollarsign.circle.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Set Your Spending Limit",
                instruction: "Create a budget and enter the dollar amount you don't want to go over this month.",
                jargonTerms: ["Spending Threshold"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Budget Button",
                instruction: "Look for the button that starts a new budget in the Billing console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Budget"
            ),
            WorkflowStep(
                title: "Choose When to Be Warned",
                instruction: "Set alert thresholds, like 50% and 90% of your budget, so you get nudged early instead of finding out at 100%.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Where the Alert Goes",
                instruction: "Enter the email address that should receive the warning the moment a threshold is crossed.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsELBSetup = Workflow(
        title: "Spread Traffic Across Your App with a Load Balancer",
        summary: "Hand incoming visitors off to whichever server has room, so no single machine gets overwhelmed.",
        symbolName: "arrow.triangle.branch",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Build the Traffic Router",
                instruction: "Assemble a load balancer to sit in front of your app and hand out incoming requests.",
                jargonTerms: ["Load Balancer"],
                visual: .engineRoom,
                engineRoomKit: .aws
            ),
            WorkflowStep(
                title: "Group the Servers It Sends Traffic To",
                instruction: "Create a target group listing the servers that are allowed to receive traffic from the load balancer.",
                jargonTerms: ["Target Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Teach It to Check for Trouble",
                instruction: "Turn on health checks so the load balancer stops sending traffic to any server that's stopped responding.",
                jargonTerms: ["Health Check"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Load Balancer Button",
                instruction: "Look for the button that starts a new load balancer in the EC2 console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Load Balancer"
            ),
            WorkflowStep(
                title: "Grow Automatically Behind It",
                instruction: "Connect the load balancer to an auto scaling group so new servers join in automatically when traffic picks up.",
                jargonTerms: ["Auto Scaling Group"],
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let awsParameterStoreSetup = Workflow(
        title: "Keep Your App's Settings in One Safe Place with Parameter Store",
        summary: "Store settings and config values outside your code, so you can change them without a new deployment.",
        symbolName: "slider.horizontal.3",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create Your First Parameter",
                instruction: "Add an SSM parameter with a name and value, like a setting your app needs to run.",
                jargonTerms: ["SSM Parameter"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Encrypt the Sensitive Ones",
                instruction: "Store passwords and other secrets as encrypted parameters instead of plain text ones.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Parameter Button",
                instruction: "Look for the button that adds a new parameter in the Systems Manager console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Parameter"
            ),
            WorkflowStep(
                title: "Read It from Your App",
                instruction: "Have your app or Lambda function fetch the parameter at startup instead of hardcoding the value.",
                jargonTerms: ["Environment Variable"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsWAFSetup = Workflow(
        title: "Block Bad Traffic Before It Reaches You with WAF",
        summary: "Filter out malicious requests, like bots and attack attempts, before they ever hit your website or API.",
        symbolName: "shield.lefthalf.filled",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create a Web ACL",
                instruction: "Set up a web ACL, the rulebook that decides which requests get through and which get blocked.",
                jargonTerms: ["Web ACL"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Managed Protection Rules",
                instruction: "Turn on AWS's ready-made rule sets to block common attacks without writing any rules yourself.",
                jargonTerms: ["Firewall Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Web ACL Button",
                instruction: "Look for the button that starts a new web ACL in the WAF console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Web ACL"
            ),
            WorkflowStep(
                title: "Attach It to What You're Protecting",
                instruction: "Connect the web ACL to your CloudFront distribution, load balancer, or API so it actually filters incoming traffic.",
                jargonTerms: ["CloudFront Distribution", "Load Balancer"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch It in Action",
                instruction: "Check the request log to see what WAF is blocking, and adjust the rules if it's stopping real visitors.",
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsECSFargateSetup = Workflow(
        title: "Run a Container Without Managing Servers, with ECS Fargate",
        summary: "Deploy your app as a container and let AWS handle the servers underneath it entirely.",
        symbolName: "shippingbox.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Describe Your Container",
                instruction: "Write a task definition telling ECS which container image to run and how much memory and CPU it needs.",
                jargonTerms: ["Task Definition"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Cluster",
                instruction: "Set up an ECS cluster, the space where your containers will actually run.",
                jargonTerms: ["ECS Cluster"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Create Cluster Button",
                instruction: "Look for the button that starts a new cluster in the ECS console.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Create Cluster"
            ),
            WorkflowStep(
                title: "Launch It with Fargate",
                instruction: "Run your task definition on Fargate so AWS provisions and manages the underlying compute for you.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Put It Behind a Load Balancer",
                instruction: "Connect a load balancer so traffic reaches your running containers, and so ECS can replace any that crash.",
                jargonTerms: ["Load Balancer"],
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let awsOrganizationsSetup = Workflow(
        title: "Manage Multiple AWS Accounts at Once with Organizations",
        summary: "Group all your team's AWS accounts under one roof, with shared billing and consistent rules.",
        symbolName: "building.2.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create Your Organization",
                instruction: "Turn your existing AWS account into the management account for a new organization.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Invite or Create Member Accounts",
                instruction: "Add separate accounts for things like production, testing, and each team, so mistakes in one don't affect the others.",
                visual: .plain
            ),
            WorkflowStep(
                title: "Sort Accounts into Groups",
                instruction: "Organize accounts into organizational units so you can apply the same rules to accounts that belong together.",
                jargonTerms: ["Organizational Unit"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Find the Add Account Button",
                instruction: "Look for the button that invites or creates a new account inside your organization.",
                visual: .consoleOverlay,
                overlayTargetLabel: "Add Account"
            ),
            WorkflowStep(
                title: "Set Ground Rules Everyone Must Follow",
                instruction: "Attach a service control policy to block risky actions, like disabling security logging, across every account in the group.",
                jargonTerms: ["Service Control Policy"],
                visual: .plain,
                xpValue: 25
            )
        ]
    )

    static let awsXRaySetup = Workflow(
        title: "See Inside a Slow Request",
        summary: "Turn on tracing so you can watch a single request travel through every piece of your app and find out exactly where it's getting stuck.",
        symbolName: "waveform.path.ecg",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Turn On Tracing",
                instruction: "Flip on X-Ray for your app so it starts recording a trace every time someone uses it.",
                jargonTerms: ["X-Ray Trace"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Read the Segments",
                instruction: "Open a single trace and look at the segments — each one shows how long one hop of the request took.",
                jargonTerms: ["Segment"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Open the Service Map",
                instruction: "Switch to the service map view to see all your app's pieces laid out and connected by real traffic.",
                jargonTerms: ["Service Map"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Service Map"
            ),
            WorkflowStep(
                title: "Set a Sampling Rule",
                instruction: "Adjust the sampling rule so you're tracing a sensible slice of traffic instead of every single request.",
                jargonTerms: ["Sampling Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Spot the Bottleneck",
                instruction: "Sort traces by response time and follow the slowest one straight to the segment that's dragging everything down.",
                jargonTerms: ["X-Ray Trace", "Segment"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsElastiCacheSetup = Workflow(
        title: "Speed Up Your App With a Cache",
        summary: "Launch a fast, in-memory cache that sits in front of your database so repeat requests come back in a blink instead of a database round-trip.",
        symbolName: "bolt.horizontal.circle.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Choose Your Cache Engine",
                instruction: "Pick the cache engine that matches what your app expects to talk to.",
                jargonTerms: ["Cache Engine"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Launch the Cluster",
                instruction: "Create the cache cluster and decide how many cache nodes it should start with.",
                jargonTerms: ["Cache Cluster", "Cache Node"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Set an Eviction Policy",
                instruction: "Choose an eviction policy so the cache knows what to throw out first once it fills up.",
                jargonTerms: ["Eviction Policy"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Lock It Down",
                instruction: "Attach a security group so only your app servers are allowed to talk to the cache.",
                jargonTerms: ["Security Group"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Point Your App at the Cache",
                instruction: "Update your app's connection settings to check the cache first before it ever queries the database.",
                jargonTerms: ["Cache Cluster"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )

    static let awsStepFunctionsSetup = Workflow(
        title: "Chain Steps Into One Workflow",
        summary: "Build a visual flowchart that runs your Lambda functions and other tasks in order, retries the ones that fail, and shows you exactly where things stand.",
        symbolName: "arrow.triangle.branch",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Sketch the State Machine",
                instruction: "Start a new state machine and give it a name that describes the whole process it's automating.",
                jargonTerms: ["State Machine"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your First State",
                instruction: "Drop in a task state and point it at the Lambda function or action it should run.",
                jargonTerms: ["State", "Task State"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Wire the Steps Together",
                instruction: "Connect each state to the next, adding branches for retries and any either-or decisions along the way.",
                jargonTerms: ["State"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Give It an Execution Role",
                instruction: "Attach an execution role so the state machine is allowed to actually call the services it's wired to.",
                jargonTerms: ["Execution Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Run It and Check the History",
                instruction: "Start an execution, then step through the execution history to see exactly which state ran, and when.",
                jargonTerms: ["Execution History"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Execution History",
                xpValue: 20
            )
        ]
    )

    static let awsBackupPlanSetup = Workflow(
        title: "Automate Backups Across Everything",
        summary: "Set up one central plan that automatically backs up your databases, file systems, and volumes on a schedule, instead of babysitting backups one service at a time.",
        symbolName: "externaldrive.badge.checkmark",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create a Backup Vault",
                instruction: "Set up a backup vault to be the locked storage room where all your recovery points will live.",
                jargonTerms: ["Backup Vault"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Build the Backup Plan",
                instruction: "Create a backup plan and add a backup rule that sets the schedule and how long to keep each backup.",
                jargonTerms: ["Backup Plan", "Backup Rule"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Choose What to Protect",
                instruction: "Assign the databases, file systems, and volumes you want this plan to automatically back up.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Check a Recovery Point",
                instruction: "After the first scheduled run, open the vault and confirm a fresh recovery point actually showed up.",
                jargonTerms: ["Recovery Point"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Recovery Points"
            ),
            WorkflowStep(
                title: "Test a Restore",
                instruction: "Restore one recovery point to a throwaway location just to prove the whole plan actually works end to end.",
                jargonTerms: ["Recovery Point"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsConfigRuleSetup = Workflow(
        title: "Get Alerted When Something Drifts",
        summary: "Turn on a watchdog that continuously checks your AWS resources against the rules you set, and flags anything that falls out of line.",
        symbolName: "checklist",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Turn On the Configuration Recorder",
                instruction: "Enable the configuration recorder so AWS starts keeping a running history of how your resources change.",
                jargonTerms: ["Configuration Recorder"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Pick a Config Rule",
                instruction: "Turn on a config rule that describes what 'correctly set up' looks like for the resource you care about.",
                jargonTerms: ["Config Rule"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Review Your Resource Inventory",
                instruction: "Browse the resource inventory to see everything the recorder is currently keeping an eye on.",
                jargonTerms: ["Resource Inventory"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Resource Inventory"
            ),
            WorkflowStep(
                title: "Check the Compliance Status",
                instruction: "Open the rule's compliance status to see which resources pass and which ones need fixing.",
                jargonTerms: ["Compliance Status"],
                visual: .plain,
                xpValue: 15
            ),
            WorkflowStep(
                title: "Set Up Notifications",
                instruction: "Connect the rule to a notification so you hear about drift the moment it happens, not weeks later.",
                jargonTerms: [],
                visual: .plain
            )
        ]
    )

    static let awsKinesisStreamSetup = Workflow(
        title: "Capture Data as It Happens",
        summary: "Create a real-time pipeline that collects a constant flow of data — clicks, sensor readings, log lines — and holds onto it just long enough for other services to process it.",
        symbolName: "waveform.path",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create the Data Stream",
                instruction: "Set up a Kinesis data stream and give it a name that matches the kind of data it'll be collecting.",
                jargonTerms: ["Kinesis Data Stream"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Decide How Many Shards",
                instruction: "Choose how many shards to start with — more shards means more data can flow through at once.",
                jargonTerms: ["Shard"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Send In a Data Record",
                instruction: "Point a producer at the stream and send in a test data record to make sure it lands.",
                jargonTerms: ["Data Record", "Producer"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Hook Up a Consumer",
                instruction: "Connect a consumer that reads records off the stream as soon as they arrive.",
                jargonTerms: ["Consumer"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Watch It Flow",
                instruction: "Open the stream's monitoring tab and watch records move through in close to real time.",
                jargonTerms: ["Kinesis Data Stream"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsAmplifyHostingSetup = Workflow(
        title: "Deploy a Web App in Minutes",
        summary: "Connect your code repository to Amplify Hosting so every push automatically builds and publishes your site, with no manual uploading.",
        symbolName: "square.and.arrow.up.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Connect Your Repository",
                instruction: "Link the repository that holds your web app's code so Amplify can watch it for changes.",
                jargonTerms: ["Repository"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create the Amplify App",
                instruction: "Create the Amplify app and confirm which repository and folder it should build from.",
                jargonTerms: ["Amplify App"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Write the Build Spec",
                instruction: "Fill out the build spec with the commands that install dependencies and produce your finished site.",
                jargonTerms: ["Build Spec"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Pick a Branch to Deploy",
                instruction: "Choose which Amplify branch should go live, so pushes to that branch trigger a real deployment.",
                jargonTerms: ["Amplify Branch"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Preview Before It's Live",
                instruction: "Open the preview deployment for a pull request to see your changes before they reach real visitors.",
                jargonTerms: ["Preview Deployment"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Go Live",
                instruction: "Merge to your production branch and watch Amplify build and publish the update automatically.",
                jargonTerms: ["Amplify App"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsIdentityCenterSetup = Workflow(
        title: "One Login for Every AWS Account",
        summary: "Set up single sign-on so your team signs in once and gets handed off to whichever AWS account and role they're supposed to use — no separate passwords per account.",
        symbolName: "person.badge.key.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Enable Identity Center",
                instruction: "Turn on IAM Identity Center for your organization so it can start managing sign-in across accounts.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Connect an Identity Source",
                instruction: "Point Identity Center at your identity source — the place your team's usernames and passwords already live.",
                jargonTerms: ["Identity Source"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Permission Set",
                instruction: "Build a permission set that spells out exactly what someone can do once they land in an account.",
                jargonTerms: ["Permission Set"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Assign It to an Account",
                instruction: "Create an account assignment linking a person or group to that permission set in a specific account.",
                jargonTerms: ["Account Assignment"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Share the SSO Portal Link",
                instruction: "Send your team the SSO portal link so they have one bookmark for every account they can access.",
                jargonTerms: ["SSO Portal"],
                visual: .consoleOverlay,
                overlayTargetLabel: "SSO Portal"
            ),
            WorkflowStep(
                title: "Test the Sign-In",
                instruction: "Sign in through the portal yourself and confirm you land in the right account with the right access.",
                jargonTerms: ["Account Assignment"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsEFSSetup = Workflow(
        title: "Share One Drive Across Many Servers",
        summary: "Set up a shared file system that multiple servers can read and write to at the same time, like a network drive that grows automatically as you add files.",
        symbolName: "folder.badge.person.crop",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create the File System",
                instruction: "Set up an EFS file system that your servers will be able to mount and share.",
                jargonTerms: ["EFS File System"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Mount Targets",
                instruction: "Create a mount target in each subnet where a server will need to reach the file system.",
                jargonTerms: ["Mount Target"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Pick a Throughput Mode",
                instruction: "Choose a throughput mode that matches how heavily your servers will be reading and writing.",
                jargonTerms: ["Throughput Mode"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create an Access Point",
                instruction: "Set up an access point so each app only sees the specific folder it's supposed to work in.",
                jargonTerms: ["Access Point"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Mount It on Your Server",
                instruction: "Mount the file system on your server and confirm a file saved from one server shows up on another.",
                jargonTerms: ["EFS File System"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsSiteToSiteVPNSetup = Workflow(
        title: "Connect Your Office Network to AWS",
        summary: "Build an encrypted tunnel between your office router and your AWS network so both sides can talk to each other like they're on the same local network.",
        symbolName: "shield.lefthalf.filled",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Register Your Customer Gateway",
                instruction: "Register your office router as a customer gateway, giving AWS its public IP address.",
                jargonTerms: ["Customer Gateway"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Create a Virtual Private Gateway",
                instruction: "Attach a virtual private gateway to your VPC so it has an AWS-side endpoint to connect to.",
                jargonTerms: ["Virtual Private Gateway"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Establish the VPN Connection",
                instruction: "Create the VPN connection between the two gateways and download the configuration for your office router.",
                jargonTerms: ["VPN Tunnel"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Update Your Route Tables",
                instruction: "Add routes pointing traffic for your office network through the new gateway.",
                jargonTerms: ["Route Table"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm the Tunnel Is Up",
                instruction: "Check the tunnel status until both sides report as up, then ping across to prove it works.",
                jargonTerms: ["VPN Tunnel"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Tunnel Status",
                xpValue: 20
            )
        ]
    )

    static let awsQuickSightSetup = Workflow(
        title: "Turn Raw Data Into a Dashboard",
        summary: "Connect QuickSight to your data and build an interactive dashboard you can share with your team, without writing a single query by hand.",
        symbolName: "chart.bar.xaxis",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Connect a Dataset",
                instruction: "Point QuickSight at your data and create a dataset from it.",
                jargonTerms: ["Dataset"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Start an Analysis",
                instruction: "Open a new analysis based on your dataset — this is your working canvas before anything gets published.",
                jargonTerms: ["Analysis"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Add Your First Visual",
                instruction: "Drag fields onto the canvas to build your first visual, like a bar chart of sales by month.",
                jargonTerms: ["Visual"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Arrange the Dashboard",
                instruction: "Lay out your visuals on the dashboard canvas so the most important numbers sit right at the top.",
                jargonTerms: ["Visual"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Dashboard Canvas"
            ),
            WorkflowStep(
                title: "Share It With Your Team",
                instruction: "Publish the dashboard and share it with the teammates who need to see these numbers regularly.",
                jargonTerms: ["Analysis"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsRedshiftSetup = Workflow(
        title: "Stand Up a Data Warehouse",
        summary: "Launch a cluster built for crunching through massive amounts of data quickly, so your team can run heavy analytics queries without slowing down your regular database.",
        symbolName: "cylinder.split.1x2.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Pick a Node Type",
                instruction: "Choose a node type sized for how much data you'll be querying and how fast you need answers.",
                jargonTerms: ["Node Type"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Launch the Redshift Cluster",
                instruction: "Launch the Redshift cluster and set the number of nodes it should start with.",
                jargonTerms: ["Redshift Cluster"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Load In Your Data",
                instruction: "Copy your data into the cluster from storage so there's something to query.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Run a Query",
                instruction: "Open the query editor and run a query against your loaded tables to check everything landed correctly.",
                jargonTerms: ["Query Editor"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Query Editor"
            ),
            WorkflowStep(
                title: "Take a Cluster Snapshot",
                instruction: "Take a cluster snapshot so you always have a recent backup to restore from if something goes wrong.",
                jargonTerms: ["Cluster Snapshot"],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let awsSessionManagerSetup = Workflow(
        title: "Connect to a Server Without SSH Keys",
        summary: "Open a secure shell to your server straight from the browser or command line, without managing SSH keys, open ports, or a bastion host.",
        symbolName: "terminal.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Install the SSM Agent",
                instruction: "Make sure the SSM agent is installed and running on the instance you want to connect to.",
                jargonTerms: ["SSM Agent"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Give the Instance an Execution Role",
                instruction: "Attach an execution role to the instance so it's allowed to check in with Session Manager.",
                jargonTerms: ["Execution Role"],
                visual: .plain
            ),
            WorkflowStep(
                title: "Confirm It's a Managed Instance",
                instruction: "Check that your instance shows up as a managed instance, which means it's reachable without SSH.",
                jargonTerms: ["Managed Instance"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Managed Instances"
            ),
            WorkflowStep(
                title: "Start a Session",
                instruction: "Open Session Manager and start a session directly against the instance, right from your browser.",
                jargonTerms: ["Session Manager"],
                visual: .engineRoom,
                engineRoomKit: .aws,
                xpValue: 20
            ),
            WorkflowStep(
                title: "Close It Out",
                instruction: "End the session when you're done — there's no open port or leftover key lying around to clean up.",
                jargonTerms: ["Session Manager"],
                visual: .plain,
                xpValue: 15
            )
        ]
    )


    // MARK: Round 4 additions (top-up to 50/company + new Facebook category)

    // MARK: Universal — Round 4 additions

    static let stolenDeviceProtectionSetup = Workflow(
        title: "Add an Extra Lock for a Stolen Device",
        summary: "Make sure a thief who has your unlocked phone still can't change the settings that would lock you out for good.",
        symbolName: "lock.iphone",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Your Device's Extra Protection Setting",
                instruction: "Open your phone's security settings and look for an option that adds delays or extra checks on sensitive changes, like disabling Find My or changing your passcode, when you're away from familiar places.",
                jargonTerms: [],
                visual: .plain
            ),
            WorkflowStep(
                title: "Turn It On",
                instruction: "Switch it on so those sensitive changes require your face or fingerprint even if someone already knows your passcode — a thief who saw you type it in still can't get past this.",
                jargonTerms: ["Stolen Device Protection"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Security Settings"
            ),
            WorkflowStep(
                title: "Understand the Security Delay",
                instruction: "For the riskiest changes, like turning off the feature itself, your device adds a short waiting period even after the right biometric check — this gives a stolen-phone scenario time to be noticed and locked down remotely.",
                jargonTerms: [],
                visual: .plain,
                xpValue: 20
            )
        ]
    )

    static let dataBreachMonitoringSetup = Workflow(
        title: "See If Your Email Has Been Exposed in a Data Breach",
        summary: "Find out fast when one of your accounts turns up in a leaked database, before someone else uses it against you.",
        symbolName: "exclamationmark.shield",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Pick a Breach-Monitoring Service",
                instruction: "Sign up with a service that checks your email addresses against known lists of leaked data. Most have a free tier that's enough for personal use.",
                jargonTerms: ["Data Breach"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add Every Email Address You Use",
                instruction: "Register your personal inbox, your work address, and any old accounts you still use anywhere. Leaks don't discriminate by how often you check that inbox.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn On Ongoing Alerts",
                instruction: "Don't settle for a one-time scan. Switch on continuous monitoring so you're notified the moment a new leak includes one of your addresses.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Alert Preferences",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Know What To Do When an Alert Arrives",
                instruction: "Change the password for the exposed account right away, turn on two-factor protection if it isn't already on, and check whether you reused that password anywhere else.",
                jargonTerms: ["Two-Factor Authentication", "Password Manager"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let browserAutofillHardeningSetup = Workflow(
        title: "Lock Down What Your Browser Autofills",
        summary: "Stop your browser from handing out saved passwords and card numbers to the wrong website.",
        symbolName: "doc.text.magnifyingglass",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Open Your Browser's Saved Info",
                instruction: "Head into your browser's settings and pull up the list of saved passwords, addresses, and payment cards. Most people have never actually looked at this list.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Delete What You Don't Recognize",
                instruction: "Remove saved logins for accounts you closed, forgot about, or don't recognize at all. Fewer saved entries means less for a stranger to find.",
                jargonTerms: ["Dormant Account"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn Off Autofill for Payment Cards",
                instruction: "Switch off automatic card filling so a stolen or borrowed device can't be used to check out with your saved card in one tap.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Payment Methods",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Switch Saved Passwords to a Real Password Manager",
                instruction: "Move your logins out of the browser and into a dedicated password manager protected by one strong Master Password, then let the browser autofill from that instead.",
                jargonTerms: ["Password Manager", "Master Password"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let guestFileDropSetup = Workflow(
        title: "Set Up a Password-Protected Drop Box for Files",
        summary: "Let clients or contractors hand you files securely without emailing attachments back and forth.",
        symbolName: "tray.and.arrow.down",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Create a Shared Upload Folder",
                instruction: "Set up a folder in your cloud storage specifically for other people to drop files into, kept separate from your own working folders.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn On Upload-Only Permissions",
                instruction: "Configure the folder so visitors can add files but can't see, download, or delete what's already inside. They should only be able to drop things in.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Folder Permissions",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add a Password to the Sharing Link",
                instruction: "Require a password before anyone can use the link, so it's useless to whoever it gets forwarded to by accident.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set the Link to Expire Automatically",
                instruction: "Give the drop box a shelf life, like thirty days, so it quietly closes itself instead of staying open forever after the project ends.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let digitalLegacySetup = Workflow(
        title: "Decide Who Inherits Your Accounts",
        summary: "Make sure someone you trust can access or close your accounts if something happens to you.",
        symbolName: "heart.text.square",
        company: nil,
        steps: [
            WorkflowStep(
                title: "List Your Most Important Accounts",
                instruction: "Write down the accounts that actually matter if you were gone tomorrow: email, banking, photos, domains, and anything running your small business.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set a Legacy Contact Where You Can",
                instruction: "Many services let you name someone in advance who can step in later. Add a trusted person wherever that option exists.",
                jargonTerms: ["Legacy Contact"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Legacy Contact",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Store Your Master Password Somewhere Safe",
                instruction: "Leave instructions for how a trusted person could get into your password manager if needed, using a sealed note, a safe, or a legal document rather than a text message.",
                jargonTerms: ["Master Password", "Recovery Key"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Write Down Instructions, Not Just Passwords",
                instruction: "For each account, note what you'd actually want done with it: closed, memorialized, handed off, or left alone. Access without instructions just creates confusion.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let dnsCaaRecordSetup = Workflow(
        title: "Control Who's Allowed to Issue Certificates for Your Domain",
        summary: "Close a loophole that lets any certificate authority issue an SSL certificate for your site without your say-so.",
        symbolName: "checkmark.shield",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Out Who Already Issues Your Certificates",
                instruction: "Check which certificate authority currently issues the SSL Certificate for your site. This is usually handled automatically by your host or hosting platform.",
                jargonTerms: ["SSL Certificate", "Certificate Authority"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Open Your Domain's DNS Settings",
                instruction: "Head to wherever you manage DNS for your domain, the same place you'd go to change other records.",
                jargonTerms: ["DNS"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add a CAA Record Naming Your Approved Issuer",
                instruction: "Create a new record that names the one certificate authority allowed to issue certificates for your domain, and nothing else.",
                jargonTerms: ["CAA Record"],
                visual: .consoleOverlay,
                overlayTargetLabel: "DNS Records",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Give It Time to Take Effect",
                instruction: "Wait out the Propagation period before assuming it's live everywhere, and don't be surprised if the change doesn't show up instantly for every visitor.",
                jargonTerms: ["Propagation", "TTL"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let travelRouterVpnSetup = Workflow(
        title: "Protect Your Connection on Hotel Wi-Fi",
        summary: "Turn any shady hotel or airport network into one you can actually trust.",
        symbolName: "personalhotspot",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Set Up Your Own Personal Travel Router",
                instruction: "Bring along a small travel router that creates its own private network wherever you plug it in or connect it to public Wi-Fi.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Connect It to the Public Wi-Fi First",
                instruction: "Join the hotel or airport network's SSID on the travel router itself, not on your laptop or phone directly.",
                jargonTerms: ["SSID"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn On a VPN on the Router Itself",
                instruction: "Enable a VPN connection on the travel router so every device you connect to it is protected automatically, without installing anything on each one.",
                jargonTerms: ["VPN"],
                visual: .consoleOverlay,
                overlayTargetLabel: "VPN Settings",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Join Your Own Private Network Instead of the Public One",
                instruction: "Connect your laptop and phone to the travel router's own network rather than the hotel's, so nothing you own ever touches the public Wi-Fi directly.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let familyPasswordVaultSetup = Workflow(
        title: "Share Passwords Safely With Your Family",
        summary: "Give your household access to shared logins without texting passwords back and forth.",
        symbolName: "person.3.fill",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Create a Family Plan in Your Password Manager",
                instruction: "Upgrade your Password Manager account to a family or household plan that supports multiple people under one subscription.",
                jargonTerms: ["Password Manager"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Invite Each Family Member Separately",
                instruction: "Send each person their own invite so everyone gets their own login and their own private space, rather than sharing one account between all of you.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Put Shared Logins in a Shared Vault",
                instruction: "Move things like the streaming account, the Wi-Fi password, and the utility bill login into a shared space everyone in the family can see.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Shared Vault",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Keep Truly Private Logins Out of It",
                instruction: "Leave personal email, banking, and anything sensitive in each person's own private vault, protected end to end so not even the family plan can see inside.",
                jargonTerms: ["Zero-Knowledge Encryption"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let certExpiryMonitoringSetup = Workflow(
        title: "Get Warned Before Your Website's Certificate Expires",
        summary: "Avoid the scary browser warning that shows up the moment your site's security certificate lapses.",
        symbolName: "calendar.badge.clock",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Find Your Certificate's Expiration Date",
                instruction: "Look up when your site's SSL Certificate is due to expire. It's usually valid for anywhere from a few months to a year at a time.",
                jargonTerms: ["SSL Certificate"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Sign Up for an Expiry-Monitoring Service",
                instruction: "Use a free monitoring tool that regularly checks your site and keeps track of the expiration date for you, so you don't have to remember.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set Alerts for 30 and 7 Days Out",
                instruction: "Configure two separate warnings so you get an early heads-up plus a last-chance reminder before anything actually breaks.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Alert Schedule",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn On Auto-Renewal Wherever You Can",
                instruction: "Where your host supports it, switch on automatic renewal so the certificate replaces itself before the deadline and the alerts become a backup plan rather than a necessity.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let privacyAnalyticsSetup = Workflow(
        title: "Track Site Visitors Without Spying on Them",
        summary: "See how your website's doing without tracking individual visitors around the internet.",
        symbolName: "chart.xyaxis.line",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Pick a Privacy-Friendly Analytics Tool",
                instruction: "Choose an analytics service built around Cookieless Analytics instead of the tracking-heavy tools most sites default to.",
                jargonTerms: ["Cookieless Analytics"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add the Tracking Snippet to Your Site",
                instruction: "Paste the small piece of code the analytics tool gives you into your site's pages, the same way you would for any tracking script.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Skip the Cookie Consent Banner You'd Otherwise Need",
                instruction: "Because nothing personal is being stored on your visitors' devices, you can often turn off the Cookie Consent Banner your old analytics setup required.",
                jargonTerms: ["Cookie Consent Banner"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Analytics Settings",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Check Your First Real Numbers",
                instruction: "Give it a day or two, then look at your dashboard to see visits, top pages, and where people are coming from, all without a single visitor being individually tracked.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let maskedEmailSetup = Workflow(
        title: "Hide Your Real Email Behind a Masked Address",
        summary: "Sign up for anything online without ever handing out your real inbox.",
        symbolName: "envelope.badge.shield.half.filled",
        company: nil,
        steps: [
            WorkflowStep(
                title: "Turn On Email Masking in Your Browser or Password Manager",
                instruction: "Enable the built-in masking feature that many browsers and password managers now offer alongside their autofill and Password Manager tools.",
                jargonTerms: ["Masked Email", "Password Manager"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Generate a New Masked Address for Each Signup",
                instruction: "Whenever a site asks for your email, create a fresh masked address instead of typing in your real one. Each site gets its own unique stand-in.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set Where Masked Mail Actually Gets Delivered",
                instruction: "Confirm that all your masked addresses forward to the one real inbox you check, so nothing important gets lost behind the scenes.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Forwarding Address",
                xpValue: 10
            ),
            WorkflowStep(
                title: "Deactivate a Masked Address the Moment It's Spammed",
                instruction: "If a masked address starts receiving junk mail, switch it off. Since it was never shared anywhere else, you'll know exactly which company leaked or sold it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    // MARK: Google — Round 4 additions

    static let googleIamCustomRoleSetup = Workflow(
        title: "Create a Custom IAM Role",
        summary: "Give a teammate exactly the access they need to do their job, and nothing more.",
        symbolName: "person.badge.key",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open IAM & Admin",
                instruction: "In Cloud Console, head to IAM & Admin. This is the master list of who can touch what across your whole project.",
                jargonTerms: ["IAM Role"],
                visual: .consoleOverlay,
                overlayTargetLabel: "IAM & Admin"
            ),
            WorkflowStep(
                title: "Start a custom role",
                instruction: "Choose Roles, then Create Role. Instead of grabbing one of Google's premade bundles, you're about to build your own from scratch.",
                jargonTerms: ["Custom Role"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick only the permissions you need",
                instruction: "Search the permission list and check off just the actions this role should allow, like viewing logs or editing one specific service. Skip everything else.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Save and assign it",
                instruction: "Name the role something clear, save it, then attach it to the person or service account who needs it. They now have exactly that slice of access.",
                jargonTerms: ["Principal"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let cloudBuildPipelineSetup = Workflow(
        title: "Set Up a Cloud Build Pipeline",
        summary: "Have your code test and package itself automatically every time you push a change.",
        symbolName: "hammer.circle",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Enable Cloud Build",
                instruction: "Turn on the Cloud Build service for your project. Think of it as hiring a robot assembly worker who's always on shift.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Write your build recipe",
                instruction: "Add a small file to your repo that lists the steps to run, like install, test, then package. This is the recipe the robot follows every single time.",
                jargonTerms: ["Build Config File"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Connect your repository",
                instruction: "In the Cloud Build console, link the source repo where your code lives so Google can watch it for changes.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Cloud Build"
            ),
            WorkflowStep(
                title: "Create a build trigger",
                instruction: "Set a rule that says 'whenever someone pushes to this branch, run the recipe automatically.' No more remembering to build things by hand.",
                jargonTerms: ["Build Trigger"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Push a change and watch it run",
                instruction: "Commit something small and check the build history. You should see your pipeline kick off on its own within moments.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let artifactRegistrySetup = Workflow(
        title: "Store Your Container Images in Artifact Registry",
        summary: "Give your packaged app a proper warehouse to live in instead of scattering builds across laptops.",
        symbolName: "shippingbox",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Artifact Registry",
                instruction: "In Cloud Console, find Artifact Registry. This is where finished, packaged versions of your app get stored and organized.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Artifact Registry"
            ),
            WorkflowStep(
                title: "Create a repository",
                instruction: "Create a new repository and give it a name and region. This is the specific shelf where one project's images will be kept.",
                jargonTerms: ["Artifact Repository"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Authenticate your tools",
                instruction: "Run the short login command Google gives you so your computer is allowed to push and pull from that shelf.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Push your first image",
                instruction: "Tag your built container image with the repository's address and push it up. It now has a permanent, versioned home.",
                jargonTerms: ["Container Image"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let bigQueryDatasetSetup = Workflow(
        title: "Query Your Data with BigQuery",
        summary: "Ask big questions of huge piles of data and get an answer back in seconds.",
        symbolName: "tablecells",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open BigQuery",
                instruction: "Head into BigQuery from Cloud Console. It's a giant, fast filing system built specifically for asking questions of huge amounts of data.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "BigQuery"
            ),
            WorkflowStep(
                title: "Create a dataset",
                instruction: "Create a new dataset to hold your tables. It's the filing cabinet everything else in this project will live inside.",
                jargonTerms: ["BigQuery Dataset"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Load or connect a table",
                instruction: "Upload a file or connect an existing data source, then confirm the columns look right. This defines what each row of data means.",
                jargonTerms: ["Table Schema"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Run your first query",
                instruction: "Type a plain query asking for something specific, like totals by month, and run it. Watch results come back from millions of rows almost instantly.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let workspaceMfaEnforcementSetup = Workflow(
        title: "Require Two-Factor Login for Your Whole Team",
        summary: "Close the easiest door hackers use by making everyone confirm it's really them at login.",
        symbolName: "lock.shield",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open the Admin console",
                instruction: "Sign in to the Workspace Admin console. This is mission control for every account your organization owns.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Admin Console"
            ),
            WorkflowStep(
                title: "Find the security settings",
                instruction: "Go to Security, then 2-Step Verification. This is where you decide how strict login needs to be for your team.",
                jargonTerms: ["Multi-Factor Authentication"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Choose who it applies to",
                instruction: "Pick the group of accounts, like a specific department, this rule should cover instead of applying it company-wide right away.",
                jargonTerms: ["Organizational Unit"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Turn on enforcement and set a grace period",
                instruction: "Flip the setting to required and give everyone a short window to set it up before it's mandatory, so nobody gets locked out by surprise.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let playAppSigningSetup = Workflow(
        title: "Turn On Google Play App Signing",
        summary: "Let Google safely hold the master key that proves every update to your app is really from you.",
        symbolName: "key.viewfinder",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open App Integrity settings",
                instruction: "In Play Console, go to your app's setup section and find App Integrity. This is where your app's identity keys are managed.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Play Console"
            ),
            WorkflowStep(
                title: "Let Google generate your signing key",
                instruction: "Choose to have Google create and store your app's permanent signing key. Think of it as a wax seal that proves any update really came from you.",
                jargonTerms: ["App Signing Key"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Keep your own upload key safe",
                instruction: "You'll still sign each build with your own upload key before sending it in. Store it somewhere safe, since it's how you prove uploads are yours.",
                jargonTerms: ["Upload Key"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Publish your first signed release",
                instruction: "Upload a build and confirm Play Console re-signs it with the managed key before it goes out to users. Your app's identity is now protected even if your laptop isn't.",
                jargonTerms: ["App Bundle"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let firebaseCrashlyticsSetup = Workflow(
        title: "Catch Crashes with Firebase Crashlytics",
        summary: "Find out the moment your app crashes for a real user, and exactly what caused it.",
        symbolName: "exclamationmark.triangle",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Add Crashlytics to your project",
                instruction: "In the Firebase console, open Crashlytics and follow the prompt to add it to your app. It starts as a silent passenger, watching for trouble.",
                jargonTerms: ["Firebase Project"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Firebase Console"
            ),
            WorkflowStep(
                title: "Install the SDK",
                instruction: "Add the Crashlytics package to your app and initialize it on launch, so it's recording in the background from the first run.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Upload your debug symbols",
                instruction: "Make sure your build process uploads its debug symbols with every release. Without them, crash reports show gibberish instead of readable code locations.",
                jargonTerms: ["Debug Symbols"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Force a test crash",
                instruction: "Trigger a deliberate test crash and check that it shows up in the dashboard within a few minutes, with a full readable crash report waiting for you.",
                jargonTerms: ["Crash Report"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let firebaseAppCheckSetup = Workflow(
        title: "Block Fake Traffic with Firebase App Check",
        summary: "Make sure only your real app, not bots or copycats, can talk to your backend.",
        symbolName: "checkmark.shield",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open App Check",
                instruction: "In the Firebase console, open the App Check section. This is the bouncer standing at the door of your backend services.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Firebase Console"
            ),
            WorkflowStep(
                title: "Register your app with a provider",
                instruction: "Pick an attestation provider for your platform. It's the ID checker that verifies a request really came from your genuine, untampered app.",
                jargonTerms: ["Attestation Provider"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add a debug token for testing",
                instruction: "Generate a debug token for your development device so you're not locked out of your own app while it's still checking real attestation on real devices.",
                jargonTerms: ["Debug Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Turn on enforcement",
                instruction: "Once you see verified traffic flowing in, switch enforcement on for Firestore and any other services. Unverified requests now get turned away at the door.",
                jargonTerms: ["Firestore", "Security Rules"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let androidAppLinksSetup = Workflow(
        title: "Make Your Website Links Open Your App",
        summary: "Let a tap on your website's link jump straight into your app instead of a browser tab.",
        symbolName: "link.circle",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Decide which links should open the app",
                instruction: "Pick the web addresses on your domain, like a product or profile page, that should launch your app directly when tapped on a phone.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Publish your ownership certificate",
                instruction: "Upload a small file to your website that proves you own both the site and the app. It's the paperwork that lets Android trust the connection.",
                jargonTerms: ["Digital Asset Links File"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Point your app at those addresses",
                instruction: "In your app's project settings, declare the same web addresses so the app knows which links it's allowed to catch and open.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Verify in Play Console",
                instruction: "Check the App Links section of Play Console to confirm your site and app are verified as a matching pair.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Play Console"
            ),
            WorkflowStep(
                title: "Test a real link on a device",
                instruction: "Tap a matching link from a text message or email on a real phone. If it opens your app instead of a browser, you're done.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let cloudDnsManagedZoneSetup = Workflow(
        title: "Host Your Domain's DNS in the Cloud",
        summary: "Move your domain's address book into Google's fast, reliable DNS hosting.",
        symbolName: "network",
        company: .google,
        steps: [
            WorkflowStep(
                title: "Open Cloud DNS",
                instruction: "In Cloud Console, open Cloud DNS. This is where you'll keep the master map that tells the internet how to find your domain.",
                jargonTerms: ["DNS"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Cloud DNS"
            ),
            WorkflowStep(
                title: "Create a managed zone",
                instruction: "Create a new zone for your domain name. It's the dedicated folder that will hold every record for that one domain.",
                jargonTerms: ["Managed Zone"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add your records",
                instruction: "Recreate your existing address and mail records inside the new zone so nothing about how your domain works actually changes.",
                jargonTerms: ["A Record", "MX Record"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Point your domain at Google's nameservers",
                instruction: "Copy the nameserver addresses Google gives you and update them at your domain registrar. This is the step that actually hands over control.",
                jargonTerms: ["Nameserver", "Propagation"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    // MARK: Apple — Round 4 additions

    static let appleTestFlightPublicLinkSetup = Workflow(
        title: "Share Your App with Anyone Using a TestFlight Link",
        summary: "Let testers join your beta by tapping one link instead of collecting everyone's email address first.",
        symbolName: "link.circle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Open the Public Link Tab",
                instruction: "In App Store Connect, open your build's TestFlight tab and find the group meant for testers who found you outside your usual circle.",
                jargonTerms: ["TestFlight"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Turn the Link On",
                instruction: "Flip the public link switch so anyone with the URL can request a spot, no personal invite required.",
                jargonTerms: ["Public Link"],
                visual: .consoleOverlay,
                overlayTargetLabel: "TestFlight"
            ),
            WorkflowStep(
                title: "Cap How Many People Can Join",
                instruction: "Set a maximum tester count so your beta doesn't fill up past what you can actually support with feedback and fixes.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Post the Link Anywhere",
                instruction: "Drop the link in a newsletter, social post, or forum thread, and testers install straight from it, no waiting on you.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleTeamRolesSetup = Workflow(
        title: "Give Teammates Just the Access They Need",
        summary: "Hand out narrow, specific permissions so nobody can accidentally touch parts of your app they shouldn't.",
        symbolName: "person.badge.key.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Pick a Role Before You Invite",
                instruction: "Before adding someone to your team, decide what they actually need to do - answer support messages, edit pricing, or ship builds.",
                jargonTerms: ["Team"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Assign a Role",
                instruction: "Choose from the roles App Store Connect offers, each one unlocking a different slice of the dashboard and hiding the rest.",
                jargonTerms: ["App Store Connect Role"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Store Connect"
            ),
            WorkflowStep(
                title: "Scope Access to Specific Apps",
                instruction: "For teams juggling more than one app, limit a role so that person only sees the apps they're actually working on.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Review Who Can Do What",
                instruction: "Every so often, check the members list and pull access from anyone who no longer needs it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleStoreKit2VerificationSetup = Workflow(
        title: "Check Purchases Right Inside Your App",
        summary: "Confirm a purchase is legitimate on the spot, without standing up your own server first.",
        symbolName: "checkmark.seal.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Listen for Transaction Updates",
                instruction: "Set up a listener using Apple's modern purchase framework that watches for new purchases and restores the moment they happen.",
                jargonTerms: ["StoreKit 2"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Read the Verification Result",
                instruction: "Every transaction arrives wrapped in a signed proof, so check that signature before you trust anything it claims.",
                jargonTerms: ["JWS Signature"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Xcode"
            ),
            WorkflowStep(
                title: "Unlock Content Only After Verifying",
                instruction: "Only grant the purchased feature once verification passes cleanly, never before.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Finish the Transaction",
                instruction: "Mark the transaction as finished once you've delivered the content, so it stops showing up as pending on future launches.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleRejectionAppealSetup = Workflow(
        title: "Appeal an App Store Rejection",
        summary: "Push back on a review decision you think is wrong instead of just resubmitting and hoping for better luck.",
        symbolName: "arrow.uturn.left.circle.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Read the Rejection Reason Carefully",
                instruction: "Open the message thread and figure out exactly which guideline the reviewer cited and why.",
                jargonTerms: ["Resolution Center"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Decide: Fix It or Argue It",
                instruction: "If the reviewer misunderstood how your app works, an appeal makes sense; if they caught a real issue, fixing it is faster than arguing.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Reply With Evidence",
                instruction: "Write back with screenshots, a short video, or a plain explanation of how the feature actually behaves for users.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Resolution Center"
            ),
            WorkflowStep(
                title: "Request a Formal Board Review",
                instruction: "If the back-and-forth stalls, ask for your case to go in front of a separate panel for a fresh second opinion.",
                jargonTerms: ["App Review Board"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let appleXcodeCloudWorkflowsSetup = Workflow(
        title: "Automate Builds for Every Branch",
        summary: "Get Xcode Cloud to build, test, or ship automatically based on what you just pushed, without lifting a finger.",
        symbolName: "arrow.triangle.branch",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Start a New Workflow",
                instruction: "Beyond the default one Xcode Cloud creates for you, add a workflow dedicated to one specific job, like nightly testing.",
                jargonTerms: ["Xcode Cloud"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick a Start Condition",
                instruction: "Choose what kicks the workflow off - a push to a certain branch, a new tag, or a pull request being opened.",
                jargonTerms: ["Start Condition"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Xcode Cloud"
            ),
            WorkflowStep(
                title: "Chain Together Actions",
                instruction: "Line up the steps you want run in order, like build, then test, then archive, so each one only fires after the last succeeds.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Send Results Where People Will See Them",
                instruction: "Point the workflow's notifications at chat or email so the team hears about a broken build right away, not days later.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleNotarizationSetup = Workflow(
        title: "Get Your Mac App Past Gatekeeper",
        summary: "Let Apple scan your Mac app for malware so it opens smoothly instead of scaring people off with a warning.",
        symbolName: "checkmark.shield.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Archive Your Mac App",
                instruction: "Build a release version of your app the same careful way you would for the App Store, since Gatekeeper checks it either way.",
                jargonTerms: ["Gatekeeper"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Submit It for Notarization",
                instruction: "Send the archive off to Apple's automated scanner instead of a human reviewer, and it usually comes back within minutes.",
                jargonTerms: ["Notarization"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Xcode"
            ),
            WorkflowStep(
                title: "Wait for the Ticket",
                instruction: "Once the scan passes, Apple attaches proof to your app confirming it's already been checked out.",
                jargonTerms: ["Notarization Ticket"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Staple the Ticket and Ship It",
                instruction: "Attach that proof directly to your app bundle so it opens fine even without an internet connection, then hand it out however you like.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleAppSandboxSetup = Workflow(
        title: "Lock Down Your Mac App with a Sandbox",
        summary: "Limit what your Mac app can touch on someone's computer so it stays trustworthy even if something in it goes wrong.",
        symbolName: "shippingbox.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On App Sandbox",
                instruction: "In your target's signing settings, switch on the capability that walls your app off from the rest of the system.",
                jargonTerms: ["App Sandbox"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add Only the Entitlements You Need",
                instruction: "Request access to just the folders, network, or hardware your app genuinely uses, and nothing more.",
                jargonTerms: ["Entitlement"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Xcode"
            ),
            WorkflowStep(
                title: "Handle User-Selected Files Properly",
                instruction: "Ask permission each time your app needs to read or write a file living outside its own sandboxed folder.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Test With the Sandbox On",
                instruction: "Run your app fully sandboxed before submitting so you catch anything it can no longer reach ahead of time.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleKeyValueStoreSetup = Workflow(
        title: "Sync Small Settings Across a User's Devices",
        summary: "Keep a user's preferences the same on their iPhone, iPad, and Mac without building your own sync system.",
        symbolName: "icloud.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Turn On iCloud Key-Value Storage",
                instruction: "Add the capability that lets small pieces of data ride along with someone's iCloud account, following them from device to device.",
                jargonTerms: ["iCloud Key-Value Store", "iCloud Account"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Save Values Like You Would Normally",
                instruction: "Store simple things - a theme choice, a toggle, a last-viewed screen - using straightforward get and set calls.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Xcode"
            ),
            WorkflowStep(
                title: "Listen for Changes From Other Devices",
                instruction: "Watch for a notification that fires the moment a value changes elsewhere, so your interface can catch up right away.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Respect the Size Limit",
                instruction: "Keep well under the store's small storage cap - it's built for settings, not files or big collections of data.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleSchoolManagerSetup = Workflow(
        title: "Distribute Your App to Schools in Bulk",
        summary: "Get your app into a classroom's hands all at once instead of asking every student to buy it individually.",
        symbolName: "graduationcap.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Make Sure Your App Qualifies",
                instruction: "Check that your app is available in the countries and age groups a school program actually requires.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Get Discovered in Apple School Manager",
                instruction: "Once published, your app becomes something IT admins can find and assign inside the portal schools use to manage devices.",
                jargonTerms: ["Apple School Manager"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Apple School Manager"
            ),
            WorkflowStep(
                title: "Let Admins Assign It Through MDM",
                instruction: "The school's device management system pushes your app straight to student iPads automatically, no App Store visits needed.",
                jargonTerms: ["MDM"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Support Managed Apple ID Sign-In",
                instruction: "Make sure your login flow works smoothly for students signing in with the ID their school issued them.",
                jargonTerms: ["Managed Apple ID"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let appleEditorialPitchSetup = Workflow(
        title: "Pitch Your App for an App Store Feature",
        summary: "Ask Apple's editors directly to consider showcasing your app instead of just hoping they stumble on it.",
        symbolName: "star.bubble.fill",
        company: .apple,
        steps: [
            WorkflowStep(
                title: "Time It Around Something Real",
                instruction: "Editors respond best to a genuine hook - a big update, a seasonal tie-in, a fresh redesign, not just a routine bug-fix release.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open the Pitch Form",
                instruction: "Inside App Store Connect, find the section built specifically for telling Apple about an upcoming release worth spotlighting.",
                jargonTerms: ["Editorial Pitch"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Store Connect"
            ),
            WorkflowStep(
                title: "Explain What Makes It Feature-Worthy",
                instruction: "Describe in plain terms why your app deserves a spotlight - what's new, what's polished, what's genuinely different.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Submit Early, Not at the Last Minute",
                instruction: "Send your pitch several weeks before launch so editors actually have time to plan it into a placement.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    // MARK: Microsoft — Round 4 additions

    static let entraExternalIdentitiesSetup = Workflow(
        title: "Let Customers Sign In With Their Own Accounts",
        summary: "Give people outside your company a smooth way to sign into your app using accounts they already trust, without you ever storing their passwords.",
        symbolName: "person.crop.circle.badge.checkmark",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Spin Up a Separate Space for Customer Logins",
                instruction: "Before you invite outside users in, create a dedicated External Tenant that's walled off from your company's own staff directory. Think of it as a separate lobby for visitors instead of routing them through the employee entrance.",
                jargonTerms: ["External Tenant"],
                visual: .engineRoom,
                overlayTargetLabel: nil,
                engineRoomKit: .azure,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Design the Sign-In Journey",
                instruction: "Build a User Flow that decides exactly what a new customer sees: do they sign up with email, reset a forgotten password, or edit their profile? You're storyboarding the front-door experience before anyone actually walks through it.",
                jargonTerms: ["User Flow"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Let People Use Accounts They Already Have",
                instruction: "Connect an Identity Provider like a social or work account so customers can sign in with credentials they already use every day, instead of creating yet another password to forget.",
                jargonTerms: ["Identity Provider"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Connect Your App to the New Front Door",
                instruction: "Register your app against this external tenant the same way you would for internal sign-in, then point its Redirect URI back at your app so people land in the right place after signing in.",
                jargonTerms: ["App Registration", "Redirect URI"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Try the Sign-In Flow Yourself",
                instruction: "Run the flow directly from the portal to see exactly what a new customer would experience, catching awkward steps before real users ever do.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Run User Flow",
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let microsoftPurviewLabelSetup = Workflow(
        title: "Label Sensitive Documents with Microsoft Purview",
        summary: "Make sure confidential files carry their own protection wherever they travel, even after they leave your company's walls.",
        symbolName: "lock.doc",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Decide What Counts as Sensitive",
                instruction: "Start by sketching out the categories that matter to your organization, like 'Confidential' or 'Public', so everyone protects information the same way instead of guessing.",
                jargonTerms: ["Sensitivity Label"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set What Each Label Actually Does",
                instruction: "Attach real protections to each label, such as Encryption or a watermark, so tagging a document as Confidential does more than add a word to a menu.",
                jargonTerms: ["Encryption"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Publish the Labels to Your Team",
                instruction: "Roll the labels out through a Label Policy so they show up automatically in Word, Excel, and Outlook, ready for people to apply without hunting through settings.",
                jargonTerms: ["Label Policy"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Turn On Automatic Detection",
                instruction: "Set up rules that scan new documents for things like credit card numbers or ID numbers and apply the right label automatically, catching sensitive content even when someone forgets to tag it themselves.",
                jargonTerms: ["Sensitive Information Type"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Microsoft Purview",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Confirm Labels Are Sticking",
                instruction: "Open a few real documents and folders to check the label shows up and the protection actually applies, giving you confidence the whole chain works end to end.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let azurePolicySetup = Workflow(
        title: "Enforce Rules Automatically with Azure Policy",
        summary: "Stop configuration mistakes before they happen by having Azure automatically block or flag resources that break your rules.",
        symbolName: "checkmark.shield",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Pick a Rule to Enforce",
                instruction: "Start with something concrete, like requiring every resource to sit in an approved region, so you have a clear target instead of trying to govern everything at once.",
                jargonTerms: ["Policy Definition"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Bundle Related Rules Together",
                instruction: "Group several related rules into an Initiative so you can assign a whole set of standards, like a security baseline, in one move instead of one rule at a time.",
                jargonTerms: ["Initiative"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide Where the Rule Applies",
                instruction: "Assign the policy to a Subscription or Resource Group, the same way you'd decide which building a security guard is posted at rather than the whole city.",
                jargonTerms: ["Subscription", "Resource Group"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Choose What Happens When Someone Breaks the Rule",
                instruction: "Set the policy's Policy Effect to deny, audit, or automatically fix the problem, so you control whether it's a hard stop, a warning, or a silent correction.",
                jargonTerms: ["Policy Effect"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Azure Policy",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Check Who's Out of Line",
                instruction: "Review the compliance report to see which existing resources already break the rule, giving you a punch list to clean up instead of a surprise later.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let azureCostBudgetSetup = Workflow(
        title: "Set a Spending Budget with Azure Cost Management",
        summary: "Get warned before your cloud bill gets out of hand instead of finding out at the end of the month.",
        symbolName: "chart.line.uptrend.xyaxis.circle",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Look at Where Money Is Going",
                instruction: "Open the cost analysis view and look at spending by resource group or service, so you know which part of the bill is actually worth capping.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set a Spending Ceiling",
                instruction: "Create a Budget with a monthly dollar amount tied to a subscription or resource group, essentially drawing a line you don't want spending to cross.",
                jargonTerms: ["Budget"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Set Up Early Warnings",
                instruction: "Add a Cost Alert Threshold at, say, 80 percent of the budget so you get a heads-up while there's still time to react, not just a notice after you've already blown past it.",
                jargonTerms: ["Cost Alert Threshold"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Cost Management",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide Who Hears About It",
                instruction: "Point the alert at the right email addresses or an Action Group so the people who can actually do something about overspending are the ones who get notified.",
                jargonTerms: ["Action Group"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let microsoft365GroupSetup = Workflow(
        title: "Create a Microsoft 365 Group for Your Team",
        summary: "Give a team one shared identity that automatically comes with a mailbox, calendar, and files instead of setting each one up separately.",
        symbolName: "person.3",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Decide What the Group Is For",
                instruction: "Figure out whether you need a full collaborative space with shared files and a calendar, or just a simple email list known as a Distribution List, since that decision determines which type of group you create.",
                jargonTerms: ["Distribution List"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Create the Group",
                instruction: "Set up a Microsoft 365 Group with a name and a short description, which bundles a shared inbox, calendar, and file library under one roof automatically.",
                jargonTerms: ["Microsoft 365 Group"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add the Right People",
                instruction: "Add members and, if needed, extend Guest Access to people outside your company, so the group doesn't just sit there empty or unmanaged.",
                jargonTerms: ["Guest Access"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide Who Can Find and Join It",
                instruction: "Choose whether the group is public within your organization or private and invite-only, controlling whether people can stumble onto it or need an invitation.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Microsoft 365 Admin Center",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Check the Shared Spaces Came Along",
                instruction: "Open the group's mailbox, calendar, and file library to confirm everything was created together, so the team can start using it right away.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let outlookForwardingRuleSetup = Workflow(
        title: "Set Up Mail Forwarding in Outlook",
        summary: "Make sure important email reaches you or your team even when it lands in an inbox nobody's actively watching.",
        symbolName: "arrowshape.turn.up.right",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Decide What Should Get Forwarded",
                instruction: "Figure out whether you want to forward everything or just messages that match a pattern, like ones sent to a certain address or containing certain words.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Build the Forwarding Rule",
                instruction: "Create an Inbox Rule that watches incoming mail and automatically forwards matching messages to another address, so nothing sits unread in a mailbox nobody checks.",
                jargonTerms: ["Inbox Rule"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide Whether to Keep a Copy",
                instruction: "Choose whether forwarded mail also stays in the original inbox or gets moved out entirely, so you know exactly where messages will end up later.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Outlook Rules",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Send a Test Message",
                instruction: "Email the account from another address and confirm it shows up wherever you expected, catching typos in the forwarding address before real messages depend on it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let azureStaticWebAppSetup = Workflow(
        title: "Deploy a Static Website with Azure Static Web Apps",
        summary: "Get a fast, secure website live straight from your code repository without managing a server yourself.",
        symbolName: "globe",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Point Azure at Your Code",
                instruction: "Connect a Static Web App resource to the Repository holding your site's code, so Azure knows exactly where to pull your files from.",
                jargonTerms: ["Repository"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Tell It How to Build Your Site",
                instruction: "Set the Build Configuration so Azure knows which folder holds your finished files and which command turns your source code into a ready-to-serve site.",
                jargonTerms: ["Build Configuration"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Let Every Push Trigger a Deploy",
                instruction: "Once connected, every update to your chosen branch automatically rebuilds and republishes your site, so your live site always matches your latest approved code.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Azure Static Web Apps",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Add a Custom Web Address",
                instruction: "Point your own domain name at the site instead of leaving it on the default auto-generated address, by adding a TXT Record that proves you actually own the domain.",
                jargonTerms: ["TXT Record"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let azureServiceBusSetup = Workflow(
        title: "Send Messages Reliably with Azure Service Bus",
        summary: "Let different parts of your system hand off work to each other without losing anything, even if the receiving side is temporarily busy or offline.",
        symbolName: "tray.and.arrow.down",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Create a Place for Messages to Wait",
                instruction: "Set up a Service Bus Namespace, which acts like a dedicated post office for your application's messages, separate from anyone else's traffic.",
                jargonTerms: ["Service Bus Namespace"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Create the Queue Itself",
                instruction: "Add a Queue inside the namespace where one part of your system can drop off messages and another can pick them up whenever it's ready, instead of both needing to be online at the same moment.",
                jargonTerms: ["Queue"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Give Apps a Way to Connect",
                instruction: "Generate a connection string and store it as an Environment Variable so your sending and receiving apps can authenticate to the queue, the same way a mailroom key lets staff drop off and collect packages.",
                jargonTerms: ["Environment Variable"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Service Bus Explorer",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Send a Test Message Through",
                instruction: "Use the built-in explorer to send a test message and then receive it, confirming the whole handoff works before real traffic depends on it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let entraGraphPermissionSetup = Workflow(
        title: "Grant an App Access to Microsoft Graph",
        summary: "Let your app safely read or update things like calendars and mail on a user's behalf, without ever seeing their password.",
        symbolName: "point.3.connected.trianglepath.dotted",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Register the App",
                instruction: "Create an App Registration so Microsoft Graph has a record of your app and can issue it credentials, the same way a building issues a badge to a new employee.",
                jargonTerms: ["App Registration"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide What the App Is Allowed to Touch",
                instruction: "Add specific API Permissions, like reading a user's calendar or sending mail on their behalf, so the app can only do exactly what you've approved and nothing more.",
                jargonTerms: ["API Permission"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Get an Admin to Sign Off",
                instruction: "Have an administrator grant Admin Consent for the whole organization, so individual users aren't stuck approving prompts themselves before the app can work.",
                jargonTerms: ["Admin Consent"],
                visual: .consoleOverlay,
                overlayTargetLabel: "API Permissions",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Create a Way for the App to Prove Who It Is",
                instruction: "Generate a Client Secret the app uses to authenticate its requests, essentially a password only the app itself knows.",
                jargonTerms: ["Client Secret"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Make a Test Call",
                instruction: "Send a simple request to Microsoft Graph, like fetching a user's profile, to confirm the permissions and credentials actually work together end to end.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let azureManagedIdentitySetup = Workflow(
        title: "Let an App Authenticate Without Passwords",
        summary: "Give your app a secure identity Azure manages for you, so it can reach other Azure resources without a password or secret buried in your code.",
        symbolName: "person.badge.shield.checkmark",
        company: .microsoft,
        steps: [
            WorkflowStep(
                title: "Turn On a Built-In Identity",
                instruction: "Enable a Managed Identity on your app or virtual machine, which gives it its own identity inside Entra ID that Azure creates and rotates automatically, no secrets required.",
                jargonTerms: ["Managed Identity", "Entra ID"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Decide What It's Allowed to Access",
                instruction: "Assign the identity an IAM Role on the resource it needs to reach, like a storage account, so it can only touch what you've explicitly approved.",
                jargonTerms: ["IAM Role"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Update the App to Use It",
                instruction: "Change your app's code to request tokens through the managed identity instead of reading a stored Client Secret, removing one more password that could ever leak.",
                jargonTerms: ["Client Secret"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Identity Settings",
                engineRoomKit: nil,
                xpValue: 10
            ),
            WorkflowStep(
                title: "Confirm the Password Is Really Gone",
                instruction: "Search your app's configuration and code for any leftover connection strings or secrets tied to the old method, and remove them so there's no forgotten backdoor.",
                jargonTerms: ["Environment Variable"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

// MARK: Amazon — Round 4 additions

    static let awsGlueSetup = Workflow(
        title: "Turn Messy Files Into Clean Tables with Glue",
        summary: "Automatically discover and reshape raw files sitting in storage into clean, structured data you can query.",
        symbolName: "wand.and.stars",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Point Glue at Your Raw Files",
                instruction: "Tell Glue which bucket holds your raw CSVs or JSON logs, then send out a Glue Crawler to peek inside every file, figure out the column names and data types, and write down what it finds.",
                jargonTerms: ["Bucket", "Glue Crawler"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Let It Build a Catalog",
                instruction: "Once the crawler finishes, it registers everything it learned in a Data Catalog, basically a table of contents for your data that other AWS tools can read from without ever touching the original files.",
                jargonTerms: ["Data Catalog"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Write the Transform Job",
                instruction: "Create a job that describes how you want the data reshaped, dropping bad rows, renaming columns, converting formats, and Glue generates most of the code for you, running under an Execution Role that only has access to what it needs.",
                jargonTerms: ["Execution Role"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Run It and Watch It Work",
                instruction: "Kick off the job and Glue spins up temporary compute behind the scenes, chews through every file in parallel, and writes the cleaned-up result to a new location, then shuts itself down so you're not paying for idle servers.",
                jargonTerms: [],
                visual: .engineRoom,
                overlayTargetLabel: nil,
                engineRoomKit: .aws
            ),
            WorkflowStep(
                title: "Check the Console for the Green Checkmark",
                instruction: "Open the job run history to see how long each run took and how many rows went in and out, useful for confirming everything landed cleanly before anything downstream touches it.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Glue Job Runs",
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let awsAthenaSetup = Workflow(
        title: "Query Files in S3 Like a Database with Athena",
        summary: "Run plain SQL questions directly against files sitting in storage without loading them into a database first.",
        symbolName: "magnifyingglass",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Point Athena at Your Data",
                instruction: "Tell Athena which bucket holds your files, and if Glue already built a Data Catalog for them, Athena reuses that same table of contents instead of making you describe the columns yourself.",
                jargonTerms: ["Bucket", "Data Catalog"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Write a Query Like You Always Have",
                instruction: "Type an ordinary SELECT statement asking for the rows you care about, filter by date, sum a column, whatever, the same SQL you'd write against any regular database.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Choose Where Results Get Saved",
                instruction: "Open the Query Editor and set a results location, Athena writes every answer back out as a file there so you can reuse or share it later without re-running the query.",
                jargonTerms: ["Query Editor"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Query Editor",
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Run It and Get Charged Only for What You Scan",
                instruction: "Hit run and Athena scans just the files it needs, charging you per gigabyte read rather than for a server sitting around waiting, so a quick question stays cheap.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let awsAppRunnerSetup = Workflow(
        title: "Deploy a Web Service Straight from Your Code with App Runner",
        summary: "Point at a repo or container image and get a live, auto-scaling web service without picking server sizes or wiring up a load balancer yourself.",
        symbolName: "bolt.horizontal.circle",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Point App Runner at Your Source",
                instruction: "Connect a GitHub repo or hand it a container image, and App Runner reads it to figure out how to build and run your service without you writing deployment scripts from scratch.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Let It Pick the Muscle",
                instruction: "Choose how much CPU and memory the service gets; App Runner handles everything else, there's no server size to shop for and no cluster to babysit.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Turn On Auto Scaling",
                instruction: "Set a minimum and maximum number of copies to run, App Runner adds more when traffic spikes and scales back down to a small idle floor when it's quiet, saving you money the whole time.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Grab Your Live URL",
                instruction: "Once the build finishes, App Runner hands you a public HTTPS address that's already live, no separate load balancer or SSL certificate to configure yourself.",
                jargonTerms: ["Load Balancer", "SSL Certificate"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Runner Service",
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let awsMqSetup = Workflow(
        title: "Run a Traditional Message Broker with Amazon MQ",
        summary: "Let apps that already speak old-school messaging protocols talk to each other in the cloud without rewriting them.",
        symbolName: "arrow.left.arrow.right.circle",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Spin Up a Broker",
                instruction: "Launch a broker and pick the Broker Engine your apps already speak, ActiveMQ or RabbitMQ, so you don't have to rewrite them to use a newer AWS-only protocol.",
                jargonTerms: ["Broker Engine"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Drop It Inside Your Network",
                instruction: "Place the broker inside a VPC and Subnet so only apps already living in your private network can reach it, keeping it off the open internet.",
                jargonTerms: ["VPC", "Subnet"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Set Up a Queue or Topic the Old-Fashioned Way",
                instruction: "Connect using the same client libraries and protocols, like AMQP or MQTT, your apps have always used, create a queue or topic, and start sending messages exactly like before.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Check In on Broker Health",
                instruction: "Open the console to see how many messages are waiting, how many consumers are connected, and whether the broker needs more storage or memory.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Amazon MQ Console",
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let awsAuroraServerlessSetup = Workflow(
        title: "Let Your Database Scale Itself with Aurora Serverless",
        summary: "Stop guessing at database size, capacity stretches with traffic automatically and you pay only for what you actually use.",
        symbolName: "cylinder.split.1x2",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create a Database Without Picking a Size",
                instruction: "Start a new cluster and choose Aurora Serverless instead of a fixed instance size, so you're not stuck guessing how much horsepower you'll need on day one.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Set a Capacity Range",
                instruction: "Give it a minimum and maximum in Aurora Capacity Units, the database automatically stretches up when queries pile up and shrinks back down, even pausing completely, when nobody's asking it anything.",
                jargonTerms: ["Aurora Capacity Unit"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Point Your App at the Endpoint",
                instruction: "Grab the Database Endpoint and drop it into your app's connection settings, everything after that works like talking to any other database.",
                jargonTerms: ["Database Endpoint"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Watch It Pause and Resume",
                instruction: "Check the console after a quiet stretch and you'll see the database dip to zero capacity, then watch it wake back up the moment a new query arrives.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Aurora Cluster",
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let awsPatchManagerSetup = Workflow(
        title: "Keep Your Servers Patched Automatically with Patch Manager",
        summary: "Stop manually logging into every server to install security updates, and let a schedule do it for you.",
        symbolName: "bandage.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Confirm Your Servers Are Checked In",
                instruction: "Patch Manager only works on machines running the SSM Agent and already showing up as a Managed Instance, so start by confirming your fleet is checked in.",
                jargonTerms: ["SSM Agent", "Managed Instance"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Pick a Patch Baseline",
                instruction: "Choose which updates count as approved, security fixes only, or everything, and how many days to wait after release before installing them.",
                jargonTerms: ["Patch Baseline"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Group Your Servers",
                instruction: "Tag the machines you want patched together into one Patch Group, like all your web servers or all your databases, so you can schedule them independently.",
                jargonTerms: ["Patch Group"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Schedule the Maintenance Window",
                instruction: "Set a recurring time slot when patches are allowed to install, Patch Manager reports back afterward on which servers succeeded and which need attention.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Maintenance Window",
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let awsTransferFamilySetup = Workflow(
        title: "Offer Secure File Uploads with Transfer Family",
        summary: "Give partners a familiar SFTP address to drop files into, while the files actually land straight in your cloud storage.",
        symbolName: "tray.and.arrow.up.fill",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Create an SFTP Server",
                instruction: "Spin up a managed endpoint that speaks SFTP, FTPS, or FTP, so any partner with an old-school file transfer client can still send you files.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Point It at a Bucket",
                instruction: "Tell the server which bucket should receive uploaded files, everything a user drops in shows up there instantly, no separate file server to maintain.",
                jargonTerms: ["Bucket"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Set Up Users and Their Home Folders",
                instruction: "Create a login for each partner and give them an IAM Role that only lets them see their own folder, so nobody can browse anyone else's files.",
                jargonTerms: ["IAM Role"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Hand Out the Address",
                instruction: "Copy the server's endpoint address and share it with your partner, they connect with the same SFTP client they've always used, no new software required.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Transfer Family Server",
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let awsShieldSetup = Workflow(
        title: "Shrug Off Traffic Floods with Shield",
        summary: "Keep a flood of junk traffic from taking your app offline instead of scrambling to react once it's already down.",
        symbolName: "shield.lefthalf.filled",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Standard Protection Is Already On",
                instruction: "Every AWS account gets baseline Shield coverage for free, absorbing common floods aimed at things like your Load Balancer or CloudFront Distribution without you lifting a finger.",
                jargonTerms: ["Load Balancer", "CloudFront Distribution"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Decide If You Need the Upgrade",
                instruction: "If you're running something big enough to be a target, sign up for the advanced tier, which adds a response team you can call and covers the extra costs a traffic spike would otherwise rack up.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Add Protected Resources",
                instruction: "Pick which load balancer, CloudFront distribution, or Route 53 hosted zone you want covered, so the extra monitoring and cost protection applies exactly where it matters.",
                jargonTerms: ["Route 53"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Watch for Alerts",
                instruction: "Check the dashboard during a suspected attack to see real-time traffic graphs and confirm whether Shield is actively mitigating something on your behalf.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Shield Console",
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

    static let awsBatchSetup = Workflow(
        title: "Run Thousands of Background Jobs with AWS Batch",
        summary: "Crunch through a huge pile of computing work without manually managing a fleet of servers to run it on.",
        symbolName: "square.stack.3d.up",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Package Your Job as a Container",
                instruction: "Wrap the script or program you want to run, image resizing, data crunching, whatever, into a container image, the same one you'd use anywhere else.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Describe the Job",
                instruction: "Create a Job Definition that says which container to run, how much memory and CPU it needs, and what command to kick off.",
                jargonTerms: ["Job Definition"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Set Up a Compute Environment",
                instruction: "Tell Batch how much computing muscle it's allowed to use, and it automatically launches EC2 Instances when jobs are waiting and shuts them down the moment the queue empties.",
                jargonTerms: ["EC2 Instance"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Submit Jobs to the Queue",
                instruction: "Drop jobs into a Job Queue by the thousands if you need to, Batch works through them in priority order, retrying anything that fails on its own.",
                jargonTerms: ["Job Queue"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Batch Job Queue",
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Watch the Backlog Clear",
                instruction: "Check the queue's status to see jobs move from waiting to running to succeeded, and know that once it's empty, Batch has already spun the extra servers back down for you.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil,
                xpValue: 25
            )
        ]
    )

    static let awsNeptuneSetup = Workflow(
        title: "Map Relationships with a Graph Database on Neptune",
        summary: "Answer 'who's connected to whom' questions fast, the kind that make a regular table-based database choke.",
        symbolName: "network",
        company: .amazon,
        steps: [
            WorkflowStep(
                title: "Launch a Graph Database Cluster",
                instruction: "Create a Neptune cluster instead of a regular RDS Database when your data is really about connections, friends of friends, who bought what, which routes link two cities.",
                jargonTerms: ["RDS Database"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Drop It Inside a VPC",
                instruction: "Place the cluster inside a VPC and Subnet just like any other database, since Neptune isn't meant to be reachable from the open internet.",
                jargonTerms: ["VPC", "Subnet"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Load In Your Connections",
                instruction: "Import your data as nodes and the Graph Edges linking them, a node might be a person, an edge might be 'follows' or 'purchased', instead of ordinary rows and columns.",
                jargonTerms: ["Graph Edge"],
                visual: .plain,
                overlayTargetLabel: nil,
                engineRoomKit: nil
            ),
            WorkflowStep(
                title: "Ask Relationship Questions",
                instruction: "Use a graph query language to ask things like 'find everyone within three connections of this person,' queries that would take a pile of joins in a normal database, here they're fast and natural.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Neptune Query Console",
                engineRoomKit: nil,
                xpValue: 20
            )
        ]
    )

// MARK: Facebook — Round 4 (Developer Platform Core)

    static let facebookAppDashboardSetup = Workflow(
        title: "Set Up Your Facebook App Listing",
        summary: "Give your project an official identity on Meta's platform so it can start talking to Facebook's tools.",
        symbolName: "plus.app",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Start a New App",
                instruction: "Head to the Meta for Developers site and create a new app entry. You'll be asked to pick a use case that roughly matches what you're building — don't stress over getting it perfect, it just tunes which products get suggested to you later.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Give It a Name",
                instruction: "Choose a display name and link the app to your developer account. This is the name people will eventually see if your app ever asks them to log in with Facebook, so keep it recognizable.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Note Your App ID",
                instruction: "As soon as the app is created, Meta hands it a public identifying number. This is safe to put in client-side code and API calls — it's more of a storefront number than a secret.",
                jargonTerms: ["App ID"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Reveal Your App Secret",
                instruction: "In the app's Basic Settings, click Show next to the secret field. Unlike the App ID, this one stays on your server only — it's what proves requests are really coming from you.",
                jargonTerms: ["Facebook App Secret"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Dashboard – Basic Settings"
            ),
            WorkflowStep(
                title: "Store Both Credentials Safely",
                instruction: "Save the App ID and App Secret somewhere your build process can read them without hardcoding the secret into your app's binary. Every future API call and login flow will lean on this pair.",
                jargonTerms: ["Facebook App Secret", "App ID"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookGraphExplorerSetup = Workflow(
        title: "Poke Around With the Graph API Explorer",
        summary: "Try out real requests against Facebook's data before you commit any of it to code.",
        symbolName: "network",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Open the Explorer",
                instruction: "Find the Graph API Explorer tool in the developer console and select your app from the dropdown at the top. This tells the tool which app's credentials to borrow for your test requests.",
                jargonTerms: ["Graph API"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Attach a Token",
                instruction: "Grab a token from the dropdown so the Explorer has something to authenticate with — without one, most requests will just bounce back an error.",
                jargonTerms: ["User Access Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Send Your First Request",
                instruction: "Type a simple path like /me into the request bar and hit Submit. Watch the raw JSON come back on the right — that's exactly what your app will receive once you wire this up in code.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Watch the Response Panel",
                instruction: "Change the fields in your request and resend it. Notice how the response shape shifts to match exactly what you asked for — nothing more, nothing less.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Graph API Explorer"
            ),
            WorkflowStep(
                title: "Copy the Request Into Your Code",
                instruction: "Once a request returns what you need, copy the generated cURL or URL and translate it into your app's networking code. You've now tested it safely before it ever touches production.",
                jargonTerms: ["Graph API"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookUserAccessTokenSetup = Workflow(
        title: "Generate a User Access Token",
        summary: "Get a temporary pass that lets your app act on someone's behalf for just that session.",
        symbolName: "person.badge.key",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand What You're Requesting",
                instruction: "A token isn't a password — it's a stand-in that a person grants your app after they log in and approve specific permissions, without ever handing over their actual credentials.",
                jargonTerms: ["User Access Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Generate One From the Explorer",
                instruction: "In the Graph API Explorer, click Generate Access Token and approve the permission prompt that appears. You'll get back a long string tied to your app, your identity, and an expiration time.",
                jargonTerms: ["User Access Token", "App ID"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check What's Inside",
                instruction: "Paste the token into the Access Token Debugger to see exactly which permissions it carries and when it expires. Treat this like reading the fine print before you rely on it.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Read the Debugger Output",
                instruction: "Confirm the app ID, user, scopes, and expiration all match what you expect. If anything looks off, regenerate the token rather than guessing.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Access Token Debugger"
            ),
            WorkflowStep(
                title: "Handle It Like a Temporary Password",
                instruction: "Never log tokens, never ship them in client-side bundles, and never share them outside your own server. Anyone holding one can act as that user until it expires.",
                jargonTerms: ["User Access Token"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookLongLivedTokenSetup = Workflow(
        title: "Trade Up for a Long-Lived Token",
        summary: "Swap a token that dies in an hour for one that keeps working for roughly two months.",
        symbolName: "arrow.triangle.2.circlepath",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Notice the Short Lifespan",
                instruction: "Tokens straight out of a login flow or the Explorer usually expire in an hour or two — perfectly fine for a quick test, but useless for anything that needs to run unattended.",
                jargonTerms: ["User Access Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Make the Exchange Call",
                instruction: "Send a request to the token exchange endpoint with your App ID, App Secret, and the short-lived token. Facebook hands back a new token in return, no fresh login required.",
                jargonTerms: ["App ID", "Facebook App Secret", "User Access Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Note the New Expiration",
                instruction: "The token you get back is good for roughly 60 days instead of 60 minutes. There's no separate refresh token here — when it's close to expiring, you simply repeat this exchange or have the user log in again.",
                jargonTerms: ["Long-Lived Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check the expires_in Field",
                instruction: "Look at the exchange response and confirm the expires_in value reflects the longer window. That number is your countdown for when to renew.",
                jargonTerms: ["Long-Lived Token"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Token Exchange Response"
            ),
            WorkflowStep(
                title: "Plan Your Renewal",
                instruction: "Store the expiration date alongside the token and set a reminder — or better, an automated check — well before it lapses, so your app never gets caught with a dead token mid-use.",
                jargonTerms: ["Long-Lived Token"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookAppDomainSetup = Workflow(
        title: "Claim Your App's Home Domain",
        summary: "Tell Facebook exactly which website your app belongs to so it can trust traffic coming from it.",
        symbolName: "globe",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Find the App Domains Field",
                instruction: "In your app's Basic Settings, locate the field for listing the domains your app is allowed to operate from. Right now it's empty, which means nothing is trusted yet.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add Your Domain",
                instruction: "Type in the bare domain your app lives on, without http or a trailing slash, and save. This doesn't unlock trust by itself — it's just the first half of the claim.",
                jargonTerms: ["Facebook App Domain"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Prove You Own It",
                instruction: "Follow the confirmation step Meta offers, whether that's dropping a small file on your server or adding a meta tag to your homepage. This is what turns a claimed domain into a verified one.",
                jargonTerms: ["Facebook App Domain"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check the App Domains Field",
                instruction: "Return to Basic Settings and confirm your domain is listed and shows as verified rather than pending.",
                jargonTerms: ["Facebook App Domain"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Domains Field"
            ),
            WorkflowStep(
                title: "Unlock Domain-Gated Features",
                instruction: "With a verified domain in place, features that require a trusted origin — like certain login and sharing behaviors — stop blocking you.",
                jargonTerms: ["Facebook App Domain"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookAppReviewSetup = Workflow(
        title: "Submit a Feature for App Review",
        summary: "Ask Meta's reviewers to unlock the permissions your app needs beyond what your own test accounts can show.",
        symbolName: "checkmark.seal",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand Why Review Exists",
                instruction: "Most meaningful permissions stay locked for everyday users until Meta confirms your app actually needs them and uses them the way you claim. This keeps people's data from being requested carelessly.",
                jargonTerms: ["App Review"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick the Permission You Need",
                instruction: "Open the Permissions and Features section of App Review and find the specific scope your feature depends on — request only what that one feature genuinely uses.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Show Your Work",
                instruction: "Fill out the request form with a short screen recording and clear steps showing a reviewer exactly how to reach the feature and see the permission in action. Vague explanations are the number one reason requests bounce back.",
                jargonTerms: ["App Review"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Double-Check the Submission Form",
                instruction: "Review every field — platform, use case description, and attached recording — before sending. Reviewers can't ask clarifying questions mid-review, so completeness matters more than speed here.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Review – Request Permission"
            ),
            WorkflowStep(
                title: "Submit and Respond to Feedback",
                instruction: "Send the request and keep an eye on your notifications. If it's rejected, read the reviewer's notes carefully, fix the actual gap they pointed out, and resubmit rather than sending the same thing twice.",
                jargonTerms: ["App Review"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookTestUsersSetup = Workflow(
        title: "Spin Up Test Users for Safe Testing",
        summary: "Try out login flows and permissions without risking your own or anyone else's real Facebook account.",
        symbolName: "person.crop.circle.badge.plus",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Open the Test Users Panel",
                instruction: "In your app's Roles section, find the area for creating test accounts. These exist purely inside your app's sandbox and never touch the real Facebook social graph.",
                jargonTerms: ["Test User"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Create One",
                instruction: "Click to generate a new test user and give it a friendly name so you can tell it apart from others later. Meta creates the account instantly, no email or phone number needed.",
                jargonTerms: ["Test User"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Log In as the Test User",
                instruction: "Use the provided login link or token to act as that account inside your app. Permissions get granted automatically here — no waiting on App Review just to click through your own flow.",
                jargonTerms: ["Test User", "App Review"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Browse Your Test Roster",
                instruction: "Scan the list of test users you've created so far and confirm each one is scoped only to this app.",
                jargonTerms: ["Test User"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Test Users Panel"
            ),
            WorkflowStep(
                title: "Cover More Ground With Multiple Test Users",
                instruction: "Create a few test users with different friend connections and permission grants so you can exercise edge cases — like a user who denies a permission — before anything reaches real people.",
                jargonTerms: ["Test User"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookWebhookSubscriptionSetup = Workflow(
        title: "Wire Up a Webhook Subscription",
        summary: "Get Facebook to ping your server the instant something changes, instead of you constantly checking for updates.",
        symbolName: "bolt.horizontal.circle",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand the Push Model",
                instruction: "Rather than your server repeatedly asking 'anything new?', a webhook flips the arrangement — Facebook sends a message to your server the moment something relevant happens.",
                jargonTerms: ["Webhook Endpoint"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add the Webhooks Product",
                instruction: "In your app's dashboard, add the Webhooks product and enter the callback URL where your server will receive incoming notifications, along with a verify token you make up yourself.",
                jargonTerms: ["Webhook Endpoint", "Verify Token"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pass the Verification Handshake",
                instruction: "When you save the subscription, Facebook sends a one-time challenge to your callback URL along with your verify token. Your server needs to echo the challenge straight back to prove it's really yours.",
                jargonTerms: ["Verify Token", "Webhook Endpoint"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm the Subscription Fields",
                instruction: "Check that your callback URL, verify token, and selected fields are all saved and showing a green, verified status.",
                jargonTerms: ["Webhook Endpoint", "Verify Token"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Webhooks Subscription Setup"
            ),
            WorkflowStep(
                title: "Subscribe to Just What You Need",
                instruction: "Pick only the specific fields your app actually cares about rather than subscribing to everything — it keeps your server's inbox focused and your processing logic simpler.",
                jargonTerms: ["Webhook Endpoint"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookPermissionsScopesSetup = Workflow(
        title: "Decode Permissions and Scopes",
        summary: "Understand exactly what access you're asking for before you ever put it in front of a real user.",
        symbolName: "key.horizontal",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "See Access as a Set of Slices",
                instruction: "Facebook doesn't hand your app all-or-nothing access — each permission unlocks one narrow slice, like reading someone's email or managing a single Page, and nothing beyond that.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Browse the Full List",
                instruction: "Look through the Permissions and Features reference in your app dashboard to see what each scope actually grants before you decide you need it.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Match Access Levels to Your Stage",
                instruction: "Notice that some scopes are available immediately for testing while others only work at full strength once your app has been reviewed and approved for them.",
                jargonTerms: ["Facebook Permission Scope", "App Review"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Scan the Permissions List",
                instruction: "Walk through each entry and note what it unlocks, so you're picking scopes deliberately rather than copying a list from somewhere else.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Permissions and Features"
            ),
            WorkflowStep(
                title: "Request Only What Each Feature Needs",
                instruction: "Map every scope you plan to request back to one specific, explainable feature in your app. This habit alone makes App Review far smoother later.",
                jargonTerms: ["Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookLiveModeSetup = Workflow(
        title: "Flip Your App Into Live Mode",
        summary: "Open your app up to everyday Facebook users instead of just your own development team.",
        symbolName: "antenna.radiowaves.left.and.right",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Know What Development Mode Limits",
                instruction: "While your app is still in development, only people with a role on it — admins, developers, and testers — can actually use it. Everyone else gets turned away at the door.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Run Through the Pre-Flight Checklist",
                instruction: "Before switching over, make sure your privacy policy link, app icon, category, and any permissions your live features depend on have already cleared App Review.",
                jargonTerms: ["App Review", "Facebook Permission Scope"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Flip the Switch",
                instruction: "At the top of your app dashboard, toggle the mode from Development to Live and confirm. The change takes effect right away for everyone, not just new visitors.",
                jargonTerms: ["Live Mode"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm the Toggle Switched Over",
                instruction: "Check that the dashboard now reads Live rather than In Development before you tell anyone your app is ready.",
                jargonTerms: ["Live Mode"],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Mode Toggle"
            ),
            WorkflowStep(
                title: "Watch It Closely at First",
                instruction: "Keep an eye on real traffic and error rates for the first stretch after going live — once real users are in, you can't quietly flip back without locking them out again.",
                jargonTerms: ["Live Mode"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    // MARK: Facebook — Round 4 (Business Manager & Assets)

    static let facebookBusinessManagerSetup = Workflow(
        title: "Set Up Meta Business Manager for Your Company",
        summary: "Give your company one official home base on Meta instead of running everything through someone's personal profile.",
        symbolName: "building.2.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Start Your Business Account",
                instruction: "Head to business.facebook.com and choose Create Account, then type in your company's real name exactly as customers know it — this becomes the label on everything you build here.",
                jargonTerms: ["Meta Business Manager"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add Your Own Details",
                instruction: "Enter your name and a work email address you actually check, since this becomes the account that controls who else gets let in later.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Fill In Company Info",
                instruction: "Add your legal business name, street address, and phone number in Business Settings — these details matter later when Meta needs to confirm you're a real company.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Business Settings"
            ),
            WorkflowStep(
                title: "Confirm Your Email And Move In",
                instruction: "Click the confirmation link waiting in your inbox — until you do, some features stay locked even though the account technically exists. Once confirmed, you're ready to start adding teammates and connecting Pages or ad accounts.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookSystemUserSetup = Workflow(
        title: "Add a System User for Server-to-Server Access",
        summary: "Let your website or software talk to Meta's tools directly without borrowing a real teammate's login.",
        symbolName: "desktopcomputer",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand What You're Creating",
                instruction: "A regular teammate logs in with a face and a password. Sometimes you just need code on a server to fetch data or post updates automatically, and that's a different kind of account entirely.",
                jargonTerms: ["System User"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open the System Users Panel",
                instruction: "In Business Settings, go to Users, then System Users, then click Add — this is a separate list from your regular human teammates.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Name It And Set Its Rank",
                instruction: "Give the system user a name that describes what it does, like 'Order Sync Bot,' and choose whether it needs Admin-level power or just Employee-level.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Add System User"
            ),
            WorkflowStep(
                title: "Hand It the Assets It Needs",
                instruction: "Assign only the specific Pages, ad accounts, or catalogs this system user actually needs to touch — resist the urge to give it access to everything just in case.",
                jargonTerms: ["Asset Assignment"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Generate Its Credential",
                instruction: "Click Generate New Token to create the credential your code will use to authenticate, then store it somewhere safe like a secrets manager — anyone who has it can act as this system user.",
                jargonTerms: ["Access Key"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookAssetAssignmentSetup = Workflow(
        title: "Loop In a Partner Business on One Asset",
        summary: "Give another company access to a single Page or ad account without handing over the keys to everything else you own.",
        symbolName: "key.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Know When You'd Do This",
                instruction: "If an agency, freelancer, or partner company needs to work inside one of your assets but shouldn't join your team directly, you loop them in at the business level instead.",
                jargonTerms: ["Partner Business"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Find the Asset to Share",
                instruction: "In Business Settings, open Accounts and pick the specific Page or ad account you want to share — not your whole business, just that one item.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Assign It By Business ID",
                instruction: "Click Add Partner and paste in the other company's Business ID, which they can find and send you from their own Business Settings.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Assign Partner"
            ),
            WorkflowStep(
                title: "Pick Their Permission Level",
                instruction: "Choose what the partner business is allowed to do with the asset, from full management down to view-only reporting access.",
                jargonTerms: ["Permission Level"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Wait for Them to Confirm",
                instruction: "The partner has to accept the assignment on their end before it's active, and you can revoke it at any time from the same screen — nothing about this arrangement is permanent.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookBusinessVerificationSetup = Workflow(
        title: "Get Your Business Verified",
        summary: "Prove your company is legitimate so Meta unlocks higher-trust features like larger ad spend and stronger Page protections.",
        symbolName: "checkmark.seal.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "See Why It's Worth Doing",
                instruction: "An unverified business is treated with more suspicion — lower ad spending limits, fewer domains you can claim, and less trust when disputes come up. Verification removes those ceilings.",
                jargonTerms: ["Business Verification"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Gather Your Paperwork",
                instruction: "Have your official business registration document, tax ID number, and a recent utility bill or bank statement ready — Meta wants documents that match the details you entered earlier.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Start the Verification",
                instruction: "In Business Settings, open the Security Center and click Start Verification, then upload your documents and fill in any fields that don't already match your records.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Start Verification"
            ),
            WorkflowStep(
                title: "Confirm However They Ask",
                instruction: "Depending on your business type, Meta may call your listed phone number or email you a one-time verification code to prove you're reachable at the details you provided.",
                jargonTerms: ["Verification Code"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Wait for the Green Check",
                instruction: "Review can take anywhere from a day to a couple weeks. Once approved, your business carries a verified badge that raises trust and limits across every tool connected to it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookPageRolesSetup = Workflow(
        title: "Assign Roles on Your Facebook Page",
        summary: "Let teammates help run your Page without giving everyone the same keys to change everything on it.",
        symbolName: "person.3.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Think Before You Add Everyone as Admin",
                instruction: "Not every teammate needs the power to delete the Page or manage its billing — most people just need to post, reply to messages, or check the numbers.",
                jargonTerms: ["Permission Level"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open the Page's People List",
                instruction: "In Business Settings, go to Accounts, then Pages, select the Page in question, and click Add People.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick the Person And Their Role",
                instruction: "Choose the teammate from your business's user list, then pick the role that fits what they actually need to do, whether that's full control, content only, or messaging only.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Assign Page Role"
            ),
            WorkflowStep(
                title: "Review Access Every So Often",
                instruction: "Set a reminder to glance back through this list every few months and remove anyone who's changed roles or left the company — stale access is how old employees end up still able to post.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookAdAccountRolesSetup = Workflow(
        title: "Set Access Levels on an Ad Account",
        summary: "Control exactly who can spend your money and who can only look at how it's performing.",
        symbolName: "person.badge.key.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Separate Spending From Watching",
                instruction: "An ad account holds a payment method attached to real money, so it deserves tighter control than most of your other tools — think carefully about who really needs to launch or edit campaigns.",
                jargonTerms: ["Custom Permission Level"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open the Ad Account's People List",
                instruction: "In Business Settings, go to Accounts, then Ad Accounts, select the account, and click Add People.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Toggle Exactly What They Can Touch",
                instruction: "Pick the teammate, then flip on only the specific permissions they need — managing campaigns, viewing performance, or handling billing — instead of granting blanket control.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Ad Account Access"
            ),
            WorkflowStep(
                title: "Cut Access the Day Someone Leaves",
                instruction: "The moment a contractor's project ends or an employee moves teams, come back here and remove them — leftover access to an ad account is one of the easiest ways for spend to go sideways unnoticed.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookBusinessManager2FASetup = Workflow(
        title: "Require Two-Factor Authentication for Your Whole Team",
        summary: "Close the easiest door hackers use — a stolen password — for every single person who touches your Business Manager.",
        symbolName: "lock.shield.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand the Blast Radius",
                instruction: "One teammate with a weak, reused password is enough to let someone into your Pages, ad accounts, and payment details — requiring it for everyone closes that gap company-wide instead of person by person.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open the Security Center",
                instruction: "In Business Settings, find the Security Center, which is where business-wide safety rules live, separate from any single person's account settings.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Flip on the Requirement",
                instruction: "Turn on the setting that requires two-factor authentication for everyone with access to your business — not just an option people can enable themselves.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Require Two-Factor Authentication"
            ),
            WorkflowStep(
                title: "Give Your Team a Heads Up",
                instruction: "Anyone who hasn't set up two-factor authentication will get temporarily locked out until they add an authenticator app or phone number and enter a verification code, so warn people before you flip the switch.",
                jargonTerms: ["Verification Code"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookDomainClaimSetup = Workflow(
        title: "Claim and Verify Your Website Domain",
        summary: "Prove you own your website so Meta trusts links and data coming from it instead of anyone who copies your domain.",
        symbolName: "globe",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "See Why Ownership Matters",
                instruction: "Without proof of ownership, someone else could technically claim control over how your links behave on Meta's platforms — claiming your domain settles that once and for all.",
                jargonTerms: ["Domain Verification"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add the Domain",
                instruction: "In Business Settings, open Brand Safety, then Domains, and type in your website's domain exactly as it appears in a browser bar, without 'https://' or a trailing slash.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Choose How You'll Prove It",
                instruction: "Pick a verification method — adding a DNS TXT record with your domain host, uploading a small HTML file to your site, or pasting a meta tag into your homepage's code.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Verify Domain"
            ),
            WorkflowStep(
                title: "Complete the Method You Picked",
                instruction: "Follow through with whichever option you chose, whether that means logging into your domain registrar or sending the file to whoever manages your website's code.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm Verification Succeeded",
                instruction: "Click Verify once you've made the change — it can take a few minutes for DNS changes to be visible, so don't panic if it doesn't succeed on the very first try.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookCatalogOwningBusinessSetup = Workflow(
        title: "Set Which Business Owns Your Product Catalog",
        summary: "Make sure the right company account is truly in control of your product catalog, especially when an agency or partner set it up on your behalf.",
        symbolName: "shippingbox.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Know Who's Actually in Charge",
                instruction: "A catalog can be built inside one business account but you want lasting control to sit with your own company — otherwise you're depending on someone else's account staying active and cooperative forever.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Open Commerce Manager",
                instruction: "Go into Commerce Manager, select the catalog in question, and open its Catalog Settings from the menu on the left.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Find the Ownership Section",
                instruction: "Scroll to the section that shows which business currently owns the catalog and which businesses simply have access to use it — ownership and access are two different things.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Catalog Ownership"
            ),
            WorkflowStep(
                title: "Transfer Ownership if Needed",
                instruction: "If an agency or partner currently owns the catalog, request a transfer to your own business — they'll need to approve it from their side before it moves over.",
                jargonTerms: ["Asset Assignment"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm the Move Went Through",
                instruction: "Once accepted, your business shows as the owner, meaning your catalog's future doesn't depend on someone else's account staying open, paid for, or cooperative.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookAdvancedAccessSetup = Workflow(
        title: "Request Advanced Access for a Business Feature",
        summary: "Unlock a feature for all of your app's real customers instead of just the handful of people on your own team.",
        symbolName: "star.circle.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand the Two Tiers",
                instruction: "Every feature starts out working only for people directly on your team's account. To open it up to your actual customers, you have to ask Meta to widen the door.",
                jargonTerms: ["Standard Access", "Advanced Access"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Make Sure Your Business Qualifies",
                instruction: "Most Advanced Access requests require your business to already be verified — if you haven't finished that step yet, do it first, since an unverified business gets requests rejected on sight.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick the Feature And Use Case",
                instruction: "Select which permission or feature you're requesting broader access for, then choose the business use case connected to your verified business rather than a personal one.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Request Advanced Access"
            ),
            WorkflowStep(
                title: "Submit and Wait It Out",
                instruction: "Meta reviews these requests against your business's history and details, which is why keeping your business information accurate and up to date genuinely speeds things along.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Watch It Go Live for Everyone",
                instruction: "Once approved, the feature stops being limited to your internal team and starts working for every real customer who uses your product — no more asking people to be added as testers.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

// MARK: Facebook — Round 4 (Login & Site Integration)

    static let facebookLoginSetup = Workflow(
        title: "Let People Sign In With Facebook",
        summary: "Give visitors a one-tap way to create an account and log in using the Facebook profile they already have.",
        symbolName: "person.badge.key.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Get Your App's ID and Secret",
                instruction: "Every app that wants to offer Facebook Login needs its own pair of credentials: a public ID and a private secret. Think of the ID as your storefront's address and the secret as the key that only you should hold onto.",
                jargonTerms: ["API Key", "Client Secret"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Tell Facebook Where to Send People Back",
                instruction: "After someone approves the login, Facebook needs to know exactly which page on your site to return them to. List that page's web address so Facebook doesn't hand your visitor's login off to the wrong place.",
                jargonTerms: ["Redirect URI"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Show the Screen People Already Trust",
                instruction: "When someone taps \"Log in with Facebook,\" they're shown a familiar Facebook-branded screen asking them to confirm it's really them and approve sharing their basic info with you. You don't design this screen — Facebook handles it.",
                jargonTerms: ["OAuth Consent Screen"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add the Login Button to Your App",
                instruction: "Drop the official Facebook Login button into your sign-in screen using the provided SDK. It's ready-made, so people instantly recognize it instead of wondering what a mystery button does.",
                jargonTerms: ["Sign-In Provider"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Facebook Login Button"
            ),
            WorkflowStep(
                title: "Read the Signed-In Person's Info",
                instruction: "Once someone approves the login, Facebook hands your app a small signed packet confirming who they are. Your app reads that packet to create their account or log them straight in — no password required.",
                jargonTerms: ["ID Token"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            ),
        ]
    )

    static let facebookLoginPermissionsSetup = Workflow(
        title: "Ask Facebook for Only the Info You Actually Need",
        summary: "Keep people's trust by requesting the smallest possible slice of their Facebook profile.",
        symbolName: "slider.horizontal.3",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "See What Your App Is Currently Requesting",
                instruction: "Pull up the full list of profile details your app is set up to ask for, from someone's name to their friend list. It's easy for this list to grow bloated over time as features get added and never removed.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Trim the List Down to Essentials",
                instruction: "For each item, ask whether a real feature in your app actually breaks without it. Every extra item you request is one more reason for a cautious visitor to bail out at the login screen.",
                jargonTerms: ["Permission Level"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Separate the Sensitive Requests",
                instruction: "A few pieces of info, like someone's email or friend list, are treated as more sensitive and get reviewed more closely before you're allowed to ask for them in front of real users.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Permissions and Features"
            ),
            WorkflowStep(
                title: "Explain Why You're Asking",
                instruction: "Next to each request, add a plain-English note about how that info improves the person's experience. Facebook checks this, and honestly, your visitors appreciate it too.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Re-Check the List Before You Publish",
                instruction: "Do one last pass right before launch. Permission lists tend to accumulate leftover requests from features that got cut, and a lean list is both faster to approve and less alarming to users.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookOpenGraphSetup = Workflow(
        title: "Make Your Links Look Good When Shared on Facebook",
        summary: "Turn a plain, boring link into a rich preview card with your own title, image, and description.",
        symbolName: "photo.on.rectangle.angled",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Add the Basic Preview Tags",
                instruction: "In the hidden header section of each page, add a few lines that spell out the title, description, and page type you want shown when someone shares that link. Without them, Facebook just guesses.",
                jargonTerms: ["Open Graph Tag"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick an Image That Won't Get Cropped Weird",
                instruction: "Point to an image sized for a wide preview card, roughly a 1.91:1 rectangle. A tall or square photo often gets awkwardly chopped when it lands in someone's feed.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Give Every Page Its Own Details",
                instruction: "Don't reuse the same title and description everywhere — each product, article, or listing page should describe itself, so a shared link actually tells people what they're about to click into.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Preview the Card Before It Goes Live",
                instruction: "Paste your page's link into Facebook's sharing preview tool to see exactly what people will see, catching a missing image or an awkward title before anyone else does.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Sharing Debugger"
            ),
            WorkflowStep(
                title: "Force Facebook to Re-Scan the Page",
                instruction: "Facebook caches preview cards, so if you update a page's tags, ask it to re-scrape the link. Otherwise people keep seeing the old, outdated preview for weeks.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookPixelSetup = Workflow(
        title: "Install the Meta Pixel to See What Happens After People Leave Your Site",
        summary: "Start measuring which visitors actually turn into customers after clicking away from Facebook.",
        symbolName: "viewfinder",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Create a Pixel for Your Website",
                instruction: "Set up a single tracking pixel to represent your website. Most businesses only ever need one, even if they run several campaigns pointing back to the same site.",
                jargonTerms: ["Meta Pixel"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Paste the Base Code Into Every Page",
                instruction: "Add the pixel's starter snippet to the shared header or footer template that every page loads, rather than copying it into individual pages one by one, so nothing gets missed.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm It's Firing on Every Page Load",
                instruction: "Browse your own site and watch for a green checkmark confirming the pixel loaded and reported back. A pixel that silently fails to load teaches you nothing.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Events Manager"
            ),
            WorkflowStep(
                title: "Match It to the Right Website",
                instruction: "If you manage more than one site or domain, double check the pixel is linked to the correct one so its data doesn't accidentally get mixed in with a different property's traffic.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Watch Your First Events Roll In",
                instruction: "Give it a few minutes of real traffic, then check that page views are showing up as expected. This baseline confirms everything's wired correctly before you build anything more advanced on top of it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookPixelCustomEventSetup = Workflow(
        title: "Track a Purchase or Signup With the Pixel",
        summary: "Find out exactly which visitors complete the action you actually care about, not just who showed up.",
        symbolName: "flag.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Pick the Moment Worth Tracking",
                instruction: "Decide on the one meaningful action you want counted, like a completed purchase or a finished signup form. Trying to track everything at once just buries the moments that matter.",
                jargonTerms: ["Custom Event"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add the Event Snippet to That Page",
                instruction: "Place a small extra piece of code on the confirmation or thank-you page that only loads once the action is truly complete, so you never count a visit as a sale by mistake.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Attach Useful Details to the Event",
                instruction: "Pass along extra info like the order value or item purchased. These small details are what let you later ask questions like \"which campaign drove the most revenue,\" not just \"which drove the most clicks.\"",
                jargonTerms: ["Event Parameter"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Confirm It Counts as a Conversion",
                instruction: "Trigger the action yourself and watch it appear as a tracked outcome, ready to be used as a goal for future campaigns rather than just a raw log entry.",
                jargonTerms: ["Conversion Action"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Test Events"
            ),
            WorkflowStep(
                title: "Check That the Numbers Match Reality",
                instruction: "Compare the count of tracked events against your own order or signup records for a few days. A mismatch usually means the snippet is firing in the wrong spot or too often.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookConversionsApiSetup = Workflow(
        title: "Send Events Straight From Your Server for More Reliable Tracking",
        summary: "Keep your event data accurate even when browsers block or lose the pixel's tracking calls.",
        symbolName: "server.rack",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "See Why Browser Tracking Alone Falls Short",
                instruction: "Ad blockers, strict browser privacy settings, and shaky connections all quietly drop some of the pixel's calls before they ever reach Facebook. A server-side channel fills in those gaps.",
                jargonTerms: ["Conversions API"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Create a Server-Side Sending Credential",
                instruction: "Generate a credential your backend can use to send events directly, without ever routing through a visitor's browser at all.",
                jargonTerms: ["API Key"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Send the Same Events From Your Backend",
                instruction: "When your server confirms an order or a signup, have it report that same event directly to Facebook, in parallel with whatever the pixel already sends from the browser.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Line Up the Two Copies of Each Event",
                instruction: "Tag both the browser event and the server event with a shared reference so Facebook recognizes them as the same real-world action instead of double-counting one sale as two.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Events Manager"
            ),
            WorkflowStep(
                title: "Confirm Your Event Match Quality Score",
                instruction: "Check the score Facebook gives your matched events. A strong score means your server data is filling in the gaps effectively rather than just adding noise on top of the pixel.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            ),
        ]
    )

    static let facebookCustomAudienceSetup = Workflow(
        title: "Build a Custom Audience From People Who Visited Your Site",
        summary: "Turn your own website traffic into a reusable group you can reach again later.",
        symbolName: "list.bullet.rectangle.portrait",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Decide Which Visitors You Want to Regroup",
                instruction: "Choose the behavior that makes someone worth remembering, like anyone who visited your pricing page or added something to a cart without checking out.",
                jargonTerms: ["Custom Audience"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Set the Time Window You Care About",
                instruction: "Pick how far back to look, from the last day to the last few months. A shorter window keeps the group focused on people whose visit is still fresh in their mind.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Choose the Pages That Define This Group",
                instruction: "Narrow the rule to specific pages or web addresses, like everything under your checkout flow, rather than lumping in every single visitor to your site.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Save It as a Reusable Group",
                instruction: "Name and save the audience so it keeps building in the background, ready whenever you need to reach these specific people again.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Audiences"
            ),
            WorkflowStep(
                title: "Let the List Keep Refreshing Itself",
                instruction: "Once saved, this audience updates automatically as new visitors match the rule, so you never have to rebuild it by hand before your next campaign.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookLookalikeAudienceSetup = Workflow(
        title: "Find New People Who Resemble Your Best Customers",
        summary: "Reach strangers who share traits with the people who already love what you offer.",
        symbolName: "person.crop.circle.badge.plus",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Pick a Source Group to Copy the Pattern From",
                instruction: "Choose a solid starting group, like past purchasers, to teach Facebook what your best customers tend to look like. The stronger this source group, the better the match.",
                jargonTerms: ["Lookalike Audience", "Custom Audience"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Choose the Country You Want to Grow In",
                instruction: "Pick which country or region to search for similar people in, since traits and habits that define your best customers can look different from one market to another.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Decide How Closely Matched You Want Them",
                instruction: "Choose a size setting that trades precision for reach — a tighter match finds people who look almost identical to your source group, while a looser one casts a wider net.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Let Facebook Build the Match",
                instruction: "Facebook compares patterns across your source group against everyone in the chosen country and assembles a brand-new group of people it hasn't shown you yet.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Audiences"
            ),
            WorkflowStep(
                title: "Save It for Your Next Campaign",
                instruction: "Name the finished audience clearly, noting which source group it was built from, so it's easy to reach for the next time you want to grow beyond your current customers.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookCommentsPluginSetup = Workflow(
        title: "Add Facebook Comments to a Page on Your Site",
        summary: "Let visitors leave comments using their existing Facebook account instead of building your own comment system.",
        symbolName: "bubble.left.and.bubble.right.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Grab the Comments Embed Code",
                instruction: "Generate the small ready-made snippet for the comments box, pointing it at the exact web address of the page you want people commenting on.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Drop the Container in Where Comments Should Appear",
                instruction: "Place the empty placeholder element exactly where you want the comment box to show up, usually right below your article or product description.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Load the SDK Script Once Per Page",
                instruction: "Add the shared script that powers the comment box, along with a tag identifying which app it belongs to, so the plugin knows whose site it's running on.",
                jargonTerms: ["Meta Tag"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Set How Many Comments Show by Default",
                instruction: "Choose how many comments load right away before someone has to click to see more, keeping long, popular threads from slowing the page down.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Comments Plugin"
            ),
            WorkflowStep(
                title: "Set Up Moderation Before You Publish",
                instruction: "Assign moderators and turn on basic filtering so an unmoderated pile-on doesn't sit on your page the first weekend you're not watching.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            ),
        ]
    )

    static let facebookDataDeletionCallbackSetup = Workflow(
        title: "Handle It Gracefully When Someone Removes Your App",
        summary: "Stay compliant by automatically deleting someone's data the moment they disconnect your app from their account.",
        symbolName: "person.crop.circle.badge.xmark",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand What Facebook Expects You to Do",
                instruction: "When someone removes your app from their Facebook settings, you're required to actually delete or anonymize whatever data you'd collected about them, not just quietly ignore the request.",
                jargonTerms: ["Data Deletion Callback"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Build an Endpoint That Accepts the Signal",
                instruction: "Set up a dedicated web address on your server whose only job is to receive the notification the moment someone removes your app.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Verify the Request Really Came From Facebook",
                instruction: "Check the signed information included in the request before acting on it, so a random outsider can't trick your endpoint into deleting the wrong person's records.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Delete or Anonymize Their Data",
                instruction: "Once verified, remove the person's stored information from your systems, or strip out anything that could identify them if you need to keep aggregate records.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Point Facebook to Your New Endpoint",
                instruction: "Register your endpoint's web address so Facebook knows exactly where to send the notification whenever someone disconnects your app.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Data Deletion Request URL"
            ),
            WorkflowStep(
                title: "Give People a Status Page to Check Progress",
                instruction: "Return a confirmation page or reference number so anyone who requested deletion can check that it actually went through, closing the loop instead of leaving them wondering.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            ),
        ]
    )

    // MARK: Facebook — Round 4 (Ads Manager & Commerce)

    static let facebookAdsManagerAccountSetup = Workflow(
        title: "Open Your First Ads Manager Account",
        summary: "Get your ad account set up the right way so every campaign you run afterward has a solid home.",
        symbolName: "person.crop.rectangle.badge.plus",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Find Your Way to Ads Manager",
                instruction: "Ads Manager is the control panel where every campaign, ad set, and ad you create actually lives. If you've never opened it before, Meta walks you through creating an Ad Account the first time you land there.",
                jargonTerms: ["Ad Account"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Lock In Currency and Time Zone",
                instruction: "Before you save, pick the currency and time zone you'll bill in. Both get locked once the account is created, so double check them now rather than fixing a mismatch later.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Tour the Ads Manager Dashboard",
                instruction: "Take a lap around the dashboard: the columns across the top switch between campaigns, ad sets, and ads, while the reporting table below updates to match whichever level you're viewing.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Ads Manager Dashboard"
            ),
            WorkflowStep(
                title: "Confirm Your Account Details",
                instruction: "Check your business name, address, and account ID under account settings, then you're cleared to build your first campaign on solid ground.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookCampaignHierarchySetup = Workflow(
        title: "Build a Campaign From the Ground Up",
        summary: "Understand how campaigns, ad sets, and ads stack together so your ad spend goes exactly where you intend.",
        symbolName: "square.stack.3d.up.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Meet the Three Layers",
                instruction: "Every Meta campaign is built like a nested folder system: a campaign holds one or more Ad Sets, and each Ad Set holds one or more ads. Changes at a lower layer never affect the layers above it.",
                jargonTerms: ["Ad Set"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Set the Objective at the Top",
                instruction: "The campaign level is where you declare what you want out of this whole effort, like driving sales or getting more messages. Everything underneath inherits that objective.",
                jargonTerms: ["Campaign Goal"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Handle the Details in the Middle Layer",
                instruction: "Inside each Ad Set you decide who sees your ads, how much you spend, where the ads show up, and when they run. This is the layer you'll duplicate most often when testing new audiences.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "See the Structure Take Shape",
                instruction: "Expand a campaign in your reporting table and you'll see its Ad Sets nested underneath, with the individual ads nested one level further, all in the same expandable view.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Campaign Structure Tree"
            ),
            WorkflowStep(
                title: "Drop In the Creative at the Bottom",
                instruction: "The ad itself is the bottom layer: the image or video, the text, and the link people actually see and tap. Now you know exactly which layer to open whenever you need to change something.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookAdCreativeSpecsSetup = Workflow(
        title: "Get Your Creative Ready for Meta's Specs",
        summary: "Prep images and video ahead of time so nothing gets cropped, rejected, or stretched once your ad goes live.",
        symbolName: "photo.on.rectangle.angled",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Let Placements Set the Shape",
                instruction: "Feed and Stories crop images differently, so the placements you plan to run in determine which aspect ratios you need. Square works almost everywhere; vertical is a must if you want Stories or Reels.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Match the Image Guidelines",
                instruction: "Export images at a resolution higher than the minimum Meta lists, and keep any logos or text away from the outer edges so they don't get trimmed by a different crop on a different screen.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Get Video Length and Captions Right",
                instruction: "Trim video to the length that suits its placement, and add burned-in or uploaded captions since most people scroll with sound off.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Preview Before You Publish",
                instruction: "Use the built-in preview panel to click through how your ad renders in every placement you selected, catching awkward crops before real budget is spent on them.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Ad Preview Tool"
            ),
            WorkflowStep(
                title: "Watch Out for Heavy Text Overlays",
                instruction: "Images packed with text tend to get less reach, so keep any words layered on top of a photo short and let the caption carry the rest of the message.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookCustomConversionSetup = Workflow(
        title: "Turn Pixel Events Into a Custom Conversion",
        summary: "Build a conversion you can actually optimize and report on out of the raw events your Pixel is already tracking.",
        symbolName: "target",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Head to Events Manager",
                instruction: "Custom Conversions are built inside Events Manager, the same place that shows you every event your Pixel has recorded so far.",
                jargonTerms: ["Events Manager"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Write a Rule, Not Code",
                instruction: "A Custom Conversion is just a rule laid on top of an existing event, like 'Purchase events on URLs containing /thank-you'. No extra tracking code needed since it filters events you're already collecting.",
                jargonTerms: ["Custom Conversion"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Attach a Value If It Helps",
                instruction: "Give the conversion a fixed or average dollar value if you want your reporting to show return on ad spend rather than just a raw count.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Review Your List of Custom Conversions",
                instruction: "Open the Custom Conversions tab to see every rule you've built, along with how many matches each one has picked up recently, so you can spot one that isn't firing.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Custom Conversions"
            ),
            WorkflowStep(
                title: "Put It to Work in an Ad Set",
                instruction: "Once it's created, your Custom Conversion shows up as a selectable option wherever an Ad Set asks what you're optimizing delivery for, so Meta can start chasing that specific action.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookProductCatalogSetup = Workflow(
        title: "Build Out a Product Catalog in Commerce Manager",
        summary: "Load your products into one organized catalog so Meta can turn them into shoppable ads and shop listings automatically.",
        symbolName: "shippingbox.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Create a Catalog in Commerce Manager",
                instruction: "Commerce Manager is where you create and manage a Product Catalog. Starting a new one just takes picking the catalog type that matches what you sell.",
                jargonTerms: ["Commerce Manager", "Product Catalog"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Pick the Right Catalog Type",
                instruction: "Choose the ecommerce option if you're selling physical or digital products; other types exist for hotels, flights, and vehicles but most small businesses want the standard product catalog.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add Products By Hand or By Feed",
                instruction: "For a handful of items, add them one at a time directly in Commerce Manager. For a larger inventory, connect a Product Feed so your catalog updates automatically whenever your stock or prices change.",
                jargonTerms: ["Product Feed"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Browse Your Catalog Once It's Populated",
                instruction: "Once items are in, scroll through the catalog grid to spot missing images, blank prices, or categories that never got filled in.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Product Catalog"
            ),
            WorkflowStep(
                title: "Check the Catalog's Data Health",
                instruction: "Open the diagnostics panel for your catalog to see which items have errors or warnings, and fix those before you build ads or a shop on top of them.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookShopLaunchSetup = Workflow(
        title: "Launch Your Shop on Facebook or Instagram",
        summary: "Turn your product catalog into a browsable storefront that lives right on your Facebook Page or Instagram profile.",
        symbolName: "bag.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Start the Shop Setup Flow",
                instruction: "From Commerce Manager, choose the option to set up a shop, then pick whether checkout happens on your own website or directly inside Facebook and Instagram.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Connect Your Catalog",
                instruction: "Point the shop at the Product Catalog you already built, so every item you stocked there becomes browsable without re-entering anything.",
                jargonTerms: ["Product Catalog"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Organize Products Into Sections",
                instruction: "Group related items into collections, like 'New Arrivals' or 'Best Sellers', so visitors can browse by theme instead of scrolling through everything at once.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Preview the Storefront Layout",
                instruction: "Step through the shop preview to see exactly how your collections and featured items will look to a visitor before anything goes public.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Shop Setup"
            ),
            WorkflowStep(
                title: "Submit and Publish",
                instruction: "Submit your shop for review; once it's approved, it appears as a Shop tab on your Page and a shopping tab on Instagram, ready for people to browse and buy.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookEventDeliveryDiagnosticsSetup = Workflow(
        title: "Troubleshoot Event Delivery in Events Manager",
        summary: "Spot and fix the reason your Pixel events aren't showing up so your ad optimization has accurate data to work with.",
        symbolName: "waveform.path.ecg",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Open the Events Overview",
                instruction: "Events Manager shows every event source you have connected, along with a status indicator that turns yellow or red the moment something stops flowing normally.",
                jargonTerms: ["Events Manager"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check Recent Activity for Gaps",
                instruction: "Look at the event volume chart for a sudden drop-off; a flat line usually points to a recent site change that broke your tracking rather than an actual dip in customer activity.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check How Well Events Are Matching",
                instruction: "A low match score means events are arriving but without enough customer details for Meta to confidently tie them to a real person, which quietly weakens your optimization.",
                jargonTerms: ["Event Match Quality"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Dig Into the Diagnostics Tab",
                instruction: "The diagnostics tab lists specific warnings and errors per event, like missing parameters or duplicate firing, each with an explanation of what's causing it.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Diagnostics Tab"
            ),
            WorkflowStep(
                title: "Fix It and Confirm With a Real Test",
                instruction: "Make the fix, then perform the action yourself on your site or app and watch for it to appear as a fresh test event, confirming the pipe is clear again.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookAdAccountBillingSetup = Workflow(
        title: "Add a Payment Method to Your Ad Account",
        summary: "Get billing squared away so your campaigns can actually spend the budget you set for them.",
        symbolName: "creditcard.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Open Billing Settings",
                instruction: "Inside Ads Manager, the billing section is where you manage every payment method attached to this specific Ad Account.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add a Card or Other Payment Option",
                instruction: "Add a credit card, debit card, or an available local payment option, then set it as the primary method so it's charged automatically going forward.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Understand How Charges Trigger",
                instruction: "Rather than billing on a fixed monthly date, most accounts get charged whenever spend crosses a set dollar amount, so a busy week can mean more than one charge.",
                jargonTerms: ["Billing Threshold"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Review Your Payment Settings Panel",
                instruction: "Scan the payment settings screen to see your saved methods, which one is primary, and your current balance since the last charge.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Payment Settings"
            ),
            WorkflowStep(
                title: "Check Past Charges Anytime",
                instruction: "Open the billing history to review past invoices and receipts, handy for reconciling your books or spotting an unexpected charge early.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookAdvantagePlacementsSetup = Workflow(
        title: "Let Advantage+ Placements Do the Work",
        summary: "Hand placement decisions to Meta's system so your ads automatically show up wherever they're likely to perform best.",
        symbolName: "wand.and.stars",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Manual vs. Letting the System Choose",
                instruction: "When you build an Ad Set, you can hand-pick exactly where ads appear or let Meta decide for you. Picking manually can protect your brand's look, but it also caps how much room the delivery system has to find cheap results.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Turn On Advantage+ Placements",
                instruction: "Selecting this option lets the system automatically shift your budget toward whichever surfaces are delivering results most efficiently in real time, instead of locking spend to a fixed set you chose upfront.",
                jargonTerms: ["Advantage+ Placements"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Know What's Included",
                instruction: "This covers Facebook Feed and Stories, Instagram Feed and Reels, Messenger, and the Audience Network of partner apps and sites outside Meta's own platforms.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "See Where the Placements Toggle Lives",
                instruction: "The placements section sits inside the Ad Set, right below your audience settings, where you switch between the automatic and manual options.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Placements"
            ),
            WorkflowStep(
                title: "Check the Placement Breakdown Later",
                instruction: "After your ads have been running for a bit, break your reporting down by placement to see which surfaces are actually pulling their weight.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookBudgetAndBiddingSetup = Workflow(
        title: "Set Your Budget and Pick a Bidding Strategy",
        summary: "Decide how much to spend and how Meta should spend it, so your budget stretches toward the results you actually want.",
        symbolName: "chart.pie.fill",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Decide Where the Budget Lives",
                instruction: "You can set one shared budget at the campaign level and let the system split it across your Ad Sets on its own, or set a separate Campaign Budget at each individual Ad Set for tighter control.",
                jargonTerms: ["Advantage Campaign Budget", "Campaign Budget"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Choose How Aggressively to Bid",
                instruction: "Your Bidding Strategy tells the auction how to spend that budget, whether that means chasing the lowest possible cost, hitting a specific cost target, or maximizing results without any cap at all.",
                jargonTerms: ["Bidding Strategy"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "See Budget and Bidding Side by Side",
                instruction: "Both settings sit together in the Ad Set editor, so you can compare your budget amount against the bidding option right before publishing.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Budget & Bidding"
            ),
            WorkflowStep(
                title: "Sanity-Check the Estimated Results",
                instruction: "Glance at the estimated daily results panel before you launch; it won't be exact, but a wildly low number is often a sign your budget or bid is too tight for the audience you picked.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    // MARK: Facebook — Round 4 (Messaging, Instagram & Extended Platform)

    static let facebookMessengerWebhookSetup = Workflow(
        title: "Wire Up Automated Messenger Replies",
        summary: "Let your Page send and receive Messenger chats automatically instead of someone typing every reply by hand.",
        symbolName: "bubble.left.and.bubble.right",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand What You're Building",
                instruction: "The Messenger Platform lets your Page act like a switchboard operator: when someone messages your business, your server gets notified instantly and can text back without a human lifting a finger. Before you touch any settings, know that you're connecting your Page to a server you control.",
                jargonTerms: ["Messenger Platform"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Give Meta a Front Door to Your Server",
                instruction: "You'll need a small server endpoint that's always awake and listening, kind of like a mail slot bolted to your building that only accepts letters addressed correctly. Meta will send a one-time verification request to prove you actually own it before anything real comes through.",
                jargonTerms: ["Webhook Endpoint"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Subscribe Your Page to Message Events",
                instruction: "In the app dashboard's Messenger settings, connect your Page and turn on the message-related fields so incoming chats actually get routed to your webhook instead of sitting unread.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Messenger Settings"
            ),
            WorkflowStep(
                title: "Send a Reply Back Programmatically",
                instruction: "Once your server receives a message, it can call the Send API to reply — think of it as the return-address side of that mail slot, letting your code write back instead of only reading what came in.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Send a Real Test Message",
                instruction: "Message your own Page from a personal account and confirm your server logs the event and fires back an automated reply within a couple of seconds.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookWhatsAppBusinessPlatformSetup = Workflow(
        title: "Get Your Business Onto the WhatsApp Business Platform",
        summary: "Send and receive WhatsApp messages from your own software instead of tapping around on a phone.",
        symbolName: "phone.bubble.left",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Know the Difference That Trips Everyone Up",
                instruction: "The regular WhatsApp Business app is for one person on one phone. The WhatsApp Business Platform is the API version — the industrial kitchen instead of the home stovetop — built so your systems can send order confirmations, support replies, and alerts at scale.",
                jargonTerms: ["WhatsApp Business Platform"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Register a Phone Number for API Use",
                instruction: "Pick a phone number that isn't already tied to a personal WhatsApp account and register it inside the platform's setup flow. This number becomes the sender identity for every automated message you send.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Get Your Message Templates Approved",
                instruction: "Unlike a live chat, the first message to a customer must use a pre-approved template — like a form letter reviewed ahead of time — so Meta can screen for spam before it ever reaches someone's phone.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Message Templates"
            ),
            WorkflowStep(
                title: "Send Your First API Message",
                instruction: "Use your registered number and an approved template to send a real WhatsApp message through the API, then check that it lands correctly on a test phone.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookInstagramPageLinkSetup = Workflow(
        title: "Connect Instagram to Your Facebook Page",
        summary: "Link your Instagram account to your Page so all your business tools can see and manage both in one place.",
        symbolName: "link",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Switch Instagram to a Professional Account",
                instruction: "Any personal Instagram account can flip into a Professional Account for free — it's like upgrading a personal mailbox into one with a business nameplate, unlocking insights and tools a personal account can't touch.",
                jargonTerms: ["Instagram Professional Account"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Find the Linking Option",
                instruction: "From your Page's settings, look for the Instagram section — this is where you formally pair the two accounts so they share data instead of living as two disconnected islands.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Linked Accounts"
            ),
            WorkflowStep(
                title: "Log In and Confirm the Pairing",
                instruction: "You'll be asked to log into the Instagram account once to prove you control it. After that, the Page and the Instagram account stay linked without needing to log in again.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Verify the Link Took Effect",
                instruction: "Check your Page's About info or settings to confirm the Instagram account now shows as connected — this link is the foundation every other Instagram business feature depends on.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookInstagramGraphAPISetup = Workflow(
        title: "Unlock Programmatic Control of Your Instagram Account",
        summary: "Let your own software read and manage your Instagram account instead of doing everything by hand in the app.",
        symbolName: "chevron.left.slash.chevron.right",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Confirm the Prerequisite Link Exists",
                instruction: "This only works once your Instagram account is a Professional Account already linked to a Facebook Page — that link is the bridge your code will walk across to reach Instagram's data.",
                jargonTerms: ["Instagram Professional Account"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Request the Right Permissions",
                instruction: "In your app's setup, request access to the Instagram-related permissions your use case needs, such as reading posts or managing comments. Think of each permission as a separate key on a keyring — you only get handed the ones you actually ask for.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Query the Instagram Graph API",
                instruction: "With access granted, your app can now call the Instagram Graph API to fetch profile data, list media, or read comments — the same programmatic doorway developers use to build scheduling tools and analytics dashboards.",
                jargonTerms: ["Instagram Graph API"],
                visual: .consoleOverlay,
                overlayTargetLabel: "Instagram Graph API"
            ),
            WorkflowStep(
                title: "Pull a Real Piece of Data",
                instruction: "Run a simple request that fetches your account's recent media or follower count, and confirm the response actually matches what you see in the Instagram app.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookHandoverProtocolSetup = Workflow(
        title: "Hand Conversations Off Between Bot and Human",
        summary: "Let a chatbot handle the easy questions and smoothly pass tricky ones to a real person without the customer noticing a hiccup.",
        symbolName: "arrow.left.arrow.right",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Picture the Relay Race",
                instruction: "The Handover Protocol works like a relay race baton: only one runner — your bot or a human agent — holds the conversation at any moment, and there's a formal way to pass it along without dropping it.",
                jargonTerms: ["Handover Protocol"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Name Your Primary and Secondary Receivers",
                instruction: "Designate which app (usually your bot) automatically owns new conversations by default, and which app (often your live-agent tool) can request control when things get complicated.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Trigger a Pass-Off Programmatically",
                instruction: "When your bot detects a question it can't handle, it calls a pass-thread action to hand control to the secondary receiver, optionally including a note about why — like a barista scribbling context on a to-go cup before handing it to a colleague.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Pass Thread Control"
            ),
            WorkflowStep(
                title: "Let the Human Hand It Back",
                instruction: "Once the human agent wraps up, they can pass control back to the bot so future automated replies resume without the customer having to start over.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Test a Full Round Trip",
                instruction: "Simulate a conversation that starts with the bot, escalates to a human, and gets handed back, confirming control changes hands cleanly at each step with no duplicate or dropped replies.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )

    static let facebookMetaVerifiedSetup = Workflow(
        title: "Apply for a Verified Badge with Meta Verified",
        summary: "Get the blue check next to your Page or profile so customers know they've found the real you.",
        symbolName: "checkmark.seal",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Understand What the Badge Actually Buys",
                instruction: "Meta Verified is a paid subscription that confirms your identity and adds proactive account protection — think of it as a passport office visit: you prove who you are once, and afterward you get a credential that makes impersonators easier to spot.",
                jargonTerms: ["Meta Verified"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check the Eligibility Basics",
                instruction: "Your Page or profile generally needs a posting history, a profile photo, and to already meet a minimum age on the platform before you can even start the application.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Submit Government ID for Review",
                instruction: "You'll upload an official ID that matches the name on your Page or profile. This is the identity-proofing step — Meta needs to confirm a real, specific person or business is behind the account.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Meta Verified Application"
            ),
            WorkflowStep(
                title: "Wait for Review and Confirm the Badge",
                instruction: "Once approved, check your Page or profile for the verified badge and make sure your subscription is active — losing the subscription later can remove the badge, so treat it as an ongoing service, not a one-time stamp.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookBusinessSuiteInboxSetup = Workflow(
        title: "Run One Inbox for Facebook and Instagram Messages",
        summary: "Answer every Facebook and Instagram conversation from a single screen instead of switching between two apps.",
        symbolName: "tray.2",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Open Meta Business Suite",
                instruction: "Meta Business Suite is the shared control room for your Page and its linked Instagram account — one dashboard that pulls messages, comments, and posts from both platforms into the same view.",
                jargonTerms: ["Meta Business Suite"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Head to the Unified Inbox",
                instruction: "Open the inbox tab and you'll see Messenger and Instagram Direct conversations sitting side by side, sortable by which platform they came from without you having to log into a second app.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Unified Inbox"
            ),
            WorkflowStep(
                title: "Assign Conversations to Teammates",
                instruction: "If more than one person handles support, assign incoming chats to specific teammates so nothing gets answered twice — or missed because everyone assumed someone else had it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Save a Quick Reply for Common Questions",
                instruction: "Set up a saved reply for something you get asked constantly, like store hours, so answering it takes one tap instead of retyping it every time.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Send a Reply from the Unified View",
                instruction: "Answer a real message from within the unified inbox and confirm it shows up correctly on the customer's side, whether they messaged you on Facebook or Instagram.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookAppInsightsSetup = Workflow(
        title: "Check How People Are Actually Using Your App",
        summary: "See real usage numbers for your Facebook-connected app instead of guessing whether people are running into trouble.",
        symbolName: "chart.xyaxis.line",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Find the Insights Section",
                instruction: "Every app you've built on the platform has an Insights area that quietly tallies activity in the background — like a doorman keeping a logbook of everyone who comes and goes, so you never have to ask.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Check Daily and Monthly Active Users",
                instruction: "These two numbers tell you how many distinct people are actually touching your app each day versus each month — a big gap between them usually means people try it once and don't come back.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "App Insights"
            ),
            WorkflowStep(
                title: "Look at API Call Volume and Error Rates",
                instruction: "Insights also tracks how many API requests your app is making and what fraction are failing — a sudden spike in errors is often the first sign something broke before a single user ever emails you about it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Set a Baseline to Compare Against",
                instruction: "Note today's numbers somewhere you'll actually look again, so next month you can tell whether usage is genuinely growing or you're just imagining it.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookPixelHelperTestSetup = Workflow(
        title: "Double-Check Your Meta Pixel Is Actually Firing",
        summary: "Confirm your website is really sending data back to Meta instead of silently failing in the background.",
        symbolName: "wand.and.rays",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Install the Browser Helper Tool",
                instruction: "Meta Pixel Helper is a free browser extension that acts like a stethoscope for your website — you point it at a page and it listens for a heartbeat from your tracking code.",
                jargonTerms: ["Meta Pixel Helper"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Visit Your Own Website",
                instruction: "Open your site in the browser where you installed the extension, then click the extension icon to see what it detected on that page.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Read the Diagnostic Results",
                instruction: "A green checkmark means your pixel fired correctly and sent the events you'd expect; warnings or errors point to something like a duplicated pixel or a missing event, so you can fix it before it quietly skews your data for weeks.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Meta Pixel Helper"
            ),
            WorkflowStep(
                title: "Walk Through a Key Action on Your Site",
                instruction: "Do something meaningful, like adding an item to a cart, and watch the extension confirm that the matching event fired at the right moment, not just when the page first loaded.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 20
            )
        ]
    )

    static let facebookPageRecoveryContactSetup = Workflow(
        title: "Lock Down Your Page with a Recovery Contact",
        summary: "Make sure you can always get back into your Page even if your login is lost, stolen, or forgotten.",
        symbolName: "lock.shield",
        company: .facebook,
        steps: [
            WorkflowStep(
                title: "Turn on Two-Factor Authentication",
                instruction: "Every admin on your Page should have Two-Factor Authentication enabled on their personal account, since a Page is only as secure as the weakest login among the people who manage it.",
                jargonTerms: ["Two-Factor Authentication"],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Add More Than One Admin",
                instruction: "Never let a single person be the only admin on your Page — if that one account gets locked out or its owner leaves the company, you want a second trusted person who can already get in.",
                jargonTerms: [],
                visual: .plain,
                overlayTargetLabel: nil
            ),
            WorkflowStep(
                title: "Review Security Settings for the Page",
                instruction: "Open your Page's security section and check who currently has admin access, removing anyone who no longer needs it — like periodically re-keying a door instead of assuming every old key was returned.",
                jargonTerms: [],
                visual: .consoleOverlay,
                overlayTargetLabel: "Page Security Settings"
            ),
            WorkflowStep(
                title: "Confirm Recovery Actually Works",
                instruction: "Have a second admin practice logging in and verifying their own two-factor code, so you know for certain someone besides you can regain control if your own account is ever compromised.",
                jargonTerms: ["Verification Code"],
                visual: .plain,
                overlayTargetLabel: nil,
                xpValue: 25
            )
        ]
    )


    static let all: [Workflow] = [
        dnsSetup, twoFactorAuthSetup, passwordManagerSetup, vpnSetup, wifiRouterSetup,
        cloudStorageSyncSetup, browserSyncSetup, emailDeliverabilitySetup,
        searchEngineVisibilitySetup, faviconSetup, qrCodeSetup, contactFormSpamProtection,
        uptimeMonitoringSetup, passkeySetup, securityKeySetup, guestWifiSetup,
        personalBackupStrategySetup, browserExtensionAuditSetup, cookieConsentBannerSetup,
        xmlSitemapSubmissionSetup, emailAliasSetup, smartHomeDeviceSetup, sessionTimeoutSetup,
        parentalControlsSetup, customShortLinkSetup, rssFeedSetup, diskEncryptionSetup,
        emailSpamFilterSetup, custom404PageSetup, publicStatusPageSetup, clipboardSyncSetup,
        adTrackerBlockerSetup, twoFactorBackupCodesSetup, encryptedNoteVaultSetup,
        openGraphPreviewSetup, tipJarSetup, autoUpdateSetup, routerHardeningSetup,
        digitalDeclutterSetup,

        googleCloudSetup, googleSearchConsoleSetup, gmailCustomDomainSetup, googleAnalyticsSetup,
        googleAdsConversionTracking, googleWorkspaceUserSetup, googleDriveSharingSetup,
        firebaseProjectSetup, googlePlayConsoleListingSetup, googleMapsApiKeySetup,
        youTubeChannelBrandingSetup, googleTagManagerSetup, googleBusinessProfileSetup,
        googleRecaptchaSetup, googleAdsCampaignSetup, googleCalendarSharingSetup, googleFormsSetup,
        firebaseAuthSetup, firebaseCloudMessagingSetup, googleGroupsSetup,
        googleMerchantCenterSetup, youTubeDataApiKeySetup, googleTagSetup, cloudRunDeploySetup,
        cloudStorageCdnSetup, googleWorkspaceSharedDriveSetup, googleCloudBudgetAlertsSetup,
        googleAnalyticsEventTrackingSetup, googleSearchConsoleIndexingRequestSetup,
        googlePlayInternalTestingSetup, googleCloudPubSubSetup, googleCloudSqlSetup,
        googleCloudSchedulerSetup, firestoreSecurityRulesSetup, firebaseRemoteConfigSetup,
        googleWorkspaceVaultSetup, googleAdsRemarketingSetup, googleCloudLoadBalancingSetup,
        googleIdentityServicesSetup, lookerStudioDashboardSetup,

        appleTestFlightSetup, applePushSetup, appleAppStoreListingSetup, appleInAppPurchaseSetup,
        appleSignInWithAppleSetup, appleScreenshotsPreviewSetup, appleTestFlightExternalGroupSetup,
        appleXcodeCloudSetup, appleAPIKeySetup, applePrivacyLabelSetup, appleUniversalLinksSetup,
        appleCloudKitContainerSetup, appleSubscriptionGroupSetup, appleUserRolesSetup,
        appleDeveloperProgramEnrollmentSetup, appleManualSigningCertificateSetup,
        appleRatingPromptSetup, appleKeywordOptimizationSetup, appleWalletPassSetup,
        appleWidgetSetup, appleAppClipSetup, appleGameCenterSetup, appleFamilySharingSetup,
        applePromoOfferCodeSetup, applePreOrderSetup, applePushCategoriesSetup,
        appleCloudKitSchemaSetup, appleTestFlightCrashReportingSetup,
        appleStoreKitServerVerificationSetup, appleServerNotificationsSetup,
        appleHealthKitEntitlementSetup, appleAppIntentsSetup, appleLiveActivitiesSetup,
        appleAgeRatingSetup, appleInAppEventsSetup, appleCustomProductPagesSetup,
        appleBusinessManagerSetup, appleMapKitApiKeySetup, appleHandoffContinuitySetup,
        appleAppStoreConnectWebhooksSetup,

        azureResourceSetup, microsoft365DomainSetup, microsoftTeamsSetup, sharePointSiteSetup,
        oneDriveSharingSetup, conditionalAccessSetup, azureKeyVaultSetup, azureStorageAccountSetup,
        powerBIWorkspaceSetup, powerAutomateFlowSetup, microsoftDefenderSetup,
        azureDevOpsRepoSetup, exchangeMailFlowRuleSetup, windowsAutopilotSetup,
        entraSecurityGroupSetup, exchangeSharedMailboxSetup, azureAppServiceDeploySetup,
        azureSqlDatabaseSetup, azureMonitorAlertSetup, intuneCompliancePolicySetup,
        entraAppRegistrationSetup, powerAppsCanvasAppSetup, microsoftFormsSetup,
        azureVirtualNetworkSetup, azureContainerRegistrySetup, teamsPhoneCallingSetup,
        microsoft365RetentionPolicySetup, microsoftDefenderCloudAppsSetup, azureFunctionSetup,
        azureLogicAppSetup, microsoftLoopWorkspaceSetup, vivaEngageCommunitySetup,
        azureFrontDoorSetup, azureApiManagementSetup, sharePointPermissionLevelsSetup,
        azureBastionSetup, copilotStudioBotSetup, azureCosmosDbSetup, windows365CloudPcSetup,
        microsoftSentinelAlertRuleSetup,

        awsS3HostingSetup, awsIAMSetup, awsRDSSetup, awsLambdaSetup, awsSQSSetup, awsSNSSetup,
        awsCloudWatchAlarmSetup, awsDynamoDBSetup, awsVPCSetup, awsElasticBeanstalkSetup,
        awsACMSetup, awsSecretsManagerSetup, awsCloudTrailSetup, awsAutoScalingSetup,
        awsCloudFrontSetup, awsRoute53Setup, awsAPIGatewaySetup, awsCognitoSetup,
        awsCloudFormationSetup, awsSESSetup, awsEventBridgeSetup, awsBudgetsSetup, awsELBSetup,
        awsParameterStoreSetup, awsWAFSetup, awsECSFargateSetup, awsOrganizationsSetup,
        awsXRaySetup, awsElastiCacheSetup, awsStepFunctionsSetup, awsBackupPlanSetup,
        awsConfigRuleSetup, awsKinesisStreamSetup, awsAmplifyHostingSetup, awsIdentityCenterSetup,
        awsEFSSetup, awsSiteToSiteVPNSetup, awsQuickSightSetup, awsRedshiftSetup,
        awsSessionManagerSetup,

        // Universal (Round 4)
        stolenDeviceProtectionSetup, dataBreachMonitoringSetup, browserAutofillHardeningSetup, guestFileDropSetup, digitalLegacySetup,
        dnsCaaRecordSetup, travelRouterVpnSetup, familyPasswordVaultSetup, certExpiryMonitoringSetup,
        privacyAnalyticsSetup, maskedEmailSetup,

        // Google (Round 4)
        googleIamCustomRoleSetup, cloudBuildPipelineSetup, artifactRegistrySetup, bigQueryDatasetSetup,
        workspaceMfaEnforcementSetup, playAppSigningSetup, firebaseCrashlyticsSetup, firebaseAppCheckSetup,
        androidAppLinksSetup, cloudDnsManagedZoneSetup,

        // Apple (Round 4)
        appleTestFlightPublicLinkSetup, appleTeamRolesSetup, appleStoreKit2VerificationSetup, appleRejectionAppealSetup,
        appleXcodeCloudWorkflowsSetup, appleNotarizationSetup, appleAppSandboxSetup, appleKeyValueStoreSetup,
        appleSchoolManagerSetup, appleEditorialPitchSetup,

        // Microsoft (Round 4)
        entraExternalIdentitiesSetup, microsoftPurviewLabelSetup, azurePolicySetup, azureCostBudgetSetup,
        microsoft365GroupSetup, outlookForwardingRuleSetup, azureStaticWebAppSetup, azureServiceBusSetup,
        entraGraphPermissionSetup, azureManagedIdentitySetup,

        // Amazon (Round 4)
        awsGlueSetup, awsAthenaSetup, awsAppRunnerSetup, awsMqSetup,
        awsAuroraServerlessSetup, awsPatchManagerSetup, awsTransferFamilySetup, awsShieldSetup,
        awsBatchSetup, awsNeptuneSetup,

        // Facebook (Round 4, new category)
        facebookAppDashboardSetup, facebookGraphExplorerSetup, facebookUserAccessTokenSetup, facebookLongLivedTokenSetup,
        facebookAppDomainSetup, facebookAppReviewSetup, facebookTestUsersSetup, facebookWebhookSubscriptionSetup,
        facebookPermissionsScopesSetup, facebookLiveModeSetup, facebookBusinessManagerSetup, facebookSystemUserSetup,
        facebookAssetAssignmentSetup, facebookBusinessVerificationSetup, facebookPageRolesSetup, facebookAdAccountRolesSetup,
        facebookBusinessManager2FASetup, facebookDomainClaimSetup, facebookCatalogOwningBusinessSetup, facebookAdvancedAccessSetup,
        facebookLoginSetup, facebookLoginPermissionsSetup, facebookOpenGraphSetup, facebookPixelSetup,
        facebookPixelCustomEventSetup, facebookConversionsApiSetup, facebookCustomAudienceSetup, facebookLookalikeAudienceSetup,
        facebookCommentsPluginSetup, facebookDataDeletionCallbackSetup, facebookAdsManagerAccountSetup, facebookCampaignHierarchySetup,
        facebookAdCreativeSpecsSetup, facebookCustomConversionSetup, facebookProductCatalogSetup, facebookShopLaunchSetup,
        facebookEventDeliveryDiagnosticsSetup, facebookAdAccountBillingSetup, facebookAdvantagePlacementsSetup, facebookBudgetAndBiddingSetup,
        facebookMessengerWebhookSetup, facebookWhatsAppBusinessPlatformSetup, facebookInstagramPageLinkSetup, facebookInstagramGraphAPISetup,
        facebookHandoverProtocolSetup, facebookMetaVerifiedSetup, facebookBusinessSuiteInboxSetup, facebookAppInsightsSetup,
        facebookPixelHelperTestSetup, facebookPageRecoveryContactSetup,
    ]

    /// Convenience grouping used by `WorkflowListView` to render one
    /// section per provider, with universal guides in their own section.
    static func grouped() -> [WorkflowGroup] {
        Company.allCases.map { company in
            WorkflowGroup(company: company, workflows: all.filter { $0.company == company })
        } + [WorkflowGroup(company: nil, workflows: all.filter { $0.company == nil })]
    }
}

/// One provider's section of the guide catalog, or the universal
/// section when `company` is `nil`. `Hashable` so it can be pushed as a
/// `NavigationLink(value:)` destination — company sections are browsed
/// as their own drill-down screen rather than rendered inline.
struct WorkflowGroup: Identifiable, Hashable {
    let company: Company?
    let workflows: [Workflow]
    var id: String { company?.rawValue ?? "universal" }
}
