# SwipeMail TestFlight Release Notes

## What to test
- Sign in with the approved Google test account flow.
- Review unread primary-inbox emails one card at a time.
- Try all four actions:
  - swipe up: mark as read
  - swipe down: delete
  - swipe right: follow up
  - swipe left: spam
- Open the drawer and confirm `Resume`, `Exit`, and `Settings` behavior.
- Use `DISCONNECT` and `EXIT` from Settings.
- Check the empty-state flow after processing all unread primary messages.

## Focus areas
- Auth persistence across relaunch
- Inbox card rendering and queue progression
- Optimistic action behavior and retry banners
- Drawer/settings navigation
- Offline blocking and reconnect behavior
- Accessibility behavior at larger text sizes and with VoiceOver enabled

## Feedback to include
- What account/setup you used
- Which action or route failed
- Whether the issue was reproducible
- Screenshot or screen recording when possible
