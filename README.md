# Senior Companion - Group 0 Prototype Foundation

This repository contains **Group 0** of the Senior Companion mobile prototype: a clean Flutter foundation that future feature groups can build on quickly.

## Scope of this foundation

Included:
- Flutter mobile app bootstrap
- Modular folder structure (`app`, `core`, `features`, `shared`)
- Riverpod + GoRouter wiring
- Theme scaffold and reusable placeholder widgets
- Lightweight local storage foundation (`shared_preferences`)
- Local notifications foundation (`flutter_local_notifications`)
- Centralized permissions scaffold
- Dio networking scaffold for future integrations
- Mock/local repositories with Riverpod injection
- Logging, structured errors, and lightweight app event bus
- Placeholder screens for Splash/Home/Senior/Guardian/Settings
- Explicit local storage policy:
  - `SharedPreferences` for preferences/session flags only
  - structured entities (events/timeline/medications/incidents) must move to
    a dedicated local store (Hive planned for G1)

Not included:
- Backend/server setup
- Docker/devops
- Database infrastructure
- AI/chatbot implementation
- Full business-domain features

## Stack

- Flutter + Dart
- Riverpod
- GoRouter
- Dio
- SharedPreferences
- flutter_local_notifications
- permission_handler (lightweight permissions helper)

## Quick start

1. Install `fvm` (Flutter Version Manager).
2. Install the pinned Flutter SDK version:
   ```bash
   fvm install
   ```
3. Open the workspace in VS Code/Cursor and install the recommended extensions when prompted.
4. Generate platform folders (one-time in this repo):
   ```bash
   fvm flutter create . --platforms=android,ios
   ```
5. Fetch dependencies:
   ```bash
   fvm flutter pub get
   ```
6. Run app:
   ```bash
   fvm flutter run
   ```

You can also pass environment:

```bash
fvm flutter run --dart-define=APP_ENV=dev
```

Valid values: `dev`, `staging`, `prod`.

## Native platform note (important)

This repository does not commit `android/` and `ios/` folders. After:

```bash
fvm flutter create . --platforms=android,ios
```

apply the native checklist in `docs/setup.md` before expecting notification and
location permission behavior to match physical devices.

## Project structure

```text
lib/
  app/
    app.dart
    bootstrap/
    router/
    theme/
  core/
    config/
    errors/
    events/
    logging/
    networking/
    notifications/
    permissions/
    repositories/
    storage/
  features/
    splash/
    home/
    senior/
    guardian/
    settings/
  shared/
    constants/
    models/
    utils/
    widgets/
```

## Documentation

- `docs/setup.md` - setup and run instructions
- `docs/architecture.md` - architecture and extension guidance for next groups
