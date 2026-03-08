# Tony VIP — Unified Contact Intelligence App

A native SwiftUI app for iPhone, iPad, and Mac (Catalyst). Tony's personal command center for high-value relationships — with Blaze powering the intelligence layer behind every conversation.

## What This Is

Instead of bouncing between iMessage, Signal, notes apps, and Salesforce, Tony opens one app. Every contact comes pre-loaded with:
- **Relationship health score** — Strong / Good / Fading / Cold (with days since last contact)
- **Blaze AI summary** — what you need to know before you reply
- **Suggested opener** — drafted by Blaze based on context and history
- **Key facts** — pulled from CRM and private notes
- **Pending items** — what's outstanding with this person
- **RPM project links** — active outcomes tied to this relationship
- **Pinned notes** — quick reference before a call or message
- **Native conversation thread** — send via Blaze channel (our protocol, not iMessage)

## Architecture

```
TonyVIP/
├── Models/
│   ├── Models.swift          # VIPContact, Message, RPMReference, BlazeContext, AppStore
│   └── SampleData.swift      # 6 realistic VIP contacts with full context
├── Views/
│   ├── ContentView.swift     # NavigationSplitView (iPad/Mac) root
│   ├── InboxView.swift       # Contact list with search, filters, relationship health
│   ├── ContactDetailView.swift # Header + Blaze banner + 4-tab detail view
│   └── ConversationView.swift  # Message thread + compose bar
└── TonyVIPApp.swift          # App entry, AppStore injection
```

## Current Status (v0.1)

**Built:**
- Full SwiftUI project, compiles clean
- `NavigationSplitView` — sidebar (contact list) + detail (conversation + context)
- Contact inbox with:
  - Avatar with relationship health ring
  - Unread badge (amber)
  - Last message preview
  - Tier badge (Inner Circle 🔥 / VIP / Key Contact)
  - Pending item alert when no messages
- Blaze Context Banner (collapsible, per-contact):
  - AI-generated summary
  - Suggested opener
  - Pending action chips
- 4-tab detail: Conversation · Context · Notes · RPM
- Custom iMessage-style chat bubbles (amber for Tony, dark for contact)
- Compose bar with multi-line input and animated send button
- Filter sheet: filter by tier or relationship health
- 6 realistic sample contacts (Oprah, Elon, Marc Benioff, Arianna, Satya, Deepak)
- Full sample message threads

**Not yet built (Phase 2):**
- Blaze backend API integration (replace sample data)
- Apple Contacts sync (Contacts framework)
- Private list import (CSV / manual)
- Push notifications for new messages
- iMessage bridge (research needed — Apple restrictions)
- Email integration
- Real-time Blaze context updates
- CRM data pull (Salesforce / custom)

## Running It

1. Open `TonyVIP/TonyVIP.xcodeproj` in Xcode 15+
2. Select iPhone 16 Pro or iPad simulator
3. Build & run (⌘R)
4. No dependencies — pure SwiftUI + SwiftData (coming in Phase 2)

## Design Decisions

- **Dark amber theme** — matches Blaze Mission Control palette
- **NavigationSplitView** — native iPad/Mac sidebar + detail layout
- **Relationship health as the primary signal** — color ring on every avatar tells Tony the state of each relationship before he reads anything
- **Blaze banner is collapsible** — Tony can hide it once he's read the context
- **Custom Blaze channel** — our own messaging protocol, not iMessage. Solves the API restriction problem elegantly.

## Next Steps for Bartok

1. Create the `.xcodeproj` / `.xcworkspace` file (the Swift source files are all here)
2. Wire `BlazeService.swift` (stub file) to real Blaze backend endpoints
3. Implement `ContactsService.swift` for Apple Contacts sync
4. Add SwiftData persistence for messages and notes
5. Push notification entitlements

---

*Built by Inigo ⚔️ — March 8, 2026*
