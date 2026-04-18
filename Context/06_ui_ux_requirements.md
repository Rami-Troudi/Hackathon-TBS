# UI/UX Design Requirements Document — Senior Companion Application

## 1. Document Purpose

This document defines the full **UI/UX design constraints, requirements, screen logic, component system, and module-level specifications** for the Senior Companion Application.

It is written to support:
- **Figma-based UI generation and design exploration**
- product alignment across team members
- future frontend implementation
- consistency between the **Senior** and **Guardian** experiences

This is not a generic style guide. It is a **detailed UI/UX requirements brief** intended to make the visual conception phase precise, coherent, and implementable.

---

## 2. Product Vision From a UI/UX Perspective

The application is a **daily companion and family coordination tool for older adults**, with a special emphasis on:
- daily follow-up
- reassurance
- reduced cognitive load
- clear prioritization of important events
- simple action-taking by family members

The product must not feel like:
- a hospital dashboard
- a surveillance app
- a complicated productivity tool
- a “tech-heavy” system requiring learning

The product should feel like:
- calm
- safe
- reassuring
- simple
- respectful
- modern but not trendy
- minimal but not empty
- accessible without looking childish

---

## 3. Core UX Positioning

### 3.1 Product Identity
The product is **not mainly a fall detector**.
It is a **multi-feature companion app for daily monitoring, reminders, reassurance, and family follow-up**.

The **incident/fall vigilance module** exists as one important module among others, but the UI must communicate that the product’s primary value is:
- helping the senior stay oriented and reassured
- helping the guardian understand what matters
- helping both sides react quickly and simply

### 3.2 Dual Experience Principle
There is one product, but two clearly distinct experiences:

#### Senior Experience
Designed for:
- low digital literacy
- low patience for complexity
- low tolerance for friction
- quick confirmation actions
- visual clarity over information density

#### Guardian Experience
Designed for:
- richer monitoring
- event understanding
- configuration and setup
- alert triage
- action-taking

The visual system must be unified, but the interaction model must be clearly different.

---

## 4. High-Level Design Principles

### 4.1 Simplicity First
Every screen must have a dominant action and a clear hierarchy.
No screen should make the user guess what to do next.

### 4.2 Reassurance Over Urgency
Most screens must feel calm and supportive.
Critical states must be visually distinct, but the general product should not feel alarmist.

### 4.3 Large Interactive Targets
The senior interface must use large touch targets and reduced precision requirements.

### 4.4 Low Cognitive Load
The interface must minimize:
- memory burden
- menu depth
- ambiguity
- option overload
- dense text blocks

### 4.5 Actionable Information
For the guardian, data must not be shown for its own sake.
The UI should convert events into:
- status
- priority
- next action

### 4.6 Respectful Accessibility
The senior experience must feel dignified and modern.
Avoid infantilizing metaphors, cartoonish UI, excessive gamification, or patronizing language.

### 4.7 Visual Consistency
All modules must share the same component language, spacing logic, typography hierarchy, and status semantics.

### 4.8 Modern Minimalism
The product should look contemporary, but restrained.
Visual language should be:
- clean
- spacious
- rounded but not overly soft
- elegant but practical
- minimal but sufficiently informative

---

## 5. Primary Users and UX Implications

## 5.1 Senior User
Typical characteristics:
- 60+
- partially autonomous
- may have limited smartphone fluency
- may have mild visual decline
- may be stressed by digital interfaces
- may not want to explore menus
- may prefer direct actions

UX implications:
- use one main home screen
- avoid hidden interactions
- avoid complex gestures
- prefer explicit buttons over icon-only interfaces
- use simple labels
- minimize forms
- support audio where relevant

## 5.2 Guardian User
Typical characteristics:
- family member or caregiver
- busy and time-constrained
- wants useful alerts, not noise
- needs quick overview + ability to go deeper

UX implications:
- dashboard-first design
- strong visual prioritization
- event timeline and filtering
- ability to configure without complexity overload
- fast access to call/contact actions

---

## 6. Platforms and Technical UI Constraints

### 6.1 Platform Scope
Primary design target:
- mobile application

Recommended design base:
- mobile-first
- portrait orientation
- support common Android and iPhone screen sizes

### 6.2 Layout Assumption
Design should be based on:
- 390px wide mobile frame as a main design base
- adaptive scaling to smaller and larger phones

