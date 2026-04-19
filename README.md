# Senior Companion — Mobile Prototype

A runnable local-first Flutter mobile app for daily senior support and family coordination. The app provides senior-focused check-ins, medication reminders, incident monitoring, hydration/nutrition tracking, and voice-based companionship, while giving guardians a dashboard for monitoring, alerts, and assistant insights.

## Product Features

### Senior Experience
- **Home dashboard** with daily status and quick actions
- **Daily check-in** — simple I'm okay / I need help flow
- **Medication reminders** with taken/skip tracking
- **Incident & emergency** handling with escalation
- **Hydration & nutrition** tracking with reminders
- **Voice companion** — microphone-first conversational support (with fallback text mode)
- **Daily summary** — personalized daily overview
- **Settings** — accessibility, notifications, language, emergency contact

### Guardian Experience
- **Monitoring dashboard** with senior status, alerts, and metrics
- **Alerts center** — prioritized notifications with acknowledge/resolve actions
- **Event timeline** — chronological history with filtering (check-ins, medication, incidents, emergencies)
- **Check-in monitoring** — status and trends
- **Medication adherence** — tracking and alerts
- **Incident monitoring** — history and escalation tracking
- **Hydration & nutrition monitoring** — completion snapshots and trends
- **Safe-zone/location** — prototype location monitoring with simulated updates
- **Daily summary & insights** — local assistant Q&A grounded in real data
- **Settings** — notification preferences, alert sensitivity, module visibility

### Technical Features
- **Local-first architecture** — all data stored locally, no backend required
- **Session management** — onboarding role/profile selection with session restore
- **Persisted events** — all user actions recorded and queryable
- **Deterministic status engine** — real-time status (ok / watch / actionRequired)
- **Local notifications** — alerts for missed check-ins, medication, emergencies, safe-zone exits
- **Voice gateway integration** — optional external STT/TTS with deterministic local fallback
- **Demo controls** — easy reseed/reset for testing and demos
- **Native permissions** — notifications and location on iOS/Android

## Stack

- Flutter + Dart
- Riverpod (state management)
- GoRouter (routing)
- Dio (networking scaffold)
- SharedPreferences (lightweight preferences)
- Hive (structured local storage)
- flutter_local_notifications
- permission_handler
- record + just_audio (voice recording/playback)

## Quick Start

### Prerequisites
- Install [fvm](https://fvm.app/) (Flutter Version Manager)

### Setup

```bash
# Install pinned Flutter version
fvm install

# Fetch dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

### Optional: Run with environment

```bash
fvm flutter run --dart-define=APP_ENV=dev
```

Valid values: `dev`, `staging`, `prod`

## Voice Companion

The app includes optional voice gateway integration for Tunisian Arabic STT/TTS.

### Local Fallback Mode (default)

The app runs entirely local-first by default with deterministic voice responses:

```bash
fvm flutter run --dart-define=APP_ENV=dev
```

This works offline and is ideal for demos without external dependencies.

### External Gateway Mode (optional)

To test against an external voice gateway:

```bash
fvm flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=VOICE_GATEWAY_MODE=gateway \
  --dart-define=VOICE_GATEWAY_BASE_URL=https://xqdrant.moetezfradi.me
```

## Onboarding & Session Flow

The app follows this startup sequence:

1. **Splash screen** → checks for existing session
2. **If session exists** → restores to senior or guardian home based on saved role
3. **If no session** → onboarding flow:
   - Role selection (Senior or Guardian)
   - Profile creation/selection

From **Settings**, you can:
- **Clear Session** → sign out and return to onboarding
- **Reseed Demo Data** → recreate demo profiles and sample data
- **Reset Demo Data** → full reset including session

## Routes

### Senior Routes
- `/splash` — session restoration
- `/senior` — home dashboard
- `/senior/check-in` — daily check-in
- `/senior/medication` — medication reminders
- `/senior/incident` — incident handling
- `/senior/hydration` — hydration tracking
- `/senior/nutrition` — meal tracking
- `/senior/companion` — voice companion
- `/senior/summary` — daily summary
- `/settings` — settings (senior)

### Guardian Routes
- `/splash` — session restoration
- `/guardian` — monitoring dashboard
- `/guardian/alerts` — alert center
- `/guardian/timeline` — event history
- `/guardian/check-ins` — check-in monitoring
- `/guardian/medication` — medication adherence
- `/guardian/incidents` — incident history
- `/guardian/hydration` — hydration monitoring
- `/guardian/nutrition` — nutrition monitoring
- `/guardian/location` — safe-zone management
- `/guardian/summary` — daily summary
- `/guardian/insights` — AI assistant
- `/settings` — settings (guardian)

## Building for Android

### Debug APK

```bash
fvm flutter pub get
fvm flutter build apk --debug
```

Install:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK

```bash
fvm flutter build apk --release
```

## Project Structure

```
lib/
  app/
    app.dart              # Root widget
    bootstrap/            # App initialization
    router/               # Route configuration
    theme/                # UI theme
  core/
    config/               # App configuration
    errors/               # Error handling
    events/               # Event system
    logging/              # Logging service
    networking/           # API client (Dio)
    notifications/        # Local notifications
    permissions/          # Permission handling
    repositories/         # Local data repositories
    storage/              # Hive + SharedPreferences
    voice/                # Voice gateway client
  features/
    splash/               # Onboarding & session
    onboarding/
    senior/               # Senior flows
    guardian/             # Guardian flows
    settings/             # Settings
    check_in/
    medication/
    incident/
    hydration/
    nutrition/
    location/
    summary/
  shared/
    constants/            # App constants
    models/               # Shared domain models
    utils/                # Utilities
    widgets/              # Reusable widgets
```

## Native Platform Configuration

`android/` and `ios/` folders are included. If regenerating locally:

**Android:**
- Ensure `android/app/src/main/AndroidManifest.xml` includes:
  - `android.permission.POST_NOTIFICATIONS` (notifications)
  - `android.permission.ACCESS_FINE_LOCATION` (location)

**iOS:**
- Ensure `ios/Runner/Info.plist` includes:
  - `NSLocationWhenInUseUsageDescription` (location)

## Documentation

- `docs/setup.md` — detailed setup instructions
- `docs/architecture.md` — architecture overview and extension patterns
- `docs/demo_runbook.md` — demo walkthrough and scenarios
- `docs/qa_checklist.md` — QA and testing checklist

## Support

For questions or issues, refer to the documentation or the project's GitHub issues.
