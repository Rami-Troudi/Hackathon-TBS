# G8 Preflight Audit Report

## 1. Executive Summary

**Overall verdict:** **PARTIALLY READY**.  
The repo is technically solid (analyze/tests/build pass, route set complete, strong local-first architecture), but several product/readiness mismatches remain.

**Release/demo readiness verdict:** **READY WITH CAVEATS**

**Top 5 blockers / critical caveats**
1. **DEF-001 (Blocker):** Demo reset/reseed is not fully deterministic (profiles reset, but historical event/state stores can survive).
2. **DEF-002 (Major):** `/senior/check-in` and `/senior/incident` routes are registered but not reachable from normal senior navigation.
3. **DEF-003 (Major):** Guardian Insights implementation (chat UI) conflicts with current final QA/checklist docs expecting deterministic handoff links.
4. **DEF-004 (Major):** External gateway mode (`VOICE_GATEWAY_MODE=gateway`) still fails in live probes (`/voice` returns 524/500); only local fallback is reliable.
5. **DEF-005 (Major):** Documentation is internally inconsistent across setup/architecture/QA checklists for AI mode and insights behavior.

**Top 5 strengths**
1. Local-first architecture is coherent: repositories + event core + deterministic status/summaries/alerts.
2. Route graph is complete and registered for all required modules.
3. Automated quality baseline is strong (`flutter analyze` clean; full `flutter test` passes).
4. Android package/demo artifact exists (`build/app/outputs/flutter-apk/app-debug.apk`).
5. AI fallback path is robust and demo-safe by default (`VOICE_GATEWAY_MODE=local_fallback`).

---

## 2. Audit Scope

- **Repository:** `Rami-Troudi/Hackathon-TBS`
- **Branch:** `Rami`
- **Audit mode:** code audit + automated validation + targeted endpoint probes + test-suite audit
- **Environment assumptions:**
  - Local-first product (no required backend for core product flows)
  - External voice gateway optional
  - Flutter toolchain available
- **External AI mode configured?**
  - Default runtime is now local fallback mode
  - External mode tested explicitly with `VOICE_GATEWAY_MODE=gateway`
- **Device/emulator assumptions:**
  - Automated tests executed
  - Live endpoint probes executed via `curl`
  - Full manual tap-through on physical Android/iOS device: **Not verified**

---

## 3. Documentation Consistency Audit

| ID | Mismatch | Severity | Evidence | Recommendation |
|---|---|---|---|---|
| DOC-001 | Guardian Insights docs in legacy QA files still describe deterministic handoff/no chat, but screen now implements conversational assistant UI. | Major | `docs/qa_test_matrix_g7_2.md`, `docs/final_qa_checklist_g8.md` vs `lib/features/companion/guardian_insights_screen.dart` | Align QA docs to current implemented behavior (or revert implementation). |
| DOC-002 | `docs/architecture.md` voice section still implies gateway-first narrative and does not clearly state local fallback is default mode now. | Major | `docs/architecture.md` (voice section) vs `lib/core/config/app_config.dart` default `VOICE_GATEWAY_MODE=local_fallback` | Update architecture doc to current default and opt-in gateway mode. |
| DOC-003 | README states Developer Hub can be opened from Senior/Guardian screens; current UI path is via onboarding role screen. | Minor | `README.md` vs navigation in `senior_home_screen.dart`, `guardian_home_screen.dart`, `role_selection_screen.dart` | Correct UI path description. |
| DOC-004 | Legacy readiness files (`release_readiness_g7_2.md`) contain historical statements conflicting with current G8 implementation state. | Minor | `docs/release_readiness_g7_2.md` | Mark as archival or refresh with explicit historical label. |
| DOC-005 | Route references are mostly accurate but `/settings` path visibility in top-level docs is uneven. | Minor | README/setup route lists vs router | Add one canonical route table in README and link from setup/architecture. |

---

## 4. Route and Screen Coverage Audit

Legend:
- **Reachable?** = reachable through normal in-app UI navigation
- **Loads?** = verified by registration/tests/static inspection
- **Correct role?** = intended role context alignment
- **Documented?** = reflected in current docs

