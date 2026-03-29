# GraftMac — Specification

> macOS companion app for Graft practice tracking.

## Overview

GraftMac is a standalone macOS application that mirrors Graft's skill-practice tracking workflow on the desktop. It provides a distraction-free environment for reviewing practice history, logging sessions, and viewing analytics — all backed by Graft's shared SQLite data store.

## Platform & Requirements

- **Platform:** macOS 15.0+
- **Architecture:** Apple Silicon (arm64)
- **Swift:** 6.0
- **UI Framework:** SwiftUI
- **Build:** XcodeGen + xcodebuild

## Dependencies

| Package | Source | Version |
|---------|--------|---------|
| SQLite.swift | stephencelis/SQLite.swift | ≥ 0.15.0 |

## Bundle

- **Identifier:** `com.graft.app.macos`
- **Display Name:** GraftMac

## Features

### Current (v1.0.0)

- [x] Skill list sidebar with emoji + name
- [x] Skill detail view (header, stats, recent sessions)
- [x] Log session sheet
- [x] Analytics view
- [x] Settings view
- [x] Dark mode support
- [x] macOS 15.0+ target

### In Progress / Planned

- [ ] **R11:** Connect GraftMac to Graft's shared SQLite database (App Group)
- [ ] **R12:** macOS Widgets (Notification Center)
- [ ] **R13:** Practice reminders & Streak notifications (macOS Notification Center)

## Architecture

```
GraftMac/
├── Sources/
│   ├── GraftMacApp.swift      — @main entry point
│   └── MacGraftView.swift    — Main NavigationSplitView + all SwiftUI views
└── Resources/
    ├── Info.plist
    └── GraftMac.entitlements
```

### Data Layer

GraftMac uses **mock/sample data** in v1.0.0 (hardcoded `MacSkill` and `MacSession` structs).
Future iterations will connect to the shared SQLite store via App Groups so both iOS and macOS share the same practice database.

## UI Layout

```
┌─────────────────────────────────────────────────────────┐
│  GraftMac                                              │
│ ┌──────────────┐ ┌─────────────────────────────────────┐│
│ │   Sidebar   │ │          Detail View                ││
│ │             │ │                                     ││
│ │  🎹 Piano   │ │  [Skill Header + Log Session btn]  ││
│ │  🎸 Guitar  │ │                                     ││
│ │  💻 Coding  │ │  [Stats: Weekly / Streak / Count]  ││
│ │             │ │                                     ││
│ │  ─────────  │ │  [Recent Sessions list]            ││
│ │  Analytics  │ │                                     ││
│ │  Settings   │ │                                     ││
│ └──────────────┘ └─────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Entitlements

```xml
com.apple.security.app-sandbox: true
```

## Build Commands

```bash
# Generate project
xcodegen generate

# Build
xcodebuild -scheme GraftMac -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="-" build

# Build (signed)
xcodebuild -scheme GraftMac -configuration Release build
```

## Iteration History

| Iteration | Focus |
|-----------|-------|
| R1–R10    | Graft iOS core (skills, sessions, widget, export, etc.) |
| **R11**   | **R11: SQLite data integration (App Group shared store)** |
| R12       | R12: macOS Widgets (Notification Center) |
| R13       | R13: Practice reminders & streak notifications |
