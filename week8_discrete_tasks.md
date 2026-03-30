# Week 8 Discrete Task List (Milestone 6 — Stabilization & TestFlight)

Derived from the QA, Compliance, and Release Prep workstream in `implementation_plan.md`, scoped as the final V1 closeout week.

## 1. QA matrix and gap review
- [x] Review all prior weekly verification checklists and identify any still-open runtime gaps.
- [x] Consolidate the V1 manual QA matrix across:
  - auth flows
  - inbox fetch behavior
  - swipe action correctness
  - queue/retry behavior
  - navigation/settings flows
  - accessibility and offline handling
- [x] Mark which items are already verified, which remain manual, and which need code changes.
- [x] Keep the final QA list concrete enough to drive release signoff.

Current open manual QA gaps carried into Week 8:
- Week 3:
  - empty state appears when no unread primary messages are returned
  - Gmail fetch failures surface through the existing error/banner system
- Week 7:
  - long-press action parity works for all four actions
  - large Dynamic Type sizes remain usable on onboarding, inbox, drawer, and settings
  - VoiceOver labels/actions are understandable on the primary flows
  - going offline blocks action commits with a clear explanation
  - returning online allows action processing to resume
  - failed/pending queue work is surfaced appropriately on foreground/resume

Verified already and not currently flagged as gaps:
- auth sign-in, stored-session relaunch, silent refresh routing, sign-out/disconnect behavior
- real inbox fetch and first-card rendering with live Gmail data
- optimistic action pipeline, queue execution, retry surface, and card-stack gesture flow
- navigation drawer, settings, exit/resume, and disconnect routing
- local Xcode builds across the implemented milestones

## 2. Reliability and hardening pass
- [x] Review queue, sync, and session edge cases for remaining obvious failure modes.
- [x] Tighten user-facing error copy where current fallback messaging is too vague for V1.
- [x] Review transient network handling and ensure retry/offline behavior is coherent.
- [x] Avoid broad architecture changes; limit work to high-signal hardening fixes only.

## 3. Security and privacy validation
- [x] Reconfirm that no backend email storage path exists in V1.
- [x] Review auth/token handling for accidental logging or unsafe persistence behavior.
- [x] Reconfirm Keychain/session handling behavior remains aligned with the intended device-local policy.
- [x] Document any residual security/privacy limitations that should be called out before TestFlight.

Security/privacy review conclusions:
- Email data remains client-side only; there is no backend persistence path in the current app architecture.
- Auth/session state is stored in Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and `kSecAttrSynchronizable = false`, which keeps tokens device-local.
- Logging and analytics paths use redaction/no-op behavior rather than storing raw tokens or email contents.
- Google token revocation requests now use proper form encoding for the token payload.

Residual limitations to call out before TestFlight:
- CI/build validation is in place, but the final manual accessibility/offline QA items remain open.
- Federated enterprise auth is still a placeholder path rather than a completed production flow.

## 4. Performance and UX polish pass
- [x] Review swipe/card interactions for obvious animation or responsiveness issues.
- [x] Smooth out any rough edges in the loading, transition, or dismissal path that materially affect first impressions.
- [x] Keep changes narrow and shippable; avoid redesigning established flows.
- [x] Preserve the current interaction model while removing any distracting implementation artifacts.

## 5. Beta instrumentation review
- [x] Review the current analytics/logging coverage for sign-in, inbox load, swipe actions, sync failure, and connectivity changes.
- [x] Add only the missing high-value events needed for TestFlight feedback and funnel visibility.
- [x] Keep sensitive data redaction intact for all logging and analytics paths.
- [x] Avoid instrumentation sprawl beyond the V1 debugging and funnel needs.

## 6. Release prep artifacts
- [x] Draft TestFlight release notes.
- [x] Draft a concise known-limitations list for beta testers.
- [x] Capture any setup notes testers need for OAuth/test-account usage.
- [x] Keep release-prep text grounded in the actual current product behavior.

Release-prep artifacts:
- `testflight_release_notes.md`
- `testflight_known_limitations.md`
- `testflight_tester_setup.md`

## 7. Final V1 verification checklist
- [ ] Auth flows behave correctly for new, returning, refresh-failure, and disconnect scenarios.
- [ ] Inbox fetch and first-card rendering still work on the current mainline branch.
- [ ] All four actions still work end-to-end with optimistic queue behavior.
- [ ] Navigation, settings, exit/resume, and disconnect flows remain correct.
- [ ] Accessibility and offline behaviors are acceptable for TestFlight.
- [ ] CI builds the project successfully from GitHub Actions.
- [ ] The app is in a state suitable for TestFlight submission.

Beta release note:
- The final V1 verification checklist is intentionally left open for beta.
- This branch is being advanced as a TestFlight candidate with known remaining manual QA gaps rather than as a fully closed-out release signoff.
