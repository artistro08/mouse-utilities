# MouseUtilities

A unified AutoHotkey v2 script combining three mouse/keyboard utilities into one.

## What It Does

- **ShowCursor** - Find your cursor with PowerToys integration (tap vs hold)
- **SnippetAndRecord** - Take screenshots or record screen (tap vs hold)
- **SmoothTrackball** - Smooth scrolling for trackball mice

## Requirements

- Windows 10/11
- [AutoHotkey v2.0+](https://www.autohotkey.com/)

## Installation

### Quick Start (Basic)

1. Download `MouseUtilities.ahk` and `settings.ini`
2. Double-click `MouseUtilities.ahk`
3. Done!

**Note:** For full PowerToys integration, use the UIAccess build below.

### Advanced Installation (UIAccess Enabled) ⭐ RECOMMENDED

For full PowerToys integration and elevated window support, enable UIAccess:

1. Install [AutoHotkey v2.0+](https://www.autohotkey.com/)
2. Open PowerShell as Administrator
3. Navigate to the `build` folder
4. Run `.\BUILD-ALL.ps1`
5. Launch from `C:\Program Files\MouseUtilities\`

**Why UIAccess?** Allows MouseUtilities to work with elevated windows and PowerToys running as admin - **without requiring the app itself to run as administrator**.

📖 **See [`build/README.md`](build/README.md) for detailed UIAccess setup instructions.**

## Default Hotkeys

- **XButton1** (Back Mouse) - ShowCursor
- **Ctrl+Shift+Win+F10** - SnippetAndRecord
- **XButton2** (Forward Mouse) - SmoothTrackball
- **F3** - Exit script

## Configuration

All settings are in `settings.ini`. The file has detailed comments for each option.

### Quick Settings

**Change ShowCursor key:**
```ini
[ShowCursor_Settings]
TriggerKey=XButton1
```

**Change Screenshot/Record key:**
```ini
[SnippetAndRecord_Settings]
TriggerKey=^+#F10
```

**Change Smooth Scroll key:**
```ini
[Trackball_Hotkeys]
hotkey1=XButton2
```

### Common Key Names

```
Mouse:      XButton1, XButton2, MButton
Keys:       F1-F12, Space, Enter
Modifiers:  LControl, RControl, LShift, RShift
Combos:     ^Space (Ctrl+Space), !z (Alt+Z), #+F10 (Win+Shift+F10)
```

### Scroll Settings

**Reverse scroll direction:**
```ini
[Trackball_Texture]
sensitivity=-1
```

**Adjust scroll speed:**
```ini
[Trackball_Texture]
sensitivity=2.5
```

**Disable axis snapping:**
```ini
[Trackball_AxisSnapping]
snapOnByDefault=false
```

## Troubleshooting

**Script won't start:** Install AutoHotkey v2.0+

**ShowCursor doesn't work with elevated PowerToys:** Use the UIAccess build (see Advanced Installation above)

**ShowCursor doesn't work:** Check that PowerToys is running and `TargetHotkey` matches your PowerToys settings

**Scrolling feels laggy:** Increase `refreshInterval` to 16 or 20 in settings.ini

**Need to exit:** Press F3 or kill "AutoHotkey" in Task Manager

## Original Projects

This combines three scripts:

- [show-cursor](https://github.com/artistro08/show-cursor) by artistro08
- [snippet-and-record](https://github.com/artistro08/snippet-and-record) by artistro08
- [Smooth-Trackball-Scrolling](https://github.com/eynsai/Smooth-Trackball-Scrolling) by eynsai

## Contributors

- **eynsai** - Original Smooth-Trackball-Scrolling author
- **artistro08** - ShowCursor, SnippetAndRecord, and unified integration

## UIAccess Build System

This project includes a complete build system for enabling UIAccess (required for PowerToys integration):

### Build Scripts (in `build/` folder)

- **`BUILD-ALL.ps1`** - One-click build (certificate → compile → sign → deploy)
- **`1-CreateCertificate.ps1`** - Creates self-signed code signing certificate
- **`2-CompileAndSign.ps1`** - Compiles AHK and signs with UIAccess manifest
- **`3-Deploy.ps1`** - Deploys to Program Files (trusted location)
- **`BUILD.bat`** - Double-click launcher for easy access

### Quick Build

```powershell
cd build
.\BUILD-ALL.ps1
```

### Documentation

- **[`build/README.md`](build/README.md)** - Complete UIAccess documentation
- **[`build/MouseUtilities.manifest`](build/MouseUtilities.manifest)** - UIAccess manifest file

### What UIAccess Enables

✅ Works with elevated/administrator windows **without running as admin**  
✅ PowerToys integration (ShowCursor feature) even when PowerToys is elevated  
✅ Bypasses UIPI restrictions while running as normal user  
✅ Professional code-signed executable  
✅ No UAC prompts - runs as standard user with elevated access  

### Without UIAccess

The script runs fine from the `.ahk` file for basic features, but:
- ❌ Won't work with elevated PowerToys (ShowCursor won't trigger)
- ❌ Limited functionality with admin windows
- ❌ Cannot send input to elevated applications

## Updating the Script

After modifying `MouseUtilities.ahk`:

```powershell
# Rebuild and redeploy
cd build
.\2-CompileAndSign.ps1
.\3-Deploy.ps1
```

The certificate (Step 1) only needs to be created once (valid for 5 years).

## License

MIT - See individual project repositories for details