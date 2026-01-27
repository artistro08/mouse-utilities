; ==============================================================================
; ShowCursor - PowerToys "Find My Mouse" Integration
; ==============================================================================
; This script integrates with Microsoft PowerToys "Find My Mouse" feature.
; It allows triggering "Find My Mouse" using a standard key without losing
; that key's original functionality.
;
; REFACTORED FOR MOUSE UTILITIES SUITE
; - Now uses unified config.ini with [ShowCursor] section
; - All variables prefixed with ShowCursor_ to prevent namespace conflicts
; - Admin elevation handled by MouseUtilities.ahk
; - No individual exit hotkey (use Main panic hotkey instead)
; ==============================================================================

#Requires AutoHotkey v2.0

; NOTE: NoTrayIcon and admin elevation are handled by MouseUtilities.ahk
; This script is designed to be #Include'd, not run standalone

; ==============================================================================
; Configuration Loading
; ==============================================================================
; Read settings from the unified config.ini file under the [ShowCursor] section.
; The config file is located in the same directory as MouseUtilities.ahk.

ShowCursor_ConfigFile := A_ScriptDir "\config.ini"

; Read all ShowCursor settings from the unified config
try {
    ShowCursor_Mode := IniRead(ShowCursor_ConfigFile, "ShowCursor", "Mode", "1")
    ShowCursor_TriggerKey := IniRead(ShowCursor_ConfigFile, "ShowCursor", "TriggerKey", "LControl")
    ShowCursor_TargetHotkey := IniRead(ShowCursor_ConfigFile, "ShowCursor", "TargetHotkey", "^!p")
    ShowCursor_HoldDuration := IniRead(ShowCursor_ConfigFile, "ShowCursor", "HoldDuration", "300")
} catch as err {
    ; If INI read fails, show error and use defaults
    MsgBox("Error reading ShowCursor settings from config.ini: " err.Message "`n`nUsing default values.", "ShowCursor Config Error", "Icon!")
    ShowCursor_Mode := "1"
    ShowCursor_TriggerKey := "LControl"
    ShowCursor_TargetHotkey := "^!p"
    ShowCursor_HoldDuration := "300"
}

; ==============================================================================
; Hotkey Registration
; ==============================================================================
; Register the trigger key dynamically based on configuration.
; Mode 1: Hold to Show (Conditional Send)
; Mode 2: Toggle Override (Blocks key)

if (ShowCursor_Mode == "1") {
    ; Mode 1: Hold to Show (Conditional Send)
    ; We do NOT prepend "~" so we can intercept the key and decide later whether to send it.
    Hotkey(ShowCursor_TriggerKey, ShowCursor_TriggerHandler)
} else if (ShowCursor_Mode == "2") {
    ; Mode 2: Toggle Override (Blocks key)
    ; We do NOT use "~", so AHK consumes the input. The system doesn't see the TriggerKey.
    Hotkey(ShowCursor_TriggerKey, ShowCursor_TriggerHandler)
} else {
    MsgBox("Invalid Mode selected in config.ini [ShowCursor] section. Please use 1 or 2.`n`nShowCursor script disabled.", "ShowCursor Config Error", "Icon!")
    return
}

; ==============================================================================
; Core Logic - Trigger Handler
; ==============================================================================
; This function handles the trigger key press/release logic.
; In Mode 1, it checks if the key was held or tapped and acts accordingly.
; In Mode 2, it immediately triggers the target hotkey.

ShowCursor_TriggerHandler(ThisHotkey) {
    ; Strip the modifier (~) if present to get the raw key name for KeyWait
    KeyName := StrReplace(ThisHotkey, "~", "")

    if (ShowCursor_Mode == "1") {
        ; Mode 1: Check if held
        TimeoutSec := ShowCursor_HoldDuration / 1000

        ; KeyWait returns 0 if timed out (held), 1 if released
        if (KeyWait(KeyName, "T" . TimeoutSec) == 0) {
            ; Held longer than duration -> Trigger Target
            Send(ShowCursor_TargetHotkey)
            KeyWait(KeyName) ; Wait for physical release
        } else {
            ; Released quickly -> Send original key
            Send("{" . KeyName . "}")
        }
    } else {
        ; Mode 2: Immediate trigger (Override)
        ; Since the hotkey blocked the original input, we just send the target immediately.
        Send(ShowCursor_TargetHotkey)
    }
}

; ==============================================================================
; ShowCursor Script Loaded
; ==============================================================================
; No return needed - this script is included by MouseUtilities.ahk
