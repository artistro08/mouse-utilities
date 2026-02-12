; ==============================================================================
; MouseUtilities.ahk
; ==============================================================================
; A unified AutoHotkey v2 script combining eight utilities:
; 1. ShowCursor - Find your cursor with PowerToys integration
; 2. SnippetAndRecord - Tap for screenshot, hold for recording
; 3. UndoRedo - Mouse button undo/redo for configured apps
; 4. DraggingUtility - Context-aware mouse button behavior when dragging windows
; 5. SmoothTrackball - Smooth scrolling with trackball
; 6. CapsLockShift - Remap CapsLock to function as Shift key
; 7. VolumeControl - Map custom hotkeys to volume up/down
; 8. WinKeyOverride - Override Win key tap to send custom key
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
Persistent
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)



; ==============================================================================
; GLOBAL CONFIGURATION
; ==============================================================================
; Config file resolution: user directory takes priority, falls back to script directory
global UserConfigDir := EnvGet("USERPROFILE") "\.config\mouse-utilities"
global UserConfigFile := UserConfigDir "\settings.ini"
global LocalConfigFile := A_ScriptDir "\settings.ini"

; Use user config if it exists, otherwise use local config
global ConfigFile := FileExist(UserConfigFile) ? UserConfigFile : LocalConfigFile

; Create default config if it doesn't exist
if !FileExist(ConfigFile) {
    SC_CreateDefaultConfig()
}

; ==============================================================================
; SHOW CURSOR - INITIALIZATION
; ==============================================================================
try {
    global SC_Mode := IniRead(ConfigFile, "ShowCursor_Settings", "Mode", "1")
    global SC_TriggerKey := IniRead(ConfigFile, "ShowCursor_Settings", "TriggerKey", "LControl")
    global SC_TargetHotkey := IniRead(ConfigFile, "ShowCursor_Settings", "TargetHotkey", "^!p")
    global SC_HoldDuration := IniRead(ConfigFile, "ShowCursor_Settings", "HoldDuration", "300")
} catch as err {
    MsgBox("Error reading ShowCursor settings from config: " err.Message)
}

; ==============================================================================
; SNIPPET AND RECORD - INITIALIZATION
; ==============================================================================
try {
    global SAR_TriggerKey := IniRead(ConfigFile, "SnippetAndRecord_Settings", "TriggerKey", "^+#F10")
    global SAR_HoldDuration := IniRead(ConfigFile, "SnippetAndRecord_Settings", "HoldDuration", "300")
    global SAR_ShowTrayIcon := IniRead(ConfigFile, "SnippetAndRecord_Settings", "ShowTrayIcon", "0")
} catch as err {
    MsgBox("Error reading SnippetAndRecord settings from config: " err.Message)
}

; Handle tray icon visibility
if (SAR_ShowTrayIcon != "0") {
    A_IconHidden := false
}

; ==============================================================================
; UNDO REDO - INITIALIZATION
; ==============================================================================
try {
    global UR_Apps := IniRead(ConfigFile, "UndoRedo_Settings", "Apps", "")
    global UR_ModifierPassthrough := IniRead(ConfigFile, "UndoRedo_Settings", "ModifierPassthrough", "")
    global UR_AlternativeRedoShortcut := IniRead(ConfigFile, "UndoRedo_Settings", "AlternativeRedoShortcut", "")
    global UR_AdditionalUndoKey := IniRead(ConfigFile, "UndoRedo_Settings", "AdditionalUndoKey", "")
    global UR_AdditionalRedoKey := IniRead(ConfigFile, "UndoRedo_Settings", "AdditionalRedoKey", "")
} catch as err {
    global UR_Apps := ""
    global UR_ModifierPassthrough := ""
    global UR_AlternativeRedoShortcut := ""
    global UR_AdditionalUndoKey := ""
    global UR_AdditionalRedoKey := ""
}

; ==============================================================================
; DRAGGING UTILITY - INITIALIZATION
; ==============================================================================
global DU_TriggerKey := IniRead(ConfigFile, "DraggingUtility_Settings", "TriggerKey", "^F12")
global DU_DragAction := IniRead(ConfigFile, "DraggingUtility_Settings", "DragAction", "MButton")
global DU_NonDragAction := IniRead(ConfigFile, "DraggingUtility_Settings", "NonDragAction", "XButton2")
global DU_IsDragging := false

; Set up drag state detection hook
DU_SetupDragHook()

DU_SetupDragHook() {
    static EVENT_SYSTEM_MOVESIZESTART := 0x000A
    static EVENT_SYSTEM_MOVESIZEEND := 0x000B

    callback := CallbackCreate(DU_DragStateCallback, "F", 7)
    DllCall("SetWinEventHook", "UInt", EVENT_SYSTEM_MOVESIZESTART, "UInt", EVENT_SYSTEM_MOVESIZEEND,
        "Ptr", 0, "Ptr", callback, "UInt", 0, "UInt", 0, "UInt", 0x0)
}

DU_DragStateCallback(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global DU_IsDragging
    if (event = 0x000A)  ; EVENT_SYSTEM_MOVESIZESTART
        DU_IsDragging := true
    else if (event = 0x000B)  ; EVENT_SYSTEM_MOVESIZEEND
        DU_IsDragging := false
}

; ==============================================================================
; CAPSLOCK SHIFT - INITIALIZATION
; ==============================================================================
try {
    global CLS_Enabled := IniRead(ConfigFile, "CapsLockShift_Settings", "Enabled", "0")
} catch as err {
    global CLS_Enabled := "0"
}

; ==============================================================================
; VOLUME CONTROL - INITIALIZATION
; ==============================================================================
try {
    global VC_VolumeUpKey := IniRead(ConfigFile, "VolumeControl_Settings", "VolumeUpKey", "")
    global VC_VolumeDownKey := IniRead(ConfigFile, "VolumeControl_Settings", "VolumeDownKey", "")
} catch as err {
    global VC_VolumeUpKey := ""
    global VC_VolumeDownKey := ""
}