| Route | Reachable? | Loads? | Correct role? | Documented? | Result | Notes |
|---|---|---|---|---|---|---|
| `/splash` | Yes (startup) | Yes | Shared | Yes | PASS | Initial route in router. |
| `/onboarding/role` | Yes | Yes | Shared | Yes | PASS | Splash fallback + settings clear/reset. |
| `/onboarding/profile/:role` | Yes | Yes | Shared | Yes | PASS | Reached from role selection. |
| `/home` | Yes (onboarding role screen) | Yes | Shared | Yes | PASS | Developer hub exists; entry path docs partially drifted. |
| `/settings` | Yes | Yes | Shared/role-aware | Partial | PASS | Reachable from app bars and guardian bottom nav. |
| `/senior` | Yes | Yes | Senior | Yes | PASS | Normal senior landing. |
| `/senior/check-in` | **No normal UI path found** | Yes | Senior | Yes | FAIL | Registered route exists but no push from senior home/cards. |
| `/senior/medication` | Yes | Yes | Senior | Yes | PASS | Senior routine card. |
| `/senior/incident` | **No normal UI path found** | Yes | Senior | Yes | FAIL | Registered route exists but not linked in senior home. |
| `/senior/hydration` | Yes | Yes | Senior | Yes | PASS | Via "More options". |
| `/senior/nutrition` | Yes | Yes | Senior | Yes | PASS | Via "More options". |
| `/senior/summary` | Yes | Yes | Senior | Yes | PASS | Via "More options". |
| `/senior/companion` | Yes | Yes | Senior | Yes | PASS | Primary action card. |
| `/guardian` | Yes | Yes | Guardian | Yes | PASS | Normal guardian landing. |
| `/guardian/alerts` | Yes | Yes | Guardian | Yes | PASS | App bar + quick actions + bottom nav context. |
| `/guardian/timeline` | Yes | Yes | Guardian | Yes | PASS | App bar + quick actions + bottom nav context. |
| `/guardian/check-ins` | Yes | Yes | Guardian | Yes | PASS | Monitoring card / deep links. |
| `/guardian/medication` | Yes | Yes | Guardian | Yes | PASS | Monitoring card / deep links. |
| `/guardian/incidents` | Yes | Yes | Guardian | Yes | PASS | Monitoring card / deep links. |
| `/guardian/profile` | Yes | Yes | Guardian | Yes | PASS | Quick action. |
| `/guardian/hydration` | Yes (settings-conditional) | Yes | Guardian | Yes | PASS | Visible if reminders enabled. |
| `/guardian/nutrition` | Yes (settings-conditional) | Yes | Guardian | Yes | PASS | Visible if reminders enabled. |
| `/guardian/location` | Yes (settings-conditional) | Yes | Guardian | Yes | PASS | Visible if location updates enabled. |
| `/guardian/summary` | Yes | Yes | Guardian | Yes | PASS | Bottom nav + digest card. |
| `/guardian/insights` | Yes | Yes | Guardian | Yes (inconsistently described) | PARTIAL | Works, but docs disagree on expected UX behavior. |

---

## 5. UI Action / Button Audit

> Evidence sources: screen implementations + widget/provider tests + route wiring.
> Items marked **Not verified** require device-level manual interaction.

