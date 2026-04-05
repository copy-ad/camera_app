# TempCam

TempCam is a Flutter mobile app for temporary sensitive capture.

The core product promise is simple:

- capture photos or videos that should not live in the main gallery
- act on useful document details like phone numbers or addresses immediately
- store them inside TempCam for only as long as needed
- let them expire automatically unless the user chooses `Keep Forever`

TempCam is positioned as a local-first utility for receipts, labels, addresses, phone numbers, travel details, business cards, and private moments that users do not want sitting around in the device gallery.

## Positioning

### Product Direction

TempCam is not trying to be a general camera app or a giant long-term cloud vault.
It is strongest when presented as:

- a temporary camera for sensitive photos and videos
- a private capture space that keeps clutter and risk out of the main gallery
- a short-lived document helper that can detect phone numbers and addresses

### Core Tagline

`Capture. Use. Let It Disappear.`

### Store Positioning

For exact App Store and Play Store copy, see:

- [app_store_positioning.md](docs/app_store_positioning.md)

## Main Features

- private photo and video capture that stays out of the main gallery by default
- live camera scan assist for phone numbers and addresses before capture
- smart document scan flow after capture or import, before timer selection
- pre-save actions for detected data: call, add to contacts, open maps, then `Temp Save`
- temporary vault with self-destruct timers for photos, videos, and detected document details
- media import from the device library into TempCam with the same temp-save flow
- biometric lock, session privacy mode, protected recents preview, and panic exit
- localization support with in-app language selection

## Current Status

TempCam is an MVP with production-oriented platform wiring for:

- timed photo and video capture
- OCR-based phone and address detection
- live camera scan assist on the preview
- private in-app vault browsing
- import from device library into TempCam
- biometric relock flow
- local expiry notifications
- store-managed yearly subscription access

Important implementation note:

- media is stored in app-private storage on the device
- the current codebase does not implement a custom encrypted media store or encrypted Hive boxes

## Feature Summary

### Capture

- photo and video capture inside the app
- front and back camera switching
- tap to focus
- pinch to zoom
- flash controls
- live scan actions on the camera screen for detected phone numbers or addresses
- private preview before save
- document scan detection before timer selection when a photo contains a phone number or address
- `Temp Save` continues into timer selection

### Vault

- private in-app gallery for photos and videos
- filter by all, photos, or videos
- item detail screen with playback or image preview
- detected phone/address details saved with the photo until expiry or `Keep Forever`
- extend timer, delete now, or keep forever
- multi-select delete

### Import

- import existing photos and videos into TempCam
- imported photos can use the same detected phone/address action flow before timer selection
- Android import flow removes originals from the main gallery when the platform/provider allows deletion
- iOS import uses `PHPicker` and requires iOS 14+

### Smart Document Actions

- OCR scans photos for phone numbers and addresses
- if a phone number is found, TempCam can open call or add-contact actions before saving
- if an address is found, TempCam can open maps before saving
- detected details remain associated with the saved temp photo inside the vault until expiry or `Keep Forever`

### Privacy

- biometric lock
- quick relock timeout
- session privacy mode
- protected recent-app preview
- panic exit

### Notifications

- local reminders shortly before expiry
- stealth wording option
- branded notification icon and secure notification visibility handling

### Localization

- app language can follow the system language or use an in-app override
- onboarding tour, vault copy, capture flow, and settings use the localization layer

### Billing

- one yearly subscription product
- restore purchases
- optional development bypass with `TEMPCAM_DISABLE_PAYMENTS`

## Legal Docs

TempCam includes editable legal pages and hosting guides:

- [privacy_policy.md](docs/privacy_policy.md)
- [subscription_terms.md](docs/subscription_terms.md)
- [privacy-policy.html](docs/privacy-policy.html)
- [subscription-terms.html](docs/subscription-terms.html)
- [legal_hosting_guide.md](docs/legal_hosting_guide.md)

The legal copy has been updated to match the current product:

- temporary sensitive capture
- OCR-based document actions
- local-first storage
- store-managed subscriptions

## Platform Notes