; ==============================================================================
; WIN KEY OVERRIDE - INITIALIZATION
; ==============================================================================
try {
    global WKO_Enabled := IniRead(ConfigFile, "WinKeyOverride_Settings", "Enabled", "0")
    global WKO_TapAction := IniRead(ConfigFile, "WinKeyOverride_Settings", "TapAction", "^{Space}")
} catch as err {
    global WKO_Enabled := "0"
    global WKO_TapAction := "^{Space}"
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - BACKEND INITIALIZATION
; ==============================================================================

; Core state variables
global STS_active := false
global STS_cursorX := 0
global STS_cursorY := 0
global STS_accumulatorX := 0
global STS_accumulatorY := 0
global STS_accumulatorWheel := 0
global STS_remainderX := 0
global STS_remainderY := 0
global STS_cursorXMouseGetPos := 0
global STS_cursorYMouseGetPos := 0
global STS_windowUnderMouse := ""
global STS_controlUnderMouse := ""
global STS_windowClassUnderMouse := ""
global STS_windowProcessUnderMouse := ""

; Texture
global STS_sensitivity := IniRead(ConfigFile, "Trackball_Texture", "sensitivity", "1")
global STS_refreshInterval := IniRead(ConfigFile, "Trackball_Texture", "refreshInterval", "10")

; Smoothing windows
global STS_smoothingWindowX := []
global STS_smoothingWindowY := []
global STS_smoothingWindowNextIndex := 1
global STS_smoothingWindowCurrentSize := 0
global STS_smoothingWindowMaxSize := IniRead(ConfigFile, "Trackball_Texture", "smoothingWindowMaxSize", "1")
Loop STS_smoothingWindowMaxSize {
    STS_smoothingWindowX.Push(0)
    STS_smoothingWindowY.Push(0)
}

; Angle snapping
global STS_snapOn := StrLower(IniRead(ConfigFile, "Trackball_AxisSnapping", "snapOnByDefault", "true")) = "true"
global STS_snapRatio := IniRead(ConfigFile, "Trackball_AxisSnapping", "snapRatio", "1.5")
global STS_snapThreshold := IniRead(ConfigFile, "Trackball_AxisSnapping", "snapThreshold", "10")
global STS_disableSnapFor := IniRead(ConfigFile, "Trackball_AxisSnapping", "disableSnapFor", "")
global STS_snapState := 0
global STS_snapDeviation := 0.0

; Acceleration
global STS_accelerationOn := StrLower(IniRead(ConfigFile, "Trackball_Acceleration", "accelerationOn", "false")) = "true"
STS_accelerationBlend := IniRead(ConfigFile, "Trackball_Acceleration", "accelerationBlend", "0.872116")
STS_accelerationScale := IniRead(ConfigFile, "Trackball_Acceleration", "accelerationScale", "500")
STS_accelerationScale *= STS_refreshInterval
global STS_accelerationP := STS_accelerationBlend / STS_accelerationScale
global STS_accelerationQ := STS_accelerationBlend + 1
global STS_accelerationR := STS_accelerationScale

; Modifier emulation
global STS_addShift := StrLower(IniRead(ConfigFile, "Trackball_ModifierEmulation", "addShift", "false")) = "true"
global STS_addCtrl := StrLower(IniRead(ConfigFile, "Trackball_ModifierEmulation", "addCtrl", "false")) = "true"
global STS_addAlt := StrLower(IniRead(ConfigFile, "Trackball_ModifierEmulation", "addAlt", "false")) = "true"

; Cursor
global STS_cursorIcon := IniRead(ConfigFile, "Trackball_Cursor", "cursorIcon", "0") + 0
global STS_cursorWasChanged := false

; Behavior
global STS_blockLeftClick := StrLower(IniRead(ConfigFile, "Trackball_Behavior", "blockLeftClick", "false")) = "true"

; Create mouse hook
global STS_hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", CallbackCreate(STS_MouseHook, "Fast"), "ptr", 0, "uint", 0, "ptr")

OnExit STS_RemoveMouseHook

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - APP INITIALIZATION
; ==============================================================================
STS_hotkey1 := IniRead(ConfigFile, "Trackball_Hotkeys", "hotkey1", "XButton2")
STS_hotkey2 := IniRead(ConfigFile, "Trackball_Hotkeys", "hotkey2", "")
STS_stopKey := IniRead(ConfigFile, "Trackball_Hotkeys", "stopKey", "")
STS_panicButton := IniRead(ConfigFile, "Trackball_Hotkeys", "panicButton", "")
STS_mode := IniRead(ConfigFile, "Trackball_Hotkeys", "mode", "ONE_KEY_HOLD_MOMENTARY")
STS_holdDuration := IniRead(ConfigFile, "Trackball_Hotkeys", "holdDuration", "200") + 0

; ==============================================================================
; SHOW CURSOR - HOTKEY REGISTRATION
; ==============================================================================
if (SC_TriggerKey != "") {
    try {
        if (SC_Mode == "1") {
            Hotkey(SC_TriggerKey, SC_TriggerHandler)
        } else if (SC_Mode == "2") {
            Hotkey(SC_TriggerKey, SC_TriggerHandler)
        }
    } catch as err {
        MsgBox("ShowCursor: Failed to register hotkey '" SC_TriggerKey "': " err.Message)
    }
}

; ==============================================================================
; SNIPPET AND RECORD - HOTKEY REGISTRATION
; ==============================================================================
if (SAR_TriggerKey != "") {
    try {
        Hotkey("$" SAR_TriggerKey, SAR_TriggerAction)
    } catch as err {
        MsgBox("SnippetAndRecord: Failed to register hotkey '" SAR_TriggerKey "': " err.Message)
    }
}

; ==============================================================================
; DRAGGING UTILITY - HOTKEY REGISTRATION
; ==============================================================================
if (DU_TriggerKey != "") {
    try {
        Hotkey("$" DU_TriggerKey, DU_TriggerHandler)
    } catch as err {
        MsgBox("DraggingUtility: Failed to register hotkey '" DU_TriggerKey "': " err.Message)
    }
}

; ==============================================================================
; UNDO REDO - HOTKEY REGISTRATION (STANDALONE)
; ==============================================================================
; Register standalone undo/redo hotkeys if the other utilities don't use XButton1/XButton2
global UR_StandaloneUndo := (SC_TriggerKey != "XButton1")
global UR_StandaloneRedo := true

if (UR_Apps != "" && UR_StandaloneUndo) {
    try {
        Hotkey("$XButton1", UR_UndoHandler)
    } catch as err {
        ; Silently fail if hotkey already registered
    }
}
if (UR_Apps != "" && UR_StandaloneRedo) {
    try {
        Hotkey("$XButton2", UR_RedoHandler)
    } catch as err {
        ; Silently fail if hotkey already registered
    }
}

; Register additional undo/redo keys (e.g., Browser_Back/Browser_Forward)
if (UR_Apps != "" && UR_AdditionalUndoKey != "") {
    try {
        Hotkey("$" UR_AdditionalUndoKey, UR_AdditionalUndoHandler)
    } catch as err {
        MsgBox("UndoRedo: Failed to register additional undo hotkey '" UR_AdditionalUndoKey "': " err.Message)
    }
}
if (UR_Apps != "" && UR_AdditionalRedoKey != "") {
    try {
        Hotkey("$" UR_AdditionalRedoKey, UR_AdditionalRedoHandler)
    } catch as err {
        MsgBox("UndoRedo: Failed to register additional redo hotkey '" UR_AdditionalRedoKey "': " err.Message)
    }
}

; ==============================================================================
; CAPSLOCK SHIFT - HOTKEY REGISTRATION
; ==============================================================================
if (CLS_Enabled = "1") {
    try {
        Hotkey("$CapsLock", CLS_CapsLockDown)
        Hotkey("$CapsLock Up", CLS_CapsLockUp)
    } catch as err {
        MsgBox("CapsLockShift: Failed to register CapsLock hotkey: " err.Message)
    }
}

; ==============================================================================
; VOLUME CONTROL - HOTKEY REGISTRATION
; ==============================================================================
if (VC_VolumeUpKey != "") {
    try {
        Hotkey("$" VC_VolumeUpKey, VC_VolumeUpHandler)
    } catch as err {
        MsgBox("VolumeControl: Failed to register volume up hotkey '" VC_VolumeUpKey "': " err.Message)
    }
}
if (VC_VolumeDownKey != "") {
    try {
        Hotkey("$" VC_VolumeDownKey, VC_VolumeDownHandler)
    } catch as err {
        MsgBox("VolumeControl: Failed to register volume down hotkey '" VC_VolumeDownKey "': " err.Message)
    }
}

; ==============================================================================
; WIN KEY OVERRIDE - HOTKEY REGISTRATION
; ==============================================================================
if (WKO_Enabled = "1") {
    try {
        Hotkey("$LWin", WKO_WinKeyDown)
        Hotkey("$LWin Up", WKO_WinKeyUp)
    } catch as err {
        MsgBox("WinKeyOverride: Failed to register LWin hotkey: " err.Message)
    }
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - HOTKEY REGISTRATION
; ==============================================================================

; PANIC BUTTON
if (STS_panicButton != "")
    Hotkey(STS_panicButton, STS_PanicFunction)

; STOP KEY
if (STS_stopKey != "") {
    HotIf STS_IsSmoothScrollingActive
    Hotkey(STS_stopKey, STS_StopFunction)
    HotIf
}

; MODE-SPECIFIC HOTKEY SETUP
if (STS_mode = "ON_OFF") {
    Hotkey("$" STS_hotkey1, STS_OnOffKey1Down)
    Hotkey("$" STS_hotkey1 " Up", STS_OnOffKey1Up)
    Hotkey("$" STS_hotkey2, STS_OnOffKey2Down)
    Hotkey("$" STS_hotkey2 " Up", STS_OnOffKey2Up)

    global STS_onOffKey1FlipFlop := false
    global STS_onOffKey2FlipFlop := false

} else if (STS_mode = "ONE_KEY_TOGGLE") {
    Hotkey("$" STS_hotkey1, STS_OneKeyToggleDown)
    Hotkey("$" STS_hotkey1 " Up", STS_OneKeyToggleUp)

    global STS_oneKeyToggleFlipFlop := false

} else if (STS_mode = "ONE_KEY_MOMENTARY") {
    Hotkey("$" STS_hotkey1, STS_OneKeyMomentaryDown)
    Hotkey("$" STS_hotkey1 " Up", STS_OneKeyMomentaryUp)

    global STS_oneKeyMomentaryFlipFlop := false

} else if (STS_mode = "ONE_KEY_TAP_TOGGLE") {
    Hotkey("$" STS_hotkey1, STS_OneKeyTapToggleDown)
    Hotkey("$" STS_hotkey1 " Up", STS_OneKeyTapToggleUp)

    global STS_oneKeyTapToggleFlipFlop := false
    global STS_oneKeyTapToggleKeyDown := false

} else if (STS_mode = "ONE_KEY_HOLD_TOGGLE") {
    Hotkey("$" STS_hotkey1, STS_OneKeyHoldToggleDown)
    Hotkey("$" STS_hotkey1 " Up", STS_OneKeyHoldToggleUp)

    global STS_oneKeyHoldToggleFlipFlop := false
    global STS_oneKeyHoldToggleLock := true

} else if (STS_mode = "ONE_KEY_HOLD_MOMENTARY") {
    Hotkey("$" STS_hotkey1, STS_OneKeyHoldMomentaryDown)
    Hotkey("$" STS_hotkey1 " Up", STS_OneKeyHoldMomentaryUp)

    global STS_oneKeyHoldMomentaryFlipFlop := false
    global STS_oneKeyHoldMomentaryTapped := true

} else if (STS_mode = "TWO_KEY_TAP_TOGGLE") {
    Hotkey("$" STS_hotkey1, STS_TwoKeyTapToggleKey1Down)
    Hotkey("$" STS_hotkey1 " Up", STS_TwoKeyTapToggleKey1Up)
    Hotkey("$" STS_hotkey2, STS_TwoKeyTapToggleKey2Down)
    Hotkey("$" STS_hotkey2 " Up", STS_TwoKeyTapToggleKey2Up)

    global STS_twoKeyTapToggleKey1FlipFlop := false
    global STS_twoKeyTapToggleKey2FlipFlop := false
    global STS_twoKeyTapToggleKey1State := false
    global STS_twoKeyTapToggleKey2State := false
    global STS_twoKeyTapToggleTimedOut := false
    global STS_twoKeyTapToggleLocked := false

} else {
    MsgBox "Error: Unsupported smooth scrolling mode '" STS_mode "' in config."
}

; ==============================================================================
; SHOW CURSOR - FUNCTIONS
; ==============================================================================

SC_TriggerHandler(ThisHotkey) {
    KeyName := StrReplace(ThisHotkey, "~", "")
    KeyName := StrReplace(KeyName, "$", "")

    if (SC_Mode == "1") {
        TimeoutSec := SC_HoldDuration / 1000

        if (KeyWait(KeyName, "T" . TimeoutSec) == 0) {
            Send(SC_TargetHotkey)
            KeyWait(KeyName)
        } else {
            ; Tap detected - check for UndoRedo mapping
            if (UR_Apps != "" && UR_IsAppActive())
                Send("^z")
            else
                Send("{" . KeyName . "}")
        }
    } else {
        Send(SC_TargetHotkey)
    }
}

SC_CreateDefaultConfig() {
    IniWrite("1", ConfigFile, "ShowCursor_Settings", "Mode")
    IniWrite("XButton1", ConfigFile, "ShowCursor_Settings", "TriggerKey")
    IniWrite("#+F", ConfigFile, "ShowCursor_Settings", "TargetHotkey")
    IniWrite("200", ConfigFile, "ShowCursor_Settings", "HoldDuration")

    IniWrite("^+#F10", ConfigFile, "SnippetAndRecord_Settings", "TriggerKey")
    IniWrite("200", ConfigFile, "SnippetAndRecord_Settings", "HoldDuration")
    IniWrite("0", ConfigFile, "SnippetAndRecord_Settings", "ShowTrayIcon")

    IniWrite("", ConfigFile, "UndoRedo_Settings", "Apps")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "ModifierPassthrough")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AlternativeRedoShortcut")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AdditionalUndoKey")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AdditionalRedoKey")

    IniWrite("^F12", ConfigFile, "DraggingUtility_Settings", "TriggerKey")
    IniWrite("MButton", ConfigFile, "DraggingUtility_Settings", "DragAction")
    IniWrite("XButton2", ConfigFile, "DraggingUtility_Settings", "NonDragAction")

    IniWrite("XButton2", ConfigFile, "Trackball_Hotkeys", "hotkey1")
    IniWrite("MButton", ConfigFile, "Trackball_Hotkeys", "hotkey2")
    IniWrite("", ConfigFile, "Trackball_Hotkeys", "stopKey")
    IniWrite("F3", ConfigFile, "Trackball_Hotkeys", "panicButton")
    IniWrite("ONE_KEY_HOLD_MOMENTARY", ConfigFile, "Trackball_Hotkeys", "mode")
    IniWrite("200", ConfigFile, "Trackball_Hotkeys", "holdDuration")

    IniWrite("1", ConfigFile, "Trackball_Texture", "sensitivity")
    IniWrite("10", ConfigFile, "Trackball_Texture", "refreshInterval")
    IniWrite("1", ConfigFile, "Trackball_Texture", "smoothingWindowMaxSize")

    IniWrite("true", ConfigFile, "Trackball_AxisSnapping", "snapOnByDefault")
    IniWrite("1.5", ConfigFile, "Trackball_AxisSnapping", "snapRatio")
    IniWrite("10", ConfigFile, "Trackball_AxisSnapping", "snapThreshold")
    IniWrite("Affinity", ConfigFile, "Trackball_AxisSnapping", "disableSnapFor")

    IniWrite("false", ConfigFile, "Trackball_Acceleration", "accelerationOn")
    IniWrite("0.872116", ConfigFile, "Trackball_Acceleration", "accelerationBlend")
    IniWrite("500", ConfigFile, "Trackball_Acceleration", "accelerationScale")

    IniWrite("false", ConfigFile, "Trackball_ModifierEmulation", "addShift")
    IniWrite("false", ConfigFile, "Trackball_ModifierEmulation", "addCtrl")
    IniWrite("false", ConfigFile, "Trackball_ModifierEmulation", "addAlt")

    IniWrite("32646", ConfigFile, "Trackball_Cursor", "cursorIcon")

    IniWrite("false", ConfigFile, "Trackball_Behavior", "blockLeftClick")

    IniWrite("", ConfigFile, "UndoRedo_Settings", "Apps")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "ModifierPassthrough")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AlternativeRedoShortcut")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AdditionalUndoKey")
    IniWrite("", ConfigFile, "UndoRedo_Settings", "AdditionalRedoKey")

    IniWrite("0", ConfigFile, "CapsLockShift_Settings", "Enabled")

    IniWrite("", ConfigFile, "VolumeControl_Settings", "VolumeUpKey")
    IniWrite("", ConfigFile, "VolumeControl_Settings", "VolumeDownKey")

    IniWrite("0", ConfigFile, "WinKeyOverride_Settings", "Enabled")
    IniWrite("^{Space}", ConfigFile, "WinKeyOverride_Settings", "TapAction")
}

