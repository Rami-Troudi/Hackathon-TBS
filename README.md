# Senior Companion - Group 7 Prototype (AI Companion + Smart Insights)

This repository contains **Group 0 + Group 1 + Group 2 + Group 3 + Group 4 + Group 5 + Group 7** of the Senior Companion mobile prototype: a runnable local-first foundation with onboarding/session flow, structured local entity storage, persisted event/status core, real senior/guardian monitoring flows, expanded settings, wellbeing modules, safe-zone prototype logic, deterministic daily summaries, and a grounded AI companion/insights layer.

## Scope of this foundation (G0 + G1 + G2 + G3 + G4 + G5 + G7)

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
- G7 AI companion + smart insights expansion:
  - senior companion screen (`/senior/companion`) with grounded Q&A and suggestion chips
  - guardian insights screen (`/guardian/insights`) with alert/status explanations and contextual guidance
  - AI orchestration layer in `core/ai`:
    - context builder from real local repositories
    - prompt builder
    - provider adapter abstraction
    - deterministic fallback service (works with no API key/provider)
    - alert/status explanation services
  - optional external provider mode via dart-defines (no backend required)
  - deterministic repositories remain source of truth; AI only explains/rephrases/suggests
- Explicit local storage policy:
  - `SharedPreferences` for preferences/flags/light session only
  - `Hive` for structured entities (profiles, links, event records, medication plans, safe zones, runtime location state, future entities)

Not included:
- Backend/server setup
- Docker/devops
- Database infrastructure
- mandatory backend/cloud AI infrastructure
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

Optional AI configuration (G7 external mode):

```bash
fvm flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=AI_PROVIDER=openai_compatible \
  --dart-define=AI_API_KEY=your_key_here \
  --dart-define=AI_MODEL=gpt-4o-mini \
  --dart-define=AI_BASE_URL=https://api.openai.com/v1
```

If AI provider settings are omitted, the app uses deterministic local fallback responses.

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

## G7 AI Companion + Smart Insights

Group 7 adds a grounded AI layer above existing repositories/events/status/summaries:

- **Senior Companion** (`/senior/companion`)
  - calm, simple assistant for “what should I do now?”, reminders left, status, and day summary
- **Guardian Insights** (`/guardian/insights`)
  - concise assistant for “what changed?”, “what needs attention?”, alert explanations, and adherence snapshots
- **Grounding policy**
  - repositories, status engine, alerts, and deterministic summaries remain factual source of truth
  - AI output is explanation/guidance only
- **Fallback mode**
  - fully functional without any external model configuration
  - deterministic responses built from real local app context
- **External mode (optional)**
  - provider adapter supports OpenAI-compatible chat completions when configured
  - provider failures automatically degrade to deterministic fallback

### G7 routes

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
