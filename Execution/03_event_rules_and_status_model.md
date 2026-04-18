# Event Rules And Global Status Model

## Event Taxonomy
Core event types used in MVP:
- CheckInCompleted
- CheckInMissed
- MedicationTaken
- MedicationIgnored
- MedicationMissed
- IncidentSuspected
- IncidentDismissed
- IncidentEscalated
- EmergencyTriggered
- AlertAcknowledged
- SeniorStatusChanged

## Event Envelope (Suggested)
Every event should include:
- eventId
- eventType
- occurredAt
- seniorId
- actorType (SENIOR, GUARDIAN, SYSTEM)
- sourceModule
- correlationId
- payload (module-specific)

## Global Status States
- OK
- WATCH
- ACTION_REQUIRED

## Deterministic Rules (MVP)

### Rule Group A: Immediate ACTION_REQUIRED
If any condition is true:
- unresolved incident in ESCALATED state
- emergency explicitly triggered by senior
- 2 or more critical alerts active

Then:
- status = ACTION_REQUIRED
- reasons include triggering condition keys

### Rule Group B: WATCH
If ACTION_REQUIRED is false and any condition is true:
- missed check-in still unresolved
- missed medication in last 24h above configured threshold
- incident suspected awaiting confirmation
- repeated warning alerts in short window

Then:
- status = WATCH

### Rule Group C: OK
If neither Group A nor Group B matches:
- status = OK

## Explainability Contract
For every computed status, return:
- computedStatus
- computedAt
- matchedRules[]
- humanReadableReasons[]

Example:
- computedStatus: WATCH
- matchedRules: ["B_CHECKIN_MISSED_OPEN"]
- humanReadableReasons: ["Daily check-in not received in expected time window."]

## Escalation Policy (MVP)
- Incident suspected -> ask senior confirmation immediately.
- If no response within timeout (for example 60 seconds) -> escalate to guardian.
- If guardian does not acknowledge within second timeout -> repeat critical notification.
- Optional emergency contact dispatch is manual in MVP.

## Pseudocode
```text
function computeGlobalStatus(snapshot):
  if hasEscalatedIncident(snapshot) or hasEmergencyTrigger(snapshot) or activeCriticalAlerts(snapshot) >= 2:
    return ACTION_REQUIRED with reasons

  if hasMissedCheckIn(snapshot) or hasMedicationRisk(snapshot) or hasPendingIncidentConfirmation(snapshot) or hasWarningBurst(snapshot):
    return WATCH with reasons

  return OK with reasons=["No active risk patterns detected."]
```