; ==============================================================================
; UNDO REDO - FUNCTIONS
; ==============================================================================

UR_IsAppActive() {
    ; Returns true if active window matches any app in UR_Apps list
    ; Check both window title and process name
    if (UR_Apps == "")
        return false

    ; If modifier passthrough is configured and held, return false to use default behavior
    if (UR_ModifierPassthrough != "" && UR_IsModifierHeld())
        return false

    try {
        activeTitle := WinGetTitle("A")
        activeProcess := WinGetProcessName("A")
    } catch {
        return false
    }

    Loop Parse, UR_Apps, "," {
        appName := Trim(A_LoopField)
        if (appName == "")
            continue
        ; Check if app name matches window title (partial match)
        if (InStr(activeTitle, appName))
            return true
        ; Check if app name matches process name (partial match)
        if (InStr(activeProcess, appName))
            return true
    }
    return false
}

UR_IsModifierHeld() {
    ; Check if any of the configured modifier keys are held
    Loop Parse, UR_ModifierPassthrough, "," {
        modifier := Trim(A_LoopField)
        if (modifier == "")
            continue
        if (GetKeyState(modifier, "P"))
            return true
    }
    return false
}

UR_UsesAlternativeRedo() {
    ; Returns true if active window matches any app in AlternativeRedoShortcut list
    global UR_AlternativeRedoShortcut
    if (UR_AlternativeRedoShortcut == "")
        return false

    try {
        activeTitle := WinGetTitle("A")
        activeProcess := WinGetProcessName("A")
    } catch {
        return false
    }

    Loop Parse, UR_AlternativeRedoShortcut, "," {
        appName := Trim(A_LoopField)
        if (appName == "")
            continue
        if (InStr(activeTitle, appName))
            return true
        if (InStr(activeProcess, appName))
            return true
    }
    return false
}