### 6.3 Navigation Assumption
Recommended structure:
- one app
- role-based experience
- dynamic navigation depending on user type

Senior navigation should be flatter than guardian navigation.

### 6.4 Connectivity Assumption
UI must support degraded states when:
- network is weak
- sync is delayed
- live status is unavailable

The design must never assume constant perfect connectivity.

### 6.5 Permission-Dependent Features
Some modules depend on:
- notifications
- motion sensors
- location
- microphone if voice support is used

The permission experience must be carefully designed and non-technical.

---

## 7. Visual Design Direction

## 7.1 Desired Style
The product should feel:
- clean
- modern
- airy
- legible
- calm
- trustworthy

### Visual references in words
- soft surfaces
- balanced whitespace
- rounded cards
- clear status chips
- large touchable controls
- minimal ornamentation
- limited color dependency for meaning

## 7.2 What to Avoid
Avoid:
- cluttered dashboards
- neon or aggressive colors
- overly playful visuals
- excessive gradients
- tiny cards packed with text
- strong skeuomorphism
- ultra-corporate hospital-style interfaces
- dark, heavy, or intimidating layouts

## 7.3 Tone of Interface
Tone should be:
- warm
- neutral
- clear
- direct
- reassuring

Not:
- robotic
- cold
- childish
- overfriendly

---

## 8. Design System Requirements

## 8.1 Typography
Typography must prioritize legibility.

### Senior Typography Rules
- large base size
- generous line-height
- strong hierarchy
- avoid light weights for body text
- avoid condensed fonts

### Recommended hierarchy
- Display / Hero for key status and primary prompts
- Heading 1 for screen titles
- Heading 2 for section labels
- Body Large for senior-facing instructions
- Body Standard for guardian content
- Caption for metadata only

### Typography constraints
- senior-side body text should not be visually small
- button labels must remain readable without zoom
- no long justified paragraphs

## 8.2 Color System
The color system must be minimal and semantic.

### Required categories
- primary brand color
- neutral background scale
- success / OK
- warning / attention
- critical / urgent
- info / neutral accent

### Usage constraints
- color must support meaning, not be the only carrier of meaning
- alert color must be reserved for true urgency
- background colors should remain soft and low-fatigue
- senior UI should avoid excessive visual stimulation

## 8.3 Spacing System
Use a consistent spacing scale.
Layouts must breathe.

Design constraints:
- avoid cramped layouts
- use large vertical spacing on senior flows
- card padding must be generous
- primary actions must not be visually crowded by secondary actions

## 8.4 Shape Language
- rounded corners preferred
- soft but not childish
- large pill or rounded-rectangle buttons for senior actions
- consistent card radius across product

## 8.5 Elevation and Shadows
Use subtle elevation.
Shadows should help separation, not create visual noise.

## 8.6 Iconography
Icons should be:
- simple
- recognizable
- secondary to text for senior UI
- always paired with labels where ambiguity is possible

Avoid icon-only critical actions on senior screens.

---

## 9. Accessibility and Inclusion Requirements

## 9.1 General Accessibility
The product must be designed for:
- reduced visual acuity
- reduced dexterity
- reduced digital confidence
- slower reading pace
- possible bilingual or mixed-language context

## 9.2 Senior-Specific Accessibility Rules
Mandatory directions:
- high contrast text/background combinations
- large tap areas
- low-density screens
- simple wording
- limited steps per task
- clear feedback after each action
- no reliance on small dismiss buttons

## 9.3 Interaction Accessibility
- avoid complex swipes as required actions
- avoid drag-only interaction
- avoid multi-step hidden menus
- primary actions must remain visible

## 9.4 Motion and Animation Accessibility
- animations must be subtle
- avoid disorienting transitions
- avoid flashy state changes
- use motion to clarify, not decorate

## 9.5 Audio Accessibility
Where audio is used:
- visual equivalent must still exist
- audio must be optional or configurable
- alert sounds must be clear but not harsh

---

## 10. Content and Microcopy Rules

## 10.1 Microcopy Tone
Text must be:
- short
- direct
- calm
- respectful
- action-oriented

## 10.2 Senior Microcopy Style
Prefer:
- “I’m okay”
- “I need help”
- “Take medication”
- “Check in now”
- “Did something happen?”

Avoid:
- technical language
- diagnostic wording
- system jargon
- long instructions

