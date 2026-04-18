# Senior Companion MVP Delivery Overview

Date: 2026-04-18

## Goal
Ship a hackathon-ready MVP of the Senior Companion application that is aligned with:
- daily monitoring first positioning
- dual user experience (Senior, Guardian)
- explainable status model (OK, WATCH, ACTION_REQUIRED)
- event-driven modular architecture

## What This Execution Pack Contains
1. `01_mvp_user_stories.md`: prioritized stories and acceptance criteria
2. `02_api_contract_v1.yaml`: OpenAPI v1 contract for core MVP operations
3. `03_event_rules_and_status_model.md`: event model and explainable rules engine
4. `04_ui_ux_screen_map.md`: screen-level structure for Senior and Guardian

## MVP Scope Locked For Hackathon
- check-in flow
- medication reminders and confirmations
- suspicious incident vigilance with confirmation and escalation
- guardian dashboard with active alerts + timeline
- simple notifications and escalation policy
- global status model

## Out Of Scope For Hackathon
- advanced predictive analytics
- full conversational companion
- clinical integrations
- hardware dependencies
- complex geofencing automation

## Delivery Plan (Compressed)
1. Day 1: domain model, API skeleton, status engine
2. Day 2: Senior flows (check-in, medication, incident confirmation)
3. Day 3: Guardian dashboard + alert/timeline integration
4. Day 4: reliability pass, accessibility pass, demo scenario scripts

## Definition Of Done (Hackathon)
- Guardian can see one clear global status at any time
- At least one full escalation scenario is testable end-to-end
- Senior can perform key actions in <= 2 taps from home screen
- Alert messages explain reason and suggested action
- Demo can run with realistic seeded events
