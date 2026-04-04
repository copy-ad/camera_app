# TempCam

TempCam is a Flutter mobile app for capturing or importing private photos and videos, storing them inside the app first, and deleting them later on a timer unless the user chooses to keep them.

The product direction is privacy-first and local-first:

- camera captures stay out of the main gallery by default
- imported media can be moved into TempCam with a self-destruct timer
- access can be protected with biometrics
- expiry reminders and vault history stay on-device

## Main Features

- private photo and video capture that stays out of the main gallery by default
- smart document scan flow for photos with detected phone numbers or addresses
- pre-save actions for detected data: call, add to contacts, open maps, then `Temp Save`
- temporary vault with self-destruct timers for photos, videos, and detected document details
- media import from device library into TempCam with the same temp-save flow
- biometric lock, session privacy mode, protected recents preview, and panic exit
- localization support with in-app language selection

## Current Status

TempCam is an MVP with production-oriented platform wiring for:

- timed photo and video capture
- smart document scan with OCR-based phone/address detection for photos
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

### Localization

- app language can follow the system language or use an in-app override
- onboarding tour, vault copy, capture flow, and settings use the localization layer

### Billing

- one yearly subscription product
- restore purchases
- optional development bypass with `TEMPCAM_DISABLE_PAYMENTS`

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
- `docs/`: release notes, legal docs, and store-launch guides

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

- [play_store_first_release.md](docs/play_store_first_release.md)
- [legal_hosting_guide.md](docs/legal_hosting_guide.md)
- [privacy_policy.md](docs/privacy_policy.md)
- [subscription_terms.md](docs/subscription_terms.md)
- [release_notes_1.2.1.md](docs/release_notes_1.2.1.md)

## Suggested Next Improvements

- add real at-rest encryption for vault metadata and media files
- add automated tests for import, expiry cleanup, billing state, and lifecycle relock behavior
- improve OCR quality for more document layouts like receipts and business cards
- centralize platform capability notes so README, onboarding, and store copy stay aligned
