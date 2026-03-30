# SwipeMail TestFlight Submission Steps

This document is for the person preparing and uploading SwipeMail to TestFlight through App Store Connect.

## 1. Pre-flight checks

Before archiving, confirm:
- the Release bundle identifier matches the App Store Connect app record
- signing team and Release provisioning are correct in Xcode
- Release OAuth values are correct in `Config/Release.xcconfig`
- the Google account(s) needed for testing are allowed by the current OAuth test-user setup
- the current branch/commit is the one you actually want to ship

## 2. Create or verify the App Store Connect app record

In App Store Connect:
1. Go to `Apps`
2. Click `+`
3. Choose `New App`
4. Enter:
   - platform: `iOS`
   - app name: `SwipeMail`
   - primary language
   - bundle ID: must match the app’s Release bundle ID
   - SKU: your internal identifier

If the app record already exists, just verify that the bundle ID is correct.

## 3. Archive the app in Xcode

In Xcode:
1. Open `SwipeMail.xcodeproj`
2. Select a generic device target such as `Any iOS Device`
3. Choose `Product` → `Archive`
4. Wait for Organizer to open with the completed archive

If archive fails, fix that before attempting upload.

## 4. Upload the build to App Store Connect

From Xcode Organizer:
1. Select the archive
2. Click `Distribute App`
3. Choose `App Store Connect`
4. Choose `Upload`
5. Use the default validation/signing choices unless Xcode reports a specific issue
6. Complete the upload

After upload, App Store Connect still needs time to process the build.

## 5. Wait for processing

In App Store Connect:
1. Open your app
2. Go to `TestFlight`
3. Wait for the uploaded build to move through processing

The build may take several minutes before it becomes selectable for testing.

## 6. Internal testing

For internal testers:
1. Open the `TestFlight` tab for the app
2. Create or select an internal testing group
3. Add internal testers if needed
4. Assign the processed build to that group

Internal testers can usually start quickly once the build is processed.

## 7. External testing

For external testers:
1. Create or select an external testing group
2. Fill in any required beta metadata
3. Complete export compliance prompts if App Store Connect asks
4. Submit the build for Beta App Review
5. After approval, add testers or enable a public link

External testing requires Apple review before testers can install the build.

## 8. Recommended release notes and tester context

Use:
- `testflight_release_notes.md` for tester-facing focus areas
- `testflight_known_limitations.md` for current beta caveats
- `testflight_tester_setup.md` for account/setup guidance

## 9. Current SwipeMail beta risks to keep in mind

- Federated enterprise auth is still not a completed production path
- Some final manual QA items are still open around:
  - VoiceOver
  - large Dynamic Type behavior
  - offline/reconnect behavior
  - failed queue resurfacing on foreground
- Gmail empty/fetch-failure edge-case validation is still not fully closed out

## 10. Suggested final ship checklist

Before pressing submit, confirm:
- archive succeeds locally
- the correct build/version number is set
- Release OAuth config is correct
- sign-in works on a Release-signed build
- App Store Connect processing succeeds
- at least one internal tester can install and launch the build
