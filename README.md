# TempCam

TempCam is a Flutter mobile app for capturing or importing private photos and videos, storing them inside the app first, and deleting them later on a timer unless the user chooses to keep them.

The product direction is privacy-first and local-first:

- camera captures stay out of the main gallery by default
- imported media can be moved into TempCam with a self-destruct timer
- access can be protected with biometrics
- expiry reminders and vault history stay on-device

## Current Status

TempCam is an MVP with production-oriented platform wiring for:

- timed photo and video capture
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
- timer selection after capture

### Vault

- private in-app gallery for photos and videos
- filter by all, photos, or videos
- item detail screen with playback or image preview
- extend timer, delete now, or keep forever
- multi-select delete

### Import

- import existing photos and videos into TempCam
- Android import flow removes originals from the main gallery when the platform/provider allows deletion
- iOS import uses `PHPicker` and requires iOS 14+

### Privacy

- biometric lock
- quick relock timeout
- session privacy mode
- protected recent-app preview
- panic exit

### Notifications

- local reminders shortly before expiry
- stealth wording option

### Billing

- one yearly subscription product
- restore purchases
- optional development bypass with `TEMPCAM_DISABLE_PAYMENTS`

## Platform Notes

### Android

- `Keep Forever` exports media to `DCIM/TempCam`
- import is handled through the native document picker bridge in `android/app/src/main/kotlin/com/tempcam/MainActivity.kt`

### iOS

- import is handled through `PHPicker` in `ios/Runner/AppDelegate.swift`
- legal links fall back to in-app sheets if hosted URLs are not supplied
- `Keep Forever` is not yet exporting to the system Photos app in the current codebase

## Project Structure

Key areas:

- `lib/src/shared/state/app_controller.dart`: app state, lifecycle, camera flow, import flow, vault actions
- `lib/src/shared/repositories/`: persistence and vault history
- `lib/src/shared/services/`: camera, storage, billing, biometrics, notifications
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
- implement iOS Photos export for `Keep Forever`
- centralize platform capability notes so README, onboarding, and store copy stay aligned
