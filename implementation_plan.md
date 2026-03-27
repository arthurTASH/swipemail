# SwipeMail Implementation Plan (V1)

This plan translates `email_app_requirements.md` into an execution-ready roadmap for building the first iPhone release of SwipeMail.

## 1) Delivery Strategy

- **Approach:** Build a thin, end-to-end vertical slice first (auth → fetch unread primary email → swipe read action), then expand to all gesture actions, navigation, accessibility, and hardening.
- **Architecture style:** Modular MVVM with service abstractions:
  - `AuthService` (OAuth + token lifecycle)
  - `GmailService` (fetch/process email)
  - `QueueService` (local in-memory swipe queue + optimistic updates)
  - `SyncEngine` (background retries + reconciliation)
- **Tech stack:** Swift + SwiftUI, AppAuth, URLSession, Keychain (Security framework wrapper).
- **Release target:** TestFlight V1 with constrained scope matching the out-of-scope list.

## 2) Workstreams

## A. Product & UX

### Goals
- Finalize all interaction details before heavy implementation.

### Tasks
1. Produce low/mid-fidelity screens:
   - Onboarding/OAuth entry
   - Card stack view with gesture indicators
   - Empty state
   - Hamburger drawer
   - Settings (Disconnect / Exit)
2. Define motion specs:
   - Swipe thresholds (~30%)
   - Rotation/tilt behavior
   - Snap-back animation timing
   - Card dismissal transitions
3. Define accessibility alternatives:
   - Long-press menu action parity for all gestures
   - Dynamic type behavior per text block
   - VoiceOver labels and action names
4. Capture visual tokens:
   - Colors (READ/FOLLOW UP/DELETE/SPAM badges)
   - Typography hierarchy
   - Spacing and card corner radius/shadow

### Exit Criteria
- UX spec approved with annotated behaviors and edge states.

---

## B. App Foundation

### Goals
- Stand up project scaffolding and app lifecycle flows.

### Tasks
1. Create iOS project baseline and modules/folders:
   - `App`, `Features`, `Services`, `Models`, `Infrastructure`, `DesignSystem`
2. Implement app state routing:
   - Launch → token check → onboarding or inbox
3. Add environment/config support:
   - OAuth client IDs, redirect URI, API base constants
4. Add logging/telemetry foundation (local + optional analytics hooks)
5. Define error model and user-facing toast system

### Exit Criteria
- App launches and correctly routes user based on token presence.

---

## C. Authentication & Session Management

### Goals
- Reliable Google + federated OAuth with secure token handling.

### Tasks
1. Integrate AppAuth for OAuth 2.0 and OIDC-based enterprise flows.
2. Implement domain-driven provider routing logic (where applicable).
3. Persist tokens in Keychain.
4. Implement silent refresh path and refresh-failure fallback.
5. Add sign-out/disconnect flow:
   - revoke/clear token
   - route to exit behavior
6. Security hardening:
   - avoid token logs
   - secure keychain access groups/options

### Exit Criteria
- First-time and returning-user flows pass on device.

---

## D. Gmail Data Layer

### Goals
- Fetch and mutate messages per requirement constraints.

### Tasks
1. Implement Gmail API client with scopes:
   - `gmail.readonly`, `gmail.modify`, `gmail.labels`
2. Build unread-primary query strategy:
   - Newest unread first
   - Exclude Promotions/Social/Updates/etc.
3. Implement message projection model:
   - sender, subject, body preview, IDs, labels
4. Implement mutation endpoints:
   - mark read (swipe up)
   - add FOLLOW UP label + mark read (swipe down)
   - trash (swipe right)
   - spam (swipe left)
5. Handle FOLLOW UP existing-label case idempotently.
6. Build retryable network layer with typed errors.

### Exit Criteria
- API layer supports all required read/write operations with tests.

---

## E. Swipe Queue & Interaction Engine

### Goals
- Deliver core Tinder-like processing experience.

### Tasks
1. Build card stack with current card + next-card ghost.
2. Wire directional gestures and visual feedback badges.
3. Implement optimistic action commit:
   - advance UI immediately
   - enqueue background sync operation