| Screen | Action / Button | Expected | Actual | Result | Severity | Notes |
|---|---|---|---|---|---|---|
| Splash | Auto navigation | Restore session or route onboarding | Implemented with role/session checks | PASS | — | Covered by splash routing tests. |
| Onboarding Role | Continue as Senior | Open senior profile selection | Works | PASS | — | |
| Onboarding Role | Continue as Guardian | Open guardian profile selection | Works | PASS | — | |
| Onboarding Role | Open developer demo hub | Navigate to `/home` | Works | PASS | — | |
| Profile Selection | Select profile card | Create session and route to role home | Works | PASS | — | |
| Profile Selection | Back to role selection | Return to `/onboarding/role` | Works | PASS | — | |
| Home (Developer Hub) | Senior Home | Open `/senior` | Works | PASS | — | |
| Home (Developer Hub) | Guardian Dashboard | Open `/guardian` | Works | PASS | — | |
| Home (Developer Hub) | Switch role | Toggle preferred role | Works | PASS | — | |
| Home (Developer Hub) | Generate check-in completed | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Generate check-in missed | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Generate medication taken/missed | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Generate hydration/meal events | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Generate incident/emergency events | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Generate safe-zone events | Publish/persist event | Works | PASS | — | |
| Home (Developer Hub) | Clear event history | Clear persisted event timeline | Works | PASS | — | |
| Home (Developer Hub) | Trigger info notification | Show local notification if granted | PARTIAL | Minor | Logic present; OS delivery not fully device-verified. |
| Senior Home | Settings icon | Open settings | Works | PASS | — | |
| Senior Home | I'm okay | Record check-in completed | Works | PASS | — | |
| Senior Home | I need help | Record escalation/help event | Works | PASS | — | |
| Senior Home | Talk to Companion | Open companion screen | Works | PASS | — | |
| Senior Home | Medication card | Open medication screen | Works | PASS | — | |
| Senior Home | More options | Open bottom sheet actions | Works | PASS | — | |
| Senior Home sheet | Hydration | Open hydration screen | Works | PASS | — | |
| Senior Home sheet | Meals | Open nutrition screen | Works | PASS | — | |
| Senior Home sheet | Daily summary | Open summary screen | Works | PASS | — | |
| Check-in screen | “I’m okay” | Persist completion | Works | PASS | — | |
| Check-in screen | “I need help” path | Persist help/escalation | Works | PASS | — | |
| Medication screen | “Taken” | Persist medication taken | Works | PASS | — | |
| Medication screen | “Skip for now” | Persist medication missed | Works | PASS | — | |
| Incident screen | “I need help now” | Trigger emergency flow | Works | PASS | — | |
| Incident screen | “I’m okay” | Dismiss incident state | Works | PASS | — | |
| Hydration screen | Done / Not now | Persist hydration slot status | Works | PASS | — | |
| Nutrition screen | Done / Not now | Persist meal slot status | Works | PASS | — | |
| Senior Summary | Open/read summary cards | Show deterministic summary | Works | PASS | — | |
| Senior Companion | Talk to Companion | Start recording flow | PARTIAL | Major | Works in fallback mode; external mode unstable. |
| Senior Companion | Stop and send | Process recording and return response | PARTIAL | Major | External gateway may timeout; fallback path works. |
| Senior Companion | Replay answer | Replay last response WAV | PASS | — | |
| Senior Companion | Cancel | Stop playback/record state | PASS | — | |
| Senior Companion | Suggestion chips | N/A | N/A | Not verified | — | Senior companion currently mic-first, no suggestion chips UI. |
| Guardian Home | Alerts icon | Open alerts | PASS | — | |
| Guardian Home | Timeline icon | Open timeline | PASS | — | |
| Guardian Home | Settings icon | Open settings | PASS | — | |
| Guardian Home | Quick Alerts/Timeline/Senior buttons | Navigate to target routes | PASS | — | |
| Guardian Home | Monitoring cards (all modules) | Open module screens | PASS | — | |
| Guardian Home | AI insights card | Open guardian insights | PASS | — | |
| Guardian Alerts | Acknowledge | Update alert state | PASS | — | |
| Guardian Alerts | Resolve | Update alert state | PASS | — | |
| Guardian Alerts | Open timeline | Navigate | PASS | — | |
| Guardian Alerts | Open module from alert | Navigate by alert type | PASS | — | |
| Guardian Timeline | Filter chips | Apply event-type filter | PASS | — | |
| Guardian Timeline | Open alerts button | Navigate | PASS | — | |
| Guardian monitoring sub-screens | App bar shortcuts | Navigate back to key modules | PASS | — | |
| Guardian Location | Add zone | Create safe zone | PASS | — | |
| Guardian Location | Zone tap simulate | Simulate enter/exit | PASS | — | |
| Guardian Location | Delete zone | Remove safe zone | PASS | — | |
| Guardian Location | Simulate outside | Set outside safe zone state | PASS | — | |
| Guardian Location | Edit zone | Modify zone config | FAIL | Minor | No explicit edit action detected. |
| Guardian Summary | Open/read summary | Show deterministic summary data | PASS | — | |
| Guardian Insights | Suggestion chips | Trigger grounded answers | PASS | — | |
| Guardian Insights | Text input + Send | Ask contextual Q&A | PASS | — | |
| Guardian Insights | Direct links to alerts/summary/timeline | Deterministic handoff navigation | FAIL | Major | Not implemented on current screen; docs/checklists expect this. |
| Settings | Notification permission request/open settings | Request/open based on state | PARTIAL | Minor | UI logic present; runtime OS behavior not fully verified. |
| Settings | Location permission request/open settings | Request/open based on state | PARTIAL | Minor | Same as above. |
| Settings | Connectivity mode selector | Set online/degraded/offline | PASS | — | |
| Settings | Switch role for testing | Swap role/profile and route | PASS | — | |
| Settings | Clear session | Clear session + route onboarding | PASS | — | |
| Settings | Reseed demo data | Recreate demo profiles/links | PARTIAL | Blocker | Does not fully reset all persisted state stores. |
| Settings | Reset demo data | Reset and route onboarding | PARTIAL | Blocker | Same data-scope gap; stale state risk remains. |

