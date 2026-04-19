# Final QA Checklist — G8

Use this checklist before handing off the final prototype or recording a demo.

## Build and Install

- [ ] `fvm flutter pub get` completes.
- [ ] `fvm flutter analyze` reports no issues.
- [ ] `fvm flutter test` passes.
- [ ] `fvm flutter build apk --debug` succeeds.
- [ ] APK installs with `adb install -r`.
- [ ] Launcher label reads **Senior Companion**.

## Onboarding and Session

- [ ] Fresh launch routes to role selection.
- [ ] Senior onboarding creates a local session and opens `/senior`.
- [ ] Guardian onboarding creates a local session and opens `/guardian`.
- [ ] Relaunch restores the last valid session.
- [ ] Clear session returns to onboarding.

## Senior Flows

- [ ] Senior home keeps primary actions clear and readable.
- [ ] Check-in "I'm okay" persists a completion event.
- [ ] Help request records incident/emergency events.
- [ ] Medication taken/missed actions persist and update state.
- [ ] Incident suspected/confirmed/dismissed/emergency transitions work.
- [ ] Hydration complete/missed state updates.
- [ ] Nutrition complete/missed state updates.
- [ ] Senior summary reflects real local events.
- [ ] Senior Companion requests microphone permission and can send audio to the configured gateway.

## Guardian Flows

- [ ] Dashboard loads linked senior status and monitoring cards.
- [ ] Alerts show deterministic local alerts.
- [ ] Alert acknowledge/resolve actions persist locally.
- [ ] Timeline shows persisted events and filters correctly.
- [ ] Check-in, medication, incident, hydration, nutrition, location, profile,
  summary, and insights entry points are reachable.
- [ ] Guardian Insights clearly links to deterministic alerts, timeline, and summaries without AI chat controls.

## Safe-Zone Prototype

- [ ] Default safe zones seed when opening location monitoring.
- [ ] Simulated movement into a zone records `safeZoneEntered`.
- [ ] Simulated movement outside zones records `safeZoneExited`.
- [ ] Unresolved outside-zone state appears in guardian alerts.
- [ ] No background location/geofencing claim appears in UI or docs.

## Notifications and Permissions

- [ ] Notification permission action is visible from Settings in senior and
  guardian sessions.
- [ ] Location permission action is visible where safe-zone testing is relevant.
- [ ] Missed check-in can trigger a warning local notification when permission
  is granted.
- [ ] Missed medication can trigger a warning local notification.
- [ ] Hydration/nutrition misses can trigger warning local notifications.
- [ ] Confirmed incident can trigger a critical local notification.
- [ ] Emergency escalation can trigger a critical local notification.
- [ ] Safe-zone exit can trigger a warning local notification.
- [ ] Completion events do not spam notifications.
- [ ] Turning off notifications in profile settings suppresses product event
  notifications for the active profile.

## Reset and Demo Controls

- [ ] Switch role for testing works from Settings.
- [ ] Reseed demo data recreates deterministic profiles and links.
- [ ] Reset demo data clears session and returns to onboarding.
- [ ] Developer Hub remains reachable for diagnostic event generation.

## Route Sanity

- [ ] `/splash`
- [ ] `/onboarding/role`
- [ ] `/onboarding/profile/senior`
- [ ] `/onboarding/profile/guardian`
- [ ] `/senior`
- [ ] `/senior/check-in`
- [ ] `/senior/medication`
- [ ] `/senior/incident`
- [ ] `/senior/hydration`
- [ ] `/senior/nutrition`
- [ ] `/senior/summary`
- [ ] `/senior/companion`
- [ ] `/guardian`
- [ ] `/guardian/alerts`
- [ ] `/guardian/timeline`
- [ ] `/guardian/check-ins`
- [ ] `/guardian/medication`
- [ ] `/guardian/incidents`
- [ ] `/guardian/profile`
- [ ] `/guardian/hydration`
- [ ] `/guardian/nutrition`
- [ ] `/guardian/location`
- [ ] `/guardian/summary`
- [ ] `/guardian/insights`
- [ ] `/settings`
- [ ] `/home` developer hub

## Offline and Degraded Assumptions

- [ ] Settings connectivity mode can switch online/degraded/offline.
- [ ] Senior and guardian home show degraded/offline banner.
- [ ] Local flows remain usable because persisted local state is source of
  truth.
- [ ] External AI failure or missing provider falls back deterministically.

## Product Language

- [ ] No medical-grade claims.
- [ ] No surveillance framing.
- [ ] No fall-detector-first positioning.
- [ ] Senior-facing copy remains calm, respectful, and simple.
- [ ] Guardian-facing copy stays actionable and grounded.
