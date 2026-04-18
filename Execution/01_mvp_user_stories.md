# MVP User Stories And Acceptance Criteria

## Priority Legend
- P0: must-have for demo
- P1: should-have if time permits

## Senior Stories

### P0-S1 Daily check-in
As a Senior, I want to confirm I am okay quickly so my family is reassured.

Acceptance criteria:
- A primary action labeled "I'm okay" is visible on Senior home.
- Tapping confirms check-in in one step.
- Confirmation creates a `CheckInCompleted` event.
- Guardian sees the update in timeline within sync window.

### P0-S2 Missed check-in escalation
As a Guardian, I want missed check-ins escalated so I can react.

Acceptance criteria:
- If no check-in occurs in configured window, system emits `CheckInMissed`.
- Alert is classified at least WARNING.
- Alert message includes expected time and elapsed delay.

### P0-S3 Medication confirmation
As a Senior, I want a simple way to confirm medication intake.

Acceptance criteria:
- Reminder presents two large actions: Taken and Ignore.
- Selecting Taken emits `MedicationTaken`.
- Selecting Ignore emits `MedicationIgnored`.
- No response inside timeout emits `MedicationMissed`.

### P0-S4 Incident vigilance confirmation
As a Senior, I want to confirm if I am safe when a suspicious incident is detected.

Acceptance criteria:
- On suspicious event, app asks "Are you okay?" with large Yes/Need help actions.
- If user selects Yes, event becomes dismissed and logged.
- If no response in timeout, escalation event is generated.

### P1-S5 Accessibility support
As a Senior, I want optional voice readout for key prompts.

Acceptance criteria:
- Key action prompts can be read aloud when option is enabled.
- Visual text remains present and primary.

## Guardian Stories

### P0-G1 Global status at a glance
As a Guardian, I want one global status so I know if action is needed.

Acceptance criteria:
- Dashboard shows one of: OK, WATCH, ACTION_REQUIRED.
- Status includes reason chips (for example: Missed check-in, Incident unresolved).
- Last update timestamp is visible.

### P0-G2 Actionable alerts
As a Guardian, I want prioritized alerts with clear next actions.

Acceptance criteria:
- Alerts are grouped by INFO, WARNING, CRITICAL.
- Each alert includes reason, timestamp, and suggested next action.
- Critical unresolved alerts stay pinned at top.

### P0-G3 Event timeline
As a Guardian, I want recent event history to understand context.

Acceptance criteria:
- Timeline shows latest events in reverse chronological order.
- Events include source module and status transitions where relevant.
- Guardian can filter by module.

### P1-G4 Escalation preferences
As a Guardian, I want simple escalation settings.

Acceptance criteria:
- Guardian can configure timeout for missed check-in and incident response.
- Guardian can configure notification channels available in MVP.

## System Stories

### P0-SYS1 Explainable rules engine
As a Product owner, I need deterministic status computation.

Acceptance criteria:
- Status engine is rule-based and documented.
- Inputs and resulting status reasons are auditable.
- No opaque AI-only status assignment.

### P0-SYS2 Audit trail
As a Team, we need traceability for key events.

Acceptance criteria:
- Every critical event and status change is timestamped.
- Event payload includes actor/source, seniorId, and correlationId.