4. Add rollback/retry behavior for failed API actions with non-intrusive toast.
5. Add long-press menu equivalents for all actions.
6. Implement empty-state transition (“You're all caught up! 🎉”).

### Exit Criteria
- Users can process unread inbox emails end-to-end with all 4 actions.

---

## F. Navigation, Menu, and Settings

### Goals
- Complete auxiliary but required navigation controls.

### Tasks
1. Implement persistent top-left hamburger icon in card view.
2. Create left drawer menu with:
   - Resume
   - Exit
   - Settings pinned bottom
3. Implement Settings screen:
   - DISCONNECT (clear token + exit)
   - EXIT (preserve token + exit)
4. Ensure Resume always lands at first unread email.

### Exit Criteria
- Navigation flows match requirements and preserve inbox context.

---

## G. Offline, Reliability, and Hardening

### Goals
- Prevent silent data loss and improve perceived reliability.

### Tasks
1. Add connectivity detection.
2. Block gesture commits when offline with clear state messaging.
3. Add background queue retry policy for transient errors.
4. Add consistency checks on app foreground/resume.
5. Add API rate-limit/backoff handling.

### Exit Criteria
- Known failure modes handled without data corruption.

---

## H. QA, Compliance, and Release Prep

### Goals
- Ship a stable TestFlight build.

### Tasks
1. Test matrix:
   - Auth scenarios (new/returning/expired token/failure)
   - Gesture action correctness
   - Queue ordering correctness
   - Empty state behavior
   - Accessibility checks (VoiceOver, Dynamic Type)
2. Security/privacy validation:
   - no backend email storage
   - keychain/token handling checks
3. Performance pass:
   - smooth swipe animation on target devices
4. Beta instrumentation:
   - event logging for funnel and gesture outcomes
5. Prepare TestFlight release notes and known limitations.

### Exit Criteria
- QA signoff and TestFlight submission ready.

## 3) Proposed Milestones & Sequence

## Milestone 0 — Project Setup (Week 1)
- Foundation modules, build config, app routing shell.

## Milestone 1 — Auth Vertical Slice (Week 2)
- OAuth login + keychain + silent refresh + launch routing.

## Milestone 2 — Inbox Read Slice (Week 3)
- Fetch unread-primary list and render first full card.

## Milestone 3 — Full Swipe Actions (Weeks 4–5)
- All 4 gestures + optimistic updates + retry/toast.

## Milestone 4 — Navigation & Settings (Week 6)
- Hamburger drawer, settings actions, exit/resume flows.

## Milestone 5 — Accessibility & Reliability (Week 7)
- Long-press actions, dynamic type, offline handling.

## Milestone 6 — Stabilization & TestFlight (Week 8)
- QA pass, performance tuning, release prep.

## 4) Acceptance Criteria (V1)

A build is V1-complete when all are true:
1. User can authenticate using Google/federated OAuth and stay signed in across launches.
2. App lands on first unread primary-inbox email for signed-in users.
3. One email card at a time displays sender, subject, preview.
4. All 4 swipe actions work with indicator feedback and no confirmation prompts.
5. Actions are optimistic with background sync and user-visible retry path on failure.
6. Hamburger menu and Settings behaviors match requirements.
7. Empty-state screen appears when queue is exhausted.
8. Accessibility parity exists via long-press action menu and Dynamic Type support.
9. Offline state blocks actions clearly.
10. No out-of-scope features are included.

## 5) Risks & Mitigations

- **Federated OAuth complexity** → Prototype with AppAuth early; test multiple IdP configurations in Milestone 1.
- **Gmail category filtering accuracy** → Validate query behavior with seeded inbox test data.
- **Optimistic sync edge cases** → Maintain an operation queue with idempotent action payloads.
- **Exit behavior on iOS** → iOS apps are generally not meant to programmatically exit; align requirement interpretation with product/testing expectations.
- **Gesture discoverability/accessibility** → Keep visible hints and long-press alternatives in first release.

## 6) Implementation Backlog (Initial)

1. Create app skeleton + dependency setup.
2. Implement `AuthService` and keychain token store.
3. Implement Gmail API client + models.
4. Build card UI with mock data.
5. Wire swipe engine and action mapping.
6. Add optimistic queue + retry engine.
7. Implement hamburger + settings flows.
8. Add offline guardrails.
9. Add accessibility action menu.
10. Complete test suite and TestFlight packaging.

## 7) Immediate Next Steps (This Week)

1. Finalize UX wireframes + motion spec.
2. Register OAuth client and configure redirect URIs.
3. Create codebase scaffolding and CI checks.
4. Deliver Milestone 1 auth prototype on physical iPhone.

## 8) Week 1 Sprint Plan (Detailed)

### Sprint Theme
Establish the product/engineering foundation and de-risk authentication setup so Week 2 can focus on a working OAuth vertical slice.

### Sprint Window
- **Week 1 (5 working days)**
- **Primary outcomes:** approved UX baseline, technical scaffolding, OAuth configuration readiness, and development workflow hygiene.

### Sprint Goals
1. Create and align on V1 UX baseline for core screens and motion.
2. Set up the project structure, build configurations, and coding standards.
3. Prepare OAuth credentials, redirect URI strategy, and environment configuration.
4. Implement CI quality gates for fast feedback on future feature work.
5. Produce a Week 2-ready backlog with clear ownership and acceptance criteria.

### In-Scope Deliverables
- Wireframes and interaction annotations for:
  - onboarding/auth entry
  - email card view
  - gesture feedback states
  - empty state
  - hamburger menu and settings
- Motion behavior spec (thresholds, easing, transitions, snap-back).
- Swift/SwiftUI project scaffold with agreed folder/module conventions.
- Config system for environment values (dev/staging/prod placeholders).
- OAuth setup artifacts:
  - client ID registration status
  - redirect URI definitions
  - scope list and consent text review
- CI pipeline checks (at minimum formatting + build smoke check).
- Sprint handoff document for Week 2 auth implementation.

### Out of Scope (Week 1)
- Full Gmail API integration.
- End-to-end swipe actions against live inbox data.
- Menu/settings production polish.
- TestFlight build submission.

### Roles & Ownership (Suggested)
- **Product/Design:** wireframes, interaction details, acceptance criteria.
- **iOS Engineering:** project scaffold, config system, CI setup.
- **Security/Platform (if available):** OAuth registration, keychain policy review.
- **QA:** early test-plan skeleton and Week 2 auth test cases.

### Sprint Backlog (Detailed)

#### P0 — Must Complete This Week
1. **UX Baseline Spec v1**
   - Finalize screen flows and component hierarchy for required V1 screens.
   - Define gesture indicator color/label mapping and thresholds.
   - Accessibility notes for long-press alternatives and Dynamic Type scaling.
   - **Acceptance:** design review signoff and implementation-ready annotations.

2. **Project Bootstrap**
   - Initialize SwiftUI app target and shared folder structure.
   - Add base app state container and route placeholders.
   - Establish lint/format tooling and README contribution notes.
   - **Acceptance:** app builds on local machine and opens placeholder routes.

3. **Config & Secrets Strategy**
   - Add typed configuration layer for OAuth/client constants.
   - Define `.xcconfig` (or equivalent) strategy for environments.
   - Document secret-handling rules (no secrets in source control).
   - **Acceptance:** environment values can be switched without code edits.

4. **OAuth Readiness Package**
   - Register app/client with Google Cloud project.
   - Draft redirect URI + callback handling plan.
   - Verify required scopes and consent screen requirements.
   - **Acceptance:** all OAuth inputs required for Week 2 coding are available.

5. **CI Foundation**
   - Configure pipeline to run formatting/lint checks.
   - Add a build-only job for the main app target.
   - Define branch/PR checks policy.
   - **Acceptance:** PRs receive automated pass/fail signals.

#### P1 — Should Complete If Time Allows
6. **UI Prototype Shell**
   - Add static mock screens for card, empty state, and settings.
   - **Acceptance:** basic navigation between static screens works.

7. **QA Starter Matrix**
   - Draft auth test cases for new/returning/expired token paths.
   - **Acceptance:** Week 2 auth stories map to test cases.

#### P2 — Nice to Have
8. **Telemetry Event Contract Draft**
   - Define initial event names for auth funnel and swipe outcomes.
   - **Acceptance:** shared event naming doc reviewed by eng/product.

### Day-by-Day Execution Plan

#### Day 1 (Mon)
- Sprint kickoff and scope lock.
- Review requirements and resolve any ambiguities for Week 1.
- Start UX wireframes and engineering bootstrap skeleton.

#### Day 2 (Tue)
- Finalize interaction/motion notes for swipe UX.
- Complete project structure, app routing placeholders, and code standards.
- Start OAuth registration and consent configuration.

#### Day 3 (Wed)
- Mid-sprint checkpoint.
- Complete config/secrets layer and environment switching.
- Integrate CI checks for lint + build smoke test.

#### Day 4 (Thu)
- Design/engineering handoff review.
- Validate OAuth readiness artifacts and callback handling approach.
- Build optional static UI prototype shell (P1).

#### Day 5 (Fri)
- Sprint demo of all completed artifacts.
- Retrospective and risk review.
- Finalize Week 2 backlog (OAuth vertical slice tasks, owners, estimates).

### Definition of Done (Week 1)
Week 1 is done when all P0 items are complete and demonstrable:
1. UX spec is implementation-ready and approved.
2. App scaffold builds with clear module/folder structure.
3. Config layer supports non-hardcoded environment values.
4. OAuth registration/config prerequisites are documented and available.
5. CI validates formatting/lint + build on each PR.
6. Week 2 sprint backlog is created with explicit story acceptance criteria.

### Dependencies & Risks (Week 1)
- **Dependency:** Access to Google Cloud console and OAuth app registration permissions.
- **Dependency:** Design bandwidth for quick turnaround on interaction specifications.
- **Risk:** Delays in OAuth app verification requirements could block Week 2 implementation.
- **Mitigation:** Use internal/testing mode initially and parallelize local auth stubs.

### Week 1 Success Metrics
- 100% completion of P0 backlog.
- CI pass rate for default branch PRs.
- Zero unresolved blockers carried into Week 2 for OAuth coding start.