---

## 6. Feature Flow Audit

### Senior scenarios

| Scenario | Result | Severity | Notes |
|---|---|---|---|
| First launch -> onboarding as senior | PASS | — | Implemented and tested. |
| Session restore as senior | PASS | — | Splash routing tests cover role restoration. |
| Senior home -> check-in completed | PASS | — | Action works from senior home and check-in screen. |
| Senior home -> need help | PASS | — | Escalation event path implemented. |
| Medication confirmation | PASS | — | Taken action persists. |
| Medication skip/miss handling | PASS | — | Missed action persists and reflected in monitoring. |
| Incident suspicious/confirm/dismiss/emergency | PARTIAL | Major | Confirm/dismiss/emergency exist; suspicious initiation path not clearly surfaced from senior UI. |
| Hydration completion/miss | PASS | — | Deterministic local flow works. |
| Nutrition completion/miss | PASS | — | Deterministic local flow works. |
| Senior summary access | PASS | — | Reachable via More options. |
| Senior companion open + first response | PARTIAL | Major | Reliable in local fallback mode; gateway mode unstable. |
| Senior companion suggestion chips | NOT IMPLEMENTED | Minor | Current implementation is voice-first mic UX. |
| Settings changes reflected in senior experience | PASS | — | Large text/simplified mode/language affect UI. |

### Guardian scenarios

| Scenario | Result | Severity | Notes |
|---|---|---|---|
| First launch -> onboarding as guardian | PASS | — | Implemented. |
| Session restore as guardian | PASS | — | Splash routing covered. |
| Dashboard loads | PASS | — | Provider/screen tests present. |
| Top alerts navigation | PASS | — | Works from app bar/cards. |
| Timeline navigation and filters | PASS | — | Filter chips + route wiring work. |
| Check-in monitoring | PASS | — | Dedicated screen. |
| Medication monitoring | PASS | — | Dedicated screen. |
| Incident monitoring | PASS | — | Dedicated screen. |
| Hydration monitoring | PASS | — | Conditional visibility works. |
| Nutrition monitoring | PASS | — | Conditional visibility works. |
| Location/safe-zone screen | PASS | — | Add/delete/simulate flows present. |
| Summary screen | PASS | — | Deterministic digest view present. |
| Guardian insights / AI screen | PARTIAL | Major | Screen works, but behavior/documentation contract mismatch persists. |
| Settings changes reflected in guardian experience | PASS | — | Preferences and module visibility are role-scoped. |

### Shared/system scenarios

| Scenario | Result | Severity | Notes |
|---|---|---|---|
| Clear session | PASS | — | Returns onboarding. |
| Reseed demo data | PARTIAL | Blocker | Only profiles/links reseeded; historical stores may remain. |
| Reset demo data | PARTIAL | Blocker | Same persistent-state scope gap. |
| Switch role for testing | PASS | — | Implemented in settings. |
| Connectivity mode behavior | PASS | — | Banner and state toggles implemented. |
| Permission request flows | PARTIAL | Minor | Code-level pass; full OS UX not fully device-verified. |
| Notification permission handling | PARTIAL | Minor | Service gating works; runtime delivery not fully verified on device. |
| Location permission handling | PARTIAL | Minor | Similar to above. |

