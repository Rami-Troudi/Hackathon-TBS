# Technical Document — Senior Companion Application

## 1. Overview

### 1.1 Product Vision
The product is a modular senior companion application focused on **daily monitoring, family coordination, and actionable alerts**.

It is designed around two distinct user experiences:
- **Senior side**: minimal interaction, low cognitive load, simple confirmations, clear reminders
- **Guardian side**: rich dashboard, event monitoring, alert prioritization, configuration, and follow-up actions

The application is not positioned as a medical-grade system. Its purpose is to provide **accessible daily follow-up**, reduce family mental load, and improve reaction time when abnormal situations occur.

### 1.2 Core Value Proposition
The system turns scattered daily signals into a **clear, useful, and actionable view** of the senior’s situation.

### 1.3 Scope of This Document
This document defines:
- product scope from a technical perspective
- software architecture
- core modules
- event model
- backend structure
- main workflows
- technical constraints
- MVP boundaries

---

## 2. Product Scope

### 2.1 Primary Objective
Provide a mobile-based companion platform that enables:
- daily check-ins
- medication reminders and confirmations
- suspicious incident monitoring
- contextual alerts for guardians
- simple coordination between senior and family

### 2.2 Main Users
#### Senior
- 60+
- partially autonomous
- low or متوسط digital literacy
- needs reassurance, simplicity, and minimal interaction

#### Guardian
- family member or close caregiver
- wants visibility, prioritization, and rapid intervention when needed

### 2.3 Product Principles
- minimal friction on senior side
- clear and prioritized information on guardian side
- modular architecture
- scalable feature addition without redesigning the whole product
- no overclaiming of reliability for safety-critical functions

---

## 3. Functional Architecture

### 3.1 High-Level Functional Domains
The system is organized into the following functional domains:

- user and authentication management
- senior daily monitoring
- guardian monitoring and response
- reminders and adherence tracking
- suspicious incident management
- optional location-based safety
- AI-assisted prioritization and summaries

### 3.2 Core Functional Modules
#### A. Check-in Module
Purpose:
- allow the senior to confirm they are fine
- detect absence of expected interaction
- trigger escalation when needed

Main functions:
- manual check-in
- scheduled check-in reminders
- missed check-in detection
- escalation to guardian

#### B. Medication Module
Purpose:
- support routine medication adherence
- surface missed confirmations to guardians

Main functions:
- medication schedule creation
- reminders
- senior confirmation: taken / ignored
- missed medication event generation

#### C. Incident Vigilance Module
Purpose:
- detect events compatible with abnormal situations such as a fall or mobility incident
- verify with the senior
- escalate if no response or emergency confirmation

Main functions:
- sensor-based suspicious event detection
- incident confirmation flow
- escalation workflow
- event logging

#### D. Guardian Dashboard Module
Purpose:
- centralize the senior’s status
- present relevant alerts only
- enable quick follow-up actions

Main functions:
- status summary
- active alerts
- recent timeline
- per-module monitoring
- quick contact actions

#### E. Optional Location Safety Module
Purpose:
- support safe-zone logic where relevant and consented

Main functions:
- safe zone definition
- zone exit alerts
- optional last known location during escalations

#### F. AI Assistance Layer
Purpose:
- reduce noise
- improve prioritization
- produce simple summaries
- improve accessibility

Main functions:
- alert prioritization
- digest generation for guardians
- voice assistance or TTS
- future conversational support

---

## 4. User Experience Structure

### 4.1 Senior Experience
The senior experience must remain intentionally minimal.

Primary interaction elements:
- “I’m okay”
- “I need help”
- reminder confirmation
- incident confirmation

UX constraints:
- large buttons
- large readable text
- minimal navigation depth
- minimal number of actions per screen
- optional audio support
- high contrast interface
- simple wording

### 4.2 Guardian Experience
The guardian experience is information-rich but should remain readable.

Main screens:
- overview dashboard
- alerts
- event timeline
- module settings
- senior profile and preferences

Guardian priorities:
- know if something is wrong
- know what happened
- know whether action is required now
- know how to act quickly

---

## 5. System Architecture

### 5.1 Client Architecture
The mobile application is structured as a modular client application.

#### Core App Shell
Contains only cross-cutting concerns:
- navigation
- authentication/session management
- local storage
- network synchronization
- notifications
- permissions handling
- shared design system

