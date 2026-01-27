; ==============================================================================
; SnippetAndRecord - Snipping Tool & Screen Recording Integration
; ==============================================================================
; Implements configurable Tap vs. Hold logic for Windows Snipping Tool
; and Screen Recording.
;
; - Tap (short press): Opens Snipping Tool (Win+Shift+S)
; - Hold (long press): Starts Screen Recording (Win+Shift+R)
;
; REFACTORED FOR MOUSE UTILITIES SUITE
; - Config reading updated to use unified config.ini [SnippetAndRecord] section
; - All variables prefixed with SAR_ to prevent namespace conflicts
; - Admin elevation handled by MouseUtilities.ahk
; - No individual exit hotkey (use Main panic hotkey instead)
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; NOTE: Admin elevation is handled by MouseUtilities.ahk
; This script is designed to be #Include'd, not run standalone

; ==============================================================================
; Configuration Management
; ==============================================================================
; Read settings from the unified config.ini file under the [SnippetAndRecord] section.

SAR_ConfigPath := A_ScriptDir "\config.ini"
SAR_DefaultTriggerKey := "XButton2"
SAR_DefaultHoldDuration := 300

; Read settings from config.ini [SnippetAndRecord] section
SAR_TriggerKey := IniRead(SAR_ConfigPath, "SnippetAndRecord", "TriggerKey", SAR_DefaultTriggerKey)
SAR_HoldDuration := IniRead(SAR_ConfigPath, "SnippetAndRecord", "HoldDuration", SAR_DefaultHoldDuration)

; Clean up and validate settings
SAR_TriggerKey := Trim(SAR_TriggerKey)
if not IsNumber(SAR_HoldDuration)
    SAR_HoldDuration := SAR_DefaultHoldDuration

; ==============================================================================
; Hotkey Setup & Logic
; ==============================================================================
; Define the action function that handles tap vs. hold logic.

SAR_TriggerAction(ThisHotkey) {
    ; Remove common hotkey prefixes and modifiers ($, *, ~, ^, !, +, #, <, >) to get the raw KeyName.
    ; KeyWait only accepts a single key name (e.g., "Space") and does not support modifiers (e.g., "^Space").
    ; This ensures that complex shortcuts work, while simple keys like "XButton2" remain unaffected.
    KeyName := RegExReplace(ThisHotkey, "[~*$^!+#<>]", "")

    ; Threshold for "Hold" in milliseconds
    HoldThreshold := SAR_HoldDuration

    ; Wait for the key to be released or for the timeout (HoldThreshold) to occur.
    ; 'T' option specifies the timeout in seconds.
    if KeyWait(KeyName, "T" HoldThreshold / 1000) {
        ; --- TAP ACTION ---
        ; Key was released BEFORE the timeout.
        Send "#+s" ; Win+Shift+S (Snipping Tool)
    } else {
        ; --- HOLD ACTION ---
        ; Timeout occurred, key is still being held.
        Send "#+r" ; Win+Shift+R (Screen Recording)

        ; Wait for the key to be released to prevent repeating the action
        KeyWait KeyName
    }
}

; ==============================================================================
; Register Hotkey
; ==============================================================================
; Register the hotkey dynamically based on configuration.

if (SAR_TriggerKey != "") {
    try {
        ; Use the hook ($) prefix to prevent the script from triggering itself
        ; and to ensure better compatibility with games/apps.
        Hotkey "$" SAR_TriggerKey, SAR_TriggerAction
    } catch as err {
        MsgBox "Invalid TriggerKey specified in config.ini [SnippetAndRecord] section: '" SAR_TriggerKey "'.`n`nError: " err.Message, "SnippetAndRecord Config Error", "Icon!"
    }
} else {
    MsgBox "TriggerKey is empty in config.ini [SnippetAndRecord] section.", "SnippetAndRecord Config Error", "Icon!"
}

; ==============================================================================
; SnippetAndRecord Script Loaded
; ==============================================================================
; No return needed - this script is included by MouseUtilities.ahk