---

## 7. Notifications Audit

**Current implementation status:** **Implemented and wired**

### What works
- Notification dispatch is connected to event persistence:
  - `AppEventRecorder.publishAndPersist(...)` triggers `afterPersist`
  - `afterPersist` wired to `AppEventNotificationDispatcher.dispatch(...)`
- Severity mapping implemented:
  - warning: missed check-in/medication/hydration/meal, safe-zone exited
  - critical: confirmed incident (unless emergency follows), emergency triggered
- Suppression logic exists:
  - notifications disabled for active profile -> event notification skipped
  - completion/non-critical events are ignored to avoid spam

### What is missing / caveats
- No background scheduler or push backend (intentional local-first limitation).
- Triggering missed-event notifications depends on local reconciliation/event generation timing.
- Device-level foreground/background notification behavior not fully verified in this audit run.

### Demo impact
- **Not a blocker** for local-first demo if notification scenarios are staged via in-app events.
- **Major caveat** if demo requires strict background-time guarantees.

---

## 8. Permissions and Native Config Audit

### UI permission flow
- Settings screen exposes:
  - Notification permission state + action row
  - Location permission state + action row (guardian contexts)
  - Action mapping: none / request / open system settings
- **Status:** PARTIAL PASS (UI logic verified; full OS interaction not fully device-verified)

### Service layer
- `PermissionHandlerPermissionService` supports:
  - status + request for notification and location
  - open app settings
- Notification service checks permission before showing.

### Native layer
- **AndroidManifest:** includes INTERNET, RECORD_AUDIO, POST_NOTIFICATIONS, COARSE/FINE_LOCATION.
- **iOS Info.plist:** includes microphone and location usage descriptions.

### Docs mismatch / risk
- Docs still have conflicting wording in some files around AI mode and guardian insights behavior.

### Demo impact
- Native permission declarations are coherent for implemented scope.
- Remaining risk is UX/documentation consistency, not missing manifest/plist keys.

---

## 9. AI / Companion / Insights Audit

### Senior Companion
- Opens and initializes.
- Voice flow controller is hardened:
  - min 3-second capture rule
  - typed gateway errors
  - deterministic local guidance on failures
- **Fallback mode quality:** good for demo continuity (`local_fallback` default).
- **External mode:** currently unreliable due upstream gateway 524/500.

### Guardian Insights
- Screen opens, initializes with assistant state, supports suggestions + text input/send.
- Response generation is grounded in local context (alerts/summary/timeline/status heuristics).
- **Anomaly:** current implementation conflicts with final QA docs that expect deterministic handoff links and no chat controls.

### Grounding quality
- Generally grounded to local repositories and deterministic summaries.
- No obvious fabricated event memory patterns in code path.

### Overall AI assessment
- **Fallback/local mode:** PASS
- **External mode:** PARTIAL (major caveat)

---

## 10. Persistence / State / Demo Data Audit

| Area | Status | Notes |
|---|---|---|
| Onboarding session creation | PASS | Role/profile creates local session and routes correctly. |
| Splash session restore | PASS | Routing logic and tests exist. |
| Role switching | PASS | Settings role switch implemented. |
| Settings persistence | PASS | Role-scoped settings repo tests present. |
| Event propagation to dashboard/timeline/alerts | PASS | Deterministic event-driven repositories and provider invalidation implemented. |
| Reseed demo data | PARTIAL | Recreates profiles/links but does not guarantee full store reset. |
| Reset demo data | PARTIAL | Clears profiles/session + seed marker; does not clear all other persisted domain data. |
| Cross-role coherence after activity | PARTIAL | Logic is strong, but deterministic full reset gap can produce stale mixed-state demos. |

---

## 11. UX / Accessibility Audit

### Senior UX
- **Strengths:** primary actions are clear and large; secondary actions tucked under “More options”; calm copy in key places.
- **Issues:** dedicated check-in/incident screens are not surfaced from senior home navigation despite being routed/doc’d.

### Guardian UX
- **Strengths:** dashboard is information-dense but reasonably scan-friendly; alert/timeline access is strong.
- **Issues:** Guardian Insights behavior currently diverges from checklist expectation (chat vs deterministic handoff links), which creates product messaging confusion.

