# SwipeMail – iPhone App Requirements Plan
**Type:** iOS Productivity App  
**Target Users:** Individual Consumers  
**Stage:** Concept  
**Last Updated:** March 25, 2026

---

## 1. Product Overview

SwipeMail is an iPhone email client that reimagines inbox management through a swipe-based card interface inspired by dating applications. Instead of a traditional list view, users process one email at a time — each displayed as a full-screen card — and take action via intuitive swipe gestures. The goal is to make reaching inbox zero faster and more satisfying.

---

## 2. Authentication Requirements

### 2.1 OAuth Flow
- On first launch, the user must be presented with an OAuth login flow to connect their Google email account.
- The app must support **standard Google OAuth 2.0** for personal Gmail accounts.
- The app must support **enterprise/federated OAuth flows**, including but not limited to **Okta**, **Microsoft Entra ID (Azure AD)**, and other SAML/OIDC identity providers that front a Gmail account.
- The app should gracefully detect the appropriate OAuth variant based on the user's email domain and route them to the correct identity provider.
- OAuth tokens must be stored securely using the iOS **Keychain**.
- Token refresh must happen silently in the background without prompting the user to re-authenticate.

### 2.2 First-Time User Flow
1. App launches → display a welcome/onboarding screen.
2. User is prompted to connect their Gmail account.
3. OAuth flow is initiated (Google or federated IdP).
4. On successful authentication, the user is taken directly to the **first unread email** in their inbox.

### 2.3 Returning User Flow
- If a valid OAuth token exists in Keychain, skip the login screen and go directly to the first unread email.
- If the token has expired and cannot be silently refreshed, re-prompt the OAuth flow.

---

## 3. Core Features & User Stories

### 3.1 Email Card View

**User Story:** As a user, I want to see one email at a time in a large, readable card so I can focus on each message and take action quickly.

**Requirements:**
- Each email is displayed as a **full-screen card** occupying the majority of the screen.
- The card must display the following fields:
  - **Sender's email address** (top of card)
  - **Subject line** (below sender, visually prominent)
  - **Email body preview** (as much text as fits the remaining card area, truncated gracefully if too long)
- Cards are shown **starting from the newest unread email** in the inbox, progressing toward the oldest.
- Only **unread emails** from the **Primary inbox** are shown in the swipe queue. Emails in Promotions, Social, Updates, and other Gmail categories are excluded.
- When all unread emails have been processed, display an **"All caught up!"** empty state screen.

---

### 3.2 Swipe Gesture Actions

**User Story:** As a user, I want to take action on emails with a single swipe gesture so I can process my inbox without tapping through menus.

Each gesture must be accompanied by a **visual indicator** (e.g., color overlay or icon) providing feedback before the action is confirmed on release.

| Gesture | Action | Behavior |
|---|---|---|
| **Swipe Up** | Mark as Read | Marks email as read via Gmail API; advances to next unread email |
| **Swipe Down** | Follow Up | Applies a **"FOLLOW UP"** label to the email AND marks it as read via Gmail API; advances to next unread email |
| **Swipe Right** | Delete | Moves email to Trash via Gmail API; advances to next unread email |
| **Swipe Left** | Mark as Spam | Marks email as spam AND deletes it via Gmail API; **no confirmation dialog**; advances to next unread email |

**Requirements:**
- All four actions must execute **without a confirmation prompt**.
- Actions must be committed to Gmail in the background (optimistic UI — advance the card immediately, sync in background).
- If an API call fails, surface a non-intrusive error (e.g., toast notification) and allow the user to retry.

---

### 3.3 Hamburger Menu

**User Story:** As a user, I want a simple side menu to navigate key app functions without losing my place in my inbox.

**Requirements:**
- A **hamburger icon (☰)** is displayed in the **top-left corner** of the screen at all times during the card view.
- Tapping the icon reveals a side drawer with three options:

#### Menu Options

**1. Resume**
- Returns the user to the card view at the **first unread email** in their inbox.
- Useful if the user navigated away or the app was backgrounded.

**2. Exit**
- Closes the application.
- The user remains **signed in** to their Google account (OAuth token is preserved).

**3. Settings** *(pinned to the bottom of the menu)*
- Opens the Settings screen (see Section 3.4).

---

### 3.4 Settings Screen

**User Story:** As a user, I want a simple settings screen where I can disconnect my account or exit the app.

**Requirements:**
- The Settings screen displays **two buttons centered vertically** on the screen.
- No other UI elements are required on this screen beyond a back/close affordance and a screen title ("Settings").

#### Buttons

