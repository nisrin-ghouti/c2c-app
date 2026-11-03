# iOS App Store Release — Handoff Notes

**Last updated:** 2026-08-30
**Purpose:** Context for resuming the iOS App Store submission after a macOS/Xcode upgrade.

---

## CLOUD iOS BUILD (no local Mac) — Codemagic

`c2c-app` is **not** a git repo / not on GitHub yet (unlike `c2c-admin` /
`c2c-landing` under `nisrin-ghouti`). Codemagic needs a remote to clone.

Config checked in: `codemagic.yaml`

Workflows:
- `ios-testflight` — signed IPA + upload to TestFlight (auto bump build number)
- `ios-ipa-only` — signed IPA artifact only

One-time setup:
1. `git init` + create `nisrin-ghouti/c2c-app` on GitHub + push (do **not** commit `.env`)
2. [codemagic.io](https://codemagic.io) → add the repo → use `codemagic.yaml`
3. Team → Integrations → App Store Connect API key named **`Nesrin Gouti ASC`**
   (App Manager). Nesrin (Account Holder) may need to create the key.
4. App → Environment variables → group **`c2c_secrets`**: `SUPABASE_URL`,
   `SUPABASE_ANON_KEY` (Secret)
5. Start build → workflow `ios-testflight`

Xcode on Codemagic is pinned to **26.6** (iOS 26.5 SDK) — same bar as Apple’s
upload rule. This bypasses the local “iOS 26.5 Platform Not Installed” blocker.

---

## WHERE WE ARE RIGHT NOW (2026-08-30)

The macOS/Xcode upgrade is **DONE**. Current toolchain:

| | |
|---|---|
| macOS | **26.6.2** (build 25G83) |
| Xcode | **26.6** (build 17F113) |
| iOS SDK | **26.5** — satisfies Apple's iOS 26 SDK requirement |
| Flutter | 3.44.8 stable / Dart 3.12.2 |

`xcode-select` already points at `/Applications/Xcode.app/Contents/Developer`
and `xcodebuild -checkFirstLaunchStatus` exits 0, so **steps 1-2 of the old
plan need no sudo and are already satisfied.**

Completed this session:
- `flutter clean` + `flutter pub get` + `pod install` (15 pods, SPM still ON) — OK
- All 7 previously-applied fixes verified still intact after the clean
  (macOS paths in `Generated.xcconfig`, deployment target 15.0, both usage
  descriptions, display name `C2C`, `ITSAppUsesNonExemptEncryption` still unset)
- `xcodebuild -downloadPlatform iOS` — installed the iOS 26.5 **Simulator**
  runtime (8.52 GB). This made `Any iOS Device` an eligible destination and
  fixed the first archive failure.

### CURRENT BLOCKER — missing Xcode device-support component

`flutter build ipa` now gets through code signing (team `8LU3CPL2YU`, identity
"Apple Development: Nesrin Gouti") and runs a 36s archive, then fails at
storyboard compilation:

```
Error (Xcode): iOS 26.5 Platform Not Installed.
ios/Runner/Base.lproj/Main.storyboard
```

**This is NOT a project bug and NOT a stale-cache problem.** Verified by running
`ibtool` standalone, with no Flutter and no project build involved:

```bash
xcrun --sdk iphoneos ibtool --target-device iphone --minimum-deployment-target 15.0 \
  --compile /tmp/out.storyboardc ios/Runner/Base.lproj/Main.storyboard
# -> "iOS 26.5 Platform Not Installed."
```

Note `-downloadPlatform iOS` only supplied the *simulator* runtime; `ibtool`
needs the *device* platform support, which is a separate component.
`-downloadComponent` cannot fetch it (it only supports `MetalToolchain`).

**THE FIX (requires the user's password — an assistant cannot run it):**

```bash
sudo xcodebuild -runFirstLaunch -checkForNewerComponents
```

The `-checkForNewerComponents` flag is the essential part; plain `-runFirstLaunch`
finds nothing to do because `-checkFirstLaunchStatus` already passes.
GUI equivalent: **Xcode → Settings → Components**, install the iOS platform entry.

Then simply re-run:

```bash
cd /Users/may.massalha/projects/c2c-app && flutter build ipa
```

> **Gotcha for whoever resumes:** do NOT run `flutter build ipa | tail -n`.
> The pipe masks the exit status and a failed build reports exit 0. Redirect to
> a log and check `$?` instead.

---

## ORIGINAL CONTEXT (resolved — kept for history)

The app built and signed correctly and an IPA was submitted to Apple.
Apple **rejected the upload** for one reason only:

```
SDK version issue. This app was built with the iOS 18.5 SDK. All iOS and iPadOS
apps must be built with the iOS 26 SDK or later, included in Xcode 26 or later,
in order to be uploaded to App Store Connect or submitted for distribution.
```

This is an Apple **policy check enforced server-side**. Not a project bug.
Nothing in the code needs to change — it only needs to be rebuilt with a newer SDK.

### The blocking chain
- Machine: MacBook Pro, Apple M4 Pro (Mac16,8), 24GB
- macOS was **15.5 Sequoia** → too old for Xcode 26
- Xcode was **16.4** (iOS 18.5 SDK) → too old for App Store uploads
- Fix: upgrade to **macOS Tahoe 26.6.2** (~9.9GB), then **Xcode 26+** (~15-20GB)

---

## NEXT STEPS AFTER THE UPGRADE *(superseded — steps 1-3 are done, see top)*

Run these in order. (An assistant with terminal access can run all of them.)

```bash
# 1. Point the toolchain at the updated Xcode (needs user's password)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 2. Confirm the SDK is now iOS 26+
xcodebuild -version
xcodebuild -showsdks | grep -i ios

# 3. Clean rebuild
cd /Users/may.massalha/projects/c2c-app
flutter clean && flutter pub get
cd ios && pod install && cd ..

# 4. Build the IPA
flutter build ipa
```

Then upload `build/ios/ipa/c2c.ipa` via **Transporter** (already installed) and click Deliver.

**Note:** build number `1` was never accepted by Apple (rejected before registering),
so `1.0.0+1` can be reused. No need to bump the version.

**Known issue that may resurface:** if Xcode shows "Unsupported Swift architecture"
errors, the fix is deleting stale caches with Xcode fully quit:
```bash
osascript -e 'quit app "Xcode"'
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## KEY PROJECT FACTS

| Item | Value |
|---|---|
| Project path | `/Users/may.massalha/projects/c2c-app` |
| Bundle ID | `com.c2c.connecttocollect` |
| Team ID | `8LU3CPL2YU` ("Nesrin Gouti") |
| App Store Connect App ID | `6806632645` |
| Version / build | `1.0.0` / `1` |
| Min iOS version | **15.0** (forced by Firebase) |
| Signing | Automatic |

### Account situation — IMPORTANT
- The paid ($99/yr) Apple Developer account belongs to **Nesrin Gouti**, not May.
- May's role is **Admin**, NOT Account Holder.
- **Consequence:** May cannot accept App Store agreements. Only Nesrin can.
  This already blocked progress once (the "Agree" button silently did nothing).
- Anything Account-Holder-only (agreement updates, Paid Apps agreement,
  tax/banking) must be done by Nesrin.

---

## FIXES ALREADY APPLIED (do not redo)

1. **Missing `ios/Podfile`** — was absent entirely; regenerated via `flutter create --platforms=ios .`
2. **Windows paths in `ios/Flutter/Generated.xcconfig`** — contained
   `C:\Users\essag\develop\flutter` left over from a Windows machine during a
   project merge. Regenerated for macOS.
3. **iOS deployment target 13.0 → 15.0** — Firebase requires 15.0.
   Changed in both `ios/Runner.xcodeproj/project.pbxproj` and `ios/Podfile`.
4. **Missing `NSPhotoLibraryUsageDescription` in Info.plist** — the app calls
   `ImageSource.gallery` in `avatar_picker.dart:50` and
   `event_create_edit_screen.dart:268`. Without this key iOS **terminates the app**
   on launch of the picker, and App Review rejects it. Added.
5. **Display name `C2c` → `C2C`** — cosmetic typo in `CFBundleDisplayName`.
6. **Device registered** in the developer portal (was blocking profile generation).
7. **App record created** in App Store Connect.

### Do NOT disable Swift Package Manager
It was tried and it fails: `firebase_messaging` and `mobile_scanner` have an
unresolvable `GoogleDataTransport` version conflict under CocoaPods alone.
The project needs the hybrid SPM + CocoaPods setup. Keep
`flutter config --enable-swift-package-manager` ON.

---

## KNOWN NON-BLOCKING ISSUES

- **iOS Simulator builds fail** with "unsupported Swift architecture".
  Cause: `EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386 arm64` in
  `ios/Flutter/Generated.xcconfig` excludes arm64, forcing an x86_64 slice on
  Apple Silicon while Swift modules are arm64-only.
  **Does not affect device/App Store builds.** Use `flutter run` (works fine) or
  the "Any iOS Device" destination in Xcode. Unfixed — cosmetic/dev-only.
- Warnings that `flutter_secure_storage` and `mobile_scanner` don't support SPM
  are harmless; CocoaPods handles them.

---

## STILL TO DO AFTER UPLOAD SUCCEEDS

Required before submitting for review in App Store Connect:
- Screenshots (6.7" iPhone minimum)
- Description, keywords, support URL
- **Privacy Policy URL** (required)
- **App Privacy questionnaire** — app collects email, name, profile info;
  uses camera (QR scanning) and push notifications. Must be declared honestly.
- Age rating
- **Export compliance** — will be asked whether the app uses encryption.
  `ITSAppUsesNonExemptEncryption` was deliberately NOT set, because it's a legal
  declaration the owner should make. Apps using only HTTPS normally answer "No"
  to non-exempt encryption.

---

## SEPARATE UNRESOLVED THREAD

Earlier work (unrelated to iOS release): a "login by code" email failure was traced
to the domain `c2c-connect2collect.com` being suspended at Namecheap over unverified
WHOIS contact info, which broke DNS and caused Resend to reject all outbound Supabase
Auth emails. DNS was restored with correct SPF/DKIM/DMARC records, but **Resend may
still need to re-verify the domain**. Final status unconfirmed.
