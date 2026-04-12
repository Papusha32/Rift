# Rift

A minimal macOS menu bar timer app. Set a duration, start the countdown, and get a gentle sound notification when time's up.

## Features

- **Menu bar pill** — always visible countdown in the macOS menu bar
- **Tick ruler** — drag to set time (1–120 min) with haptic feedback, or type any duration manually (up to 99h 59m)
- **3 customizable presets** — quick-access buttons with user-defined values, persisted across restarts
- **Gentle alarm sounds** — curated system sounds (Glass, Breeze, Crystal, etc.) with adjustable volume and auto-mute
- **Floating timer** — optional always-on-top overlay during countdown
- **Launch at login** — start automatically with macOS
- **Persisted state** — last used time and presets survive app restarts

## Requirements

- macOS 14.0+
- Xcode 15+
- Swift 5.9+

## Setup

1. Clone the repo:
   ```bash
   git clone git@github.com:Papusha32/Rift.git
   ```
2. Open `Rift.xcodeproj` in Xcode
3. Set your **Development Team** in Signing & Capabilities
4. Build and run (Cmd+R)

## Project Structure

```
Rift/
├── RiftApp.swift                 # App entry point (@main)
├── MenuBarController.swift       # Menu bar pill, popover, status item
├── TimerManager.swift            # Timer logic, state machine
├── TimerPopoverView.swift        # Main popover UI (ruler, presets, input)
├── SettingsView.swift            # Settings panel (presets, sound, options)
├── FloatingWindowController.swift # Floating overlay window
├── FloatingDisplayView.swift     # Floating overlay UI
├── SoundManager.swift            # Alarm sound playback
├── PresetModel.swift             # Preset data model
├── Info.plist                    # App config (LSUIElement for menu bar)
├── Rift.entitlements             # Sandbox/security entitlements
└── Assets.xcassets/              # App icon (16–1024px)
```

## Notes

- **Bundle ID** is `com.focusdrop.app` (legacy name, kept for backward compatibility with existing users' settings and permissions)
- No external dependencies — pure SwiftUI + AppKit
- The app runs as a menu bar agent (`LSUIElement = true`) — no Dock icon