#### Feature Modules
Each feature module contains:
- domain logic
- application services
- UI components
- local state management
- integration layer
- tests

Target modules:
- `checkin`
- `medication`
- `incident_vigilance`
- `guardian_dashboard`
- `location_safety`
- `ai_assistance`

### 5.2 Communication Model
Inter-module communication should be event-driven.

Example domain events:
- `CheckInCompleted`
- `CheckInMissed`
- `MedicationTaken`
- `MedicationMissed`
- `IncidentSuspected`
- `IncidentConfirmed`
- `IncidentDismissed`
- `EmergencyTriggered`
- `SafeZoneExited`
- `SeniorStatusChanged`

The goal is to avoid direct tight coupling between business modules.

---

## 6. Backend Architecture

### 6.1 Backend Style
Recommended approach:
- **modular monolith** for MVP and early product stages

Reasoning:
- simpler deployment
- easier coordination for a small team
- sufficient separation of concerns
- avoids premature distributed-system complexity

### 6.2 Backend Domains
Suggested backend domains:
- `auth`
- `users`
- `guardians`
- `checkin`
- `medication`
- `incidents`
- `alerts`
- `location`
- `ai`
- `audit`

### 6.3 Main Responsibilities
#### Auth
- login
- token/session management
- permission checks

#### Users / Guardians
- user profiles
- senior–guardian linking
- notification targets

#### Check-in
- schedule definition
- completion tracking
- missed event generation

#### Medication
- medication plans
- reminder scheduling
- confirmation status
- missed reminder events

#### Incidents
- suspicious event ingestion
- confirmation state machine
- escalation orchestration
- incident logs

#### Alerts
- notification generation
- delivery policy
- multi-guardian escalation rules

#### AI
- summaries
- alert prioritization
- future assistance functions

#### Audit
- event history
- compliance-friendly logging
- traceability

---

## 7. Data Model Overview

### 7.1 Main Entities
#### Senior
Fields:
- id
- name
- age range or date of birth
- preferences
- accessibility settings
- linked guardians

#### Guardian
Fields:
- id
- name
- contact information
- notification preferences
- linked seniors

#### CheckInSchedule
Fields:
- id
- senior_id
- frequency
- time windows
- escalation timeout

#### CheckInEvent
Fields:
- id
- senior_id
- status
- expected_at
- completed_at
- escalated_at

#### MedicationPlan
Fields:
- id
- senior_id
- medication name
- schedule
- dosage text
- reminder times

#### MedicationEvent
Fields:
- id
- plan_id
- status
- scheduled_at
- confirmed_at

#### IncidentEvent
Fields:
- id
- senior_id
- type
- confidence_score
- detected_at
- confirmation_status
- escalation_status
- resolution_status
- context payload

#### Alert
Fields:
- id
- senior_id
- alert_type
- priority
- created_at
- delivered_to
- status

#### SafeZone
Fields:
- id
- senior_id
- label
- coordinates or geofence definition

---

## 8. Status Model

### 8.1 Global Status States
The application should expose a simple global state for guardians:
- `OK`
- `WATCH`
- `ACTION_REQUIRED`

### 8.2 Status Derivation Logic
Examples:
- all expected events completed → `OK`
- one or more missed low-priority events → `WATCH`
- suspicious unresolved incident or repeated misses → `ACTION_REQUIRED`

This derived state must remain explainable.

---

## 9. Incident Vigilance Logic

### 9.1 Purpose
The incident vigilance module does not claim to detect every fall with certainty.
It aims to detect **events compatible with a fall or abnormal mobility incident** and trigger the correct response flow.

### 9.2 Detection Inputs
Potential smartphone inputs:
- accelerometer
- gyroscope
- device motion/orientation
- activity recognition if available
- optional location context

### 9.3 Decision Logic
Recommended logic:
1. suspicious event candidate detected
2. confidence score computed from multiple signals
3. senior confirmation requested
4. if no response or emergency response → guardian escalation

### 9.4 Important Positioning
This module must be described as:
- vigilance support
- suspicious incident detection
- faster reaction support

It must not be described as:
- guaranteed fall detection
- medical-grade emergency monitoring
- zero-failure safety system

---

## 10. Alerting Logic

