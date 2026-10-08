//
//  BeginnerGuides.swift
//  Tech Unknotted (project: Clarify)
//
//  The Very Easy and Easy end of the catalog: everyday problems like a
//  forgotten password, a login code that never arrives, or a phone that
//  says its storage is full. Every provider section gets its own set so
//  someone who has never opened a developer console still has a clear
//  place to start.
//
//  Same rules as the rest of the library: original plain-English
//  wording, no text copied from any provider's help pages, and nothing
//  fetched at runtime. Menu names describe where things usually live;
//  providers rename menus over time, so steps also say what to look for
//  rather than relying on one exact label.
//

import Foundation

extension WorkflowLibrary {

    // MARK: Universal — Very Easy / Easy

    static let forgotPasswordBasics = Workflow(
        title: "I Forgot My Password",
        summary: "Get back into almost any account using its built-in reset link.",
        symbolName: "key.fill",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Go to the Sign-In Page",
                instruction: "Open the app or website you're locked out of and go to the screen where you normally type your password."
            ),
            WorkflowStep(
                title: "Tap the Forgot Password Link",
                instruction: "Look just under the password box for a link like Forgot password or Can't sign in. Tap it and enter the email or phone number on the account.",
                jargonTerms: ["Password Reset"]
            ),
            WorkflowStep(
                title: "Open the Reset Message",
                instruction: "Check your email or texts for the reset message. If it isn't there after a few minutes, look in your spam or junk folder before asking for another one.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Pick a New Password and Save It",
                instruction: "Choose a password you haven't used anywhere else, then save it in a password manager so you don't have to remember it next time.",
                jargonTerms: ["Password Manager"],
                xpValue: 15
            )
        ]
    )

    static let loginCodeMissing = Workflow(
        title: "My Login Code Isn't Arriving",
        summary: "What to try when the text or email with your sign-in code never shows up.",
        symbolName: "message.badge.filled.fill",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Wait One Minute, Then Ask Once More",
                instruction: "Codes can take a minute to arrive. Tap Resend only once; asking many times in a row can make the service pause sending for a while.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Check Signal and Spam",
                instruction: "Make sure your phone has signal or Wi-Fi, and look in your email's spam folder. Codes from new senders often land there."
            ),
            WorkflowStep(
                title: "Try Another Way to Get the Code",
                instruction: "On the code screen, look for Try another way or More options. You may be able to use an authenticator app, a backup code, or a different phone number.",
                jargonTerms: ["Authenticator App", "Backup Code"]
            ),
            WorkflowStep(
                title: "Use Account Recovery as a Last Resort",
                instruction: "If nothing works, start the service's account recovery process. It's slower, but it's built for exactly this situation.",
                jargonTerms: ["Account Recovery"],
                xpValue: 15
            )
        ]
    )

    static let spotPhishingBasics = Workflow(
        title: "Spot a Fake Login Message",
        summary: "Tell the difference between a real security alert and a scam trying to steal your password.",
        symbolName: "exclamationmark.shield.fill",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Notice the Pressure",
                instruction: "Scam messages rush you: your account will close today, you owe money, click now. Real companies rarely threaten you in a text or email.",
                jargonTerms: ["Phishing"]
            ),
            WorkflowStep(
                title: "Don't Tap the Link",
                instruction: "Instead of tapping anything in the message, open the company's app yourself or type its web address by hand. If something is really wrong, you'll see it there."
            ),
            WorkflowStep(
                title: "Never Share a Code",
                instruction: "No real company will call or message to ask for the code they just sent you. Anyone asking for it is trying to get into your account.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Report It and Delete It",
                instruction: "Use your email app's Report spam or Report phishing button, then delete the message. If you already typed your password, change it right away.",
                xpValue: 15
            )
        ]
    )

    static let wifiNotLoadingBasics = Workflow(
        title: "Wi-Fi Is Connected but Nothing Loads",
        summary: "Simple fixes to try, in order, before calling your internet company.",
        symbolName: "wifi.exclamationmark",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Test Another Device",
                instruction: "Try loading a website on a different phone or computer on the same Wi-Fi. If it also fails, the problem is the internet, not your device."
            ),
            WorkflowStep(
                title: "Restart the Router",
                instruction: "Unplug the router's power cord, wait 30 seconds, and plug it back in. Give it a few minutes for its lights to settle.",
                jargonTerms: ["Router"]
            ),
            WorkflowStep(
                title: "Forget and Rejoin the Network",
                instruction: "In your device's Wi-Fi settings, choose the network, select Forget, and then join it again with the Wi-Fi password.",
                jargonTerms: ["SSID"]
            ),
            WorkflowStep(
                title: "Check for an Outage",
                instruction: "If it's still down, use your phone's cellular data to check your internet provider's outage page or app before booking a repair visit.",
                xpValue: 15
            )
        ]
    )

    static let storageFullBasics = Workflow(
        title: "My Phone Says Storage Is Full",
        summary: "Free up space quickly without losing the photos and messages you care about.",
        symbolName: "internaldrive.fill",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "See What's Using the Space",
                instruction: "Open Settings and search for Storage. Your phone lists apps from largest to smallest, so you know where to start.",
                jargonTerms: ["Device Storage"]
            ),
            WorkflowStep(
                title: "Clear Out Big Videos",
                instruction: "Videos take up far more room than photos. Delete ones you don't need, then empty the Recently Deleted album so the space is actually freed."
            ),
            WorkflowStep(
                title: "Remove Apps You Don't Use",
                instruction: "Delete or offload apps you haven't opened in months. You can download them again any time from the app store."
            ),
            WorkflowStep(
                title: "Back Up Before Deleting Anything Precious",
                instruction: "Turn on photo backup to a cloud service first, so clearing space never means losing memories.",
                jargonTerms: ["Cloud Backup"],
                xpValue: 15
            )
        ]
    )

    static let frozenDeviceBasics = Workflow(
        title: "My Phone or Computer Is Frozen",
        summary: "Safely restart a device that has stopped responding.",
        symbolName: "power",
        company: nil,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Give It a Moment",
                instruction: "Wait about 30 seconds. Sometimes a device is just busy finishing an update or a large download."
            ),
            WorkflowStep(
                title: "Close the Stuck App",
                instruction: "If only one app is frozen, close it. On a phone, swipe it away from the app switcher; on a computer, use Force Quit or Task Manager."
            ),
            WorkflowStep(
                title: "Force a Restart",
                instruction: "If the whole device is stuck, hold the power button until it turns off, then turn it back on. On newer iPhones, quickly press volume up, volume down, then hold the side button.",
                jargonTerms: ["Force Restart"]
            ),
            WorkflowStep(
                title: "Install Updates Once It's Back",
                instruction: "After it restarts, check for software updates. Many freezes are bugs that an update already fixes.",
                jargonTerms: ["Software Update"],
                xpValue: 15
            )
        ]
    )

    // MARK: Google — Very Easy / Easy

    static let googleAccountRecovery = Workflow(
        title: "Get Back Into Your Google Account",
        summary: "Recover a Gmail or Google account when you can't sign in.",
        symbolName: "person.badge.key.fill",
        company: .google,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open Google's Recovery Page",
                instruction: "On a device you've used before, go to g.co/recover. Google trusts familiar devices and locations more, which helps your chances.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Enter Your Email or Phone",
                instruction: "Type the Gmail address or phone number on the account, then follow the prompts."
            ),
            WorkflowStep(
                title: "Answer What You Can",
                instruction: "Google may ask for an old password, send a code to your recovery phone or email, or ask a question. If you're unsure, give your best guess instead of skipping.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Set a New Password",
                instruction: "Once you're in, choose a new password you don't use anywhere else, and save it in a password manager.",
                jargonTerms: ["Password Manager"],
                xpValue: 15
            )
        ]
    )

    static let googleChangePassword = Workflow(
        title: "Change Your Google Password",
        summary: "Swap in a new password when you think someone might know your old one.",
        symbolName: "key.horizontal.fill",
        company: .google,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open Your Google Account",
                instruction: "Go to myaccount.google.com and sign in, or open Gmail, tap your profile picture, and choose Manage your Google Account."
            ),
            WorkflowStep(
                title: "Find the Password Setting",
                instruction: "Open the Security section and look under How you sign in to Google for Password."
            ),
            WorkflowStep(
                title: "Enter the New Password",
                instruction: "Confirm your current password, then type a new one twice. Long and unique beats short and clever.",
                jargonTerms: ["Password Manager"]
            ),
            WorkflowStep(
                title: "Sign Out Anywhere Unfamiliar",
                instruction: "Still in Security, open Your devices and sign out of any phone or computer you don't recognize.",
                jargonTerms: ["Active Session"],
                xpValue: 15
            )
        ]
    )

    static let googleSecurityCheckup = Workflow(
        title: "Run a Google Security Checkup",
        summary: "Let Google walk you through the settings that keep your account safe.",
        symbolName: "checkmark.shield.fill",
        company: .google,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Start the Checkup",
                instruction: "Go to myaccount.google.com/security-checkup. Google shows a short list of items with a green check or a warning icon."
            ),
            WorkflowStep(
                title: "Fix Anything Yellow or Red",
                instruction: "Tap each warning and follow its suggestion. Most fixes take a single tap, like removing an old device."
            ),
            WorkflowStep(
                title: "Review Third-Party Access",
                instruction: "Look at which apps and sites can use your Google account. Remove any you don't recognize or no longer use."
            ),
            WorkflowStep(
                title: "Turn On 2-Step Verification",
                instruction: "If the checkup suggests it, turn on 2-Step Verification so a stolen password alone can't get anyone in.",
                jargonTerms: ["Two-Factor Authentication"],
                xpValue: 15
            )
        ]
    )

    static let googleRecoveryInfo = Workflow(
        title: "Add a Recovery Phone and Email",
        summary: "Make sure Google can reach you if you ever get locked out.",
        symbolName: "phone.badge.checkmark",
        company: .google,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Security Settings",
                instruction: "Go to myaccount.google.com, open Security, and find the section about how you sign in to Google."
            ),
            WorkflowStep(
                title: "Add a Recovery Phone",
                instruction: "Choose Recovery phone and add a mobile number you'll still have years from now. Google will text a code to confirm it.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Add a Recovery Email",
                instruction: "Choose Recovery email and add a different address from the one you're protecting, like a work or family email.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Double-Check Both",
                instruction: "Make sure neither is an old number or an email you can't open anymore. Outdated recovery info is the most common reason recovery fails.",
                xpValue: 15
            )
        ]
    )

    static let googleStorageCleanup = Workflow(
        title: "Free Up Google Storage Space",
        summary: "Clear room in Gmail, Drive, and Photos when Google says you're almost out of space.",
        symbolName: "externaldrive.fill",
        company: .google,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "See What's Using Space",
                instruction: "Go to one.google.com/storage. You'll see how much Gmail, Drive, and Photos each use, since they all share one storage total.",
                jargonTerms: ["Storage Quota"]
            ),
            WorkflowStep(
                title: "Clean Up Large Items",
                instruction: "Use the clean-up tool on that page to review big files, large email attachments, and blurry photos."
            ),
            WorkflowStep(
                title: "Empty the Trash",
                instruction: "Deleted items can keep counting until they leave the trash. Empty the trash in Gmail, Drive, and Photos to get the space back."
            ),
            WorkflowStep(
                title: "Download Before Deleting",
                instruction: "If something matters, download a copy to your computer or an external drive before removing it from Google.",
                jargonTerms: ["3-2-1 Backup Rule"],
                xpValue: 15
            )
        ]
    )

    static let googleLostDeviceSignOut = Workflow(
        title: "Sign Out of Google on a Lost Phone",
        summary: "Cut off access to your Google account from a phone or computer you no longer have.",
        symbolName: "iphone.slash",
        company: .google,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Your Devices",
                instruction: "On another device, go to myaccount.google.com, open Security, and choose Your devices or Manage all devices."
            ),
            WorkflowStep(
                title: "Pick the Lost Device",
                instruction: "Find the phone or computer in the list. The last-active time helps you tell similar devices apart.",
                jargonTerms: ["Active Session"]
            ),
            WorkflowStep(
                title: "Sign Out",
                instruction: "Choose Sign out. Google apps on that device will need your password again before anyone can use them."
            ),
            WorkflowStep(
                title: "Change Your Password Too",
                instruction: "If the device may be in someone else's hands, change your Google password as an extra safety step.",
                jargonTerms: ["Password Reset"],
                xpValue: 15
            )
        ]
    )

    // MARK: Apple — Very Easy / Easy

    static let appleAccountPasswordReset = Workflow(
        title: "Reset a Forgotten Apple Account Password",
        summary: "Get back into the account you use for the App Store, iCloud, and Find My.",
        symbolName: "key.fill",
        company: .apple,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Start on a Device You Own",
                instruction: "The fastest route is a device that's already signed in. On an iPhone, open Settings, tap your name, then Sign-In & Security, then Change Password."
            ),
            WorkflowStep(
                title: "Enter Your Passcode",
                instruction: "Type the passcode you use to unlock that device. It proves you're the owner, so Apple doesn't need to ask for the old password.",
                jargonTerms: ["Password Reset"]
            ),
            WorkflowStep(
                title: "No Device? Use the Web",
                instruction: "If you don't have a signed-in device, go to iforgot.apple.com on any browser and follow the steps there.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Sign In Everywhere Again",
                instruction: "After the change, your other Apple devices will ask for the new password. Enter it on each one so iCloud keeps syncing.",
                xpValue: 15
            )
        ]
    )

    static let appleFindLostIphone = Workflow(
        title: "Find a Lost iPhone",
        summary: "Locate, lock, or play a sound on a missing iPhone with Find My.",
        symbolName: "location.circle.fill",
        company: .apple,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open Find My",
                instruction: "Use the Find My app on another Apple device, or go to icloud.com/find on any computer and sign in.",
                jargonTerms: ["Find My"]
            ),
            WorkflowStep(
                title: "Select Your iPhone",
                instruction: "Choose your iPhone from the device list to see it on a map. If it's nearby, tap Play Sound."
            ),
            WorkflowStep(
                title: "Mark It as Lost",
                instruction: "If it's truly missing, choose Mark as Lost. This locks it and shows a message with a number someone can call to return it."
            ),
            WorkflowStep(
                title: "Erase Only as a Last Step",
                instruction: "Erasing protects your data but also stops you from tracking it. Wait until you're sure it won't be found before choosing Erase.",
                xpValue: 15
            )
        ]
    )

    static let appleUpdateIphone = Workflow(
        title: "Update Your iPhone",
        summary: "Install the latest iOS so you get Apple's newest security fixes.",
        symbolName: "arrow.down.circle.fill",
        company: .apple,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Plug In and Join Wi-Fi",
                instruction: "Connect your iPhone to a charger and to Wi-Fi. Updates are large and need some battery to install safely."
            ),
            WorkflowStep(
                title: "Check for the Update",
                instruction: "Open Settings, tap General, then Software Update. Your iPhone checks automatically and shows any update that's available.",
                jargonTerms: ["Software Update"]
            ),
            WorkflowStep(
                title: "Install It",
                instruction: "Tap Update Now, enter your passcode, and leave the phone alone while it restarts. This can take a little while."
            ),
            WorkflowStep(
                title: "Turn On Automatic Updates",
                instruction: "On the same screen, open Automatic Updates and turn the options on so future updates install overnight.",
                jargonTerms: ["Background Update"],
                xpValue: 15
            )
        ]
    )

    static let appleUnavailableIphone = Workflow(
        title: "My iPhone Says It's Unavailable",
        summary: "What to do after too many wrong passcode tries lock your iPhone.",
        symbolName: "lock.iphone",
        company: .apple,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Wait Out the Timer",
                instruction: "After several wrong tries, the iPhone makes you wait before trying again. If you're sure you now remember the passcode, wait for the timer and try once more."
            ),
            WorkflowStep(
                title: "Tap Forgot Passcode",
                instruction: "If you can't remember it, look at the bottom of the lock screen for Forgot Passcode and tap it."
            ),
            WorkflowStep(
                title: "Reset With Your Apple Account",
                instruction: "Enter your Apple Account password to erase and reset the iPhone. This removes everything on the phone, which is why the next step matters.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Restore From Your Backup",
                instruction: "During setup, choose to restore from your iCloud backup so your photos, messages, and apps come back.",
                jargonTerms: ["Cloud Backup"],
                xpValue: 15
            )
        ]
    )

    static let appleIcloudBackup = Workflow(
        title: "Back Up Your iPhone to iCloud",
        summary: "Make sure a lost or broken phone never means lost photos and messages.",
        symbolName: "icloud.and.arrow.up.fill",
        company: .apple,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open iCloud Settings",
                instruction: "Open Settings, tap your name at the top, then tap iCloud.",
                jargonTerms: ["iCloud Account"]
            ),
            WorkflowStep(
                title: "Turn On iCloud Backup",
                instruction: "Tap iCloud Backup and switch on Back Up This iPhone. It runs on its own when the phone is charging, locked, and on Wi-Fi.",
                jargonTerms: ["Cloud Backup"]
            ),
            WorkflowStep(
                title: "Run the First Backup Now",
                instruction: "Tap Back Up Now and keep the phone on Wi-Fi until it finishes."
            ),
            WorkflowStep(
                title: "Check You Have Room",
                instruction: "If iCloud says there isn't enough space, either clear out old backups and files or choose a larger iCloud+ plan.",
                jargonTerms: ["Storage Quota"],
                xpValue: 15
            )
        ]
    )

    static let appleRecoveryContact = Workflow(
        title: "Add a Recovery Contact",
        summary: "Pick someone you trust who can help you get back into your Apple Account.",
        symbolName: "person.2.fill",
        company: .apple,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Account Recovery",
                instruction: "Open Settings, tap your name, tap Sign-In & Security, then Account Recovery."
            ),
            WorkflowStep(
                title: "Add a Contact",
                instruction: "Tap Add Recovery Contact and choose a family member or close friend who also uses an Apple device.",
                jargonTerms: ["Recovery Contact"]
            ),
            WorkflowStep(
                title: "Let Them Know",
                instruction: "Apple sends them a message to accept. Tell them to expect it, so they don't mistake it for spam."
            ),
            WorkflowStep(
                title: "How It Helps Later",
                instruction: "If you're ever locked out, your contact can show you a code on their device. They never get access to your account or data.",
                jargonTerms: ["Verification Code"],
                xpValue: 15
            )
        ]
    )

    // MARK: Microsoft — Very Easy / Easy

    static let microsoftPasswordReset = Workflow(
        title: "Reset Your Microsoft Account Password",
        summary: "Get back into Outlook, Hotmail, OneDrive, Xbox, or Windows sign-in.",
        symbolName: "key.fill",
        company: .microsoft,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open the Reset Page",
                instruction: "Go to account.live.com/password/reset, or choose Forgot password on any Microsoft sign-in screen.",
                jargonTerms: ["Password Reset"]
            ),
            WorkflowStep(
                title: "Enter Your Account",
                instruction: "Type the email, phone number, or Skype name you use to sign in."
            ),
            WorkflowStep(
                title: "Get a Security Code",
                instruction: "Choose where Microsoft should send a code, like your phone or a backup email, then type the code in.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Choose a New Password",
                instruction: "Pick a new password you don't use anywhere else. Your Windows PC may ask for it the next time it starts if you sign in with this account.",
                xpValue: 15
            )
        ]
    )

    static let microsoftLockedOutRecovery = Workflow(
        title: "Recover a Locked Outlook or Hotmail Account",
        summary: "Use Microsoft's recovery form when you can't get a reset code.",
        symbolName: "envelope.badge.shield.half.filled",
        company: .microsoft,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open the Recovery Form",
                instruction: "If you can't receive any security code, go to account.live.com/acsr to start Microsoft's account recovery form.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Give a Contact Email",
                instruction: "Enter an email address you can open right now, different from the locked one. Microsoft uses it to reach you about the request."
            ),
            WorkflowStep(
                title: "Share What You Remember",
                instruction: "Fill in as much as you can: old passwords, recent email subjects, people you've emailed. More detail gives the form a better chance."
            ),
            WorkflowStep(
                title: "Watch for the Reply",
                instruction: "Microsoft replies to your contact email, usually within a day. If it's turned down, you can try the form again with more details.",
                xpValue: 15
            )
        ]
    )

    static let windowsUpdateRestart = Workflow(
        title: "Update and Restart Windows",
        summary: "Install the latest Windows fixes and clear up slowdowns with a proper restart.",
        symbolName: "arrow.triangle.2.circlepath",
        company: .microsoft,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Save Your Work",
                instruction: "Save and close anything you have open. Windows needs to restart to finish most updates."
            ),
            WorkflowStep(
                title: "Open Windows Update",
                instruction: "Open the Start menu, choose Settings, then Windows Update, and select Check for updates.",
                jargonTerms: ["Software Update"]
            ),
            WorkflowStep(
                title: "Install and Restart",
                instruction: "Let the updates download, then choose Restart now. Keep a laptop plugged in until it's back on the desktop."
            ),
            WorkflowStep(
                title: "Restart Weekly Even Without Updates",
                instruction: "Choosing Restart, not Shut down, gives Windows a full fresh start and often fixes slowness on its own.",
                xpValue: 15
            )
        ]
    )

    static let windowsFindMyDevice = Workflow(
        title: "Find a Lost Windows Laptop",
        summary: "Turn on Find my device now so you can locate or lock your laptop later.",
        symbolName: "laptopcomputer",
        company: .microsoft,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Turn It On Before You Need It",
                instruction: "On the laptop, open Settings, then Privacy & security, then Find my device, and switch it on. You must be signed in with a Microsoft account.",
                jargonTerms: ["Find My"]
            ),
            WorkflowStep(
                title: "Check Location Is On",
                instruction: "Find my device needs location services turned on. Windows will point you to the setting if it's off."
            ),
            WorkflowStep(
                title: "Locate It From Any Browser",
                instruction: "If the laptop goes missing, go to account.microsoft.com/devices, sign in, and choose Find my device for that laptop."
            ),
            WorkflowStep(
                title: "Lock It Remotely",
                instruction: "From the same page you can lock the laptop and show a message, which keeps your files safe while you track it down.",
                xpValue: 15
            )
        ]
    )

    static let microsoftTwoStepSetup = Workflow(
        title: "Turn On Two-Step Verification for Microsoft",
        summary: "Add a second check to your Outlook, OneDrive, and Xbox sign-in.",
        symbolName: "lock.shield.fill",
        company: .microsoft,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Your Security Page",
                instruction: "Go to account.microsoft.com, sign in, and open the Security section."
            ),
            WorkflowStep(
                title: "Find Two-Step Verification",
                instruction: "Look for the option to manage how you sign in, then find Two-step verification and choose to turn it on.",
                jargonTerms: ["Two-Step Verification"]
            ),
            WorkflowStep(
                title: "Pick Your Second Check",
                instruction: "Choose an authenticator app if you can; it works even without phone signal. A text message is a fine backup.",
                jargonTerms: ["Authenticator App"]
            ),
            WorkflowStep(
                title: "Save Your Recovery Code",
                instruction: "Microsoft shows a recovery code. Write it down or save it in your password manager in case you lose your phone.",
                jargonTerms: ["Backup Code"],
                xpValue: 15
            )
        ]
    )

    static let oneDriveFolderBackup = Workflow(
        title: "Back Up Your PC Folders to OneDrive",
        summary: "Keep Desktop, Documents, and Pictures safe if your computer breaks.",
        symbolName: "icloud.and.arrow.up.fill",
        company: .microsoft,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open OneDrive Settings",
                instruction: "Click the OneDrive cloud icon near the clock, select the gear icon, then Settings."
            ),
            WorkflowStep(
                title: "Manage Backup",
                instruction: "Open Sync and back up and choose Manage back up.",
                jargonTerms: ["Cloud Backup"]
            ),
            WorkflowStep(
                title: "Pick Your Folders",
                instruction: "Switch on Desktop, Documents, and Pictures, then choose Start backup. The files stay on your PC and also go to OneDrive."
            ),
            WorkflowStep(
                title: "Check Your Space",
                instruction: "Free OneDrive accounts have limited space. If backup stops, check your storage at onedrive.live.com and clear old files.",
                jargonTerms: ["Storage Quota"],
                xpValue: 15
            )
        ]
    )

    // MARK: Amazon — Very Easy / Easy

    static let amazonPasswordReset = Workflow(
        title: "Reset Your Amazon Password",
        summary: "Get back into your Amazon shopping account when your password stops working.",
        symbolName: "key.fill",
        company: .amazon,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Start Signing In",
                instruction: "Open the Amazon app or website, choose Sign in, and enter your email or mobile number."
            ),
            WorkflowStep(
                title: "Choose Forgot Password",
                instruction: "On the password screen, tap Forgot password or Need help, then follow the prompts.",
                jargonTerms: ["Password Reset"]
            ),
            WorkflowStep(
                title: "Enter the Code",
                instruction: "Amazon sends a one-time code to your email or phone. Type it in; never share it with anyone who calls or messages you.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Create a New Password",
                instruction: "Pick a password you don't use anywhere else, especially not for your email.",
                xpValue: 15
            )
        ]
    )

    static let amazonSpotFakeMessage = Workflow(
        title: "Spot a Fake Amazon Message",
        summary: "Check whether an Amazon email, text, or call is real before you act on it.",
        symbolName: "exclamationmark.bubble.fill",
        company: .amazon,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Don't Tap Links in the Message",
                instruction: "Scammers copy Amazon's look closely. Open the Amazon app yourself instead of tapping anything in the message.",
                jargonTerms: ["Phishing"]
            ),
            WorkflowStep(
                title: "Check Your Message Center",
                instruction: "In the app or website, open Your Account and look for Your Messages. Real messages from Amazon appear there too."
            ),
            WorkflowStep(
                title: "Check Your Orders",
                instruction: "If the message mentions an order, open Your Orders. If you don't see it there, the message is almost certainly fake."
            ),
            WorkflowStep(
                title: "Never Pay With Gift Cards",
                instruction: "Amazon won't ask you to pay by gift card, wire transfer, or over the phone to fix an account. Hang up and change your password if you already shared anything.",
                xpValue: 15
            )
        ]
    )

    static let amazonTrackReturnOrder = Workflow(
        title: "Track or Return an Amazon Order",
        summary: "See where a package is or send something back.",
        symbolName: "shippingbox.fill",
        company: .amazon,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open Your Orders",
                instruction: "In the Amazon app, tap the person icon, then Your Orders. On the website, choose Returns & Orders."
            ),
            WorkflowStep(
                title: "Track a Package",
                instruction: "Tap the order and choose Track package to see the delivery estimate and latest location."
            ),
            WorkflowStep(
                title: "Start a Return",
                instruction: "Choose Return or replace items, pick a reason, and select a drop-off option. Many locations accept returns without a box or label printer."
            ),
            WorkflowStep(
                title: "Watch for the Refund",
                instruction: "The order page shows the refund status. Card refunds can take several business days to appear after Amazon processes them.",
                xpValue: 15
            )
        ]
    )

    static let amazonTwoStepSetup = Workflow(
        title: "Turn On Two-Step Verification for Amazon",
        summary: "Stop someone with your password from ordering on your account.",
        symbolName: "lock.shield.fill",
        company: .amazon,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Login & Security",
                instruction: "Go to Your Account and choose Login & security. Amazon may ask you to sign in again."
            ),
            WorkflowStep(
                title: "Turn On 2-Step Verification",
                instruction: "Find 2-step verification and choose Turn on.",
                jargonTerms: ["Two-Step Verification"]
            ),
            WorkflowStep(
                title: "Add Your Phone or App",
                instruction: "Add a phone number for text codes, or scan the code with an authenticator app for a sturdier option.",
                jargonTerms: ["Authenticator App"]
            ),
            WorkflowStep(
                title: "Add a Backup Method",
                instruction: "Add a second phone number or app as a backup, so losing one phone never locks you out.",
                jargonTerms: ["Backup Code"],
                xpValue: 15
            )
        ]
    )

    static let amazonPrimeMembership = Workflow(
        title: "Check or Cancel Amazon Prime",
        summary: "See when Prime renews, what it costs, and how to stop it.",
        symbolName: "creditcard.fill",
        company: .amazon,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Prime Membership",
                instruction: "Go to Your Account and choose Prime or Prime Membership."
            ),
            WorkflowStep(
                title: "Check the Renewal Date",
                instruction: "The page shows your plan, price, and next renewal date, plus the card that will be charged.",
                jargonTerms: ["Auto-Renewal"]
            ),
            WorkflowStep(
                title: "Turn On a Reminder",
                instruction: "If you're unsure about renewing, look for the option to get a reminder before you're charged."
            ),
            WorkflowStep(
                title: "End Membership if You Want",
                instruction: "Choose End membership and follow each screen to the final confirmation. Amazon offers alternatives along the way, so read each button before tapping.",
                xpValue: 15
            )
        ]
    )

    static let alexaVoicePurchasing = Workflow(
        title: "Stop Accidental Alexa Orders",
        summary: "Keep kids or guests from buying things by voice.",
        symbolName: "mic.slash.fill",
        company: .amazon,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open the Alexa App",
                instruction: "Open the Amazon Alexa app on your phone and tap More."
            ),
            WorkflowStep(
                title: "Find Voice Purchasing",
                instruction: "Tap Settings, then Account Settings, then Voice Purchasing."
            ),
            WorkflowStep(
                title: "Add a Voice Code or Turn It Off",
                instruction: "Turn purchasing off completely, or set a spoken code that Alexa asks for before any order.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Check Your Orders",
                instruction: "If an order already slipped through, cancel it from Your Orders before it ships.",
                xpValue: 15
            )
        ]
    )

    // MARK: Facebook — Very Easy / Easy

    static let facebookPasswordReset = Workflow(
        title: "Reset Your Facebook Password",
        summary: "Get back into Facebook when you've forgotten your password.",
        symbolName: "key.fill",
        company: .facebook,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open the Find Your Account Page",
                instruction: "Go to facebook.com/login/identify, or tap Forgot password on the Facebook sign-in screen.",
                jargonTerms: ["Password Reset"]
            ),
            WorkflowStep(
                title: "Search for Your Account",
                instruction: "Enter the email, mobile number, or name on your account, then pick your profile from the results."
            ),
            WorkflowStep(
                title: "Get the Code",
                instruction: "Choose where Facebook should send a code and enter it. Codes from Facebook never come with a request to call anyone.",
                jargonTerms: ["Verification Code"]
            ),
            WorkflowStep(
                title: "Set a New Password",
                instruction: "Choose a new password and keep the option checked to log out of other devices, so anyone else gets kicked out.",
                jargonTerms: ["Active Session"],
                xpValue: 15
            )
        ]
    )

    static let facebookHackedRecovery = Workflow(
        title: "My Facebook Account Was Hacked",
        summary: "Take your account back after someone else got in.",
        symbolName: "exclamationmark.lock.fill",
        company: .facebook,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Go to the Hacked Page",
                instruction: "Go to facebook.com/hacked on any browser. It's Facebook's own tool for compromised accounts.",
                jargonTerms: ["Account Recovery"]
            ),
            WorkflowStep(
                title: "Say What Happened",
                instruction: "Pick the option that matches, like someone changed your password or posted things you didn't, and follow the steps."
            ),
            WorkflowStep(
                title: "Secure Your Email Too",
                instruction: "Change your email account's password as well. Hackers often get in through an email account that uses the same password."
            ),
            WorkflowStep(
                title: "Turn On Two-Factor Authentication",
                instruction: "Once you're back in, turn on two-factor authentication so this is much harder to repeat.",
                jargonTerms: ["Two-Factor Authentication"],
                xpValue: 15
            )
        ]
    )

    static let facebookWhereLoggedIn = Workflow(
        title: "See Where You're Logged In to Facebook",
        summary: "Find and sign out of phones and computers you don't recognize.",
        symbolName: "laptopcomputer.and.iphone",
        company: .facebook,
        level: .veryEasy,
        steps: [
            WorkflowStep(
                title: "Open Accounts Center",
                instruction: "Tap the menu, then Settings & privacy, then Settings, then Accounts Center."
            ),
            WorkflowStep(
                title: "Open Where You're Logged In",
                instruction: "Choose Password and security, then Where you're logged in.",
                jargonTerms: ["Active Session"]
            ),
            WorkflowStep(
                title: "Log Out of Unknown Devices",
                instruction: "Look at each device and place. Select any you don't recognize and choose Log out."
            ),
            WorkflowStep(
                title: "Change Your Password if Anything Was Wrong",
                instruction: "If you logged anything out, change your password right after so they can't simply sign back in.",
                jargonTerms: ["Password Reset"],
                xpValue: 15
            )
        ]
    )

    static let facebookPrivacyCheckup = Workflow(
        title: "Make Your Facebook Profile More Private",
        summary: "Choose who can see your posts, find you, and look you up.",
        symbolName: "eye.slash.fill",
        company: .facebook,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Privacy Checkup",
                instruction: "Tap the menu, then Settings & privacy, and look for Privacy Checkup.",
                jargonTerms: ["Privacy Checkup"]
            ),
            WorkflowStep(
                title: "Choose Who Sees Your Posts",
                instruction: "Pick the Who can see what you share topic and set future posts to Friends instead of Public."
            ),
            WorkflowStep(
                title: "Limit Who Can Find You",
                instruction: "In How people can find you, limit who can look you up by phone number or email."
            ),
            WorkflowStep(
                title: "Review Old Posts",
                instruction: "You can also limit the audience of older public posts in one step from the privacy settings.",
                xpValue: 15
            )
        ]
    )

    static let facebookTwoFactorSetup = Workflow(
        title: "Turn On Two-Factor Authentication for Facebook",
        summary: "Make sure a stolen password alone can't open your Facebook account.",
        symbolName: "lock.shield.fill",
        company: .facebook,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open Password and Security",
                instruction: "Go to Settings & privacy, then Settings, then Accounts Center, then Password and security."
            ),
            WorkflowStep(
                title: "Choose Two-Factor Authentication",
                instruction: "Select Two-factor authentication, then pick your Facebook account.",
                jargonTerms: ["Two-Factor Authentication"]
            ),
            WorkflowStep(
                title: "Pick a Method",
                instruction: "An authenticator app is the sturdiest choice. Text messages are easier but can be intercepted.",
                jargonTerms: ["Authenticator App"]
            ),
            WorkflowStep(
                title: "Save Your Recovery Codes",
                instruction: "Facebook offers backup recovery codes. Save them somewhere safe in case you lose your phone.",
                jargonTerms: ["Backup Code"],
                xpValue: 15
            )
        ]
    )

    static let facebookReportImpersonation = Workflow(
        title: "Report a Fake Account Pretending to Be You",
        summary: "Get a copycat profile using your name and photos taken down.",
        symbolName: "theatermasks.fill",
        company: .facebook,
        level: .easy,
        steps: [
            WorkflowStep(
                title: "Open the Fake Profile",
                instruction: "Go to the profile that's pretending to be you. Don't message or friend it.",
                jargonTerms: ["Impersonation"]
            ),
            WorkflowStep(
                title: "Report the Profile",
                instruction: "Tap the three dots on the profile, choose Report profile, then pick the option saying they're pretending to be someone."
            ),
            WorkflowStep(
                title: "Say It's You",
                instruction: "When asked who they're pretending to be, choose Me. Facebook reviews these reports and removes accounts that break its rules."
            ),
            WorkflowStep(
                title: "Warn Your Friends",
                instruction: "Post or message friends that a fake account exists and ask them to report it too, and not to send it money or codes.",
                xpValue: 15
            )
        ]
    )

    /// Every beginner guide, in display order. Merged into
    /// `WorkflowLibrary.all` so search, progress, and badges count them
    /// like any other guide.
    static let beginnerGuides: [Workflow] = [
        forgotPasswordBasics, loginCodeMissing, spotPhishingBasics,
        wifiNotLoadingBasics, storageFullBasics, frozenDeviceBasics,

        googleAccountRecovery, googleChangePassword, googleSecurityCheckup,
        googleRecoveryInfo, googleStorageCleanup, googleLostDeviceSignOut,

        appleAccountPasswordReset, appleFindLostIphone, appleUpdateIphone,
        appleUnavailableIphone, appleIcloudBackup, appleRecoveryContact,

        microsoftPasswordReset, microsoftLockedOutRecovery, windowsUpdateRestart,
        windowsFindMyDevice, microsoftTwoStepSetup, oneDriveFolderBackup,

        amazonPasswordReset, amazonSpotFakeMessage, amazonTrackReturnOrder,
        amazonTwoStepSetup, amazonPrimeMembership, alexaVoicePurchasing,

        facebookPasswordReset, facebookHackedRecovery, facebookWhereLoggedIn,
        facebookPrivacyCheckup, facebookTwoFactorSetup, facebookReportImpersonation,
    ]
}
