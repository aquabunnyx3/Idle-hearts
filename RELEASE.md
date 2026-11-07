# Shipping Idle Hearts to TestFlight and the App Store

Everything in the repo is already set up for release: app icon, launch screen,
privacy manifest, export-compliance flag, portrait-only iPhone build, privacy
and support pages, and a GitHub Actions workflow that uploads to TestFlight.
What's left are the steps only you can do with your Apple account.

## 1. One-time Apple setup (≈15 minutes)

1. **Join the Apple Developer Program** ($99/yr) at <https://developer.apple.com/programs/> if you haven't.
2. **Pick your bundle ID.** The project uses `com.aquabunnyx3.idlehearts`. Bundle IDs are global, so if
   that one is taken, change `PRODUCT_BUNDLE_IDENTIFIER` in Xcode (target → Signing & Capabilities).
3. **Create the app record** in [App Store Connect](https://appstoreconnect.apple.com) → Apps → **+** → New App:
   - Platform: iOS · Name: **Idle Hearts** (or a variant if taken, e.g. "Idle Hearts: Matchmaker")
   - Primary language: English (U.S.) · Bundle ID: the one above · SKU: `idlehearts001`
4. **Turn on GitHub Pages** so the privacy/support URLs work: repo → Settings → Pages →
   Source *Deploy from a branch* → `main` / `/docs`. URLs become
   `https://aquabunnyx3.github.io/idle-hearts/privacy.html` and `.../support.html`
   (these are already wired into the in-game Settings screen).

## 2a. Upload from Xcode (simplest)

1. Open `IdleHearts.xcodeproj` in **Xcode 26 or newer** (App Store uploads require the iOS 26 SDK).
2. Select the **IdleHearts** target → *Signing & Capabilities* → tick *Automatically manage signing* → choose your **Team**.
3. Run it on your iPhone once (⌘R) to sanity-check.
4. Choose **Any iOS Device (arm64)** as the destination → **Product ▸ Archive**.
5. In the Organizer: **Distribute App ▸ App Store Connect ▸ Upload**. Accept the defaults.
6. Before each new upload, bump **Build** (`CURRENT_PROJECT_VERSION`) by 1.

## 2b. Upload from GitHub Actions (no Mac needed after setup)

1. App Store Connect → Users and Access → **Integrations ▸ App Store Connect API** → generate a key with
   **Admin** access (needed for cloud signing). Download the `.p8` (you only get one chance).
2. In GitHub → Settings → Secrets and variables → Actions, add:

   | Secret | Value |
   |---|---|
   | `APPLE_TEAM_ID` | your 10-character Team ID (developer.apple.com/account → Membership) |
   | `ASC_KEY_ID` | the key ID shown next to the key |
   | `ASC_ISSUER_ID` | the Issuer ID at the top of the keys page |
   | `ASC_KEY_P8_BASE64` | output of `base64 -i AuthKey_XXXXXX.p8` |

   Optional variable `BUNDLE_ID` if you changed the bundle ID.
3. Actions tab → **TestFlight** → *Run workflow* (or push a tag such as `v1.0.0`).
   The build number is the workflow run number, so it always increases.

## 3. TestFlight

- After upload, the build shows under **TestFlight** once processing finishes (5–30 min).
- **Internal testing** (up to 100 people on your team): add yourself → install the *TestFlight* app on iPhone → accept.
- **External testing** (up to 10,000 by email or public link) needs a quick Beta App Review; fill in
  *Test Information* (feedback email, what to test — use the text in `docs/APP_STORE.md`).

## 4. Submit for App Store review

In App Store Connect → your app → the 1.0 version:

1. **Screenshots** – 6.9" iPhone screenshots are required. Generate them on a Mac with
   `scripts/screenshots.sh` (writes to `screenshots/`), or use the ones CI commits to the
   `ci/macos-26` branch. Upload 01–05.
2. **Text** – paste name, subtitle, promotional text, description and keywords from `docs/APP_STORE.md`.
3. **URLs** – Support URL and Privacy Policy URL from step 1.4.
4. **App Privacy** – answer *"No, we do not collect data from this app."*
5. **Age rating** – questionnaire answers are in `docs/APP_STORE.md` (results in 9+ / 12+ depending on the
   "mild romance" answer — choose honestly).
6. **Pricing** – Free. **Category** – Games ▸ Simulation (secondary: Casual).
7. Select the build, then **Add for Review ▸ Submit**. First reviews usually take 1–3 days.

## Release checklist

- [ ] Signing team set, bundle ID registered
- [ ] Builds and runs on a physical iPhone
- [ ] GitHub Pages enabled; privacy & support pages load
- [ ] Version 1.0, build number bumped
- [ ] Screenshots uploaded (6.9")
- [ ] Description, keywords, URLs, age rating, App Privacy filled in
- [ ] Internal TestFlight pass: first date completes, hiring works, progress survives a force-quit,
      Welcome Back appears after 2+ minutes away