**Button 1 – DISCONNECT** *(top button)*
- Signs the user out of their Google account (revokes/clears the OAuth token from Keychain).
- Exits the application.
- No confirmation dialog required.

**Button 2 – EXIT** *(bottom button)*
- Exits the application.
- The user remains **signed in** (OAuth token is preserved).
- Functionally identical to the "Exit" option in the hamburger menu.

---

## 4. UI/UX Guidelines

### 4.1 Design Language
- The overall aesthetic should feel **clean, modern, and gesture-first** — inspired by dating app interfaces (e.g., Tinder-style card stacks).
- Use **ample whitespace** and **large typography** to make emails easy to scan at a glance.
- Avoid clutter — the card and gesture system are the primary UI; everything else should be secondary.

### 4.2 Email Card Design
- Cards should have **rounded corners** and a subtle **drop shadow** to convey depth.
- The card should occupy approximately **85–90% of the screen height**, leaving room for gesture hint indicators at the edges.
- Consider showing the **"ghost" of the next card** peeking behind the current one to reinforce the stack metaphor.
- Text hierarchy on the card:
  - Sender email: small, muted label style
  - Subject: large, bold, primary color
  - Body: standard body font, secondary color, line-clamped to available space

### 4.3 Swipe Gesture Feedback
- As the user swipes, display a **directional indicator** on the card:
  - **Up →** Blue badge: "READ"
  - **Down →** Yellow badge: "FOLLOW UP"
  - **Right →** Red badge: "DELETE"
  - **Left →** Orange badge: "SPAM"
- The card should tilt/rotate slightly in the swipe direction to feel physical and responsive.
- On release past a threshold (~30% of screen width/height), the action fires and the card animates off-screen.
- If released before the threshold, the card snaps back to center.

### 4.4 Navigation & Chrome
- **Status bar:** Visible, light or dark adaptive.
- **Navigation bar:** Minimal — only the hamburger icon (top-left) and optionally an unread count badge (top-right).
- **No bottom tab bar** — the swipe interface is the primary navigation paradigm.
- Hamburger menu drawer should slide in from the left, dimming the card view behind it.

### 4.5 Empty State
- When no unread emails remain, display a friendly **"You're all caught up! 🎉"** screen with a brief message and the option to exit or check back later.

### 4.6 Accessibility
- All swipe actions must also be accessible via **long-press context menus** for users who cannot perform swipe gestures.
- Text must meet **WCAG AA contrast** standards.
- Support **Dynamic Type** for user-adjusted font sizes.

---

## 5. Technical Considerations (High-Level)

- **Gmail API:** Use the Gmail REST API (`v1`) for reading emails, applying labels, moving to trash, and marking spam. Requires OAuth scopes: `gmail.readonly`, `gmail.modify`, `gmail.labels`.
- **OAuth Library:** Use `AppAuth` (open source, iOS-compatible) to handle both standard Google OAuth and federated flows (Okta, etc.).
- **Keychain:** Store and retrieve tokens using `Security` framework or a wrapper like `KeychainSwift`.
- **Offline Handling:** If no internet connection is available, display a clear offline state and prevent gesture actions from firing.
- **Privacy:** Email content must never be stored on any backend server. All processing happens on-device.

---

## 6. Out of Scope (V1)

The following features are explicitly excluded from the initial version to keep scope focused:

- Composing or replying to emails
- Support for non-Gmail providers (Outlook, Yahoo, etc.)
- Push notifications for new emails
- Search functionality
- Multiple account support
- iPad or Mac (Catalyst) support

---

## 7. Open Questions

| # | Question | Owner |
|---|---|---|
| 1 | ~~What should happen when the user swipes down ("Follow Up") on an email that already has the FOLLOW UP label?~~ **Resolved: If the email already has the FOLLOW UP label, swipe down will only mark it as read — the label will not be re-applied.** | Product |
| 2 | ~~Should the swipe queue include emails from all Gmail labels/folders, or only the Primary inbox?~~ **Resolved: Primary inbox only.** | Product |
| 3 | ~~Should deleted/spam emails be immediately purged or moved to Trash/Spam for 30 days per Gmail defaults?~~ **Resolved: Deleted and spam emails follow Gmail's default 30-day retention in Trash/Spam before permanent deletion.** | Product |
| 4 | ~~What monetization model will be pursued?~~ **Resolved: Deferred. App will be tested via TestFlight before a monetization decision is made.** | Product |
| 5 | ~~Is there a need to handle very long email threads vs. individual emails differently?~~ **Resolved: Deferred. Long email threads will be treated the same as individual emails in V1. To be revisited after TestFlight testing.** | Product |
