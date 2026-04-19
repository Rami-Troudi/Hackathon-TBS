  # AI Coding Context — Senior Companion Application

Use this file as the **primary context prompt** for AI-assisted coding, scaffolding, architecture decisions, or implementation planning.

---

## 1. Product identity
The product is a **Senior Companion Application** focused on:
- daily monitoring
- family coordination
- actionable alerts
- low-friction senior interaction

It is **not** a fall detector first.  
It is **not** a medical-grade emergency system.  
It is **not** a hardware-dependent product.

The product is a smartphone-first companion platform.

---

## 2. User roles
### Senior
- 60+
- partially autonomous
- low digital literacy possible
- needs reassurance, simplicity, large controls, low cognitive load

### Guardian
- family member or close caregiver
- needs a clear dashboard
- needs prioritization and alerts
- needs to know when action is required

---

## 3. Core product promise
Transform scattered daily signals into a clear, useful, and actionable view of the senior’s situation.

---

## 4. Core MVP modules
- check-in
- medication reminders and confirmations
- incident vigilance
- guardian dashboard
- alerts and escalation
- global status model

Optional / later:
- location safety
- AI summaries
- voice assistance
- conversational companion
- cognitive activities

---

## 5. Core status model
Expose a simple global state to guardians:
- OK
- WATCH
- ACTION_REQUIRED

This state must remain explainable.

---

## 6. Incident vigilance positioning
The incident module:
- detects suspicious events compatible with a fall or abnormal mobility incident
- requests confirmation from the senior
- escalates if needed

Do not describe it as:
- guaranteed fall detection
- medical monitoring
- zero-failure safety

Preferred wording:
- suspicious incident detection
- vigilance support
- faster reaction support

---

## 7. UX principles
### Senior side
- minimal navigation
- very large tap targets
- high contrast
- simple wording
- very few actions per screen
- optional audio support

### Guardian side
- richer but still readable
- status summary first
- recent alerts and events
- quick contact actions
- simple module settings

---

## 8. Technical direction
- modular mobile application
- modular monolith backend for MVP
- event-driven communication between modules
- understandable business rules
- AI only as bounded assistance

---

## 9. AI role
AI should:
- reduce noise
- rank urgency
- summarize daily status
- improve accessibility
- help explain

AI should not replace core deterministic safety logic.

---

## 10. Constraints to preserve during coding
- keep the product scope focused
- avoid feature sprawl in MVP
- avoid coupling modules tightly
- avoid “fall detection first” framing in code naming, docs, and UX
- keep the senior experience extremely simple
- design for explainability and consent
