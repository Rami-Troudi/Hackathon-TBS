# Release Readiness — G7.2 Stabilization

Historical stabilization snapshot before G8. For final delivery, use
`docs/demo_runbook_g8.md` and `docs/final_qa_checklist_g8.md` as the active
handoff documents.

## 1. Implemented scope through G7

Senior Companion is currently a **smartphone-first, local-first Flutter prototype** with:

- Dual role experience: **Senior** and **Guardian**
- Onboarding + local session restore from splash
- Deterministic local event core, timeline, and status engine (`ok/watch/actionRequired`)
- Senior modules: check-in, medication, incident/help, hydration, nutrition, summary
- Guardian modules: dashboard, alerts, timeline, check-ins, medication, incidents, profile, hydration, nutrition, location/safe-zone, summary
- Persisted settings and demo reset/reseed controls
- Bounded AI layer:
  - `/senior/companion`
  - `/guardian/insights`
  - grounded context from local repositories
  - deterministic fallback when no external provider is configured

## 2. G7.2 stabilization delivered

- Documentation aligned to real repository state and product positioning.
- Native permission configuration hardened for currently implemented features:
  - Android notifications + location permissions
  - iOS in-use location usage description
- Regression tests expanded for:
  - splash role restore paths
  - senior home quick actions
  - guardian dashboard route entry points
  - route registration sanity
- QA manual matrix added for all implemented flows.

## 3. Explicitly deferred to G8

- Visual polish pass and broader UX refinements beyond stabilization
- Dark theme support
- Additional external AI provider adapters beyond current OpenAI-compatible shape
- Voice interaction implementation (voice-ready structure exists, feature not shipped)
- Any backend/cloud/auth/infra work

## 4. Known prototype limitations

- Local-first only; no backend synchronization.
- No medical-grade guarantees; incident flow is vigilance support, not certified detection.
- Safe-zone/location is prototype simulation/manual update flow (no background geofencing service).
- AI responses are assistive explanations/guidance; deterministic repositories and status logic remain source of truth.
- Conversation memory is lightweight session-level behavior, not long-term assistant memory.

## 5. Demo assumptions

- Demo runs on a configured emulator/simulator or physical phone with Flutter toolchain.
- Optional AI provider defines may be absent; fallback mode must still be used during demo.
- Demo data can be reseeded/reset from Settings when scenario preparation is needed.

## 6. Manual fallback assumptions

- If no external AI provider is configured (or provider call fails), companion/insights continues with deterministic grounded responses.
- If notification/location permissions are denied, the app remains usable and surfaces explicit next actions (request or open system settings).
- If connectivity mode is degraded/offline, UI shows local-data messaging and continues operating on persisted local state.

## 7. Non-goals (for this release state)

- No backend API implementation
- No server database
- No authentication system
- No Docker/CI/devops expansion
- No G8 feature development inside G7.2
