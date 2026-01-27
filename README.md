# Mouse Utilities Suite

A unified collection of AutoHotkey v2 scripts designed to enhance mouse and trackball functionality on Windows.

## Overview

The Mouse Utilities Suite combines three powerful scripts into a single, modular system with unified configuration management. All scripts are managed through a master `MouseUtilities.ahk` script and configured via a single `config.ini` file.

## Features

### 1. ShowCursor - PowerToys "Find My Mouse" Integration

Integrates with Microsoft PowerToys "Find My Mouse" feature, allowing you to trigger cursor highlighting using a standard key without losing that key's original functionality.

**Modes:**
- **Mode 1 (Smart Hold):** Use a key normally (e.g., Back button in browser), but hold it down to trigger "Find My Mouse"
- **Mode 2 (Dedicated):** Completely override a key to serve solely as the "Find My Mouse" trigger

### 2. Smooth-Trackball-Scrolling - Trackball Smooth Scrolling

Transform your trackball into a smooth scroll wheel! This script provides continuous, smooth scrolling with configurable axis snapping, acceleration curves, and multiple control modes.

**Key Features:**
- Multiple control modes (toggle, momentary, tap/hold, two-key)
- Axis snapping for precise horizontal/vertical scrolling
- Acceleration curve emulation
- Cursor customization while scrolling
- Extensive configuration options

### 3. SnippetAndRecord - Snipping Tool & Screen Recording

Combines Windows Snipping Tool and Screen Recording into a single hotkey using tap vs. hold logic.

**Actions:**
- **Tap** (short press): Opens Snipping Tool (`Win+Shift+S`)
- **Hold** (long press): Starts Screen Recording (`Win+Shift+R`)

## Prerequisites

