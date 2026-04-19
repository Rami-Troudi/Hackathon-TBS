# QA Test Matrix — G7.2

Historical QA matrix for the G7.2 stabilization state. For final G8 handoff,
use `docs/final_qa_checklist_g8.md`.

Manual test matrix for implemented production flows.  
Run on at least one Android target and one iOS target when available.

| Flow | Objective | Setup / Preconditions | Test steps | Expected result | Edge cases / regressions to watch |
|---|---|---|---|---|---|
| Onboarding | Create local session from role + profile selection | Fresh app state (Clear Session or Reset Demo Data) | 1. Launch app. 2. Select role. 3. Select profile. | Session is created and user lands on `/senior` or `/guardian` matching role. | Missing profile list, wrong post-onboarding route, duplicate session creation. |
| Splash/session restore | Restore valid local session to role home | Existing valid session for senior and guardian (test separately) | 1. Kill app. 2. Relaunch. | Splash routes directly to correct role home without onboarding. | Wrong role restored, splash loops, stale profile id not handled. |
| Senior home | Validate low-cognitive-load home with core actions | Active senior session + seeded data | 1. Open `/senior`. 2. Confirm primary actions and routine card. 3. Open More options. | Core actions visible; secondary actions (hydration/meals/summary) available via More options. | Action density regression, missing companion/medication entry, broken banner display in degraded/offline mode. |
| Check-in | Persist check-in/help events and state transitions | Senior session | 1. Open `/senior/check-in`. 2. Tap “I’m okay”. 3. Re-open screen. 4. Tap “I need help” path (fresh day or reseeded state). | Check-in state updates and events persist; help path records escalation event chain. | Duplicate completion handling, incorrect pending/completed/missed transitions. |
| Medication | Persist medication taken/missed actions | Senior session with seeded plans | 1. Open `/senior/medication`. 2. Mark reminder taken. 3. Mark another skipped/missed. | Reminder statuses update and persist; guardian side reflects adherence changes. | Wrong reminder reconciliation, no cross-screen update, stale pending counts. |
| Incident/help | Validate suspicious incident confirmation/escalation flow | Senior session | 1. Open `/senior/incident`. 2. Trigger suspicious incident path. 3. Confirm/dismiss and test emergency action. | Incident state and timeline events reflect action deterministically. | Incident chain not closing, emergency not escalating status/alerts. |
| Guardian dashboard | Validate high-level status, cards, and route entry points | Guardian session linked to seeded senior | 1. Open `/guardian`. 2. Use quick actions and module cards. | Dashboard shows status/metrics and navigates to each target module route. | Broken card navigation, wrong counts after senior actions, missing AI insights entry. |
| Alerts | Validate local alert derivation and state transitions | Guardian session with events that produce alerts | 1. Open `/guardian/alerts`. 2. Acknowledge one alert. 3. Resolve one alert. | Alert state updates locally and persists across navigation. | Severity misclassification, unresolved critical alerts not shown. |
| Timeline | Validate chronological event history and filters | Guardian session with mixed event history | 1. Open `/guardian/timeline`. 2. Apply each filter chip. | Timeline remains deterministic and shows matching event groups. | Filter mismatch, order regression (newest-first), missing recent events. |
| Profile | Validate linked senior overview data | Guardian session | 1. Open `/guardian/profile`. | Linked senior identity and monitoring context render correctly. | Missing profile link handling, stale profile info after reseed. |
| Hydration | Validate senior actions and guardian monitoring snapshot | Senior + guardian sessions | 1. Senior marks hydration completed/missed. 2. Guardian opens `/guardian/hydration`. | Slot state persists and guardian monitoring reflects updates. | Slot reconciliation regressions, counts not synced through event history. |
| Nutrition | Validate meal actions and guardian monitoring snapshot | Senior + guardian sessions | 1. Senior marks meals completed/missed. 2. Guardian opens `/guardian/nutrition`. | Meal state persists and guardian monitoring updates. | Incorrect missed meal reconciliation, stale summary cards. |
| Safe-zone/location prototype | Validate simulated location updates and safe-zone status | Guardian session; default safe zones seeded | 1. Open `/guardian/location`. 2. Trigger simulated movement in/out safe zone. | Status, zone label, and related alerts/events update deterministically. | False enter/exit transitions, unresolved outside-zone status not surfaced. |
| Summaries | Validate deterministic senior/guardian summaries | Sessions with current-day events | 1. Open `/senior/summary`. 2. Open `/guardian/summary`. | Summaries reflect real local facts and status (no fabricated events). | Summary drift from timeline, missing actionable points. |
| Senior companion | Validate grounded companion with fallback resilience | Senior session; test with no AI provider defines | 1. Open `/senior/companion`. 2. Use suggestion chips and free-text prompts. | Responses are calm/simple, grounded in local data, and usable in fallback mode. | Ungrounded answers, over-claiming language, dead screen when provider unavailable. |
| Guardian insights | Validate assistant explanations and actionable guidance | Guardian session; active alerts/history present | 1. Open `/guardian/insights`. 2. Ask “What changed today?” and “What needs attention?”. | Responses explain alerts/status from deterministic local facts. | Invented incidents, missing explanation for active alerts, non-concise responses. |
| Settings | Validate profile-scoped settings + permission actions | Active session | 1. Open `/settings`. 2. Toggle role-specific settings. 3. Trigger permission actions. | Preferences persist per profile; denied/permanently denied states map to proper action. | Settings bleed across profiles, wrong permission CTA (request vs system settings). |
| Reset/reseed demo data | Validate repeatable demo preparation | Any active session | 1. In settings, run Clear Session. 2. Reseed Demo Data. 3. Reset Demo Data. 4. Relaunch. | App returns to expected onboarding/session state and seeded profiles are recreated predictably. | Partial reset (stale entities), crash on relaunch, inconsistent seed marker behavior. |

## Manual pass criteria

- No route crashes across listed flows.
- Event-driven state changes are visible on downstream screens without restarting app.
- Companion/insights remain usable in deterministic fallback mode.
- Product wording remains aligned with: daily support, family coordination, incident vigilance, actionable alerts.
