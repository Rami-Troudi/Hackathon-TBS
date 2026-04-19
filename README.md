# Senior Companion — Final Prototype (G0→G8)

This repository contains the final hackathon prototype through **G8**: a runnable local-first Flutter app with onboarding/session flow, structured local entity storage, persisted event/status core, real senior/guardian monitoring flows, expanded settings, wellbeing modules, safe-zone prototype logic, deterministic daily summaries, senior voice companion integration, notification wiring, native permission configuration, and final demo documentation.

## Scope of this prototype (G0 + G1 + G2 + G3 + G4 + G5 + G7 + G8)

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
- Placeholder-free senior core flow screens (check-in, medication, incident/help)
- Onboarding flow with role + profile selection
- Prototype local session restoration from splash
- Hive structured local storage for demo profiles and profile links
- Hive structured local storage for persisted domain event records
- Idempotent demo seed data (first run + reseed/reset support)
- Event repository with timeline/history queries (per senior, by type, recent)
- Deterministic local status engine (`ok` / `watch` / `actionRequired`)
- Real local dashboard summary aggregation from persisted events
- Developer event generation controls (publish + persist) and event history clearing
- Real senior event generation flows:
  - daily check-in (`I’m okay` / `I need help`)
  - medication confirmation (`Taken` / `Skip`)
  - incident vigilance and emergency escalation
- Real guardian event-driven monitoring flows:
  - `/guardian` dashboard with status, metrics, module cards, and recent important events
  - `/guardian/alerts` prioritized alerts center with acknowledge/resolve actions
  - `/guardian/timeline` chronological event history with event-type filtering
  - `/guardian/check-ins` check-in monitoring
  - `/guardian/medication` medication adherence monitoring
  - `/guardian/incidents` incident state/history monitoring
  - `/guardian/profile` senior monitoring overview
- G5 wellbeing + safety expansion:
  - role-aware persisted settings via `SettingsRepository` (senior + guardian)
  - senior hydration flow (`/senior/hydration`) with completed/missed slot logic
  - senior nutrition flow (`/senior/nutrition`) with meal completed/missed logic
  - safe-zone/location prototype monitoring (`/guardian/location`) with local simulated updates
  - deterministic summaries (`/senior/summary`, `/guardian/summary`)
  - guardian hydration/nutrition monitoring (`/guardian/hydration`, `/guardian/nutrition`)
  - expanded guardian alert rules for hydration/nutrition misses and unresolved safe-zone exits
- Voice companion integration:
  - senior voice companion screen (`/senior/companion`) with microphone-first access
  - voice gateway client in `core/voice` sends recorded audio plus compact local context
  - target gateway pipeline: Tunisian Arabic STT (`linagora/linto-asr-ar-tn-0.1`) -> local LLM -> Sawti TTS WAV response
  - guardian insights route remains a deterministic handoff screen until a guardian/text endpoint exists
  - deterministic repositories remain source of truth; the voice service only receives grounded context for the current question
- Explicit local storage policy:
  - `SharedPreferences` for preferences/flags/light session only
  - `Hive` for structured entities (profiles, links, event records, medication plans, safe zones, runtime location state, future entities)
- G8 final-mile delivery:
  - event-driven local notifications for missed routines, incidents, emergencies, and safe-zone exits
  - Android/iOS native permission declarations aligned with current prototype features
  - Android APK demo runbook and final QA checklist
  - final route/build/demo documentation cleanup
  - app launch label set to **Senior Companion**

Not included:
- Backend/server setup
- Docker/devops
- Server-side database infrastructure
- Cloud auth
- in-app AI provider keys or direct Sawti credentials
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
- record
- just_audio

## Quick start

1. Install `fvm` (Flutter Version Manager).
2. Install the pinned Flutter SDK version:
   ```bash
   fvm install
   ```
3. Open the workspace in VS Code/Cursor and install the recommended extensions when prompted.
4. Platform folders are already committed in this repository (`android/`, `ios/`).
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

Voice gateway configuration:

```bash
fvm flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=VOICE_GATEWAY_BASE_URL=https://xqdrant.moetezfradi.me
```

`VOICE_GATEWAY_BASE_URL` defaults to `https://xqdrant.moetezfradi.me`. If the gateway later requires an app-level key, pass `VOICE_GATEWAY_API_KEY`, but keep Sawti and model-provider secrets on the gateway server only.

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

## G3 Senior Feature Bundle

Group 3 makes senior flows the primary event source (instead of developer-only generation):

- `/senior` -> real senior home with global status, primary daily action, quick help, and module entry points
- `/senior/check-in` -> check-in state (`pending/completed/missed`) and action buttons
- `/senior/medication` -> medication reminders with `Taken` and `Skip` actions
- `/senior/incident` -> suspicious incident, confirmation/dismissal, and emergency escalation flow

All actions publish and persist real events through the existing G2 core (`AppEventRecorder` + `EventRepository`) and immediately affect local status/timeline/dashboard aggregation.

Developer Hub remains available for diagnostics and demo control, but it is no longer the only practical way to generate meaningful product events.

## G4 Guardian Feature Bundle

Group 4 replaces the old guardian placeholder with a real local-first product flow:

- **Dashboard (`/guardian`)**
  - global status, active alert count, check-in/medication/incident cards
  - top alerts and recent important events
  - direct navigation to deeper monitoring modules
- **Alerts center (`/guardian/alerts`)**
  - deterministic alert derivation from persisted timeline + status context
  - severity: `info`, `warning`, `critical`
  - state: `active`, `acknowledged`, `resolved`
  - actions: acknowledge, resolve, open timeline, open related monitoring module
