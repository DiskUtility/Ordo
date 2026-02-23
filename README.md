# Ordo: Planner

Ordo: Planner is a local-first iOS student planner concept app for high school and college students.

## Overview

Ordo focuses on the essentials:

- Set up your profile and active term
- Organize classes in a timeline
- Track tasks with deadline triage
- Get local reminders before due dates

Everything is on-device. No account and no cloud dependency in this concept version.

## Core Features

- Student onboarding and profile defaults
- Timeline course management
- Tasks with course linking, status, and priority
- Dashboard triage: `Overdue`, `Today`, `Upcoming`
- Local notification reminders
- Display settings including compact cards

## Tech Stack

- SwiftUI + UIKit
- SwiftData (local persistence)
- UserNotifications (local reminders)
- XCTest / XCUITest

## Project Layout

- `OrdoPlanner/` app source
- `OrdoPlannerTests/` unit tests
- `OrdoPlannerUITests/` UI tests
- `docs/` product and engineering docs

## Build

```bash
xcodebuild -list -project Planner.xcodeproj
xcodebuild build -scheme Planner -project Planner.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Test

```bash
xcodebuild test -scheme Planner -project Planner.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Docs

- [`docs/README.md`](docs/README.md)
- [`docs/README_PRODUCT.md`](docs/README_PRODUCT.md)
- [`docs/README_FEATURES.md`](docs/README_FEATURES.md)
- [`docs/README_ARCHITECTURE.md`](docs/README_ARCHITECTURE.md)
- [`docs/README_SETUP.md`](docs/README_SETUP.md)
- [`docs/README_RELEASE.md`](docs/README_RELEASE.md)
- [`docs/README_ROADMAP.md`](docs/README_ROADMAP.md)
