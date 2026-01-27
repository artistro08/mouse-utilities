; ==============================================================================
; Mouse Utilities Suite - Main Script
; ==============================================================================
; This is the master script that loads all mouse utility sub-scripts.
; It provides a unified panic hotkey to exit all scripts simultaneously.
;
; Author: artistro08
; Version: 1.0
; Requires: AutoHotkey v2.0+
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; Auto-Elevation to Admin
; ==============================================================================
; All sub-scripts require admin privileges to work in elevated windows.
; This ensures the entire suite runs with proper permissions.
if !A_IsAdmin {
    try {
        Run("*RunAs `"" A_ScriptFullPath "`"")
    } catch as err {
        MsgBox("Failed to run as administrator. The suite may not function correctly in elevated windows.`n`nError: " err.Message, "Admin Elevation Failed", "Icon!")
    }
    ExitApp
}

; ==============================================================================
; Configuration Validation
; ==============================================================================
; Verify that config.ini exists before loading sub-scripts.
ConfigFile := A_ScriptDir "\config.ini"

if !FileExist(ConfigFile) {
    MsgBox("ERROR: config.ini not found!`n`nExpected location: " ConfigFile "`n`nThe Mouse Utilities Suite requires a configuration file to function.`n`nPlease ensure config.ini exists in the same directory as MouseUtilities.ahk.", "Configuration Missing", "Icon! 16")
    ExitApp
}

; ==============================================================================
; Load Configuration from [Main] Section
; ==============================================================================
; Read the panic hotkey and tray icon settings from the unified config file.

; Panic Hotkey
try {
    MUS_PanicHotkey := IniRead(ConfigFile, "Main", "PanicHotkey", "F12")
} catch as err {
    MsgBox("Error reading PanicHotkey from config.ini.`n`nDefaulting to F12.`n`nError: " err.Message, "Config Read Warning", "Icon!")
    MUS_PanicHotkey := "F12"
}

; Tray Icon Visibility
try {
    MUS_ShowTrayIcon := IniRead(ConfigFile, "Main", "ShowTrayIcon", "1")
    if (MUS_ShowTrayIcon == "0") {
        A_IconHidden := true
    }
} catch as err {
    ; If read fails, show the tray icon by default
    MsgBox("Error reading ShowTrayIcon from config.ini.`n`nDefaulting to visible.`n`nError: " err.Message, "Config Read Warning", "Icon!")
}

; ==============================================================================
; Register Panic Hotkey
; ==============================================================================
; The panic hotkey immediately terminates all scripts in the suite.
; This provides a quick escape mechanism if any script misbehaves.
try {
    Hotkey(MUS_PanicHotkey, MUS_PanicHandler)
} catch as err {
    MsgBox("Failed to register panic hotkey: " MUS_PanicHotkey "`n`nError: " err.Message "`n`nThe suite will continue without a panic hotkey.", "Hotkey Registration Failed", "Icon!")
}

; Panic handler function - terminates the entire suite immediately.
MUS_PanicHandler(*) {
    ExitApp
}

; ==============================================================================
; Include Sub-Scripts
; ==============================================================================
; Load all mouse utility scripts.
; Each script is now refactored to use the unified config.ini file.
; The order of inclusion matters if scripts depend on each other.

; NOTE: All variable names in sub-scripts have been prefixed with their script
; name to prevent global namespace conflicts (e.g., ShowCursor_Mode, SmoothScrolling_active).

try {
    ; ShowCursor - PowerToys "Find My Mouse" integration
    #Include ShowCursor.ahk
} catch as err {
    MsgBox("Failed to load ShowCursor.ahk`n`nError: " err.Message, "Script Load Error", "Icon!")
}

try {
    ; Smooth-Trackball-Scrolling - Trackball smooth scrolling
    ; This consists of two files: the backend and the app
    #Include smooth_scrolling_app.ahk
} catch as err {
    MsgBox("Failed to load smooth_scrolling_app.ahk`n`nError: " err.Message, "Script Load Error", "Icon!")
}

try {
    ; SnippetAndRecord - Snipping Tool and Screen Recording
    #Include SnippetAndRecord.ahk
} catch as err {
    MsgBox("Failed to load SnippetAndRecord.ahk`n`nError: " err.Message, "Script Load Error", "Icon!")
}

; ==============================================================================
; Initialization Complete
; ==============================================================================
; Keep the script running
return
