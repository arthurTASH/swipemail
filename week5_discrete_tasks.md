# Week 5 Discrete Task List (Milestone 3 — Full Swipe Actions, Part 2)

Derived from the Swipe Queue & Interaction Engine requirements in `implementation_plan.md` and the gesture/UI behavior in `email_app_requirements.md`.

## 1. Card stack foundation
- [x] Replace the temporary inbox action-button layout with a real stacked card presentation.
- [x] Show the current message card plus a subtle next-card preview/ghost.
- [x] Preserve the existing message model and optimistic queue pipeline while changing only the presentation layer.
- [x] Keep the card stack implementation isolated from Gmail networking concerns.

## 2. Directional gesture engine
- [x] Add drag gesture handling for up, down, left, and right directions.
- [x] Resolve gesture direction deterministically so horizontal and vertical actions do not conflict.
- [x] Apply threshold-based commit behavior for actions and snap-back behavior for canceled drags.
- [x] Ensure gesture handling emits the existing `SwipeAction` intents rather than duplicating action logic.

## 3. Visual feedback badges and motion
- [x] Show the directional feedback badges during drag:
  - READ
  - FOLLOW UP
  - DELETE
  - SPAM
- [x] Add color-coded overlays/icons matching the product requirements.
- [x] Add card tilt/rotation behavior tied to drag direction.
- [x] Add dismissal and snap-back animation timing that feels intentional and testable.

## 4. Card dismissal and queue progression
- [x] Animate committed cards off-screen in the chosen direction.
- [x] Advance to the next unread message after the dismissal animation completes.
- [x] Keep optimistic advancement visually aligned with the existing queue/sync pipeline.
- [x] Avoid double-firing actions during rapid gesture interaction.

## 5. Long-press action parity
- [x] Add a long-press or context-menu action surface for all four actions.
- [x] Ensure the long-press path uses the same `SwipeAction` and queue pipeline as gestures.
- [x] Keep labels and action naming explicit and user-readable.
- [x] Verify the non-gesture action path works even when swipe interaction is unavailable.

## 6. Production empty state transition
- [x] Replace the generic empty inbox copy with the product-specific “All caught up” state.
- [x] Make the empty-state transition feel like the terminal state of the card stack, not a separate screen jump.
- [x] Preserve retry/check-again affordances where appropriate without conflicting with the “caught up” experience.
- [x] Keep the empty state consistent with the rest of the swipe-first visual language.

## 7. Week 5 verification checklist
- [ ] Users can trigger all four actions via drag gestures.
- [ ] Gesture thresholds and snap-back behavior feel correct in the simulator.
- [ ] Directional badges and motion align with the selected action before release.
- [ ] Long-press/context-menu actions perform the same operations as gestures.
- [ ] The card stack advances correctly through multiple unread messages.
- [ ] The “All caught up!” empty state appears when the queue is exhausted.
- [ ] Debug build succeeds after gesture and card-stack integration.