### Android

- `Keep Forever` exports media to `DCIM/TempCam`
- import is handled through the native document picker bridge in `android/app/src/main/kotlin/com/tempcam/MainActivity.kt`
- detected phone numbers can open the dialer or contact insert flow through the Android native bridge

### iOS

- import is handled through `PHPicker` in `ios/Runner/AppDelegate.swift`
- document scan text recognition requires the current iOS deployment target configured in the project
- legal links fall back to in-app sheets if hosted URLs are not supplied
- detected phone numbers can open the dialer or contact insert flow through the iOS native bridge

## Project Structure

Key areas:

- `lib/src/shared/state/app_controller.dart`: app state, lifecycle, camera flow, import flow, vault actions
- `lib/src/features/camera/presentation/document_action_sheet.dart`: pre-save smart document actions
- `lib/src/shared/repositories/`: persistence and vault history
- `lib/src/shared/services/`: camera, storage, billing, biometrics, notifications, OCR scan, system actions
- `lib/src/features/`: screens for camera, photos, lock, onboarding, settings, paywall
- `android/app/src/main/kotlin/com/tempcam/MainActivity.kt`: Android media and external URL bridges
- `ios/Runner/AppDelegate.swift`: iOS media import bridge
- `docs/`: release notes, legal docs, store positioning, and launch guides

## Libraries Used

### Flutter SDK

- `flutter`
- `flutter_localizations`
- `flutter_test`

### App Dependencies

- `cupertino_icons: ^1.0.8`
- `provider: ^6.1.2`
- `camera: ^0.11.0+2`
- `path: ^1.9.0`
- `path_provider: ^2.1.4`
- `hive: ^2.2.3`
- `hive_flutter: ^1.1.0`
- `uuid: ^4.5.1`
- `intl: ^0.20.2`
- `local_auth: ^2.3.0`
- `flutter_local_notifications: ^18.0.1`
- `flutter_timezone: ^4.1.1`
- `in_app_purchase: ^3.2.3`
- `in_app_purchase_android: ^0.4.0+8`
- `image_picker: 1.1.2`
- `quick_actions: 1.0.8`
- `video_player: ^2.9.2`
- `video_thumbnail: ^0.5.6`
- `timezone: ^0.10.1`
- `google_mlkit_text_recognition: ^0.15.1`

### Dev Dependencies

- `flutter_lints: ^4.0.0`

### Dependency Override

- `image_picker_android: 0.8.12+12`

## Getting Started

### Prerequisites

- Flutter SDK compatible with `sdk: ">=3.4.0 <4.0.0"`
- Android Studio for Android builds
- Xcode for iOS builds

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Static Analysis

```bash
flutter analyze
```

### Android Debug Build

```bash
flutter build apk --debug
```

## Release Configuration

TempCam expects these build-time values for release readiness:

- `TEMPCAM_PRIVACY_POLICY_URL`
- `TEMPCAM_SUBSCRIPTION_TERMS_URL`
- `TEMPCAM_DISABLE_PAYMENTS`

Example:

```bash
flutter build appbundle --release \
  --dart-define=TEMPCAM_PRIVACY_POLICY_URL=https://example.com/privacy-policy.html \
  --dart-define=TEMPCAM_SUBSCRIPTION_TERMS_URL=https://example.com/subscription-terms.html
```

## Repo Docs

- [app_store_positioning.md](docs/app_store_positioning.md)
- [play_store_first_release.md](docs/play_store_first_release.md)
- [legal_hosting_guide.md](docs/legal_hosting_guide.md)
- [privacy_policy.md](docs/privacy_policy.md)
- [subscription_terms.md](docs/subscription_terms.md)
- [release_notes_1.2.1.md](docs/release_notes_1.2.1.md)

## Suggested Next Improvements

- add real at-rest encryption for vault metadata and media files
- add automated tests for import, expiry cleanup, billing state, and lifecycle relock behavior
- improve OCR quality for more document layouts like receipts and business cards
- centralize platform capability notes so README, onboarding, legal pages, and store copy stay aligned
