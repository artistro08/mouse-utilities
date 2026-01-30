# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MouseUtilities is a unified AutoHotkey v2 script combining three mouse/keyboard utilities:
- **ShowCursor (SC_)** - Triggers PowerToys "Find My Mouse" on key hold
- **SnippetAndRecord (SAR_)** - Tap for screenshot (Win+Shift+S), hold for screen record (Win+Shift+R)
- **SmoothTrackball (STS_)** - Converts trackball movement to smooth scroll wheel input using a low-level mouse hook

## Running the Script

```
# Run directly (requires AutoHotkey v2.0+ installed)
MouseUtilities.ahk

# Or use the compiled executable
MouseUtilities.exe
```

The script auto-elevates to admin privileges on startup.

## Architecture

### Single-File Design
All code lives in `MouseUtilities.ahk`. Configuration is externalized to `settings.ini` (auto-created with defaults if missing).

### Prefix Convention
Each utility uses a distinct prefix for its functions and global variables:
- `SC_` - ShowCursor functions
- `SAR_` - SnippetAndRecord functions
- `STS_` - SmoothTrackball functions (most complex, ~600 lines)

### SmoothTrackball Internals
The STS module uses a Windows low-level mouse hook (`SetWindowsHookEx` with `WH_MOUSE_LL`) to intercept mouse movement when scrolling mode is active. Key components:

- **Mouse Hook** (`STS_MouseHook`): Captures mouse deltas and accumulates them
- **Timers** (`STS_TimerScroll`, `STS_TimerWheel`): Process accumulated movement at `refreshInterval` and send scroll messages
- **Smoothing Window**: Ring buffer for movement smoothing (`STS_smoothingWindow*` variables)
- **Axis Snapping**: Locks scrolling to horizontal or vertical axis based on initial direction
- **Seven Hotkey Modes**: Different activation behaviors (toggle, momentary, tap-toggle, etc.)

### Configuration Loading
Settings are read via `IniRead()` at startup. Each section maps to a utility:
- `[ShowCursor_Settings]`
- `[SnippetAndRecord_Settings]`
- `[Trackball_*]` - Multiple sections for SmoothTrackball

### Hotkey Registration
Hotkeys are registered dynamically based on config. The `$` prefix prevents self-triggering. STS mode-specific handlers are registered based on the configured `mode` value.

## Key Behaviors

- **Tap vs Hold Detection**: Used by ShowCursor and SnippetAndRecord. `KeyWait` with timeout determines if user tapped or held the key.
- **Scroll Message Targeting**: STS identifies the window/control under cursor at activation time and posts `WM_MOUSEWHEEL` (0x20A) / `WM_MOUSEHWHEEL` (0x20E) messages directly. Special handling for XAML/UWP windows uses `mouse_event` instead.
- **Cursor Change**: During STS scroll mode, system cursors are replaced with a configurable icon and restored on deactivation.

## Modifying the Code

When adding features or fixing bugs:
1. Use the appropriate prefix for the utility being modified
2. Global variables should be declared at the top of the utility's section
3. Test hotkey conflicts - all three utilities share the keyboard/mouse input space
