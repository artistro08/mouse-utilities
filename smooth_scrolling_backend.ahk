; ==============================================================================
; Smooth Scrolling Backend - Core Scrolling Engine
; ==============================================================================
; This file implements the low-level functionality for trackball smooth scrolling.
; It provides an API for activating/deactivating smooth scrolling and managing
; angle snapping.
;
; REFACTORED FOR MOUSE UTILITIES SUITE
; - All global variables prefixed with SS_ to prevent namespace conflicts
; - Config reading updated to use unified config.ini [SmoothScrolling] section
; - No standalone execution (designed to be #Include'd)
;
; Original project: https://github.com/Seelge/TrackballScroll
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
OnExit SS_RemoveMouseHook

; ==============================================================================
; PUBLIC INTERFACE FUNCTIONS
; ==============================================================================

; Check if smooth scrolling is active.
IsSmoothScrollingActive(_:="") {
    return SS_active
}

; Check if angle snapping is on.
IsAngleSnapOn() {
    return SS_snapOn
}

; Freeze the cursor and begin generating scroll inputs.
ScrollingActivate(changeCursor := true) {
    global SS_active := 1
    global SS_accumulatorX := 0
    global SS_accumulatorY := 0
    global SS_accumulatorWheel := 0
    global SS_remainderX := 0
    global SS_remainderY := 0
    global SS_snapState := 0
    global SS_snapDeviation := 0.0
    global SS_cursorWasChanged := false
    global SS_cursorXMouseGetPos, SS_cursorYMouseGetPos, SS_windowUnderMouse, SS_controlUnderMouse, SS_windowClassUnderMouse, SS_windowProcessUnderMouse
    MouseGetPos(&SS_cursorXMouseGetPos, &SS_cursorYMouseGetPos, &SS_windowUnderMouse, &SS_controlUnderMouse, 3)
    try {
        SS_windowClassUnderMouse := WinGetClass("ahk_id " SS_windowUnderMouse)
        SS_windowProcessUnderMouse := WinGetProcessName("ahk_id " SS_windowUnderMouse)
    } catch {
        SS_windowClassUnderMouse := ""
        SS_windowProcessUnderMouse := ""
    }
    SS_SmoothingWindowsReset()
    SetTimer(SS_TimerScroll, SS_refreshInterval)
    SetTimer(SS_TimerWheel, SS_refreshInterval)
    if (changeCursor and SS_cursorIcon != 0) {
        SS_SetSystemCursor(SS_cursorIcon)
        SS_cursorWasChanged := true
    }
}

; Change the cursor to the scrolling cursor (if scrolling is active).
ScrollingShowCursor() {
    global SS_cursorWasChanged
    if (SS_active and SS_cursorIcon != 0 and !SS_cursorWasChanged) {
        SS_SetSystemCursor(SS_cursorIcon)
        SS_cursorWasChanged := true
    }
}

; Unfreeze the cursor and stop generating scroll inputs.
ScrollingDeactivate() {
    global SS_active := 0
    SetTimer(SS_TimerScroll, 0)
    SetTimer(SS_TimerWheel, 0)
    global SS_cursorWasChanged
    if (SS_cursorWasChanged) {
        SS_SetSystemCursor("")
        SS_cursorWasChanged := false
    }
}

; Turn angle snapping on.
AngleSnapOn() {
    global SS_snapOn := true
    global SS_snapDeviation := 0.0
    SS_SmoothingWindowsReset()
}

; Turn angle snapping off.
AngleSnapOff() {
    global SS_snapOn := false
    global SS_snapDeviation := 0.0
    SS_SmoothingWindowsReset()
}

; ==============================================================================
; INITIALIZATION
; ==============================================================================

; Configuration file path
SS_ConfigFile := A_ScriptDir "\config.ini"

; Core state variables (prefixed with SS_)
global SS_active := false
global SS_cursorX := 0
global SS_cursorY := 0
global SS_accumulatorX := 0
global SS_accumulatorY := 0
global SS_accumulatorWheel := 0
global SS_remainderX := 0
global SS_remainderY := 0
global SS_cursorXMouseGetPos := 0
global SS_cursorYMouseGetPos := 0
global SS_windowUnderMouse := ""
global SS_controlUnderMouse := ""
global SS_windowClassUnderMouse := ""
global SS_windowProcessUnderMouse := ""

; Texture settings (read from unified config [SmoothScrolling] section)
global SS_sensitivity := IniRead(SS_ConfigFile, "SmoothScrolling", "sensitivity")
global SS_refreshInterval := IniRead(SS_ConfigFile, "SmoothScrolling", "refreshInterval")

; Smoothing windows
global SS_smoothingWindowX := []
global SS_smoothingWindowY := []
global SS_smoothingWindowNextIndex := 1
global SS_smoothingWindowCurrentSize := 0
global SS_smoothingWindowMaxSize := IniRead(SS_ConfigFile, "SmoothScrolling", "smoothingWindowMaxSize")
Loop SS_smoothingWindowMaxSize {
    SS_smoothingWindowX.Push(0)
    SS_smoothingWindowY.Push(0)
}

; Angle snapping settings
global SS_snapOn := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "snapOnByDefault")) = "true"
global SS_snapRatio := IniRead(SS_ConfigFile, "SmoothScrolling", "snapRatio")
global SS_snapThreshold := IniRead(SS_ConfigFile, "SmoothScrolling", "snapThreshold")
global SS_disableSnapFor := IniRead(SS_ConfigFile, "SmoothScrolling", "disableSnapFor", "")
global SS_snapState := 0
global SS_snapDeviation := 0.0