UR_UndoHandler(ThisHotkey) {
    if (UR_Apps != "" && UR_IsAppActive())
        Send("^z")
    else
        Send("{XButton1}")
}

UR_RedoHandler(ThisHotkey) {
    global UR_Apps
    if (UR_Apps != "" && UR_IsAppActive()) {
        if (UR_UsesAlternativeRedo())
            Send("^+{z}")
        else
            Send("^y")
    } else
        Send("{XButton2}")
}

UR_AdditionalUndoHandler(ThisHotkey) {
    global UR_AdditionalUndoKey
    if (UR_Apps != "" && UR_IsAppActive())
        Send("^z")
    else
        Send("{" UR_AdditionalUndoKey "}")
}

UR_AdditionalRedoHandler(ThisHotkey) {
    global UR_Apps, UR_AdditionalRedoKey
    if (UR_Apps != "" && UR_IsAppActive()) {
        if (UR_UsesAlternativeRedo())
            Send("^+{z}")
        else
            Send("^y")
    } else
        Send("{" UR_AdditionalRedoKey "}")
}

; ==============================================================================
; SNIPPET AND RECORD - FUNCTIONS
; ==============================================================================

SAR_TriggerAction(ThisHotkey) {
    KeyName := RegExReplace(ThisHotkey, "[~*$^!+#<>]", "")
    HoldThreshold := SAR_HoldDuration

    if KeyWait(KeyName, "T" HoldThreshold / 1000) {
        Send "#+s"
    } else {
        Send "#+r"
        KeyWait KeyName
    }
}

