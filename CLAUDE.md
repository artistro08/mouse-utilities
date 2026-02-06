# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MouseUtilities is a unified AutoHotkey v2 script combining seven mouse/keyboard utilities:
- **ShowCursor (SC_)** - Triggers PowerToys "Find My Mouse" on key hold
- **SnippetAndRecord (SAR_)** - Tap for screenshot (Win+Shift+S), hold for screen record (Win+Shift+R)
- **UndoRedo (UR_)** - Maps mouse buttons to undo/redo shortcuts for configured apps
- **DraggingUtility (DU_)** - Context-aware mouse button behavior for FancyZones window snapping
- **SmoothTrackball (STS_)** - Converts trackball movement to smooth scroll wheel input using a low-level mouse hook
- **CapsLockShift (CLS_)** - Remaps CapsLock to function as Shift key
- **VolumeControl (VC_)** - Maps custom hotkeys to volume up/down

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
All code lives in `MouseUtilities.ahk`. Configuration is externalized to `settings.ini`, which can be located in the user config directory or script directory (see Configuration File Location below). A default config is auto-created if missing.

### Prefix Convention
Each utility uses a distinct prefix for its functions and global variables:
- `SC_` - ShowCursor functions
- `SAR_` - SnippetAndRecord functions
- `UR_` - UndoRedo functions
- `DU_` - DraggingUtility functions
- `STS_` - SmoothTrackball functions (most complex, ~600 lines)
- `CLS_` - CapsLockShift functions
- `VC_` - VolumeControl functions

### SmoothTrackball Internals
The STS module uses a Windows low-level mouse hook (`SetWindowsHookEx` with `WH_MOUSE_LL`) to intercept mouse movement when scrolling mode is active. Key components:

- **Mouse Hook** (`STS_MouseHook`): Captures mouse deltas and accumulates them
- **Timers** (`STS_TimerScroll`, `STS_TimerWheel`): Process accumulated movement at `refreshInterval` and send scroll messages
- **Smoothing Window**: Ring buffer for movement smoothing (`STS_smoothingWindow*` variables)
- **Axis Snapping**: Locks scrolling to horizontal or vertical axis based on initial direction
- **Seven Hotkey Modes**: Different activation behaviors (toggle, momentary, tap-toggle, etc.)

### Configuration File Location
The script looks for `settings.ini` in the following order:
1. **User config directory**: `%USERPROFILE%\.config\mouse-utilities\settings.ini`
2. **Script directory**: Same folder as the running script/exe

If neither exists, a default config is created in the script directory. This allows users to opt-in to the user directory by manually moving their config, or by using the deploy script which places it there.

| Scenario | Config Location Used |
|----------|---------------------|
| User config exists | `%USERPROFILE%\.config\mouse-utilities\settings.ini` |
| Only local config exists | Script directory `settings.ini` |
| Neither exists | Creates default in script directory |
| After running deploy script | User config directory |

### Configuration Loading
Settings are read via `IniRead()` at startup. Each section maps to a utility:
- `[ShowCursor_Settings]`
- `[SnippetAndRecord_Settings]`
- `[UndoRedo_Settings]`
- `[DraggingUtility_Settings]`
- `[CapsLockShift_Settings]`
- `[VolumeControl_Settings]`
- `[Trackball_*]` - Multiple sections for SmoothTrackball

### DraggingUtility Settings
The DraggingUtility is designed for use with PowerToys FancyZones. It detects when you're dragging a window and sends a different mouse button depending on the drag state. This allows you to map your forward mouse button (XButton2) to the trigger, which will:
- Send middle-click (MButton) when dragging a window - useful for FancyZones zone selection
- Send forward button (XButton2) normally when not dragging

Configuration in `[DraggingUtility_Settings]`:
- `TriggerKey` - The hotkey that triggers the utility (default: `^F12`, but map to `XButton2` for FancyZones use)
- `DragAction` - Mouse button to send when dragging a window (default: `MButton`)
- `NonDragAction` - Mouse button to send when not dragging (default: `XButton2`)

To use with FancyZones, set `TriggerKey=XButton2` in settings.ini. This makes your forward mouse button act as middle-click only when dragging windows, enabling FancyZones zone snapping while preserving normal forward button behavior otherwise.

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
3. Test hotkey conflicts - all seven utilities share the keyboard/mouse input space