; Acceleration settings
global SS_accelerationOn := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "accelerationOn")) = "true"
SS_accelerationBlend := IniRead(SS_ConfigFile, "SmoothScrolling", "accelerationBlend")
SS_accelerationScale := IniRead(SS_ConfigFile, "SmoothScrolling", "accelerationScale")
SS_accelerationScale *= SS_refreshInterval
global SS_accelerationP := SS_accelerationBlend / SS_accelerationScale
global SS_accelerationQ := SS_accelerationBlend + 1
global SS_accelerationR := SS_accelerationScale

; Modifier emulation settings
global SS_addShift := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "addShift")) = "true"
global SS_addCtrl := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "addCtrl")) = "true"
global SS_addAlt := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "addAlt")) = "true"

; Cursor settings
global SS_cursorIcon := IniRead(SS_ConfigFile, "SmoothScrolling", "cursorIcon", 0) + 0
global SS_cursorWasChanged := false

; Behavior settings
global SS_blockLeftClick := StrLower(IniRead(SS_ConfigFile, "SmoothScrolling", "blockLeftClick", "false")) = "true"

; Create mouse hook
global SS_hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", CallbackCreate(SS_MouseHook, "Fast"), "ptr", 0, "uint", 0, "ptr")  ; WH_MOUSE_LL is 14

; ==============================================================================
; MOUSE HOOK FUNCTIONS
; ==============================================================================

SS_MouseHook(nCode, wParam, lParam)
{
    ; Pass on messages with nCode < 0, as per Microsoft specifications
    if (nCode < 0)
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)

    ; Extract info from MSLLHOOKSTRUCT
    static msllSize := 16  ; the actual struct is bigger, but we only need the first 16 bytes
    static msllBuffer := Buffer(msllSize, 0)
    DllCall("RtlMoveMemory", "ptr", msllBuffer.Ptr, "ptr", lParam, "ptr", msllSize)
    messageX         := NumGet(msllBuffer,  0,  "int")
    messageY         := NumGet(msllBuffer,  4,  "int")
    messageMouseData := NumGet(msllBuffer,  8, "uint")
    messageFlags     := NumGet(msllBuffer, 12, "uint")

    ; Ignore injected events (to prevent feedback loops when using mouse_event)
    if (messageFlags & 0x1)
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)

    ; If user isn't pressing the hotkey, store cursor position for later
    if (not SS_active) {
        global SS_cursorX := messageX
        global SS_cursorY := messageY
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
    }

    ; Block left click if configured
    if (SS_blockLeftClick and (wParam = 0x0201 or wParam = 0x0202)) {
        return 1
    }

    ; Handle mouse movements
    if (wParam = 0x0200) {
        deltaX := messageX - SS_cursorX
        deltaY := messageY - SS_cursorY
        global SS_accumulatorX += deltaX
        global SS_accumulatorY += deltaY
        return 1
    }

    ; Handle vertical wheel movements
    if (wParam = 0x020A) {
        wheelDelta := messageMouseData >> 16
        if (wheelDelta & 0x8000)
            wheelDelta := -(0x10000 - wheelDelta)
        global SS_accumulatorWheel += wheelDelta
        return 1
    }

    ; Pass on all other messages (e.g. clicks)
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
}

SS_RemoveMouseHook(ExitReason, ExitCode) {
    SS_SetSystemCursor("")
    if (SS_hHook)
        DllCall("UnhookWindowsHookEx", "ptr", SS_hHook)
}

