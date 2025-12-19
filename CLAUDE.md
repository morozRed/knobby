# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Knobby** is a minimalist iOS app providing a sensory wall of tactile objects (knobs, switches, sliders, pressure buttons) for users who need something steady to interact with. The core principle: **Knobby does nothing useful — and that's the point.**

## Build Commands

```bash
# Build for Debug
xcodebuild -project knobby.xcodeproj -scheme knobby -configuration Debug

# Build for Release
xcodebuild -project knobby.xcodeproj -scheme knobby -configuration Release

# Run tests (when added)
xcodebuild -project knobby.xcodeproj -scheme knobby test
```

## Tech Stack

- **SwiftUI** for declarative UI
- **SwiftData** for persistence
- **iOS 18.6** deployment target (iOS 15.0 recommended minimum)
- **No external dependencies** currently

## Architecture

- Entry point: `knobby/knobbyApp.swift` - Sets up SwiftData ModelContainer
- Main UI: `knobby/ContentView.swift` - Currently template code, needs implementation
- Data model: `knobby/Item.swift` - SwiftData model

## Product Specification

See **PRD.md** for complete product requirements. Key points:

### Core UX Constraints
- No home screen, menu, or onboarding flow
- App opens directly to the sensory wall
- No goals, progress, tracking, or coaching
- No numbers, values, or explanations shown
- Objects must respond instantly with subtle resistance

### Sensory Priority
1. Haptics (primary)
2. Micro-sound (optional, off by default)
3. Visual change (follows touch, doesn't lead)

### MVP Objects
1. **Knob** - Infinite rotation, gentle ticking haptics (anchor object)
2. **Light Switch** - On/off/half-press, soft haptic thunk
3. **Pressure Button** - Press and hold, haptics deepen over time
4. **Weighted Slider** - Slow response, elastic resistance, center-pull

### Navigation
- No visible navigation UI
- Swipe left/right for additional walls (if unlocked)
- Two-finger long press for settings

### Monetization
- Free tier: 1-2 complete objects, unlimited use, no ads
- Paid: $29.99 lifetime (primary), optional subscriptions
- Never interrupt interaction with paywalls

## Development Priorities

The current codebase is a fresh Xcode template. Implementation needs:

1. Tactile object views matching PRD specifications
2. Haptic feedback system with proper curves
3. Sensory wall grid layout (4-6 objects, no scrolling)
4. Gesture handlers for each object type
5. Settings UI (haptics intensity, sound toggle, reduce motion)
6. In-app purchase system
7. iOS widget support
