# MouseUtilities

A unified AutoHotkey v2 script combining three mouse/keyboard utilities into one.

## What It Does

- **ShowCursor** - Find your cursor with PowerToys integration (tap vs hold)
- **SnippetAndRecord** - Take screenshots or record screen (tap vs hold)
- **SmoothTrackball** - Smooth scrolling for trackball mice

## Requirements

- Windows 10/11
- [AutoHotkey v2.0+](https://www.autohotkey.com/)
- Admin privileges (auto-requested)

## Installation

1. Download `MouseUtilities.ahk` and `settings.ini`
2. Double-click `MouseUtilities.ahk`
3. Accept the admin prompt
4. Done!

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

**Hotkeys not working:** Make sure you accepted the admin prompt

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

## License

MIT - See individual project repositories for details