; ==============================================================================
; DRAGGING UTILITY - FUNCTIONS
; ==============================================================================

DU_TriggerHandler(ThisHotkey) {
    global DU_IsDragging, DU_DragAction, DU_NonDragAction, UR_Apps
    if (DU_IsDragging) {
        Send("{" DU_DragAction "}")
    } else {
        ; Check for UndoRedo mapping first (redo action since this is forward button)
        if (UR_Apps != "" && UR_IsAppActive()) {
            if (UR_UsesAlternativeRedo())
                Send("^+{z}")
            else
                Send("^y")
        } else {
            Send("{" DU_NonDragAction "}")
        }
    }
}

; ==============================================================================
; CAPSLOCK SHIFT - FUNCTIONS
; ==============================================================================

CLS_CapsLockDown(ThisHotkey) {
    Send("{Shift down}")
}

CLS_CapsLockUp(ThisHotkey) {
    Send("{Shift up}")
}

; ==============================================================================
; WIN KEY OVERRIDE - FUNCTIONS
; ==============================================================================

WKO_WinKeyDown(ThisHotkey) {
    Send("{LWin down}")
}

WKO_WinKeyUp(ThisHotkey) {
    global WKO_TapAction
    if (A_PriorKey = "LWin") {
        ; Solo press — no other key was pressed while LWin was held
        ; Send a dummy key to cancel the Start menu, then send TapAction
        Send("{vkE8}")
        Send("{LWin up}")
        Send(WKO_TapAction)
    } else {
        ; Another key was pressed — normal Win+X combo, just release
        Send("{LWin up}")
    }
}

; ==============================================================================
; VOLUME CONTROL - FUNCTIONS
; ==============================================================================

VC_VolumeUpHandler(ThisHotkey) {
    VC_VolumeOSD("+1")
}

VC_VolumeDownHandler(ThisHotkey) {
    VC_VolumeOSD("-1")
}

VC_VolumeOSD(v) {
    ; Adjust volume
    SoundSetVolume(v)

    ; Trigger Windows native volume OSD
    try if shellProvider := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}") {
        try if flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}")
            ComCall(3, flyoutDisp, "int", 0, "uint", 0)
    }
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - PUBLIC API FUNCTIONS
; ==============================================================================

STS_IsSmoothScrollingActive(_:="") {
    return STS_active
}

STS_IsAngleSnapOn() {
    return STS_snapOn
}

STS_ScrollingActivate(changeCursor := true) {
    global STS_active := 1
    global STS_accumulatorX := 0
    global STS_accumulatorY := 0
    global STS_accumulatorWheel := 0
    global STS_remainderX := 0
    global STS_remainderY := 0
    global STS_snapState := 0
    global STS_snapDeviation := 0.0
    global STS_cursorWasChanged := false
    global STS_cursorXMouseGetPos, STS_cursorYMouseGetPos, STS_windowUnderMouse, STS_controlUnderMouse, STS_windowClassUnderMouse, STS_windowProcessUnderMouse
    MouseGetPos(&STS_cursorXMouseGetPos, &STS_cursorYMouseGetPos, &STS_windowUnderMouse, &STS_controlUnderMouse, 3)
    try {
        STS_windowClassUnderMouse := WinGetClass("ahk_id " STS_windowUnderMouse)
        STS_windowProcessUnderMouse := WinGetProcessName("ahk_id " STS_windowUnderMouse)
    } catch {
        STS_windowClassUnderMouse := ""
        STS_windowProcessUnderMouse := ""
    }
    STS_SmoothingWindowsReset()
    SetTimer(STS_TimerScroll, STS_refreshInterval)
    SetTimer(STS_TimerWheel, STS_refreshInterval)
    if (changeCursor and STS_cursorIcon != 0) {
        STS_SetSystemCursor(STS_cursorIcon)
        STS_cursorWasChanged := true
    }
}

STS_ScrollingShowCursor() {
    global STS_cursorWasChanged
    if (STS_active and STS_cursorIcon != 0 and !STS_cursorWasChanged) {
        STS_SetSystemCursor(STS_cursorIcon)
        STS_cursorWasChanged := true
    }
}

STS_ScrollingDeactivate() {
    global STS_active := 0
    SetTimer(STS_TimerScroll, 0)
    SetTimer(STS_TimerWheel, 0)
    ; Restore cursor position to where it was when scrolling started,
    ; preventing the cursor from snapping to the accumulated hardware position
    DllCall("SetCursorPos", "int", STS_cursorXMouseGetPos, "int", STS_cursorYMouseGetPos)
    global STS_cursorWasChanged
    if (STS_cursorWasChanged) {
        STS_SetSystemCursor("")
        STS_cursorWasChanged := false
    }
}

STS_AngleSnapOn() {
    global STS_snapOn := true
    global STS_snapDeviation := 0.0
    STS_SmoothingWindowsReset()
}

STS_AngleSnapOff() {
    global STS_snapOn := false
    global STS_snapDeviation := 0.0
    STS_SmoothingWindowsReset()
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - MOUSE HOOK
; ==============================================================================

STS_MouseHook(nCode, wParam, lParam) {
    if (nCode < 0)
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)

    static msllSize := 16
    static msllBuffer := Buffer(msllSize, 0)
    DllCall("RtlMoveMemory", "ptr", msllBuffer.Ptr, "ptr", lParam, "ptr", msllSize)
    messageX         := NumGet(msllBuffer,  0,  "int")
    messageY         := NumGet(msllBuffer,  4,  "int")
    messageMouseData := NumGet(msllBuffer,  8, "uint")
    messageFlags     := NumGet(msllBuffer, 12, "uint")

    if (messageFlags & 0x1)
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)

    if (not STS_active) {
        global STS_cursorX := messageX
        global STS_cursorY := messageY
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
    }

    if (STS_blockLeftClick and (wParam = 0x0201 or wParam = 0x0202)) {
        return 1
    }

    if (wParam = 0x0200) {
        deltaX := messageX - STS_cursorX
        deltaY := messageY - STS_cursorY
        global STS_accumulatorX += deltaX
        global STS_accumulatorY += deltaY
        return 1
    }

    if (wParam = 0x020A) {
        wheelDelta := messageMouseData >> 16
        if (wheelDelta & 0x8000)
            wheelDelta := -(0x10000 - wheelDelta)
        global STS_accumulatorWheel += wheelDelta
        return 1
    }

    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
}