### 10.1 Alert Principles
Alerts must be:
- relevant
- limited
- prioritized
- explainable

### 10.2 Alert Categories
- informational
- warning
- critical

### 10.3 Examples
Informational:
- check-in completed

Warning:
- one missed medication confirmation
- delayed check-in

Critical:
- unresolved suspicious incident
- emergency-triggered action
- repeated missed critical events

### 10.4 Escalation Policy
A configurable escalation policy should support:
- one or multiple guardians
- timeout before escalation
- different channels depending on severity

---

## 11. AI Layer

### 11.1 AI Objectives
The AI layer must serve practical product goals:
- reduce alert noise
- rank event urgency
- summarize senior status for guardians
- assist accessibility through voice or simplification

### 11.2 MVP AI Functions
Recommended initial AI functions:
- rule-enhanced prioritization
- natural-language daily summary generation
- text-to-speech for reminders or confirmations

### 11.3 Future AI Functions
- conversational companion
- anomaly pattern learning
- personalized guardian digests
- adaptive reminder timing

### 11.4 Constraint
AI must remain assistive and bounded. Core safety workflows must remain understandable without relying on opaque model behavior.

---

## 12. Non-Functional Requirements

### 12.1 Performance
- core user actions must feel immediate
- alerts must be delivered with low latency under normal connectivity
- dashboard should remain readable and responsive

### 12.2 Reliability
- events must not be silently lost
- retries should exist for critical sync paths
- failed deliveries must be traceable

### 12.3 Accessibility
- large tap targets
- readable typography
- low cognitive load
- optional audio guidance
- support for simple language

### 12.4 Privacy and Consent
The system must support:
- explicit guardian linking
- consented sharing of location and status data
- control over optional monitoring features
- transparent handling of data collected

### 12.5 Offline / Low Connectivity Behavior
The product should degrade gracefully:
- local event capture when possible
- deferred synchronization
- visible sync state where necessary

---

## 13. MVP Definition

### 13.1 In Scope for MVP
- senior simple interface
- guardian dashboard basic version
- daily check-in
- medication reminders and confirmations
- suspicious incident confirmation flow
- alerts and escalation
- basic global status model

### 13.2 Out of Scope for MVP
- advanced predictive analytics
- institution-facing administration portal
- complex wearables integration
- large-scale conversational agent
- full clinical integrations

---

## 14. Main User Flows

### 14.1 Daily Check-In Flow
1. scheduled reminder appears
2. senior taps “I’m okay”
3. event stored locally
4. event synced to backend
5. guardian dashboard updates status

### 14.2 Missed Check-In Flow
1. scheduled check-in window expires
2. event marked as missed
3. status may move to `WATCH`
4. guardian receives warning if escalation rule matches

### 14.3 Medication Flow
1. reminder is triggered
2. senior confirms taken / ignored
3. event recorded
4. repeated missed events increase concern level

### 14.4 Suspicious Incident Flow
1. suspicious event detected
2. confirmation UI shown to senior
3. if dismissed → event closed
4. if emergency or no response → critical alert sent to guardian
5. guardian can follow up directly

---

## 15. Risks and Constraints

### 15.1 Product Risks
- senior may not keep smartphone on them consistently
- too many alerts may reduce trust
- feature sprawl may dilute core value

### 15.2 Technical Risks
- sensor-based vigilance has false positives and false negatives
- mobile background execution constraints may vary by OS
- notification reliability depends partly on platform behavior and connectivity

### 15.3 Mitigation Principles
- position incident monitoring as vigilance, not certainty
- keep senior interaction simple
- prioritize the check-in and guardian dashboard flows
- design for explainability

---

## 16. Recommended Technical Priorities

### Phase 1
- domain model
- authentication
- senior/guardian linking
- basic dashboard
- check-in flow

### Phase 2
- medication reminders
- event history
- alert prioritization rules

### Phase 3
- suspicious incident monitoring
- confirmation state machine
- escalation improvements

### Phase 4
- AI summaries
- voice support
- optional safe-zone features

---

## 17. Final Technical Positioning

The product is a **senior daily monitoring and family coordination platform** with modular vigilance features.

Its identity is not “fall detector first.”
Its identity is:
- simple daily support for seniors
- useful visibility for guardians
- actionable alerts when something matters
- extensible architecture for future smart assistance
