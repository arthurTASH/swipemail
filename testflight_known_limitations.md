# SwipeMail Known Limitations

- Federated enterprise auth routing is not a finished production flow; Google auth is the intended beta path.
- Some final manual QA items are still open around:
  - VoiceOver clarity
  - large Dynamic Type behavior
  - offline/reconnect behavior
  - failed queue work resurfacing on foreground
- Gmail empty-state and fetch-failure behavior were implemented, but those edge cases still need broader manual validation across test accounts.
- The app is intentionally scoped to unread primary-inbox processing only; out-of-scope features are still excluded.

## Privacy and security notes
- Email data stays on-device in the client app; there is no backend email storage path in V1.
- Auth session data is stored in device-local Keychain storage.
