# Ordo: Planner Architecture

## App Style

- Hybrid UIKit + SwiftUI
- Feature-first MVVM
- Service layer for domain logic
- SwiftData persistence layer

## Main Folders

- `OrdoPlanner/Models/`
- `OrdoPlanner/ViewModels/`
- `OrdoPlanner/Views/`
- `OrdoPlanner/Services/`
- `OrdoPlanner/Utilities/`
- `OrdoPlanner/DesignSystem/`

## Key Data Models

- `StudentProfile`
- `AcademicTerm`
- `Course`
- `AssignmentTask`

## Core Services

- `TriageService`: bucket and sort tasks for dashboard logic
- `LocalNotificationScheduler`: notification auth and scheduling
- `AppServices`: centralized service container

## UI Composition

- Root UIKit host: `PlannerRootViewController`
- Tab shell: Today, Timeline, Tasks, Settings
- Today screen implemented with UIKit controller for fine layout control
- Other screens built in SwiftUI

## Persistence Strategy

- Local-only storage via SwiftData
- Pre-release fallback: reset store on schema init failure
