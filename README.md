# Nudge

A tiny native macOS menu bar app that nudges the mouse cursor by 1 pixel on a
timer, alternating direction each tick so it drifts back and forth instead of
wandering off. It resets the system idle timer the same way real hardware
input does, which is enough to keep status-tracking apps (Slack, Teams, etc.)
from marking you away — no physical jiggler required.

Pure Swift, no dependencies.

## Features

- **Menu bar only** — no Dock icon, one status item with a Start/Stop toggle
- **Configurable interval** — 10s, 20s, 30s, 60s, 2m, 5m
- **Starts nudging on launch** — open the app and it's already running
- **Launch at Login** — toggle from the menu, backed by `SMAppService`
- **Lightweight** — a single `Timer` posting a synthetic `CGEvent`, nothing else running in the background

## Requirements

- macOS 13 Ventura or later
- Xcode command-line tools (for `swift build`)

## Installation

One-liner (clones to a temp dir, builds, installs, cleans up):

```bash
curl -fsSL https://raw.githubusercontent.com/smedleyi/Nudge/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone git@github.com:smedleyi/Nudge.git
cd Nudge
bash install.sh
```

Either way, `install.sh` builds a release binary, assembles `Nudge.app` in
`/Applications`, ad-hoc signs it, and launches it. Subsequent runs reinstall
over the existing copy.

## Usage

Click the menu bar icon to toggle nudging on/off, change the interval, or
enable Launch at Login. Quit from the same menu.

## How it works

Every `interval` seconds, `NudgeManager` reads the current cursor position,
posts a synthetic `CGEvent` of type `.mouseMoved` offset by ±1px on the X
axis via `CGEvent.post(tap: .cghidEventTap)`, and flips direction for next
time. Synthetic HID-level events reset `CGEventSourceSecondsSinceLastEventType`
just like real input, which is what status-tracking apps check.

Launch at Login registers the app itself as a login item via
`SMAppService.mainApp` (macOS 13+) — no separate helper bundle needed.

`AppIcon.icns` is generated from `GenerateIcon.swift` (draws a gradient
squircle with a tinted SF Symbol). Re-run with `swift GenerateIcon.swift &&
iconutil -c icns AppIcon.iconset -o AppIcon.icns` to tweak it.

## License

MIT