### For Compiled Executable (Recommended)
- **Microsoft PowerToys** (optional, for ShowCursor): [Download here](https://github.com/microsoft/PowerToys)

### For Running from Source
1. **AutoHotkey v2.0+**: [Download here](https://www.autohotkey.com/)
2. **Microsoft PowerToys** (optional, for ShowCursor): [Download here](https://github.com/microsoft/PowerToys)

## Installation

### Option 1: Using Compiled Executable (No AutoHotkey Required)

1. Download the latest release from the [Releases](../../releases) page
2. Extract the files to a folder of your choice
3. Ensure `config.ini` is in the same directory as `MouseUtilities.exe`
4. Double-click `MouseUtilities.exe` to run the suite
5. The script will automatically request administrator privileges (required for elevated windows)

### Option 2: Running from Source

1. Download or clone this repository
2. Install AutoHotkey v2.0+ if not already installed
3. Ensure `config.ini` exists in the same directory as `MouseUtilities.ahk`
4. Double-click `MouseUtilities.ahk` to run the suite
5. The script will automatically request administrator privileges (required for elevated windows)

## Configuration

All scripts are configured through a single `config.ini` file. Each script has its own section to prevent variable conflicts.

### [Main] - Master Script Settings

```ini
[Main]
; Panic hotkey to immediately exit all scripts
; Examples: F12, ^!Esc (Ctrl+Alt+Esc), #+q (Win+Shift+Q)
PanicHotkey=F12

; Show or hide the system tray icon for the entire suite
; Set to 1 (Visible) or 0 (Hidden)
ShowTrayIcon=1
```

### [ShowCursor] - PowerToys Integration

```ini
[ShowCursor]
; Mode 1: Hold to Show, Mode 2: Toggle Override
Mode=1

; Trigger key (LControl, RControl, XButton1, XButton2, etc.)
TriggerKey=XButton1

; Target hotkey sent to PowerToys (match your PowerToys settings)
TargetHotkey=#+F

; Hold duration in milliseconds (Mode 1 only)
HoldDuration=200
```

### [SmoothScrolling] - Trackball Scrolling

```ini
[SmoothScrolling]
; Hotkeys
hotkey1=XButton2
hotkey2=MButton

; Control mode (see documentation for all modes)
mode=ONE_KEY_HOLD_MOMENTARY

; Hold duration for tap/hold modes
holdDuration=200

; Texture settings
sensitivity=12
refreshInterval=10
smoothingWindowMaxSize=1

; Axis snapping
snapOnByDefault=true
snapRatio=1.5
snapThreshold=10
disableSnapFor=Affinity

; Acceleration
accelerationOn=true
accelerationBlend=0.872116
accelerationScale=500

; Modifier emulation
addShift=false
addCtrl=false
addAlt=false

; Cursor icon (32646 = Size All, 0 = disable)
cursorIcon=32646

; Behavior
blockLeftClick=false
```

**Available Modes:**
- `ON_OFF`: Separate keys for on/off
- `ONE_KEY_TOGGLE`: Toggle on each press
- `ONE_KEY_MOMENTARY`: Active while held
- `ONE_KEY_TAP_TOGGLE`: Tap to toggle, hold for original function
- `ONE_KEY_HOLD_TOGGLE`: Hold to toggle, tap for original function
- `ONE_KEY_HOLD_MOMENTARY`: Hold to activate, tap for original function
- `TWO_KEY_TAP_TOGGLE`: Tap both keys simultaneously to toggle

### [SnippetAndRecord] - Snipping & Recording

```ini
[SnippetAndRecord]
; Trigger key
TriggerKey=^+#F10

; Hold duration to distinguish tap from hold
HoldDuration=200
```

## Key Bindings

The suite uses AutoHotkey's key notation. Here are some common examples:

| Key Notation | Description |
| :--- | :--- |
| `XButton1` | Mouse Button 4 (Back) |
| `XButton2` | Mouse Button 5 (Forward) |
| `MButton` | Middle Mouse Button |
| `LControl` / `RControl` | Left/Right Control |
| `F1` - `F12` | Function Keys |
| `^` | Control modifier |
| `!` | Alt modifier |
| `+` | Shift modifier |
| `#` | Win modifier |
| `^!p` | Ctrl+Alt+P |
| `#+F` | Win+Shift+F |

## Usage

### Starting the Suite

1. Double-click `MouseUtilities.exe` (compiled version) or `MouseUtilities.ahk` (source version)
2. Accept the UAC prompt for administrator privileges

### Emergency Exit (Panic Hotkey)

Press the configured panic hotkey (default: `F12`) to immediately terminate all scripts.

### Stopping the Suite

- Press the panic hotkey, OR
- Open Task Manager and end the AutoHotkey process, OR
- Right-click the AutoHotkey tray icon and select "Exit"

## Troubleshooting

### Scripts don't work in elevated windows

The suite automatically requests administrator privileges. If you denied the UAC prompt, restart the script and accept it.

### Config changes aren't taking effect

After editing `config.ini`, you must restart the suite (either `MouseUtilities.exe` or `MouseUtilities.ahk`) for changes to apply.

### Conflicts with other scripts

All variables in the suite are prefixed with script-specific identifiers (e.g., `ShowCursor_`, `SS_`, `SAR_`) to prevent namespace conflicts. If you're including these scripts in other projects, ensure you maintain these prefixes.

### Individual script panic buttons

Some scripts (like Smooth-Trackball-Scrolling) support their own panic buttons for stopping just that script without exiting the entire suite. However, the Main panic hotkey will always terminate everything.

## Architecture

### File Structure

```
MouseUtilities/
├── .gitignore                    # Git ignore file
├── MouseUtilities.ahk            # Master script (entry point)
├── config.ini                    # Unified configuration
├── ShowCursor.ahk                # PowerToys integration
├── smooth_scrolling_backend.ahk  # Scrolling engine
├── smooth_scrolling_app.ahk      # Scrolling frontend
├── SnippetAndRecord.ahk          # Snipping & recording
└── README.md                     # This file
```

### Namespace Management

To prevent variable conflicts in the global namespace, each script uses prefixed variables:

- **ShowCursor:** `ShowCursor_`
- **Smooth Scrolling:** `SS_` (backend), `SSApp_` (app)
- **SnippetAndRecord:** `SAR_`
- **Main:** `MUS_`

### Admin Elevation

All scripts require administrator privileges to function in elevated windows (Task Manager, Registry Editor, etc.). The Main script handles elevation automatically - individual sub-scripts no longer request elevation separately.

### Include Architecture

The suite uses AutoHotkey's `#Include` directive. `MouseUtilities.ahk` includes all sub-scripts, which run in a shared global namespace. This is why variable prefixing is critical.

## Credits & Acknowledgments

### Original Authors

- **ShowCursor**: Developed by artistro08
- **Smooth-Trackball-Scrolling**: Originally developed by [Morgan Sun (morgannewellsun)](https://github.com/morgannewellsun). Inspired by [TrackballScroll](https://github.com/Seelge/TrackballScroll) by Seelge. Additional contributions by Devin Green (UWP app support, stop key, cursor handling, elevation). Major thanks to community contributors who provided feedback and testing.
- **SnippetAndRecord**: Developed by artistro08

### Suite Integration

- **Mouse Utilities Suite Integration**: artistro08 (2025)
- Refactored all scripts to use unified configuration
- Implemented namespace conflict prevention
- Created master script architecture

### Special Thanks

- The AutoHotkey community for extensive documentation and examples
- Microsoft PowerToys team for the "Find My Mouse" feature
- All users who provided feedback and testing for the original scripts
- Seelge and contributors to the TrackballScroll project

## Version History

### v1.0 (2025)
- Initial release of unified Mouse Utilities Suite
- Consolidated 3 separate scripts into modular architecture
- Implemented unified `config.ini` configuration
- Added master panic hotkey functionality
- Refactored all scripts to prevent namespace conflicts
- Comprehensive documentation

## License

This suite incorporates multiple scripts, each with their own licensing:

- **Smooth-Trackball-Scrolling**: See original repository for license
- **Other scripts**: Created by artistro08

Please respect the original licenses when redistributing or modifying.

## Support & Contributing

For issues, suggestions, or contributions:

1. Check the Troubleshooting section
2. Review the configuration documentation
3. Test with default `config.ini` settings
4. Report issues with specific details about your configuration

## Future Enhancements

Potential improvements for future versions:

- GUI configuration editor
- Per-application configuration profiles
- Additional mouse utility scripts
- Hotkey conflict detection
- Configuration validation tool
- Backup/restore config functionality

---

**Note**: This suite is designed for productivity and accessibility. Always ensure hotkeys don't conflict with critical system functions or applications you use frequently.