### Terminology consistency
- Mostly aligned to “daily support/actionable alerts/local-first”.
- Some docs still contain older wording inconsistent with current AI behavior defaults.

### Critical usability issues
- Demo reset determinism gap can break repeatable scenario walkthroughs.

---

## 12. Automated Test Suite Audit

**Confidence level:** **PARTIAL-STRONG**

### Strongest covered areas
- Routing sanity and splash routing
- Core local repositories (check-in/medication/incident/hydration/nutrition/safe-zone/summary/settings/events)
- Guardian alert derivation and timeline filters
- Senior home and guardian home route entry tests
- Voice fallback/error mapping/provider behavior
- Notification dispatch policy mapping

### Weakest / uncovered areas
- Full device-level E2E UI tapping across all screens/buttons
- OS permission dialogs and settings-return behavior
- Real external gateway STT/TTS roundtrip success path
- Android/iOS runtime notification behavior in background
- Explicit tests for demo reset clearing all persistent stores

### Recommended missing tests (high value)
1. End-to-end widget/integration test for reset/reseed determinism across all stores.
2. Navigation reachability tests for `/senior/check-in` and `/senior/incident` from production senior UX.
3. Guardian insights product-contract test (chat mode vs deterministic handoff expectation).
4. Device integration test for permission CTA request/open-settings path.

---

## 13. Conformity to Product Requirements

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Local-first prototype | CONFORMANT | Local repositories/event core; no required backend | Backend absence is intentional. |
| No backend required | CONFORMANT | Core flows run on local state | Dio remains scaffold/future. |
| Bounded AI | PARTIALLY CONFORMANT | Fallback deterministic and grounded; external mode unstable | External reliability caveat remains. |
| Explainable status model | CONFORMANT | Deterministic status engine + summaries + alerts | |
| Senior-first simplicity | PARTIALLY CONFORMANT | Senior home simplified; some route/flow mismatch remains | Check-in/incident route reachability mismatch. |
| Guardian clarity | PARTIALLY CONFORMANT | Dashboard strong; insights behavior/docs mismatch | |
| Actionable alerts | CONFORMANT | Alert derivation + acknowledge/resolve + notification mapping | |
| No medical overclaiming | CONFORMANT | Copy mostly bounded and non-medical | |
| Not fall-detector-first framing | CONFORMANT | Product language focuses on daily support/coordination | |
| Hackathon demo suitability | PARTIALLY CONFORMANT | Build/test strong, fallback mode works | Reset determinism + doc drift + gateway caveat. |
| Business/demo plausibility | PARTIALLY CONFORMANT | Coherent prototype architecture | Needs tighter doc-product alignment for judging. |

---

## 14. Android APK Demo Readiness

**Verdict:** **READY WITH CAVEATS**

### Why not NOT READY
- Build artifact exists and app label is correct.
- Local-first flows and fallback AI mode support demo continuity.
- Core automated checks pass.

### Caveats before recording demo
1. Fix/reset determinism issue (or use strict demo script avoiding stale-state paths).
2. Align Guardian Insights behavior and QA docs to one product contract.
3. Do not depend on external gateway mode during live demo unless gateway health is proven immediately before recording.
4. Ensure manual role-route script includes entry for check-in/incident if those screens remain non-discoverable from senior home.

---

## 15. Final Defect List

