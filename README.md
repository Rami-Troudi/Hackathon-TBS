# Senior Companion - Group 2 Prototype (Event Core)

This repository contains **Group 0 + Group 1 + Group 2** of the Senior Companion mobile prototype: a runnable local-first foundation with onboarding/session flow, structured local entity storage, and a real persisted event/timeline/status core.

## Scope of this foundation (G0 + G1 + G2)

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
- Onboarding flow with role + profile selection
- Prototype local session restoration from splash
- Hive structured local storage for demo profiles and profile links
- Hive structured local storage for persisted domain event records
- Idempotent demo seed data (first run + reseed/reset support)
- Event repository with timeline/history queries (per senior, by type, recent)
- Deterministic local status engine (`ok` / `watch` / `actionRequired`)
- Real local dashboard summary aggregation from persisted events
- Developer event generation controls (publish + persist) and event history clearing
- Explicit local storage policy:
  - `SharedPreferences` for preferences/flags/light session only
  - `Hive` for structured entities (profiles, links, event records, future feature entities)

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
- Hive + hive_flutter
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

## Onboarding + session flow (G1)

Startup routing now follows this prototype flow:

1. `/splash`
2. If local session exists and linked profile is valid:
   - senior session -> `/senior`
   - guardian session -> `/guardian`
3. If no valid session:
   - `/onboarding/role`
   - `/onboarding/profile/:role`

The old `/home` screen is kept as a developer demo hub and is no longer the normal first-launch path.

## G2 Event Core (local-first)

Group 2 introduces a reusable local event foundation that future feature groups build on:

- **Persisted event records** in Hive (`event_records`)
- **Timeline queries** via `EventRepository`
- **Deterministic status engine** rules:
  - emergency or unresolved confirmed incident -> `actionRequired`
  - unresolved suspected incident or single missed routine signal -> `watch`
  - repeated missed routine signals (3+) -> `actionRequired`
  - otherwise -> `ok`
- **Real dashboard summary** derived from persisted events (no hardcoded mock counts)

For prototype validation, open the **Developer Hub** (`/home`) from Senior/Guardian screens and use the event buttons to:
- generate check-in, medication, incident, and emergency events
- publish events on the in-app event bus
- persist events locally
- clear local event history for the active senior context

## Demo data reset flow (G1)

From **Settings**:
- **Clear Session** -> removes current local session and returns to onboarding.
- **Reseed Demo Data** -> recreates deterministic local demo profiles/links.
- **Reset Demo Data** -> clears structured demo data + session and returns to onboarding.

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
    onboarding/
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