; ==============================================================================
; WHEEL INPUT FUNCTIONS
; ==============================================================================

SS_SendWheel(deltaH, deltaV) {
    if (SS_windowClassUnderMouse = "XamlExplorerHostIslandWindow" or SS_windowClassUnderMouse = "Open With" or SS_windowClassUnderMouse = "WinUIDesktopWin32WindowClass" or SS_windowClassUnderMouse = "ApplicationFrameWindow" or SS_windowClassUnderMouse = "Windows.UI.Core.CoreWindow" or SS_windowClassUnderMouse = "ControlCenterWindow" or SS_windowClassUnderMouse = "Xaml_WindowedPopupClass") {
        if (deltaV != 0)
            DllCall("mouse_event", "uint", 0x0800, "int", 0, "int", 0, "uint", deltaV, "int", 0)
        if (deltaH != 0)
            DllCall("mouse_event", "uint", 0x1000, "int", 0, "int", 0, "uint", deltaH, "int", 0)
        return
    }

    lowOrderX := SS_cursorXMouseGetPos & 0xFFFF
    highOrderY := SS_cursorYMouseGetPos & 0xFFFF
    if (SS_controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX, SS_controlUnderMouse, "ahk_id " SS_windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX, SS_controlUnderMouse, "ahk_id " SS_windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX,, "ahk_id " SS_windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX,, "ahk_id " SS_windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    }
}

SS_SendWheelWithModifiers(deltaH, deltaV, shift, ctrl, alt) {
    if (SS_windowClassUnderMouse = "XamlExplorerHostIslandWindow" or SS_windowClassUnderMouse = "Open With" or SS_windowClassUnderMouse = "WinUIDesktopWin32WindowClass" or SS_windowClassUnderMouse = "ApplicationFrameWindow" or SS_windowClassUnderMouse = "Windows.UI.Core.CoreWindow" or SS_windowClassUnderMouse = "ControlCenterWindow" or SS_windowClassUnderMouse = "Xaml_WindowedPopupClass") {
        if (deltaV != 0)
            DllCall("mouse_event", "uint", 0x0800, "int", 0, "int", 0, "uint", deltaV, "int", 0)
        if (deltaH != 0)
            DllCall("mouse_event", "uint", 0x1000, "int", 0, "int", 0, "uint", deltaH, "int", 0)
        return
    }

    lowOrderX := SS_cursorXMouseGetPos & 0xFFFF
    highOrderY := SS_cursorYMouseGetPos & 0xFFFF
    modifiers := 0x00
    if (shift)
        modifiers += 0x04
    if (ctrl)
        modifiers += 0x08
    if (alt)
        modifiers += 0x20
    if (SS_controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX, SS_controlUnderMouse, "ahk_id " SS_windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX, SS_controlUnderMouse, "ahk_id " SS_windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " SS_windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " SS_windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    }
}

; ==============================================================================
; SMOOTHING WINDOWS
; ==============================================================================

SS_SmoothingWindowsReset() {
    global SS_smoothingWindowNextIndex := 1
    global SS_smoothingWindowCurrentSize := 0
}

SS_SmoothingWindowsPush(x, y) {
    global SS_smoothingWindowX, SS_smoothingWindowY
    SS_smoothingWindowX[SS_smoothingWindowNextIndex] := x
    SS_smoothingWindowY[SS_smoothingWindowNextIndex] := y
    if (SS_smoothingWindowNextIndex = SS_smoothingWindowMaxSize) {
        global SS_smoothingWindowNextIndex := 1
    } else {
        global SS_smoothingWindowNextIndex += 1
    }
    if (SS_smoothingWindowCurrentSize < SS_smoothingWindowMaxSize) {
        global SS_smoothingWindowCurrentSize += 1
    }
}

