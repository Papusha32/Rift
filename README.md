# Rift

A minimal macOS menu bar timer app. Set a duration, start the countdown, and get a gentle sound notification when time's up.

## Install

Paste this into Terminal and press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Papusha32/Rift/main/install.sh)"
```

That's it — the installer downloads the latest release, places Rift in `/Applications`, and launches it. Look for the timer pill in your menu bar.

Rift auto-updates itself from now on: when a new version ships, you'll see a banner inside the popover with a one-click update button.

> **Prefer manual install?** Download the latest `Rift.dmg` from [Releases](https://github.com/Papusha32/Rift/releases), open it, drag `Rift.app` into `Applications`. On first launch, right-click the app → **Open** → **Open** (needed once because the app isn't signed with a paid Apple Developer certificate).

## Features

- **Menu bar pill** — always visible countdown in the macOS menu bar
- **Tick ruler** — drag to set time (1–120 min) with haptic feedback, or type any duration manually (up to 99h 59m)
- **3 customizable presets** — quick-access buttons with user-defined values, persisted across restarts
- **Gentle alarm sounds** — curated system sounds (Glass, Breeze, Crystal, etc.) with adjustable volume and auto-mute
- **Floating timer** — optional always-on-top overlay during countdown
- **Launch at login** — start automatically with macOS
- **Auto-updates** — in-app banner when a new version is released on GitHub
- **Persisted state** — last used time and presets survive app restarts

## Requirements

- macOS 14.0+

## Build from source

Requires Xcode 15+ and Swift 5.9+.

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
