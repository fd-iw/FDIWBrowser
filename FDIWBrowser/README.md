# FDIW Browser

A small WKWebView browser for iOS. Deployment target **iOS 15.0**, so it runs fine on 15.8.x.

Features: address bar with search fallback, back/forward/home/reload/stop, share sheet,
load progress bar, swipe-back gestures, `tel:` / `mailto:` handoff, `target="_blank"` handling.

---

## Why there's no prebuilt .ipa in this zip

An `.ipa` contains a compiled ARM64 Mach-O binary. Producing one requires Apple's iOS SDK,
which only runs on macOS. There is no Linux or Windows path around this — every
"cross-platform" option (Flutter, React Native, Capacitor) still shells out to Xcode on a Mac
at the final step.

So: this repo builds the `.ipa` for you on a free GitHub-hosted Mac.

---

## Path A — build on GitHub Actions (no Mac needed)

1. Create a new **public** repo on GitHub (public = free macOS runner minutes).
2. Push these files to it:
   ```
   git init
   git add .
   git commit -m "FDIW Browser"
   git branch -M main
   git remote add origin https://github.com/YOURNAME/fdiw-browser.git
   git push -u origin main
   ```
3. Go to the **Actions** tab. The `Build unsigned IPA` job runs automatically (~3 min).
4. Download the `FDIWBrowser-unsigned-ipa` artifact. Unzip it — inside is
   `FDIWBrowser-unsigned.ipa`.

That `.ipa` is unsigned, which is what you want: sideloading tools sign it with your own
Apple ID.

## Path B — build on a Mac

```
chmod +x build_mac.sh
./build_mac.sh
```

Or just `xcodegen generate`, open `FDIWBrowser.xcodeproj`, set your team under
Signing & Capabilities, and hit Run with your iPhone plugged in.

---

## Installing on your iPhone

Pick one, on Windows:

| Tool | Notes |
|---|---|
| **Sideloadly** | Simplest. Plug in phone, drag the `.ipa`, enter Apple ID, click Start. |
| **AltStore Classic** | Needs AltServer running on the PC; auto-refreshes apps over Wi-Fi. |

Then on the phone: **Settings → General → VPN & Device Management → your Apple ID → Trust**.

### The 7-day thing

A free Apple ID signs apps for **7 days**, then the app stops opening until you re-sign it.
AltStore refreshes automatically while it's on the same Wi-Fi as your PC. A paid Apple
Developer account ($99/yr) extends this to a year and lifts the 3-apps-at-a-time cap.

---

## Customizing

- **Home page / search engine** — top of `Sources/BrowserViewController.swift`
  (`homeURL` and `searchTemplate`).
- **App name** — `CFBundleDisplayName` in `project.yml`.
- **Bundle ID** — change `cc.fdiw.browser` in `project.yml` if it collides with something
  already on your device.
- **App icon** — add an `Assets.xcassets` with an `AppIcon` set, then add
  `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` under `settings.base` in `project.yml`.

## Note on iOS browsers

Apple requires third-party browsers to use WebKit, so `WKWebView` is the correct and only
engine here. Rendering will match Safari.