| ID | Title | Severity | Affected module | Reproduction | Expected | Actual | Suspected cause |
|---|---|---|---|---|---|---|---|
| DEF-001 | Demo reset/reseed is not full-state deterministic | **Blocker** | `local_demo_seed_repository`, Settings demo controls | Use app for events/settings, then Reset/Reseed; re-enter with same seeded profiles | Full clean deterministic demo baseline | Profiles reset but non-profile persisted state can survive | Reset/reseed only clears profiles + seed marker + session |
| DEF-002 | Dead senior routes in normal UX (`/senior/check-in`, `/senior/incident`) | Major | Senior home navigation | Use senior UI navigation only | Dedicated check-in and incident screens should be reachable | Routes exist but no normal in-app entry path found | UX wiring drift after simplifying senior home actions |
| DEF-003 | Guardian Insights implementation conflicts with final QA contract | Major | Guardian insights + docs | Open `/guardian/insights`; compare with checklist expectation | Either deterministic handoff links OR documented chat assistant contract | Current UI is chat assistant; docs/checklist still expect no chat controls | Feature/docs drift |
| DEF-004 | External AI voice mode unstable | Major | External gateway mode | Run with `VOICE_GATEWAY_MODE=gateway`, POST valid WAV to `/voice` | Stable STT/TTS response | 524/500 observed in probes | Upstream gateway runtime/timeouts |
| DEF-005 | Architecture docs outdated for voice mode defaults | Major | `docs/architecture.md` | Compare config defaults and architecture section | Docs match runtime defaults | Runtime defaults local fallback; docs imply gateway-first default | Documentation not updated after mode change |
| DEF-006 | README navigation hint to Developer Hub is inaccurate | Minor | README | Follow README from senior/guardian screens | Reachable per documented path | Actual entry is from onboarding role screen | Documentation drift |
| DEF-007 | Incident suspicious-flow wording overstates discoverability | Minor | QA checklist/docs vs UI | Follow checklist “incident suspected/confirmed...” from normal senior UX | Fully discoverable suspicious-flow controls | Core incident transitions exist but suspicious trigger discoverability is limited | UX + docs mismatch |
| DEF-008 | Safe-zone explicit edit action missing | Minor | Guardian location screen | Manage existing zone | Add/edit/delete should be available if specified | Add/delete/simulate exists; edit control absent | Feature completeness gap vs expectation wording |
| DEF-009 | Permission/runtime behavior not fully evidenced in final QA docs | Minor | Settings/permissions docs | Follow docs for full permission QA | Device-verified behavior evidence | Mostly code-level assertions; limited runtime evidence | QA artifact incompleteness |

---

## 16. Final Recommendations Before G8/G8.1 Fixes

1. **Blocker first:** make reset/reseed truly deterministic across all persistent stores (events, settings, plans, safe-zone, links/profile/session).
2. Resolve product contract for Guardian Insights (chat assistant vs deterministic handoff) and align implementation + docs + checklist.
3. Add explicit senior-home navigation entries (or clear rationale) for check-in and incident route discoverability.
4. Update architecture docs to reflect current AI mode defaults and fallback/gateway behavior.
5. Keep default demo script on local fallback mode; treat external gateway as optional pre-validated enhancement.
6. Add high-value regression tests for reset determinism and route discoverability.

---

## 17. Appendices

### A. Tested routes
- `/splash`
- `/onboarding/role`
- `/onboarding/profile/:role`
- `/home`
- `/settings`
- `/senior`
- `/senior/check-in`
- `/senior/medication`
- `/senior/incident`
- `/senior/hydration`
- `/senior/nutrition`
- `/senior/summary`
- `/senior/companion`
- `/guardian`
- `/guardian/alerts`
- `/guardian/timeline`
- `/guardian/check-ins`
- `/guardian/medication`
- `/guardian/incidents`
- `/guardian/profile`
- `/guardian/hydration`
- `/guardian/nutrition`
- `/guardian/location`
- `/guardian/summary`
- `/guardian/insights`

### B. Tested roles
- Senior
- Guardian
- Shared/onboarding context

### C. Tested scenarios (high-level)
- Startup/session restore/onboarding
- Senior daily modules and companion
- Guardian dashboard/monitoring modules/insights
- Settings + demo controls + permission CTAs
- Notification pipeline mapping
- AI fallback mode + external gateway probe
- APK artifact readiness check

### D. Validation commands used
- `flutter analyze`
- `flutter test`
- `flutter test --machine` (done=true)
- External probe: `curl` against `/health`, `/openapi.json`, `/voice`
- APK artifact check: `build/app/outputs/flutter-apk/app-debug.apk`

### E. Not verified / skipped (and why)
- Full physical-device manual tap-through for every OS permission transition.
- Foreground/background notification behavior on real devices.
- Stable external STT/TTS success path in gateway mode (upstream service instability).
- iOS runtime execution (native plist checked statically, no full iOS run in this pass).