## 10.3 Guardian Microcopy Style
Guardian text can be more informative, but still concise.
Use plain language and prioritize:
- what happened
- what changed
- what action is needed

## 10.4 Localization
UI must be prepared for:
- English
- French
- possible Tunisian Arabic / dialect-oriented content layer later

Design must handle text expansion and multilingual layout.

---

## 11. Information Architecture

## 11.1 Senior Information Architecture
Senior app should remain shallow.

Recommended primary screens:
1. Home
2. Reminders / Today
3. Help / Emergency
4. Simple profile or settings (very limited)

Optional secondary screens only if needed:
- incident confirmation
- check-in confirmation
- reminder detail

### Senior structure principle
The senior must be able to use most of the app from the **home screen alone**.

## 11.2 Guardian Information Architecture
Recommended guardian navigation:
1. Dashboard
2. Alerts
3. Timeline
4. Modules
5. Senior Profile / Settings

Optional tabs or sections:
- medication
- check-in schedule
- safe zones
- AI summaries

Guardian architecture must support two modes:
- quick glance
- deeper follow-up

---

## 12. Navigation Requirements

## 12.1 Senior Navigation
Preferred navigation model:
- bottom navigation with limited tabs, or
- single home-centric design with very few entry points

Constraints:
- maximum 3–4 primary destinations
- avoid nested navigation deeper than 2 levels where possible
- primary help action always visible or easily reachable

## 12.2 Guardian Navigation
Preferred navigation model:
- bottom navigation or tab-based top-level structure
- clear separation between monitoring and configuration

Constraints:
- dashboard must be the default landing screen
- alert center must be reachable in one tap
- settings must not dominate the main experience

---

## 13. Global UI States That Must Exist

Each module and each key screen must support the following states where relevant:

- default state
- loading state
- empty state
- success state
- warning state
- critical state
- offline or sync-delayed state
- permission-missing state
- error state

The design system must include reusable patterns for these states.

---

## 14. Core Component Library Requirements

The Figma system must include reusable components for the entire product.

## 14.1 Structural Components
- App bar / screen header
- bottom navigation bar
- section header
- card container
- sticky action area
- modal / bottom sheet
- full-screen alert dialog

## 14.2 Action Components
- primary button
- secondary button
- tertiary text action
- icon + label action button
- emergency action button
- segmented control
- toggle switch
- checkbox / confirmation selector

## 14.3 Information Components
- status chip
- alert chip
- info banner
- timeline item
- reminder item
- module card
- summary card
- KPI tile for guardian dashboard
- empty state card

## 14.4 Form Components
- text field
- date/time selector
- schedule builder input
- contact selector
- stepper or counter
- safe zone form controls

## 14.5 Feedback Components
- toast
- inline confirmation message
- alert dialog
- countdown confirmation panel
- vibration/sound indicator placeholder states in UI

## 14.6 Senior-Specific Components
- giant action button
- simple reminder confirmation card
- one-question check-in card
- incident confirmation overlay
- “I’m okay” / “Help” paired action block

## 14.7 Guardian-Specific Components
- alert list row
- event timeline group
- quick action footer
- module settings card
- activity digest card
- last-known-status card

---

## 15. Dashboard and Status System

## 15.1 Status Semantics
A universal status system must be used across the product.

Recommended high-level states:
- **OK**
- **Needs attention**
- **Action required**

This status logic must be visually consistent in:
- cards
- chips
- banners
- dashboard summaries
- timeline labels

## 15.2 Guardian Dashboard Goals
The guardian dashboard must answer immediately:
- Is everything okay?
- What changed recently?
- Is there anything urgent?
- What should I do now?

## 15.3 Dashboard Sections
Recommended order:
1. senior overview/status summary
2. active alerts
3. today’s events or recent activity
4. module snapshot cards
5. quick actions

## 15.4 Dashboard Constraints
- no dense analytics feel
- no overly technical event wording
- no more than one dominant urgent area at a time
- recent events must be scannable in seconds

---

## 16. Senior Module UI/UX Requirements

## 16.1 Senior Home Screen
### Purpose
Primary interaction hub.

### Must include
- greeting or reassuring header
- current overall simple state
- main actions:
  - I’m okay
  - I need help
- today’s reminders summary
- next expected action if relevant

### Must feel
- calm
- uncluttered
- immediately understandable

### Constraints
- no dense lists on landing view
- no complex charts
- no more than one major informational block beyond main actions

