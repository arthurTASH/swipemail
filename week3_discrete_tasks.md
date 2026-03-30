# Week 3 Discrete Task List (Milestone 2 — Inbox Read Slice)

Derived from the Gmail Data Layer and early Inbox Read Slice goals in `implementation_plan.md`.

## 1. Gmail API readiness and scope validation
- [ ] Confirm the Google OAuth flow requests the Gmail scopes needed for the read slice.
- [ ] Verify the signed-in session carries the scopes required for fetching inbox messages.
- [ ] Confirm the current auth configuration is compatible with Gmail API requests from the app.
- [ ] Ensure Gmail API usage remains client-side only with no backend email storage.

## 2. Gmail networking foundation
- [x] Implement the base Gmail API request layer in `GmailService`.
- [x] Add authenticated request construction using the stored access token.
- [x] Add typed response decoding for the unread message list endpoint.
- [x] Map HTTP/network failures into the shared app error model.

## 3. Unread primary query strategy
- [x] Implement the unread-primary query used for the initial inbox slice.
- [x] Ensure results are ordered newest unread first.
- [x] Exclude Promotions, Social, Updates, and non-primary categories per the requirements.
- [x] Keep the query logic isolated so it can be refined without restructuring the service layer.

## 4. Message projection and parsing
- [x] Expand the `GmailMessage` model to support the fields needed by the card UI.
- [x] Parse sender, subject, preview/body snippet, IDs, and any label metadata required for later actions.
- [x] Handle missing/partial payload data without crashing.
- [x] Keep parsing logic separate from view code.

## 5. Inbox fetch flow integration
- [x] Connect the inbox shell to the real `GmailService` instead of the placeholder empty state.
- [x] Trigger unread-message loading after a valid auth session is restored.
- [x] Route fetched results into the inbox view state model.
- [x] Keep auth bootstrap and inbox fetch responsibilities separated cleanly.

## 6. First real inbox card UI
- [x] Replace the inbox placeholder copy with a first-pass email card layout.
- [x] Display one message at a time using the fetched Gmail data.
- [x] Show sender, subject, and preview text in a readable hierarchy.
- [x] Preserve room for future swipe interactions without overengineering the card stack yet.

## 7. Inbox loading, empty, and error states
- [x] Show a loading state while the unread-primary query is in flight.
- [x] Show an empty state when no unread primary messages remain.
- [x] Show a user-facing error state when the Gmail fetch fails.
- [x] Ensure state transitions are deterministic across relaunch and session restore.

## 8. Week 3 verification checklist
- [ ] Signed-in users trigger a real Gmail unread-primary fetch.
- [ ] The inbox shell displays the first fetched unread email instead of placeholder text.
- [ ] Sender, subject, and preview render from live Gmail data.
- [ ] Empty state appears when no unread primary messages are returned.
- [ ] Gmail fetch failures surface through the existing error/banner system.
- [x] Debug build succeeds after Gmail data layer integration.
