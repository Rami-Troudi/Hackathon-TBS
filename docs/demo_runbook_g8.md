# Demo Runbook — G8 Final Prototype

This runbook prepares **Senior Companion** for Android APK testing and video
demo recording.

## 1. Setup

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

Use fallback AI mode by default. External AI is optional and not required for
the demo.

Optional external AI run:

```bash
fvm flutter run \
  --dart-define=AI_PROVIDER=openai_compatible \
  --dart-define=AI_API_KEY=your_key_here \
  --dart-define=AI_MODEL=gpt-4o-mini \
  --dart-define=AI_BASE_URL=https://api.openai.com/v1
```

## 2. Build and Install on Android

Debug APK:

```bash
fvm flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Release-style local APK:

```bash
fvm flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The app label should appear as **Senior Companion**.

## 3. Permissions

Open **Settings** in the app before recording permission-sensitive scenarios.

Grant:
- Notification permission: needed to show local alerts from missed routines,
  incidents, emergency escalation, and safe-zone exits.
- Location permission: only needed for the safe-zone prototype screen. The app
  does not run background tracking or native geofencing.

If a permission is permanently denied, use **Open System Settings** from the
Settings screen.

## 4. Reset and Reseed Demo Data

From **Settings**:
- **Clear session** returns to onboarding without reseeding.
- **Reseed demo data** recreates deterministic profiles and links.
- **Reset demo data** clears structured demo data and session, then returns to
  onboarding.

Recommended before a clean demo:

1. Open Settings.
2. Tap **Reset demo data**.
3. Relaunch or complete onboarding again.
4. Choose a senior or guardian profile depending on the scenario.

## 5. Recommended Demo Narrative

1. **Positioning**
   - "Senior Companion is daily support and family coordination for older
     adults. It is not a fall-detector-first or medical-grade product."

2. **Senior low-cognitive-load flow**
   - Onboard as a senior.
   - Show the simple home screen.
   - Tap **I'm okay**.
   - Open hydration or nutrition and mark one routine complete.
   - Open Companion and ask what to do next. If no AI provider is configured,
     point out the grounded fallback response.

3. **Incident/help flow**
   - Open incident/help.
   - Trigger suspicious incident or emergency request.
   - Show that the app records a real local event and can produce a local
     notification when permission is granted.

4. **Guardian visibility**
   - Switch role from Settings or onboard as guardian.
   - Show dashboard status, alerts, timeline, and related monitoring screens.
   - Acknowledge or resolve an alert.
   - Open Guardian Insights and ask what needs attention.

5. **Wellbeing and safe-zone expansion**
   - Show hydration/nutrition monitoring.
   - Open Location, simulate an outside-zone update, and show the derived alert.

6. **Summary**
   - Open senior or guardian summary.
   - Explain that summaries are deterministic, local, and based on persisted
     events.

## 6. Scenario Helpers

Fast scenario setup:
- Use senior flows to create real events.
- Use Developer Hub (`/home`) only when you need quick diagnostic event
  generation.
- Use Settings role switch to move between senior and guardian views on one
  demo device.

## 7. AI Fallback Flow

If no external AI provider is configured:
- Senior Companion still answers from local check-ins, medication, hydration,
  nutrition, safe-zone status, incidents, and summaries.
- Guardian Insights still explains local alerts/status using deterministic
  fallback services.
- The app should never invent events or make medical claims.

## 8. Known Prototype Limits During Demo

- No backend sync.
- No real authentication.
- No cloud database.
- Safe-zone/location is simulated/manual and foreground-only.
- Notifications are local device notifications, not push notifications.
- AI is assistive only; repositories and deterministic status/alert rules are
  the source of truth.