## 16.2 Check-In Module — Senior Side
### Goal
Allow easy status confirmation.

### UI requirements
- one-tap check-in flow
- scheduled prompt card
- success confirmation state
- missed check-in reminder state

### Preferred interaction
Prompt example:
- “Please check in”
- large confirmation button

### Optional secondary action
- “Not now” if product logic allows it

## 16.3 Medication Module — Senior Side
### Goal
Allow simple medication confirmation.

### Required UI elements
- reminder card
- medication label
- time
- confirmation actions:
  - Taken
  - Skip / Not now if permitted

### Constraints
- avoid visually dense medical detail
- use simplified wording
- show only essential information

## 16.4 Incident Vigilance Module — Senior Side
### Goal
Verify a suspicious event with minimal friction.

### Required UI pattern
A high-priority full-screen or modal alert with:
- clear question
- simple wording
- strong visual hierarchy
- timer/countdown if needed
- two obvious actions:
  - I’m okay
  - I need help

### Visual requirements
- higher contrast than normal screen
- unmistakable urgency without panic-inducing aesthetics

### Constraints
- no long explanation paragraph
- no technical terms like “sensor anomaly detected”

## 16.5 Help / Emergency Screen
### Goal
Provide a direct way to request help.

### Must include
- one large emergency/help action
- clear explanation of what happens next
- visible guardian contact shortcut if applicable

### Constraints
- this screen must be reachable quickly
- interaction must be highly obvious

## 16.6 Senior Today / Routine View
### Goal
Provide a simple daily overview.

### Must include
- today’s reminders
- completed vs pending items
- next action

### Constraints
- this should not look like a task manager
- keep it lightweight and reassuring

## 16.7 Senior Settings / Profile
### Goal
Minimal and non-technical settings only.

### Include only essentials
- language
- sound / voice preferences
- accessibility options
- emergency/contact visibility if applicable

### Avoid
- complex technical controls
- advanced permissions explanations here

---

## 17. Guardian Module UI/UX Requirements

## 17.1 Guardian Dashboard
### Goal
Provide immediate situational awareness.

### Must include
- senior name/profile summary
- current status
- active alerts
- latest check-in info
- latest reminder adherence summary
- quick actions:
  - call
  - message
  - view history

### Constraints
- status and alert hierarchy must dominate
- supporting data must stay secondary

## 17.2 Alerts Screen
### Goal
Centralized alert triage.

### Must include
- alert severity
- title
- time
- source module
- action recommendation
- quick action buttons

### Filtering options
- active
- resolved
- by module
- by severity

### Constraints
- visually scannable list
- obvious difference between critical and non-critical

## 17.3 Timeline Screen
### Goal
Provide historical understanding.

### Must include
- chronological event list
- grouped by day or period
- event icon/type
- concise description
- optional detail expansion

### Constraints
- should support scanning, not full report reading
- metadata should not overpower event meaning

## 17.4 Check-In Module — Guardian Side
### Must include
- expected check-in schedule
- completion status
- missed check-ins
- ability to configure frequency and reminder timing

### Constraints
- configuration must remain simple
- avoid overly granular scheduling complexity in MVP

## 17.5 Medication Module — Guardian Side
### Must include
- medication schedule overview
- missed/taken history
- reminder setup UI
- ability to edit time and recurrence

### Constraints
- the module should feel structured and practical
- do not make it look like a clinical prescription management system

## 17.6 Incident Module — Guardian Side
### Must include
- recent suspicious incidents
- severity / confidence / status
- whether the senior responded
- action options
- event details

### Constraints
- wording must remain non-medical
- should emphasize “suspected event” or “incident” language

## 17.7 Location Safety Module — Guardian Side
### Must include
- safe zone setup
- zone status
- entry/exit event history
- location-sharing explanation

### Constraints
- privacy and consent messaging must be visible
- location must not dominate the overall product identity

## 17.8 AI Digest / Summary Module
### Goal
Reduce information overload.

### Must include
- short digest card
- key changes summary
- suggested follow-up wording
- summary grouped by priority

### Constraints
- AI output must be readable and structured
- avoid long assistant-style paragraphs
- summaries must support quick action

## 17.9 Guardian Settings
### Must include
- notification preferences
- escalation preferences
- linked contacts
- module enable/disable
- permissions and privacy references

### Constraints
- avoid overly technical configuration wording
- advanced settings should be grouped separately

---