STS_RemoveMouseHook(ExitReason, ExitCode) {
    STS_SetSystemCursor("")
    if (STS_hHook)
        DllCall("UnhookWindowsHookEx", "ptr", STS_hHook)
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - WHEEL INPUT FUNCTIONS
; ==============================================================================

STS_SendWheel(deltaH, deltaV) {
    if (STS_windowClassUnderMouse = "XamlExplorerHostIslandWindow" or STS_windowClassUnderMouse = "Open With" or STS_windowClassUnderMouse = "WinUIDesktopWin32WindowClass" or STS_windowClassUnderMouse = "ApplicationFrameWindow" or STS_windowClassUnderMouse = "Windows.UI.Core.CoreWindow" or STS_windowClassUnderMouse = "ControlCenterWindow" or STS_windowClassUnderMouse = "Xaml_WindowedPopupClass") {
        if (deltaV != 0)
            DllCall("mouse_event", "uint", 0x0800, "int", 0, "int", 0, "uint", deltaV, "int", 0)
        if (deltaH != 0)
            DllCall("mouse_event", "uint", 0x1000, "int", 0, "int", 0, "uint", deltaH, "int", 0)
        return
    }

    lowOrderX := STS_cursorXMouseGetPos & 0xFFFF
    highOrderY := STS_cursorYMouseGetPos & 0xFFFF
    if (STS_controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX, STS_controlUnderMouse, "ahk_id " STS_windowUnderMouse)
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX, STS_controlUnderMouse, "ahk_id " STS_windowUnderMouse)
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX,, "ahk_id " STS_windowUnderMouse)
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX,, "ahk_id " STS_windowUnderMouse)
    }
}

STS_SendWheelWithModifiers(deltaH, deltaV, shift, ctrl, alt) {
    if (STS_windowClassUnderMouse = "XamlExplorerHostIslandWindow" or STS_windowClassUnderMouse = "Open With" or STS_windowClassUnderMouse = "WinUIDesktopWin32WindowClass" or STS_windowClassUnderMouse = "ApplicationFrameWindow" or STS_windowClassUnderMouse = "Windows.UI.Core.CoreWindow" or STS_windowClassUnderMouse = "ControlCenterWindow" or STS_windowClassUnderMouse = "Xaml_WindowedPopupClass") {
        if (deltaV != 0)
            DllCall("mouse_event", "uint", 0x0800, "int", 0, "int", 0, "uint", deltaV, "int", 0)
        if (deltaH != 0)
            DllCall("mouse_event", "uint", 0x1000, "int", 0, "int", 0, "uint", deltaH, "int", 0)
        return
    }

    lowOrderX := STS_cursorXMouseGetPos & 0xFFFF
    highOrderY := STS_cursorYMouseGetPos & 0xFFFF
    modifiers := 0x00
    if (shift)
        modifiers += 0x04
    if (ctrl)
        modifiers += 0x08
    if (alt)
        modifiers += 0x20
    if (STS_controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX, STS_controlUnderMouse, "ahk_id " STS_windowUnderMouse)
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX, STS_controlUnderMouse, "ahk_id " STS_windowUnderMouse)
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " STS_windowUnderMouse)
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " STS_windowUnderMouse)
    }
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - SMOOTHING WINDOWS
; ==============================================================================

STS_SmoothingWindowsReset() {
    global STS_smoothingWindowNextIndex := 1
    global STS_smoothingWindowCurrentSize := 0
}

STS_SmoothingWindowsPush(x, y) {
    global STS_smoothingWindowX, STS_smoothingWindowY
    STS_smoothingWindowX[STS_smoothingWindowNextIndex] := x
    STS_smoothingWindowY[STS_smoothingWindowNextIndex] := y
    if (STS_smoothingWindowNextIndex = STS_smoothingWindowMaxSize) {
        global STS_smoothingWindowNextIndex := 1
    } else {
        global STS_smoothingWindowNextIndex += 1
    }
    if (STS_smoothingWindowCurrentSize < STS_smoothingWindowMaxSize) {
        global STS_smoothingWindowCurrentSize += 1
    }
}

