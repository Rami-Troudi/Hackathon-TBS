# UI/UX Screen Map (MVP)

## Senior Experience

### S-01 Senior Home (Primary)
Purpose:
- one-screen reassurance and action

Core elements:
- large status card ("Today is on track" or warning summary)
- primary button: I'm okay
- secondary button: I need help
- next reminder preview
- simple connectivity indicator

Design constraints:
- max 2 primary actions visible
- large tap areas
- high contrast text

### S-02 Medication Prompt
Purpose:
- confirm reminder quickly

Core elements:
- medication name + time
- actions: Taken / Ignore
- optional read-aloud button

### S-03 Incident Confirmation
Purpose:
- confirm safety after suspicious signal

Core elements:
- direct prompt: Are you okay?
- actions: Yes, I'm okay / I need help
- countdown indicator before escalation

### S-04 Lightweight History (Optional P1)
Purpose:
- reassure user that actions were recorded

Core elements:
- latest 3 confirmations
- clear timestamps

## Guardian Experience

### G-01 Dashboard Overview
Purpose:
- provide immediate status and priority

Core elements:
- global status chip (OK, WATCH, ACTION_REQUIRED)
- reason chips
- active alerts card
- quick actions: Call senior, Send message

### G-02 Alerts List
Purpose:
- triage and action

Core elements:
- grouped by severity
- alert card with reason, timestamp, suggested action
- acknowledge/resolve controls

### G-03 Timeline
Purpose:
- understand context and progression

Core elements:
- chronological event list
- module filter (check-in, meds, incidents)
- status transition markers

### G-04 Settings (P1)
Purpose:
- tune thresholds and notification preferences

Core elements:
- check-in timeout
- incident response timeout
- preferred channels

## Shared UX States
Mandatory shared states for each screen:
- loading
- empty
- offline/degraded
- error/retry

## Navigation Model (MVP)
- role-aware entry point after authentication
- Senior: flat navigation (home-first)
- Guardian: tab structure (Dashboard, Alerts, Timeline, Settings)

## Component Starter Set
- status chip
- alert card
- primary large button
- confirmation modal
- timeline item
- offline banner

## First Figma Frames To Build
1. Senior Home (default OK)
2. Senior Incident Confirmation (countdown)
3. Guardian Dashboard (WATCH state)
4. Guardian Alerts (critical + warning mixed)
5. Guardian Timeline (event filter open)
