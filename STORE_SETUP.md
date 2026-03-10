# Store Publishing Guide — ToothHurts

## Prerequisites
- Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- Xcode (for iOS) — macOS only
- Android Studio / Java JDK 17+
- Apple Developer account ($99/yr) for App Store
- Google Play Developer account ($25 one-time)
- Amazon Developer account (free) for Amazon Appstore

## 1. Setup

```bash
flutter pub get
flutter doctor  # confirm no issues
```

## 2. iOS — App Store

```bash
# Build the iOS release archive
flutter build ipa --target lib/main.dart

# Then open Xcode:
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

**App Store Connect settings:**
- Age Rating: 4+
- Category: Games → Family
- Privacy: No data collected (core game) — update if you add analytics
- Review notes: "A touch game where players count a baby's teeth by tapping them, avoiding bites, tongue, and squirming."

## 3. Google Play

```bash
# Build App Bundle (preferred format)
flutter build appbundle --flavor google --target lib/main_google.dart

# Output: build/app/outputs/bundle/googleRelease/app-google-release.aab
# Upload to Google Play Console → Production
```

**Google Play Console settings:**
- Target audience: Everyone (or 5 and under if targeting kids — triggers COPPA requirements)
- Content rating: Everyone
- Family policy: Complete Family Policy declaration in Play Console if targeting children

## 4. Amazon Appstore

```bash
# Amazon requires APK (not AAB)
flutter build apk --flavor amazon --target lib/main_amazon.dart --release

# Output: build/app/outputs/flutter-apk/app-amazon-release.apk
# Upload to Amazon Developer Console → Appstore → New App
```

**Amazon-specific notes:**
- Amazon re-signs your APK — upload your signed APK, they'll override the signature
- Test on a Fire tablet or the Amazon Device Farm before submission
- Fire OS 7 = Android 9 base; Fire OS 8 = Android 11 base
- No Google Play Services available on Fire OS — verify no GMS dependency at runtime
- Child-directed: If submitting to Kids category, declare COPPA compliance

## 5. Audio Assets

Place `.mp3` files in `assets/audio/` to enable sound effects:
- `bite.mp3` — chomp sound
- `count_tick.mp3` — soft tick when counting a tooth
- `level_clear.mp3` — fanfare on round complete
- `tongue_slurp.mp3` — slurp when tongue slides in
- `squirm.mp3` — short shuffle sound
- `game_over.mp3` — game over sting
- `button_tap.mp3` — UI tap sound

Game runs silently without these files — add them before shipping.

## 6. App Icons

Replace the default Flutter icons with a tooth-themed icon:
```bash
# Use flutter_launcher_icons package or manually place:
# android: android/app/src/main/res/mipmap-*/ic_launcher.png
# iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Recommended: tooth emoji on a pastel pink background, 1024×1024px master.

## 7. Signing

### Android
1. Generate keystore: `keytool -genkey -v -keystore toothhurts.jks -keyalg RSA -keysize 2048 -validity 10000 -alias toothhurts`
2. Create `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=toothhurts
   storeFile=../toothhurts.jks
   ```
3. Update `android/app/build.gradle` signingConfigs to reference `key.properties`

### iOS
Managed by Xcode / Apple Developer portal. Use automatic signing in Xcode.
