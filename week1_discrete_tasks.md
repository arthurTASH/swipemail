# Week 1 Discrete Task List (Milestone 0 — Project Setup)

Derived from the Week 1 milestone in `implementation_plan.md`.

## 1. Repository and Xcode project scaffolding
- [x] Create the iOS app project file structure in-repo (`SwipeMail.xcodeproj`, shared scheme, `Info.plist`).
- [ ] Verify Build/Run on macOS Xcode simulator.
- [x] Add top-level groups/folders: `App`, `Features`, `Services`, `Models`, `Infrastructure`, `DesignSystem`.
- [x] Add starter Swift files/placeholders in each folder to establish module boundaries.

### Unresolved item completion steps (Xcode/simulator)
1. On macOS with Xcode 16+, clone this repository and open:
   - `SwipeMail.xcodeproj` (or the repo folder directly in Xcode)
2. Confirm project wiring in Xcode:
   - Target: `SwipeMail`
   - Source groups include `App`, `Features`, `Services`, `Models`, `Infrastructure`, `DesignSystem`
   - Shared scheme `SwipeMail` is available
3. In Target Build Settings, confirm:
   - iOS Deployment Target is set for the team’s baseline (e.g., iOS 17+)
   - Bundle Identifier is set (currently `com.swipemail.app` in project settings)
4. In **Target → Signing & Capabilities**:
   - For simulator-only local runs, a Signing Team is **not required**
   - Configure Signing Team only when running on a physical device or preparing archive/distribution
5. Build verification:
   - Run `Product → Build` (⌘B) and resolve any target membership issues
6. Simulator verification:
   - Select `iPhone 16` (or team standard simulator)
   - Run `Product → Run` (⌘R) and confirm app launches to scaffold screen
7. Mark Task 1 complete by changing the unchecked simulator verification item above to `[x]`.

## 2. Build configurations and environment setup
- Add environment config structure for:
  - OAuth client ID(s)
  - Redirect URI
  - Gmail API constants/scopes placeholders
- Create Debug/Release config values (e.g., `.xcconfig` or equivalent).
- Ensure no secrets are hardcoded in source files.

## 3. App lifecycle and initial routing shell
- Implement app bootstrap flow:
  - Launch app
  - Check for stored auth token in Keychain abstraction
  - Route to Onboarding when token missing
  - Route to Inbox shell when token present
- Add placeholder Onboarding and Inbox screens to validate routing.

## 4. Core service contracts (interfaces only)
- Define protocol/contract stubs for:
  - `AuthService`
  - `GmailService`
  - `QueueService`
  - `SyncEngine`
- Add dependency injection entry point in app composition root.

## 5. Error and state handling foundations
- Define shared app error model (network, auth, unknown).
- Add basic user-facing toast/banner component API for transient errors.
- Add minimal loading/empty/error state models for Inbox shell.

## 6. Logging/telemetry baseline
- Add structured logging utility with levels (debug/info/error).
- Add analytics event protocol + no-op implementation for local builds.
- Ensure sensitive data (tokens/message bodies) are redacted by default.

## 7. Definition of done checks for Week 1
- App launches successfully from clean install.
- Routing is deterministic based on token presence.
- Project builds cleanly on Debug configuration.
- Basic architecture folders/contracts are in place.
- Team can begin Week 2 OAuth implementation without restructuring.