## 18. Module Cards and Modular UX Pattern

Because the product is multi-feature, module presentation must be consistent.

## 18.1 Module Card Structure
Each module card should support:
- module name
- current status
- short summary
- entry point to detail/configuration
- optional action shortcut

## 18.2 Required States per Module Card
- active and healthy
- pending attention
- urgent issue
- inactive/disabled
- no data yet

## 18.3 Module Detail View Pattern
Every module detail page should follow a consistent structure:
1. module header
2. status summary
3. recent activity or data
4. configuration or actions
5. history if relevant

---

## 19. Onboarding and Setup UX Requirements

## 19.1 Onboarding Philosophy
Onboarding should not overwhelm either role.
The setup process should feel guided, progressive, and understandable.

## 19.2 Senior Onboarding
Senior onboarding must be minimal.
Potential content:
- welcome
- what the app helps with
- how to use main buttons
- permission prompts in plain language

### Constraints
- avoid long setup flows
- avoid account complexity where possible
- one concept per screen

## 19.3 Guardian Onboarding
Guardian onboarding may be more complete.

### Must include
- relationship to senior
- module activation choices
- basic schedule setup
- emergency contact setup
- permission explanations

### Constraints
- must remain digestible
- progressive disclosure preferred

## 19.4 Pairing / Linking Flow
If senior and guardian accounts are linked, the linking flow must be:
- explicit
- simple
- secure-feeling
- easy to understand

Potential UI patterns:
- invite code
- QR code
- phone number/email invite

---

## 20. Permissions UX Requirements

Permissions are sensitive and must be explained clearly.

## 20.1 Notifications
Explain value simply:
- reminders
- alerts
- check-ins

## 20.2 Motion / Activity Permissions
Explain without technical jargon:
- used to help detect unusual incidents

## 20.3 Location Permissions
Explain clearly:
- used only for safe-zone alerts or emergency context, if enabled

## 20.4 Microphone / Voice
Explain clearly:
- used for voice assistance if activated

## 20.5 Permission Missing State Screens
Each permission-dependent feature must have a designed “not enabled” state with:
- plain explanation
- enable action
- consequence of not enabling

---

## 21. Notification and Alert UX Requirements

## 21.1 Notification Philosophy
Notifications must be:
- useful
- sparse enough to avoid fatigue
- clearly prioritized
- role appropriate

## 21.2 Senior Notifications
Senior notifications should be:
- simple
- short
- action-based
- optionally reinforced with sound/vibration

## 21.3 Guardian Notifications
Guardian notifications should indicate:
- what happened
- who is concerned
- whether action is needed
- urgency level

## 21.4 Alert Severity Levels
At minimum:
- informational
- attention needed
- urgent

Each level must have a defined visual treatment.

## 21.5 Alert Detail Screen
Each alert detail screen should include:
- alert title
- summary
- time
- source module
- response status
- recommended next action
- quick contact buttons

---

## 22. Empty, Loading, Error, and Offline States

## 22.1 Empty States
All empty states should be constructive.
Examples:
- no medications configured
- no alerts
- no recent incidents
- no safe zones defined

Each empty state should provide:
- short explanation
- next action button where relevant

## 22.2 Loading States
Use calm placeholders or skeletons.
Avoid flashing loaders that feel unstable.

## 22.3 Error States
Error UI must be human-readable.
Do not expose technical codes as the primary message.

## 22.4 Offline / Delayed Sync States
The user should understand:
- the app is still usable or partially usable
- some data may be delayed
- alerts may sync later

Design patterns required:
- sync banner
- status note
- retry action where relevant

---

## 23. Trust, Privacy, and Consent UI Requirements

This product touches sensitive daily life data.
Trust must be designed, not assumed.

## 23.1 UI Requirements for Trust
The product must visibly communicate:
- what is being monitored
- what is shared
- who sees what
- when escalation happens

## 23.2 Consent-Related Screens
Must be present for:
- location sharing
- guardian linkage
- suspicious incident escalation
- optional AI support features if data use is relevant

## 23.3 Wording Constraints
Avoid surveillance-feeling wording.
Prefer:
- safety
- support
- follow-up
- reassurance

Over:
- tracking
- control
- monitoring everything

---

## 24. Motion and Interaction Patterns

## 24.1 Motion Philosophy
Use motion to:
- confirm actions
- clarify transitions
- draw attention gently

Do not use motion for decorative excess.

