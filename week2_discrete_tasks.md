# Week 2 Discrete Task List (Milestone 1 — Auth Vertical Slice)

Derived from the Authentication & Session Management workstream and Milestone 1 in `implementation_plan.md`.

## 1. OAuth dependency and project wiring
- [ ] Add the OAuth dependency to the Xcode project (AppAuth or approved alternative).
- [ ] Confirm the package/framework resolves cleanly in Xcode.
- [ ] Ensure the app target links the OAuth dependency successfully on device and simulator builds.

### Notes
- Prefer `AppAuth` unless the team explicitly changes libraries.
- Keep dependency setup isolated so the auth integration can evolve without touching unrelated modules.

## 2. Auth configuration completion
- [ ] Replace placeholder OAuth client IDs in `Debug.xcconfig` / `Release.xcconfig` with real values.
- [ ] Replace placeholder redirect URI values with the registered app redirect URI.
- [ ] Confirm Info.plist and runtime config surface the final auth values correctly.
- [ ] Verify no client secrets or other sensitive credentials are committed to source.

### Replacement Instructions
1. In Google Cloud Console, create or open the iOS OAuth client for each bundle identifier:
   - Debug: `com.swipemail.app.debug`
   - Release: `com.swipemail.app`
2. Copy the client ID value into:
   - `Config/Debug.xcconfig` → `SWIPEMAIL_OAUTH_CLIENT_ID`
   - `Config/Release.xcconfig` → `SWIPEMAIL_OAUTH_CLIENT_ID`
3. Copy the registered redirect URI into:
   - `Config/Debug.xcconfig` → `SWIPEMAIL_OAUTH_REDIRECT_URI`
   - `Config/Release.xcconfig` → `SWIPEMAIL_OAUTH_REDIRECT_URI`
4. Do not add client secrets, downloaded JSON credentials, or any other secret material to the repository.
5. After replacing the placeholders, verify the values resolve through:
   - `.xcconfig` → `App/Info.plist` build settings substitution
   - `AppEnvironment.current` runtime loading
6. Build the app in Debug and confirm no placeholder values remain in the effective auth configuration.

## 3. Auth domain and provider routing
- [ ] Define the initial provider-routing model for standard Google OAuth vs enterprise/federated flows.
- [ ] Add domain-based provider selection rules or a placeholder abstraction if discovery is deferred.
- [ ] Ensure the auth layer can choose the correct OAuth entry point from user input or session context.

## 4. Real AuthService implementation
- [ ] Expand `AuthService` from placeholder session persistence into a real OAuth session service.
- [ ] Model the minimum auth session payload needed for access token, refresh token, and expiry metadata.
- [ ] Replace placeholder sign-in behavior with a real OAuth start/completion flow.
- [ ] Preserve the existing app routing contract so launch behavior continues to depend on stored session presence.

## 5. Secure token persistence and retrieval
- [x] Store the OAuth session securely in Keychain using the Week 1 token-store abstraction or a refined replacement.
- [x] Confirm saved session data can be loaded across app relaunches.
- [x] Ensure token persistence logging remains redacted by default.
- [x] Review Keychain query options and accessibility class for the expected launch-time behavior.

## 6. Silent refresh path
- [x] Detect expired or near-expiry access tokens at app bootstrap.
- [x] Implement silent token refresh before routing into the inbox experience.
- [x] Update persisted session state after a successful refresh.
- [x] Fall back to onboarding if refresh fails or the session is no longer valid.

## 7. Sign-out and disconnect behavior
- [x] Implement auth-session clearing through the real auth stack, not just the placeholder path.
- [x] Revoke tokens if supported by the chosen provider flow.
- [x] Route back to onboarding after disconnect.
- [ ] Confirm local session and Keychain state are removed after sign-out.

## 8. Error handling and observability for auth flows
- [x] Add typed auth failure mapping for cancellation, configuration failure, refresh failure, and unknown auth errors.
- [x] Surface user-facing auth failures through the existing banner/toast foundation.
- [x] Add analytics/logging events for auth start, success, refresh success/failure, and sign-out.
- [x] Confirm tokens, auth codes, and raw email identifiers never appear in logs.

## 9. Week 2 verification checklist
- [x] First launch reaches onboarding and can begin a real OAuth flow.
- [x] Successful auth persists a session and routes into the inbox shell.
- [x] Relaunch with a valid stored session skips onboarding.
- [x] Expired session attempts silent refresh before showing onboarding.
- [x] Failed refresh or invalid session returns the user to onboarding cleanly.
- [x] Sign-out/disconnect clears stored auth state and returns to onboarding.
- [x] Project builds cleanly on Debug configuration after auth integration.