- **Timeline (`/guardian/timeline`)**
  - real persisted events only (no fake history)
  - newest-first chronological feed
  - filter chips: all/check-ins/medication/incidents/emergency
  - day grouping for fast scan
- **Monitoring modules**
  - check-ins: today state + missed/completed trend + recent check-ins
  - medication: plans + today reminder states + adherence snapshot
  - incidents: open/resolved summary + suspicious/confirmed/dismissed/emergency history
- **Senior overview (`/guardian/profile`)**
  - identity, language, accessibility preferences, linked relationship context, monitoring summary

### Guardian alert derivation rules (local deterministic)

- unresolved confirmed incident -> critical active alert
- active emergency incident chain -> critical active alert
- unresolved suspected incident -> warning active alert
- missed medication today -> warning (critical when repeated routine misses escalate)
- missed check-in today -> warning (critical when repeated routine misses escalate)
- repeated missed routine signals (3+ today) -> critical active alert
- incident dismissed -> resolved info item

## G5 Settings + Wellbeing + Safety Expansion

Group 5 extends the product into a fuller daily companion, while staying local-first:

- **Settings expansion**
  - Senior settings: text size, high contrast, notifications, reminder intensity, language, emergency label, simplified mode
  - Guardian settings: notifications, alert sensitivity, digest toggles, module visibility toggles, linked senior info visibility
  - Permission UX maps denied/permanently denied/restricted/limited states to clear actions (request vs open system settings)
  - Connectivity mode scaffold (online/degraded/offline) is persisted locally for degraded-state simulation
  - Settings persist per active profile in `SharedPreferences` through `LocalSettingsRepository`
- **Hydration module**
  - Senior flow with deterministic morning/afternoon/evening slots
  - Guardian monitoring with completion/missed snapshots and activity feed
  - Events: `hydrationCompleted`, `hydrationMissed`
- **Nutrition module**
  - Senior flow with breakfast/lunch/dinner completion/missed states
  - Guardian monitoring with daily and weekly-style snapshots
  - Events: `mealCompleted`, `mealMissed`
- **Safe-zone prototype module**
  - Guardian safe-zone list and simulated location update controls
  - Local enter/exit derivation and status tracking using Hive-backed safe-zone entities
  - Events: `safeZoneEntered`, `safeZoneExited`
- **Deterministic summaries**
  - Senior summary (`/senior/summary`) and guardian digest (`/guardian/summary`)
  - Local, rule-based generation from persisted event history + status engine (no AI/LLM)

### G5 routes

- Senior:
  - `/senior/hydration`
  - `/senior/nutrition`
  - `/senior/summary`
- Guardian:
  - `/guardian/hydration`
  - `/guardian/nutrition`
  - `/guardian/location`
  - `/guardian/summary`

## Voice Companion

The senior voice companion is the only AI surface in the Flutter app:

- **Senior Companion** (`/senior/companion`)
  - records senior speech and sends it to the configured voice gateway
  - gateway performs STT, LLM reasoning, and TTS outside the Flutter app
- **Guardian Insights** (`/guardian/insights`)
  - no chat/AI in this build; links guardians to alerts, timeline, and deterministic summaries
- **Grounding policy**
  - repositories, status engine, alerts, and deterministic summaries remain factual source of truth
  - the app sends compact context with each voice request
  - no diagnosis, no invented incidents, and no AI-owned alert/status decisions

### Companion routes

- Senior:
  - `/senior/companion`
- Guardian:
  - `/guardian/insights`

## Technical UX hardening

- Senior home keeps core actions visible by default and moves secondary actions
  (hydration, meals, daily summary) behind **More options**.
- Senior and guardian homes now render a connectivity banner in degraded/offline
  mode while continuing to operate from local persisted data.
- Settings now provides explicit permission guidance for denied and permanently
  denied states, including an open-system-settings path.
- Settings exposes notification permission and demo controls from both senior
  and guardian roles so APK testers can recover/reset without hidden paths.
- Event notifications are produced centrally from persisted domain events, not
  from one-off widget code.

## Demo data reset flow (G1)

From **Settings**:
- **Clear Session** -> removes current local session and returns to onboarding.
- **Reseed Demo Data** -> recreates deterministic local demo profiles/links.
- **Reset Demo Data** -> clears structured demo data + session and returns to onboarding.

## Native platform note (important)

`android/` and `ios/` are part of the final deliverable. If you regenerate platforms locally, keep
permission declarations aligned with current prototype features:
- Android: notifications + location in `android/app/src/main/AndroidManifest.xml`
- iOS: in-use location usage description in `ios/Runner/Info.plist`

## APK demo path

For Android demo testing:

```bash
fvm flutter pub get
fvm flutter build apk --debug
```

Install with:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

For a release-style local APK:

```bash
fvm flutter build apk --release
```

See `docs/demo_runbook_g8.md` for the recommended demo story and reset flow.

## Project structure

```text
lib/
  app/
    app.dart
    bootstrap/
    router/
    theme/
  core/
    connectivity/
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
    check_in/
    home/
    hydration/
    incident/
    location/
    medication/
    nutrition/
    senior/
    guardian/
    settings/
    summary/
  shared/
    constants/
    models/
    utils/
    widgets/
```

## Documentation

- `docs/setup.md` - setup and run instructions
- `docs/architecture.md` - architecture and extension guidance for next groups
- `docs/release_readiness_g7_2.md` - current implementation status and non-goals
- `docs/qa_test_matrix_g7_2.md` - manual QA matrix for demo/validation
- `docs/demo_runbook_g8.md` - final Android demo setup, scenario, and voice gateway guide
- `docs/final_qa_checklist_g8.md` - final handoff QA checklist