## 24.2 Required Motion Cases
- button press feedback
- success confirmation
- alert appearance
- bottom sheet transitions
- timeline expansion

## 24.3 Motion Constraints
- subtle duration
- no complex parallax
- no bouncing playful motion on serious screens
- urgent states may use controlled emphasis only

---

## 25. Detailed Screen Inventory for Figma

The following screens or templates should be designed.

## 25.1 Shared / Global
- splash / launch
- role selection or login routing
- sign in / create account
- permission prompts
- generic modal
- generic bottom sheet
- generic empty state
- generic offline state
- generic error state

## 25.2 Senior Experience
- onboarding welcome
- onboarding simple feature intro
- permission explanation screens
- senior home
- senior today / reminders view
- medication reminder prompt
- check-in prompt
- check-in success screen/state
- incident confirmation overlay
- help / emergency screen
- profile / language / accessibility settings

## 25.3 Guardian Experience
- guardian onboarding
- senior linking flow
- guardian dashboard
- alert center
- alert detail
- timeline
- medication overview
- medication schedule editor
- check-in schedule settings
- incident history / detail
- safe zones list
- safe zone setup/edit
- AI digest screen
- settings
- privacy/permissions explanation screen

---

## 26. Figma File Structure Recommendation

To keep the design system scalable, Figma should be organized as follows:

### Page 1 — Foundations
- color tokens
- typography
- spacing
- icons
- grids
- elevation rules

### Page 2 — Components
- buttons
- chips
- cards
- nav bars
- inputs
- banners
- modal patterns
- list items

### Page 3 — Senior Flows
- onboarding
- home
- routine
- reminders
- incident flow
- help flow

### Page 4 — Guardian Flows
- dashboard
- alerts
- timeline
- module detail pages
- settings

### Page 5 — States
- loading
- empty
- error
- offline
- permission missing
- success states

### Page 6 — Prototype Flows
- senior daily flow
- guardian alert flow
- medication flow
- incident escalation flow

---

## 27. Prototyping Requirements for Figma

The initial Figma prototype should demonstrate at least:

### Senior Flow Prototype
- open app
- see home
- receive reminder
- confirm medication or check-in
- incident confirmation scenario
- ask for help

### Guardian Flow Prototype
- open dashboard
- see alert
- open alert detail
- take quick action
- review timeline
- adjust settings for one module

### Transition goal
Prototype should communicate:
- simplicity on senior side
- control and clarity on guardian side
- coherence across modules

---

## 28. UI/UX Constraints by Module Priority

## 28.1 Core MVP Modules
These must receive the highest design polish:
- senior home
- check-in
- medication reminders
- guardian dashboard
- alerts center
- incident confirmation flow

## 28.2 Secondary Modules
Can be designed with lighter detail initially:
- location safety
- AI digest
- cognitive activity
- advanced settings

---

## 29. Acceptance Criteria for the UI Direction

The UI direction should be considered successful if:

### Senior Side
- a senior can understand the main screen in seconds
- the primary actions are obvious
- the interface does not feel overwhelming
- reminder and confirmation flows are effortless
- help access is immediate and clear

### Guardian Side
- a guardian can understand status quickly
- active issues are easy to spot
- the next action is obvious
- module information feels organized and not chaotic
- alerts and history are both usable

### Shared Product Quality
- the product feels calm and trustworthy
- the visual language is modern and minimal
- accessibility is built in, not added later
- the multi-module nature does not create visual fragmentation

---

## 30. What the Figma Generation Must Prioritize

When generating or designing the UI, prioritize in this order:

1. clarity of role split
2. senior simplicity
3. dashboard readability for guardian
4. reusable component consistency
5. accessibility and large touch targets
6. calm minimal visual style
7. module scalability
8. refined but restrained aesthetics

---

## 31. Short Design Prompt Summary

If this document is used to brief a UI generator or designer, the product should be described as:

> A modern, minimal, calm mobile companion app for older adults and their families. One product, two experiences: a highly simplified senior interface with large actions and reassuring routines, and a richer guardian dashboard focused on status, alerts, and follow-up. The UI should be elegant, accessible, high-clarity, and modular, with check-ins, reminders, incident vigilance, and family coordination as the core experience.

---

## 32. Final Design Intent

The final UI must communicate one clear message:

> This product helps families stay informed and helps older adults feel supported, without overwhelming either of them.
