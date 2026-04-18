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
flutter doctor
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
flutter create . --platforms=android,ios
```

If you are targeting only one platform:

```bash
flutter create . --platforms=android
flutter create . --platforms=ios
```

### 3. Install dependencies

```bash
flutter pub get
```

---

## Running the app

### Default run (dev environment)

```bash
flutter run
```

### Run with an explicit environment

```bash
flutter run --dart-define=APP_ENV=dev
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
flutter devices
```

Run on a specific device by device ID:

```bash
flutter run -d <device-id>
```

Examples:

```bash
flutter run -d emulator-5554        # Android emulator
flutter run -d "iPhone 15"          # iOS simulator by name
flutter run -d chrome               # Web (not a target platform for this project)
```

---

## Static analysis

```bash
flutter analyze
```

The project uses `flutter_lints` via `analysis_options.yaml`. All new code
should pass analysis cleanly before committing.

---

## Running tests

```bash
flutter test
```

Run a specific test file:

```bash
flutter test test/core/app_result_test.dart
```

Run with verbose output:

```bash
flutter test --reporter expanded
```

---

## Useful development commands

```bash
# Hot reload is automatic when using flutter run
# Press r in the terminal to trigger a hot reload manually
# Press R for a full hot restart
# Press q to quit

# Check for outdated packages
flutter pub outdated

# Upgrade packages within constraint bounds
flutter pub upgrade

# Clean build artifacts (useful when things break unexpectedly)
flutter clean && flutter pub get
```

---

## Project-specific notes

- **No backend required.** The prototype is fully local-first. All repositories
  use mock or SharedPreferences-backed implementations.
- **No code generation.** Group 0 does not use `build_runner`, `freezed`, or
  `json_serializable`. If these are added in a later group, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Notification permissions.** On a physical device, the Settings screen
  provides a button to request notification and location permissions. On
  simulators/emulators, permission dialogs may behave differently.
- **Environment flag.** The `APP_ENV` dart-define is optional. When omitted,
  the app defaults to `dev`. You never need to set it during normal prototype
  development.

---

## Troubleshooting

### `flutter doctor` shows issues with Android SDK

Run Android Studio and go to **SDK Manager → SDK Tools**. Ensure
`Android SDK Build-Tools`, `Android SDK Command-line Tools`, and
`Android Emulator` are installed.

### `flutter create . --platforms=android,ios` fails

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