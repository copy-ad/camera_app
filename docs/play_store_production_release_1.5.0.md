# TempCam 1.5.0 Google Play Production Release

## Version

- versionName: `1.5.0`
- versionCode: `101`
- package: `com.tempcam`
- artifact: Android App Bundle (`.aab`)

## Build Commands

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define=TEMPCAM_PRIVACY_POLICY_URL=PRIVACY_POLICY_URL_PLACEHOLDER --dart-define=TEMPCAM_SUBSCRIPTION_TERMS_URL=SUBSCRIPTION_TERMS_URL_PLACEHOLDER
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Do not use APK for Google Play production upload.

## Play Console What's New

```text
First production release of TempCam.

- Capture private photos and videos into a temporary local vault
- Import existing photos and videos from your main gallery
- Choose expiry timers for temporary media
- Use OCR-based document actions for detected phone numbers and addresses
- Protect access with biometric lock and privacy controls
- Get expiry reminders before temporary media disappears
- Keep selected items forever by exporting them when needed
```

## Short Release Notes

TempCam is now ready for production with private photo and video capture, temporary vault storage, import support, OCR document actions, biometric protection, expiry reminders, and Keep Forever export.

## Medium Release Notes

TempCam's first production release helps keep sensitive photos, videos, and document captures temporary by default. Capture or import media into a local private vault, choose expiry timers, use OCR-powered actions for detected phone numbers and addresses, protect access with biometrics, receive expiry reminders, and export selected items only when you choose Keep Forever.

## Submission Checklist

- Confirm `versionName` is `1.5.0` and `versionCode` is `101`.
- Confirm package identity remains `com.tempcam`.
- Confirm `android/key.properties` points to the real upload keystore.
- Confirm `upload-keystore.jks` is backed up securely and not committed.
- Replace `PRIVACY_POLICY_URL_PLACEHOLDER` with the hosted privacy policy URL.
- Replace `SUBSCRIPTION_TERMS_URL_PLACEHOLDER` with the hosted subscription terms URL.
- Confirm `TEMPCAM_DISABLE_PAYMENTS` is not passed in release commands.
- Confirm Play Console subscription product ID is `tempcam_premium_yearly`.
- Confirm yearly base plan ID is `yearly`.
- Confirm the store-managed trial offer ID is `free-trial-15` if the offer is active.
- Confirm app listing screenshots, feature graphic, short description, and full description are final.
- Complete Google Play Data safety.
- Complete content rating.
- Confirm target countries, pricing, yearly subscription price, and tax settings.
- Upload `build/app/outputs/bundle/release/app-release.aab` to Production.
- Start with a conservative staged rollout, such as 5% to 10%, then expand after checking crash and billing signals.
