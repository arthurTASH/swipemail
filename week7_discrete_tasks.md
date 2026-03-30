# Week 7 Discrete Task List (Milestone 5 — Accessibility & Reliability)

Derived from the Accessibility & Reliability goals in `implementation_plan.md`, with scope limited to V1 requirements that are still open after Week 6.

## 1. Long-press action hardening
- [x] Review the existing long-press/context-menu action path against all four swipe actions.
- [x] Ensure long-press actions remain available anywhere the top card is actionable.
- [x] Confirm long-press action labels and icons match the final gesture mapping.
- [x] Keep long-press behavior routed through the same optimistic queue pipeline as gestures.

## 2. Dynamic Type support
- [x] Audit the core user-facing surfaces for scalable typography:
  - onboarding
  - inbox card stack
  - empty state
  - drawer
  - settings
- [x] Remove layout assumptions that break at larger accessibility sizes.
- [x] Preserve action clarity and badge readability at larger text sizes.
- [x] Keep the swipe/card experience usable without truncation-driven ambiguity.

## 3. VoiceOver and accessibility semantics
- [x] Add meaningful accessibility labels for the inbox card content.
- [x] Add explicit accessibility labels and hints for each swipe action path.
- [x] Ensure drawer controls, settings actions, and exit/resume flows are screen-reader understandable.
- [x] Keep accessibility semantics aligned with the actual gesture/action mapping.

## 4. Connectivity detection foundation
- [x] Add a lightweight connectivity monitor for online/offline state.
- [x] Surface connectivity status through app/session state instead of ad hoc view checks.
- [x] Keep the implementation local and simple enough for V1.
- [x] Avoid introducing background/network complexity beyond what is needed for action blocking.

## 5. Offline action blocking
- [x] Prevent new swipe/long-press action commits while offline.
- [x] Present a clear banner or inline message explaining why actions are blocked.
- [x] Ensure inbox browsing remains available even when action commits are blocked.
- [x] Keep disconnect/navigation flows unaffected unless they truly depend on connectivity.

## 6. Foreground consistency and retry behavior
- [x] Add a foreground/resume consistency check for pending failed queue work.
- [x] Retry or re-surface pending failures when the app becomes active again.
- [x] Preserve the non-intrusive retry/banner model introduced earlier.
- [x] Avoid duplicating queue/sync orchestration logic across app state transitions.

## 7. Week 7 verification checklist
- [ ] Long-press action parity works for all four actions.
- [ ] Large Dynamic Type sizes remain usable on onboarding, inbox, drawer, and settings.
- [ ] VoiceOver labels/actions are understandable on the primary flows.
- [ ] Going offline blocks action commits with a clear explanation.
- [ ] Returning online allows action processing to resume.
- [ ] Failed/pending queue work is surfaced appropriately on foreground/resume.
- [ ] Debug build succeeds after accessibility and reliability integration.
