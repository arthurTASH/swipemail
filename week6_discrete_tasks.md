# Week 6 Discrete Task List (Milestone 4 — Navigation & Settings)

Derived from the Navigation, Menu, and Settings workstream in `implementation_plan.md` and the navigation/settings requirements in `email_app_requirements.md`.

## 1. Navigation chrome foundation
- [x] Add a persistent top-left hamburger control to the inbox/card experience.
- [x] Keep the navigation chrome minimal and compatible with the existing card stack layout.
- [x] Ensure the hamburger affordance remains available across loading, ready, empty, and error inbox states where appropriate.
- [x] Keep navigation controls separate from the swipe-action engine so card interactions remain focused.

## 2. Side drawer container
- [x] Implement a left-side drawer that overlays the inbox/card view.
- [x] Add background dimming and a clear open/close interaction model.
- [x] Ensure the drawer does not break the current card-stack gesture interactions when closed.
- [x] Add deterministic drawer state handling for open, close, and resume transitions.

## 3. Drawer menu actions
- [x] Add `Resume` to return to the current inbox/card experience.
- [x] Add `Exit` to leave the app flow while preserving the signed-in session.
- [x] Add `Settings` and pin it to the bottom area of the drawer.
- [x] Keep menu labeling explicit and aligned with the product requirements.

## 4. Settings screen foundation
- [x] Implement a dedicated Settings screen with a title and close/back affordance.
- [x] Keep the screen intentionally minimal with vertically centered actions.
- [x] Preserve visual consistency with the swipe-first design language instead of default form styling.
- [x] Ensure navigation to and from Settings preserves inbox context.

## 5. Disconnect flow
- [x] Implement the `DISCONNECT` action from Settings.
- [x] Clear or revoke the stored auth session using the existing auth stack.
- [x] Route the app back out of the signed-in experience after disconnect.
- [x] Keep disconnect behavior aligned with the existing auth/session lifecycle logic.

## 6. Exit and resume behavior
- [x] Implement `Exit` behavior from both the drawer and Settings.
- [x] Preserve the signed-in session when exiting without disconnecting.
- [x] Ensure `Resume` returns to the first unread email/card context as required.
- [x] Keep exit/resume handling explicit so it can be revisited if product interpretation changes for iOS.

## 7. Week 6 verification checklist
- [x] Hamburger icon is always available in the card experience.
- [x] Drawer opens and closes cleanly with dimming/background behavior.
- [x] `Resume` returns to the inbox/card experience without losing context.
- [x] `Settings` opens from the drawer and returns cleanly.
- [x] `DISCONNECT` signs the user out and removes signed-in access.
- [x] `Exit` preserves the signed-in session.
- [x] Debug build succeeds after navigation and settings integration.
