# TempCam Play Store First Release Guide

This guide is the exact order to follow for your first Android release of TempCam.

## 1. Final Product Facts

- Package name: `com.tempcam`
- Subscription product ID in code: `tempcam_premium_yearly`
- Price target: `$3.00 / year`
- Billing model: one auto-renewing yearly subscription

Important:
- The Play Console subscription product ID must exactly match `tempcam_premium_yearly`.
- If you change the product ID in Play Console, you must also change it in `lib/src/core/constants/premium_constants.dart`.

## 2. Create Your Upload Keystore

Run this in a terminal:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then:

1. Move `upload-keystore.jks` to the project root or another safe local path.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Fill `android/key.properties` with your real values.

Example:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../../upload-keystore.jks
```

Never commit `android/key.properties` or your real keystore to Git.

## 3. Prepare Public Legal Pages

Before Play submission, host these on a public HTTPS URL:

- `docs/privacy-policy.html`
- `docs/subscription-terms.html`

Good options:

- GitHub Pages
- Notion public page
- your own website

Google Play requires a public privacy policy URL.
For subscriptions, keep terms text accessible inside the app too.

## 4. Create the App in Play Console

In Play Console:

1. Create the app entry.
2. Set app name, default language, and app type.
3. Complete store listing assets.
4. Complete App content.
5. Complete Data safety.
6. Add the public privacy policy URL.
7. Keep your subscription terms URL ready for in-app legal access.

## 5. Create the Subscription

In Play Console:

1. Go to `Monetize with Play > Products > Subscriptions`.
2. Click `Create subscription`.
3. Use product ID: `tempcam_premium_yearly`.
4. Set a user-facing name like `TempCam Yearly Access`.
5. Add benefits such as:
   - Open the full TempCam app
   - Temporary private photo vault
   - Temporary private video vault
   - Keep forever export
6. Save the subscription.

Then create the base plan:

1. Open the subscription details.
2. Click `Add base plan`.
3. Choose `Auto-renewing`.
4. Set billing period to `Yearly`.
5. Set the price to `$3.00`.
6. Save.
7. Activate the base plan.

Do not create monthly plans, trial plans, or extra offers unless you intentionally want them.

## 6. Internal Testing First

Do not go straight to production.

1. Go to `Testing > Internal testing`.
2. Create an internal testing release.
3. Build and upload an Android App Bundle:

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Expected output:

- `build/app/outputs/bundle/release/app-release.aab`

Keep the `build/symbols` folder private and backed up. You need it later if you
want readable crash stack traces after obfuscation.

4. Add tester email accounts.
5. Accept the internal testing opt-in link on your Android phone.
6. Install the Play-distributed build from the Play Store test page.

## 7. Set Up Billing Test Accounts

In Play Console:

1. Go to `Settings > License testing`.
2. Add your tester Gmail accounts.
3. Use one of those accounts on your real Android test device.

Use a real device, not an emulator, for Play Billing testing.

## 8. Test the Subscription End to End

With the internal testing build installed from Play:

1. Open the app.
2. Confirm the paywall appears when no active subscription exists.
3. Buy the yearly subscription.
4. Confirm the app unlocks.
5. Close and reopen the app.
6. Confirm access stays active.
7. Uninstall and reinstall from the Play test link.
8. Use `Restore Purchase`.
9. Confirm access restores correctly.

Also test:

- canceling the purchase flow
- no network
- subscription already active
- account switched on device

## 9. Build Config Notes

Production billing is enabled by default.

Release hardening already enabled in the Android project:

- R8 / code shrinking
- resource shrinking
- release signing

Recommended production build command:

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Why use it:

- makes Dart symbols harder to reverse engineer
- reduces the value of basic string and symbol scraping tools
- keeps a local symbol map for crash investigation

If you ever need to disable billing for local development only:

```powershell
flutter run --dart-define=TEMPCAM_DISABLE_PAYMENTS=true
```

Do not use that flag for Play builds.

## 10. Before Production Rollout

Check all of these:

- real keystore configured
- privacy policy URL live
- subscription terms URL live
- subscription active in Play Console
- store-managed free trial offer active if you are using one
- internal test purchase works
- restore works
- same-account reinstall does not create a second free trial
- clear-data does not create a second free trial
- notifications work on device
- biometric lock works on device
- camera, photo capture, video capture, and playback work on device
- Play store listing graphics are ready
- Data safety form is accurate
- content rating is complete

## 11. Production Rollout

When internal testing is good:

1. Go to `Release > Production`.
2. Create a new release.
3. Upload the same `.aab` or a new release build.
4. Fill release notes.
5. Review warnings.
6. Start rollout.

If Play asks for more review information, explain:

- TempCam is a local-first temporary camera app
- subscription is required for access
- the subscription product is `tempcam_premium_yearly`
- reviewers can use Play test purchases in the testing track

## 12. Important Technical Limitation

The current app uses client-side entitlement state with store purchase syncing and restore support.

That is good enough for an initial release, but the stronger long-term version is:

- a secure backend
- Play Developer API purchase verification
- server-side entitlement state

Without a backend, Google Play trial and subscription eligibility is protected for
the same store account, but a totally different Google account can still be
separately eligible according to Play's rules.

That should be your next billing hardening step after the first release is live.