SS_SmoothingWindowsGetMeanX() {
    if (SS_smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop SS_smoothingWindowCurrentSize {
        mean += SS_smoothingWindowX[A_Index]
    }
    return mean / SS_smoothingWindowCurrentSize
}

SS_SmoothingWindowsGetMeanY() {
    if (SS_smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop SS_smoothingWindowCurrentSize {
        mean += SS_smoothingWindowY[A_Index]
    }
    return mean / SS_smoothingWindowCurrentSize
}

; ==============================================================================
; TIMERS
; ==============================================================================

SS_TimerWheel() {
    If (SS_accumulatorWheel = 0) {
        return
    }
    SS_SendWheelWithModifiers(0, SS_accumulatorWheel, ((SS_addShift = 1) ^ GetKeyState("Shift", "P")), ((SS_addCtrl = 1) ^ GetKeyState("Ctrl", "P")), ((SS_addAlt = 1) ^ GetKeyState("Alt", "P")))
    global SS_accumulatorWheel := 0
}

SS_TimerScroll() {
    ; Apply smoothing window and reset accumulators
    SS_SmoothingWindowsPush(SS_accumulatorX, SS_accumulatorY)
    smoothedX := SS_SmoothingWindowsGetMeanX()
    smoothedY := SS_SmoothingWindowsGetMeanY() * -1
    global SS_accumulatorX := 0
    global SS_accumulatorY := 0

    ; Apply angle snapping
    shouldSnap := SS_snapOn
    if (shouldSnap and SS_disableSnapFor != "") {
        Loop Parse, SS_disableSnapFor, "," {
            if (WinActive(Trim(A_LoopField))) {
                shouldSnap := false
                break
            }
        }
    }

    if (shouldSnap) {
        if (SS_snapState = 0) {  ; Snapping is on, but we haven't decided which axis to snap to yet
            if (Abs(smoothedX) > Abs(smoothedY)) {  ; Switch to X axis snap
                smoothedY := 0
                global SS_remainderY := 0
                global SS_snapState := 1
            } else if (Abs(smoothedX) < Abs(smoothedY)) {  ; Switch to Y axis snap
                smoothedX := 0
                global SS_remainderX := 0
                global SS_snapState := 2
            }
        } else if (SS_snapState = 1) {  ; Snapping is on, and we're snapped to the X axis
            global SS_snapDeviation := SS_snapDeviation + smoothedY
            if (SS_snapDeviation > 0) {
                global SS_snapDeviation := Max(0, SS_snapDeviation - Abs(smoothedX) * SS_snapRatio)
            } else if (SS_snapDeviation < 0) {
                global SS_snapDeviation := Min(0, SS_snapDeviation + Abs(smoothedX) * SS_snapRatio)
            }
            if (Abs(SS_snapDeviation) > SS_snapThreshold) {  ; Switch to Y axis snap
                smoothedX := 0
                global SS_remainderX := 0
                global SS_snapState := 2
                global SS_snapDeviation := 0.0
                SS_SmoothingWindowsReset()
            } else {  ; Remain snapped to X axis
                smoothedY := 0
                global SS_remainderY := 0
            }
        } else if (SS_snapState = 2) {  ; Snapping is on, and we're snapped to the Y axis
            global SS_snapDeviation := SS_snapDeviation + smoothedX
            if (SS_snapDeviation > 0) {
                global SS_snapDeviation := Max(0, SS_snapDeviation - Abs(smoothedY) * SS_snapRatio)
            } else if (SS_snapDeviation < 0) {
                global SS_snapDeviation := Min(0, SS_snapDeviation + Abs(smoothedY) * SS_snapRatio)
            }
            if (Abs(SS_snapDeviation) > SS_snapThreshold) {  ; Switch to X axis snap
                smoothedY := 0
                global SS_remainderY := 0
                global SS_snapState := 1
                global SS_snapDeviation := 0.0
                SS_SmoothingWindowsReset()
            } else {
                smoothedX := 0
                global SS_remainderX := 0
            }
        }
    }

    ; Apply acceleration (v_out = p * square(min(v_in - r, 0)) + q * (v_in - r) + r)
    if (SS_accelerationOn and ((smoothedX != 0) or (smoothedY != 0))) {
        speed := Sqrt(smoothedX * smoothedX + smoothedY * smoothedY)
        speed_offset := speed - SS_accelerationR
        scale_factor := SS_accelerationQ * speed_offset + SS_accelerationR
        if (speed_offset < 0)
            scale_factor += SS_accelerationP * speed_offset * speed_offset
        scale_factor /= speed
        smoothedX *= scale_factor
        smoothedY *= scale_factor
    }

    ; Apply sensitivity adjustment
    smoothedX *= SS_sensitivity
    smoothedY *= SS_sensitivity

    ; Apply previous rounding errors, and save new rounding errors
    smoothedX += SS_remainderX
    smoothedY += SS_remainderY
    roundedX := Round(smoothedX)
    roundedY := Round(smoothedY)
    global SS_remainderX := smoothedX - roundedX
    global SS_remainderY := smoothedY - roundedY

    ; Send wheel input
    SS_SendWheel(roundedX, roundedY)
}

; ==============================================================================
; CURSOR FUNCTIONS
; ==============================================================================

SS_SetSystemCursor(CursorId := "") {
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
