# Setup Guide — Senior Companion Prototype

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | `>=3.4.0 <4.0.0` | See `pubspec.yaml` `environment.sdk` |
| Dart SDK | Included with Flutter | |
| Android Studio | Latest stable | For Android emulator and SDK tools |
| Xcode | Latest stable | macOS only — required for iOS simulator |
| VS Code | Optional | Install the Flutter + Dart extensions |
| Git | Any recent version | |

### Verify your Flutter installation

```bash
fvm flutter doctor
```

All entries should be green before running the project. Pay special attention to:
- Android SDK and emulator setup
- Xcode / iOS toolchain (macOS only)
- Connected devices

---

## First-time setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd senior-companion
```

### 2. Generate platform folders (one-time only)

This repository does not commit the `android/` and `ios/` platform folders.
Run this once after cloning to generate them:

```bash
fvm flutter create . --platforms=android,ios
```

If you are targeting only one platform:

```bash
fvm flutter create . --platforms=android
fvm flutter create . --platforms=ios
```

### 3. Install dependencies

```bash
fvm flutter pub get
```

---

## Running the app

### Default run (dev environment)

```bash
fvm flutter run
```

### Run with an explicit environment

```bash
fvm flutter run --dart-define=APP_ENV=dev
```

Supported `APP_ENV` values:

| Value | API base URL | Network logs |
|---|---|---|
| `dev` | `https://prototype.local` | Enabled (debug builds) |
| `staging` | `https://staging.prototype.local` | Enabled (debug builds) |
| `prod` | `https://api.prototype.local` | Disabled |

> **Note:** All API URLs are stubs in Group 0. No real network calls are made.
> Dio is scaffolded for future use only.

### Run on a specific device

List available devices:

```bash
fvm flutter devices
```

Run on a specific device by device ID:

```bash
fvm flutter run -d <device-id>
```

Examples:

```bash
fvm flutter run -d emulator-5554        # Android emulator
fvm flutter run -d "iPhone 15"          # iOS simulator by name
fvm flutter run -d chrome               # Web (not a target platform for this project)
```

---

## Startup behavior (G1)

On first launch (no local session), the app routes to onboarding:

1. `/onboarding/role`
2. `/onboarding/profile/:role`
3. local session creation
4. route to `/senior` or `/guardian`

If a valid local session already exists, splash restores it and routes directly
to the matching role experience.

---

## Static analysis

```bash
fvm flutter analyze
```

The project uses `flutter_lints` via `analysis_options.yaml`. All new code
should pass analysis cleanly before committing.

---

## Running tests

```bash
fvm flutter test
```

Run a specific test file:

```bash
fvm flutter test test/core/app_result_test.dart
```

Run with verbose output:

```bash
fvm flutter test --reporter expanded
```

Current targeted G1 tests:

- `test/app/bootstrap/app_initializer_test.dart` (bootstrap init path)
- `test/core/repositories/local_profile_seed_test.dart` (seeding/reset behavior)
- `test/core/repositories/local_repositories_test.dart` (session/preferences local repos)
- `test/features/splash/splash_routing_test.dart` (startup routing)

---

## Useful development commands

```bash
# Hot reload is automatic when using fvm flutter run
# Press r in the terminal to trigger a hot reload manually
# Press R for a full hot restart
# Press q to quit

# Check for outdated packages
fvm flutter pub outdated

# Upgrade packages within constraint bounds
fvm flutter pub upgrade

# Clean build artifacts (useful when things break unexpectedly)
fvm flutter clean && fvm flutter pub get
```

---

## Project-specific notes

- **No backend required.** The prototype is fully local-first. All repositories
  use mock or local implementations.
- **Storage policy for G1.** `SharedPreferences` is reserved for
  preferences/session/flags only. Structured entities are stored in Hive.
- **No code generation currently required.** G1 uses manual JSON maps for Hive.
  If code generation is introduced later (`hive_generator`, `freezed`, etc.), run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Notification permissions.** On a physical device, the Settings screen
  provides a button to request notification and location permissions. On
  simulators/emulators, permission dialogs may behave differently.
- **Environment flag.** The `APP_ENV` dart-define is optional. When omitted,
  the app defaults to `dev`. You never need to set it during normal prototype
  development.

- **Demo reset controls.** Use Settings screen actions:
  - Clear Session
  - Reseed Demo Data
  - Reset Demo Data
  to quickly prepare demo scenarios during hackathon iteration.

---

## Troubleshooting

### `fvm flutter doctor` shows issues with Android SDK

Run Android Studio and go to **SDK Manager → SDK Tools**. Ensure
`Android SDK Build-Tools`, `Android SDK Command-line Tools`, and
`Android Emulator` are installed.

### `fvm flutter create . --platforms=android,ios` fails

Make sure you are inside the project root directory (the folder containing
`pubspec.yaml`) before running the command.

### App crashes on launch with `StateError: Storage service used before initialization`

This means `StorageService.initialize()` was not awaited during bootstrap.
Check `AppInitializer.initialize()` in `lib/app/bootstrap/app_initializer.dart`.

### Notification permission is not requested automatically

By design, permissions are requested lazily. Go to **Settings** in the app
and tap **Request Notification Permission** to trigger the permission dialog.

### Hot reload does not reflect changes to providers

Riverpod providers that depend on bootstrap overrides are not hot-reloadable
in all cases. Use **hot restart** (press `R` in the terminal) to reset the
full provider graph.

---

## Native checklist after `flutter create` (required)

Because `android/` and `ios/` are generated locally, each machine must confirm
these settings after generation.

### Android

Edit `android/app/src/main/AndroidManifest.xml` and ensure:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS

Edit `ios/Runner/Info.plist` and ensure:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to support safety and context-aware reminders.</string>
```

Notification permissions are requested at runtime by the app; behavior can vary
between simulator and physical device.
