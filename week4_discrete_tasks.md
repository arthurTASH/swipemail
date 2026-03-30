# Week 4 Discrete Task List (Milestone 3 — Full Swipe Actions, Part 1)

Derived from the Gmail Data Layer and Swipe Queue & Interaction Engine sections in `implementation_plan.md`, plus the action requirements in `email_app_requirements.md`.

## 1. Action model and operation contracts
- [x] Finalize the app-side action model for the four supported gestures: read, follow up, delete, spam.
- [x] Define a queue operation model that captures the Gmail mutation intent independently of UI gestures.
- [x] Ensure each operation includes the message identifiers needed for retry and reconciliation.
- [x] Keep action modeling separate from view code so gesture handling can stay thin later.

## 2. Gmail mutation endpoints
- [x] Implement the Gmail API mutation for mark as read.
- [x] Implement the Gmail API mutation for follow up: apply the `FOLLOW UP` label and mark the message as read.
- [x] Implement the Gmail API mutation for trash.
- [x] Implement the Gmail API mutation for spam.
- [x] Use typed request/response helpers and map failures into the shared app error model.

## 3. FOLLOW UP label handling
- [x] Add Gmail label lookup support for the custom `FOLLOW UP` label.
- [x] Create the label if it does not already exist.
- [x] Make the follow-up action idempotent when the label is already present.
- [x] Keep label management encapsulated in the Gmail service layer.

## 4. Queue service foundation
- [x] Replace the placeholder queue service with a real in-memory operation queue.
- [x] Support enqueue, peek/next, completion, and failure bookkeeping.
- [x] Preserve operation ordering so UI advancement and background sync remain deterministic.
- [x] Expose only the minimal API needed by the app session/inbox flow.

## 5. Optimistic action pipeline
- [x] Connect the current inbox message to a concrete swipe/action intent.
- [x] Advance the inbox UI immediately when an action is triggered.
- [x] Enqueue the corresponding mutation operation for background processing.
- [x] Keep the optimistic UI step and the sync execution step clearly separated.

## 6. Background sync execution
- [x] Implement a first-pass sync executor that drains queued mutation operations.
- [x] Execute Gmail mutations asynchronously after optimistic UI advancement.
- [x] Mark successful operations complete and remove them from the in-memory queue.
- [x] Surface failures back into app-visible state without blocking the queue model.

## 7. Failure handling and retry surface
- [x] Show a non-intrusive banner/toast when a queued Gmail action fails.
- [x] Add a minimal retry path for failed operations.
- [x] Avoid duplicating successful Gmail mutations when retrying.
- [x] Log and track action outcomes for later QA and debugging.

## 8. Week 4 verification checklist
- [x] Swipe-up/mark-read action advances the UI and updates Gmail successfully.
- [x] Follow-up action applies the label and marks the message as read.
- [x] Delete action moves the email to Trash.
- [x] Spam action marks the email as spam without a confirmation dialog.
- [x] Failed Gmail mutations surface through the existing banner/error system.
- [x] Debug build succeeds after mutation and queue integration.