STS_SmoothingWindowsGetMeanX() {
    if (STS_smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop STS_smoothingWindowCurrentSize {
        mean += STS_smoothingWindowX[A_Index]
    }
    return mean / STS_smoothingWindowCurrentSize
}

STS_SmoothingWindowsGetMeanY() {
    if (STS_smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop STS_smoothingWindowCurrentSize {
        mean += STS_smoothingWindowY[A_Index]
    }
    return mean / STS_smoothingWindowCurrentSize
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - TIMERS
; ==============================================================================

STS_TimerWheel() {
    If (STS_accumulatorWheel = 0) {
        return
    }
    STS_SendWheelWithModifiers(0, STS_accumulatorWheel, ((STS_addShift = 1) ^ GetKeyState("Shift", "P")), ((STS_addCtrl = 1) ^ GetKeyState("Ctrl", "P")), ((STS_addAlt = 1) ^ GetKeyState("Alt", "P")))
    global STS_accumulatorWheel := 0
}

STS_TimerScroll() {
    STS_SmoothingWindowsPush(STS_accumulatorX, STS_accumulatorY)
    smoothedX := STS_SmoothingWindowsGetMeanX()
    smoothedY := STS_SmoothingWindowsGetMeanY() * -1
    global STS_accumulatorX := 0
    global STS_accumulatorY := 0

    shouldSnap := STS_snapOn
    if (shouldSnap and STS_disableSnapFor != "") {
        Loop Parse, STS_disableSnapFor, "," {
            if (WinActive(Trim(A_LoopField))) {
                shouldSnap := false
                break
            }
        }
    }

    if (shouldSnap) {
        if (STS_snapState = 0) {
            if (Abs(smoothedX) > Abs(smoothedY)) {
                smoothedY := 0
                global STS_remainderY := 0
                global STS_snapState := 1
            } else if (Abs(smoothedX) < Abs(smoothedY)) {
                smoothedX := 0
                global STS_remainderX := 0
                global STS_snapState := 2
            }
        } else if (STS_snapState = 1) {
            global STS_snapDeviation := STS_snapDeviation + smoothedY
            if (STS_snapDeviation > 0) {
                global STS_snapDeviation := Max(0, STS_snapDeviation - Abs(smoothedX) * STS_snapRatio)
            } else if (STS_snapDeviation < 0) {
                global STS_snapDeviation := Min(0, STS_snapDeviation + Abs(smoothedX) * STS_snapRatio)
            }
            if (Abs(STS_snapDeviation) > STS_snapThreshold) {
                smoothedX := 0
                global STS_remainderX := 0
                global STS_snapState := 2
                global STS_snapDeviation := 0.0
                STS_SmoothingWindowsReset()
            } else {
                smoothedY := 0
                global STS_remainderY := 0
            }
        } else if (STS_snapState = 2) {
            global STS_snapDeviation := STS_snapDeviation + smoothedX
            if (STS_snapDeviation > 0) {
                global STS_snapDeviation := Max(0, STS_snapDeviation - Abs(smoothedY) * STS_snapRatio)
            } else if (STS_snapDeviation < 0) {
                global STS_snapDeviation := Min(0, STS_snapDeviation + Abs(smoothedY) * STS_snapRatio)
            }
            if (Abs(STS_snapDeviation) > STS_snapThreshold) {
                smoothedY := 0
                global STS_remainderY := 0
                global STS_snapState := 1
                global STS_snapDeviation := 0.0
                STS_SmoothingWindowsReset()
            } else {
                smoothedX := 0
                global STS_remainderX := 0
            }
        }
    }

    if (STS_accelerationOn and ((smoothedX != 0) or (smoothedY != 0))) {
        speed := Sqrt(smoothedX * smoothedX + smoothedY * smoothedY)
        speed_offset := speed - STS_accelerationR
        scale_factor := STS_accelerationQ * speed_offset + STS_accelerationR
        if (speed_offset < 0)
            scale_factor += STS_accelerationP * speed_offset * speed_offset
        scale_factor /= speed
        smoothedX *= scale_factor
        smoothedY *= scale_factor
    }

    smoothedX *= STS_sensitivity
    smoothedY *= STS_sensitivity

    smoothedX += STS_remainderX
    smoothedY += STS_remainderY
    roundedX := Round(smoothedX)
    roundedY := Round(smoothedY)
    global STS_remainderX := smoothedX - roundedX
    global STS_remainderY := smoothedY - roundedY

    STS_SendWheel(roundedX, roundedY)
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - CURSOR FUNCTIONS
; ==============================================================================

STS_SetSystemCursor(CursorId := "") {
    static SystemCursors := [32512, 32513, 32514, 32515, 32516, 32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650, 32651]
    if (CursorId = "") {
        return DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)
    }

    hCursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", CursorId, "Ptr")
    for id in SystemCursors {
        hCopy := DllCall("CopyImage", "Ptr", hCursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
        DllCall("SetSystemCursor", "Ptr", hCopy, "Int", id)
    }
}

; ==============================================================================
; SMOOTH TRACKBALL SCROLLING - HOTKEY MODE IMPLEMENTATIONS
; ==============================================================================

; PANIC FUNCTION
STS_PanicFunction(_) {
    ExitApp()
}

; STOP FUNCTION
STS_StopFunction(_) {
    STS_ScrollingDeactivate()
}

; ON_OFF MODE
STS_OnOffKey1Down(_) {
    global STS_onOffKey1FlipFlop
    if (STS_onOffKey1FlipFlop)
        return
    STS_onOffKey1FlipFlop := true
    STS_ScrollingActivate()
}

STS_OnOffKey2Down(_) {
    global STS_onOffKey2FlipFlop
    if (STS_onOffKey2FlipFlop)
        return
    STS_onOffKey2FlipFlop := true
    STS_ScrollingDeactivate()
}

STS_OnOffKey1Up(_) {
    global STS_onOffKey1FlipFlop
    STS_onOffKey1FlipFlop := false
}

STS_OnOffKey2Up(_) {
    global STS_onOffKey2FlipFlop
    STS_onOffKey2FlipFlop := false
}

; ONE_KEY_TOGGLE MODE
STS_OneKeyToggleDown(_) {
    global STS_oneKeyToggleFlipFlop
    if (STS_oneKeyToggleFlipFlop)
        return
    STS_oneKeyToggleFlipFlop := true
    if (STS_IsSmoothScrollingActive()) {
        STS_ScrollingDeactivate()
    } else {
        STS_ScrollingActivate()
    }
}

STS_OneKeyToggleUp(_) {
    global STS_oneKeyToggleFlipFlop
    STS_oneKeyToggleFlipFlop := false
}

; ONE_KEY_MOMENTARY MODE
STS_OneKeyMomentaryDown(_) {
    global STS_oneKeyMomentaryFlipFlop
    if (STS_oneKeyMomentaryFlipFlop)
        return
    STS_oneKeyMomentaryFlipFlop := true
    STS_ScrollingActivate()
}

STS_OneKeyMomentaryUp(_) {
    global STS_oneKeyMomentaryFlipFlop
    STS_oneKeyMomentaryFlipFlop := false
    STS_ScrollingDeactivate()
}

; ONE_KEY_TAP_TOGGLE MODE
STS_OneKeyTapToggleTimer() {
    global STS_oneKeyTapToggleKeyDown
    STS_oneKeyTapToggleKeyDown := true
    Send("{" STS_hotkey1 " down}")
}

STS_OneKeyTapToggleDown(_) {
    global STS_oneKeyTapToggleFlipFlop
    if (STS_oneKeyTapToggleFlipFlop)
        return
    STS_oneKeyTapToggleFlipFlop := true
    SetTimer(STS_OneKeyTapToggleTimer, -STS_holdDuration)
}

STS_OneKeyTapToggleUp(_) {
    global STS_oneKeyTapToggleFlipFlop, STS_oneKeyTapToggleKeyDown
    STS_oneKeyTapToggleFlipFlop := false

    SetTimer(STS_OneKeyTapToggleTimer, 0)
    if (STS_oneKeyTapToggleKeyDown) {
        STS_oneKeyTapToggleKeyDown := false
        Send("{" STS_hotkey1 " up}")
    } else {
        if STS_IsSmoothScrollingActive() {
            STS_ScrollingDeactivate()
        } else {
            STS_ScrollingActivate()
        }
    }
}

; ONE_KEY_HOLD_TOGGLE MODE
STS_OneKeyHoldToggleTimer() {
    STS_ScrollingActivate()
}

STS_OneKeyHoldToggleDown(_) {
    global STS_oneKeyHoldToggleFlipFlop, STS_oneKeyHoldToggleLock
    if (STS_oneKeyHoldToggleFlipFlop)
        return
    STS_oneKeyHoldToggleFlipFlop := true

    if (STS_IsSmoothScrollingActive()) {
        STS_oneKeyHoldToggleLock := true
        STS_ScrollingDeactivate()
    } else {
        STS_oneKeyHoldToggleLock := false
        SetTimer(STS_OneKeyHoldToggleTimer, -STS_holdDuration)
    }
}

STS_OneKeyHoldToggleUp(_) {
    global STS_oneKeyHoldToggleFlipFlop
    STS_oneKeyHoldToggleFlipFlop := false

    if (STS_oneKeyHoldToggleLock)
        return
    SetTimer(STS_OneKeyHoldToggleTimer, 0)
    if (not STS_IsSmoothScrollingActive())
        Send("{" STS_hotkey1 " down}{" STS_hotkey1 " up}")
}

; ONE_KEY_HOLD_MOMENTARY MODE
STS_OneKeyHoldMomentaryTimer() {
    global STS_oneKeyHoldMomentaryTapped
    STS_oneKeyHoldMomentaryTapped := false
    STS_ScrollingShowCursor()
}

STS_OneKeyHoldMomentaryDown(_) {
    global STS_oneKeyHoldMomentaryFlipFlop, STS_oneKeyHoldMomentaryTapped
    if (STS_oneKeyHoldMomentaryFlipFlop)
        return
    STS_oneKeyHoldMomentaryFlipFlop := true

    STS_ScrollingActivate(false)
    STS_oneKeyHoldMomentaryTapped := true
    SetTimer(STS_OneKeyHoldMomentaryTimer, -STS_holdDuration)
}

STS_OneKeyHoldMomentaryUp(_) {
    global STS_oneKeyHoldMomentaryFlipFlop
    STS_oneKeyHoldMomentaryFlipFlop := false

    STS_ScrollingDeactivate()
    SetTimer(STS_OneKeyHoldMomentaryTimer, 0)
    if (STS_oneKeyHoldMomentaryTapped) {
        ; Check if DraggingUtility should handle this button (XButton2)
        if (STS_hotkey1 = DU_TriggerKey && DU_TriggerKey != "") {
            DU_TriggerHandler(STS_hotkey1)
        } else {
            Send("{" STS_hotkey1 " down}{" STS_hotkey1 " up}")
        }
    }
}

; TWO_KEY_TAP_TOGGLE MODE
STS_TwoKeyTapToggleTimer() {
    global STS_twoKeyTapToggleTimedOut
    STS_twoKeyTapToggleTimedOut := true
    if (STS_twoKeyTapToggleKey1State) {
        Send("{" STS_hotkey1 " down}")
    }
    if (STS_twoKeyTapToggleKey2State) {
        Send("{" STS_hotkey2 " down}")
    }
}

STS_TwoKeyTapToggleKey1Down(_) {
    global STS_twoKeyTapToggleKey1FlipFlop, STS_twoKeyTapToggleKey1State, STS_twoKeyTapToggleTimedOut, STS_twoKeyTapToggleLocked
    if (STS_twoKeyTapToggleKey1FlipFlop)
        return
    STS_twoKeyTapToggleKey1FlipFlop := true

    STS_twoKeyTapToggleKey1State := true
    if (STS_twoKeyTapToggleLocked) {
        return
    }
    if (STS_IsSmoothScrollingActive()) {
        STS_ScrollingDeactivate()
        STS_twoKeyTapToggleLocked := true
        return
    }
    if (STS_twoKeyTapToggleTimedOut) {
        Send("{" STS_hotkey1 " down}")
        return
    }
    if (STS_twoKeyTapToggleKey2State) {
        SetTimer(STS_TwoKeyTapToggleTimer, 0)
        if (not STS_IsSmoothScrollingActive()) {
            STS_ScrollingActivate()
        }
    } else {
        SetTimer(STS_TwoKeyTapToggleTimer, -STS_holdDuration)
    }
}

STS_TwoKeyTapToggleKey2Down(_) {
    global STS_twoKeyTapToggleKey2FlipFlop, STS_twoKeyTapToggleKey2State, STS_twoKeyTapToggleTimedOut, STS_twoKeyTapToggleLocked
    if (STS_twoKeyTapToggleKey2FlipFlop)
        return
    STS_twoKeyTapToggleKey2FlipFlop := true

    STS_twoKeyTapToggleKey2State := true
    if (STS_twoKeyTapToggleLocked) {
        return
    }
    if (STS_IsSmoothScrollingActive()) {
        STS_ScrollingDeactivate()
        STS_twoKeyTapToggleLocked := true
        return
    }
    if (STS_twoKeyTapToggleTimedOut) {
        Send("{" STS_hotkey2 " down}")
        return
    }
    if (STS_twoKeyTapToggleKey1State) {
        SetTimer(STS_TwoKeyTapToggleTimer, 0)
        if (not STS_IsSmoothScrollingActive()) {
            STS_ScrollingActivate()
        }
    } else {
        SetTimer(STS_TwoKeyTapToggleTimer, -STS_holdDuration)
    }
}

STS_TwoKeyTapToggleKey1Up(_) {
    global STS_twoKeyTapToggleKey1FlipFlop, STS_twoKeyTapToggleKey1State, STS_twoKeyTapToggleTimedOut, STS_twoKeyTapToggleLocked
    STS_twoKeyTapToggleKey1FlipFlop := false

    STS_twoKeyTapToggleKey1State := false
    if (STS_twoKeyTapToggleTimedOut) {
        Send("{" STS_hotkey1 " up}")
    } else if ((not STS_IsSmoothScrollingActive()) and (not STS_twoKeyTapToggleLocked)) {
        Send("{" STS_hotkey1 " down}")
        Send("{" STS_hotkey1 " up}")
    }
    if (not STS_twoKeyTapToggleKey2State) {
        SetTimer(STS_TwoKeyTapToggleTimer, 0)
        STS_twoKeyTapToggleTimedOut := false
        STS_twoKeyTapToggleLocked := false
    }
}

STS_TwoKeyTapToggleKey2Up(_) {
    global STS_twoKeyTapToggleKey2FlipFlop, STS_twoKeyTapToggleKey2State, STS_twoKeyTapToggleTimedOut, STS_twoKeyTapToggleLocked
    STS_twoKeyTapToggleKey2FlipFlop := false

    STS_twoKeyTapToggleKey2State := false
    if (STS_twoKeyTapToggleTimedOut) {
        Send("{" STS_hotkey2 " up}")
    } else if ((not STS_IsSmoothScrollingActive()) and (not STS_twoKeyTapToggleLocked)) {
        Send("{" STS_hotkey2 " down}")
        Send("{" STS_hotkey2 " up}")
    }
    if (not STS_twoKeyTapToggleKey1State) {
        SetTimer(STS_TwoKeyTapToggleTimer, 0)
        STS_twoKeyTapToggleTimedOut := false
        STS_twoKeyTapToggleLocked := false
    }
}
