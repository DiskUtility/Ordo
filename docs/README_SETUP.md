# Ordo: Planner Setup

## Requirements

- macOS with Xcode installed
- iOS Simulator runtime available (iPhone 17 recommended in current scripts)

## Open Project

```bash
open Planner.xcodeproj
```

## CLI Build

```bash
xcodebuild build \
  -scheme Planner \
  -project Planner.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## CLI Tests

```bash
xcodebuild test \
  -scheme Planner \
  -project Planner.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Troubleshooting

If you hit DerivedData build artifact errors:

```bash
xcodebuild clean \
  -scheme Planner \
  -project Planner.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or build with isolated DerivedData:

```bash
xcodebuild build \
  -scheme Planner \
  -project Planner.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/PlannerDerivedData
```
