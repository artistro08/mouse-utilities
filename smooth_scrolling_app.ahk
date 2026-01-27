; ==============================================================================
; Smooth Scrolling App - Trackball Smooth Scrolling Frontend
; ==============================================================================
; This file provides the user-facing hotkey functionality for smooth scrolling.
; It includes the backend API and sets up hotkeys based on configuration.
;
; REFACTORED FOR MOUSE UTILITIES SUITE
; - Config reading updated to use unified config.ini [SmoothScrolling] section
; - Removed individual panic button (use Main panic hotkey instead)
; - Removed admin elevation (handled by MouseUtilities.ahk)
; - Removed NoTrayIcon (handled by MouseUtilities.ahk)
; - All variables prefixed with SSApp_ to prevent namespace conflicts
;
; Original project: https://github.com/Seelge/TrackballScroll
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Include smooth_scrolling_backend.ahk
Persistent

; NOTE: Admin elevation and NoTrayIcon are handled by MouseUtilities.ahk
; This script is designed to be #Include'd, not run standalone

; ==============================================================================
; READ CONFIG
; ==============================================================================
; Read all hotkey settings from the unified config.ini [SmoothScrolling] section.

SSApp_ConfigFile := A_ScriptDir "\config.ini"

SSApp_hotkey1 := IniRead(SSApp_ConfigFile, "SmoothScrolling", "hotkey1")
SSApp_hotkey2 := IniRead(SSApp_ConfigFile, "SmoothScrolling", "hotkey2", "")
SSApp_stopKey := IniRead(SSApp_ConfigFile, "SmoothScrolling", "stopKey", "")
SSApp_panicButton := IniRead(SSApp_ConfigFile, "SmoothScrolling", "panicButton", "")
SSApp_mode := IniRead(SSApp_ConfigFile, "SmoothScrolling", "mode")
SSApp_holdDuration := IniRead(SSApp_ConfigFile, "SmoothScrolling", "holdDuration") + 0

; ==============================================================================
; PANIC BUTTON (Optional - for Smooth Scrolling only)
; ==============================================================================
; NOTE: This panic button only stops smooth scrolling, not the entire suite.
; For full suite termination, use the Main panic hotkey instead.

if (SSApp_panicButton != "")
    Hotkey(SSApp_panicButton, SSApp_PanicFunction)

SSApp_PanicFunction(_) {
    ScrollingDeactivate()  ; Only deactivate smooth scrolling, don't exit
}

; ==============================================================================
; STOP KEY
; ==============================================================================
; Optional key to manually stop smooth scrolling while active.

if (SSApp_stopKey != "") {
    HotIf IsSmoothScrollingActive
    Hotkey(SSApp_stopKey, SSApp_StopFunction)
    HotIf
}

SSApp_StopFunction(_) {
    ScrollingDeactivate()
}

; ==============================================================================
; MODE: ON_OFF
; ==============================================================================
; Smooth scrolling is turned on when hotkey1 is pressed down,
; and turned off when hotkey2 is pressed down.

if (SSApp_mode = "ON_OFF") {
    Hotkey("$" SSApp_hotkey1, SSApp_OnOffKey1Down)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OnOffKey1Up)
    Hotkey("$" SSApp_hotkey2, SSApp_OnOffKey2Down)
    Hotkey("$" SSApp_hotkey2 " Up", SSApp_OnOffKey2Up)

    global SSApp_onOffKey1FlipFlop := false
    global SSApp_onOffKey2FlipFlop := false

    SSApp_OnOffKey1Down(_) {
        global SSApp_onOffKey1FlipFlop
        if (SSApp_onOffKey1FlipFlop)
            return  ; ignore autorepeats
        SSApp_onOffKey1FlipFlop := true
        ScrollingActivate()
    }

    SSApp_OnOffKey2Down(_) {
        global SSApp_onOffKey2FlipFlop
        if (SSApp_onOffKey2FlipFlop)
            return  ; ignore autorepeats
        SSApp_onOffKey2FlipFlop := true
        ScrollingDeactivate()
    }

    SSApp_OnOffKey1Up(_) {
        global SSApp_onOffKey1FlipFlop
        SSApp_onOffKey1FlipFlop := false
    }

    SSApp_OnOffKey2Up(_) {
        global SSApp_onOffKey2FlipFlop
        SSApp_onOffKey2FlipFlop := false
    }
}

; ==============================================================================
; MODE: ONE_KEY_TOGGLE
; ==============================================================================
; Smooth scrolling is toggled when hotkey1 is pressed.
; Original functionality of hotkey1 is blocked.

else if (SSApp_mode = "ONE_KEY_TOGGLE") {
    Hotkey("$" SSApp_hotkey1, SSApp_OneKeyToggleDown)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OneKeyToggleUp)

    global SSApp_oneKeyToggleFlipFlop := false

    SSApp_OneKeyToggleDown(_) {
        global SSApp_oneKeyToggleFlipFlop
        if (SSApp_oneKeyToggleFlipFlop)
            return  ; ignore autorepeats
        SSApp_oneKeyToggleFlipFlop := true
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
        } else {
            ScrollingActivate()
        }
    }

    SSApp_OneKeyToggleUp(_) {
        global SSApp_oneKeyToggleFlipFlop
        SSApp_oneKeyToggleFlipFlop := false
    }
}

; ==============================================================================
; MODE: ONE_KEY_MOMENTARY
; ==============================================================================
; Smooth scrolling is turned on while hotkey1 is held.
; Original functionality of hotkey1 is blocked.

else if (SSApp_mode = "ONE_KEY_MOMENTARY") {
    Hotkey("$" SSApp_hotkey1, SSApp_OneKeyMomentaryDown)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OneKeyMomentaryUp)

    global SSApp_oneKeyMomentaryFlipFlop := false

    SSApp_OneKeyMomentaryDown(_) {
        global SSApp_oneKeyMomentaryFlipFlop
        if (SSApp_oneKeyMomentaryFlipFlop)
            return  ; ignore autorepeats
        SSApp_oneKeyMomentaryFlipFlop := true
        ScrollingActivate()
    }

    SSApp_OneKeyMomentaryUp(_) {
        global SSApp_oneKeyMomentaryFlipFlop
        SSApp_oneKeyMomentaryFlipFlop := false
        ScrollingDeactivate()
    }
}

; ==============================================================================
; MODE: ONE_KEY_TAP_TOGGLE
; ==============================================================================
; Smooth scrolling is toggled when hotkey1 is tapped for shorter than holdDuration.
; Original functionality is retained if hotkey1 is held.

else if (SSApp_mode = "ONE_KEY_TAP_TOGGLE") {
    Hotkey("$" SSApp_hotkey1, SSApp_OneKeyTapToggleDown)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OneKeyTapToggleUp)

    global SSApp_oneKeyTapToggleFlipFlop := false
    global SSApp_oneKeyTapToggleKeyDown := false

    SSApp_OneKeyTapToggleTimer() {
        global SSApp_oneKeyTapToggleKeyDown
        SSApp_oneKeyTapToggleKeyDown := true
        Send("{" SSApp_hotkey1 " down}")
    }

    SSApp_OneKeyTapToggleDown(_) {
        global SSApp_oneKeyTapToggleFlipFlop
        if (SSApp_oneKeyTapToggleFlipFlop)
            return  ; ignore autorepeats
        SSApp_oneKeyTapToggleFlipFlop := true

        SetTimer(SSApp_OneKeyTapToggleTimer, -SSApp_holdDuration)
    }

    SSApp_OneKeyTapToggleUp(_) {
        global SSApp_oneKeyTapToggleFlipFlop, SSApp_oneKeyTapToggleKeyDown
        SSApp_oneKeyTapToggleFlipFlop := false

        SetTimer(SSApp_OneKeyTapToggleTimer, 0)
        if (SSApp_oneKeyTapToggleKeyDown) {
            SSApp_oneKeyTapToggleKeyDown := false
            Send("{" SSApp_hotkey1 " up}")
        } else {
            if IsSmoothScrollingActive() {
                ScrollingDeactivate()
            } else {
                ScrollingActivate()
            }
        }
    }
}

; ==============================================================================
; MODE: ONE_KEY_HOLD_TOGGLE
; ==============================================================================
; Smooth scrolling is toggled when hotkey1 is held for longer than holdDuration.
; Original functionality is retained if hotkey1 is tapped.

else if (SSApp_mode = "ONE_KEY_HOLD_TOGGLE") {
    Hotkey("$" SSApp_hotkey1, SSApp_OneKeyHoldToggleDown)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OneKeyHoldToggleUp)

    global SSApp_oneKeyHoldToggleFlipFlop := false
    global SSApp_oneKeyHoldToggleLock := true

    SSApp_OneKeyHoldToggleTimer() {
        ScrollingActivate()
    }

    SSApp_OneKeyHoldToggleDown(_) {
        global SSApp_oneKeyHoldToggleFlipFlop, SSApp_oneKeyHoldToggleLock
        if (SSApp_oneKeyHoldToggleFlipFlop)
            return  ; ignore autorepeats
        SSApp_oneKeyHoldToggleFlipFlop := true

        if (IsSmoothScrollingActive()) {
            SSApp_oneKeyHoldToggleLock := true
            ScrollingDeactivate()
        } else {
            SSApp_oneKeyHoldToggleLock := false
            SetTimer(SSApp_OneKeyHoldToggleTimer, -SSApp_holdDuration)
        }
    }

    SSApp_OneKeyHoldToggleUp(_) {
        global SSApp_oneKeyHoldToggleFlipFlop
        SSApp_oneKeyHoldToggleFlipFlop := false

        if (SSApp_oneKeyHoldToggleLock)
            return  ; ignore up event after toggle off
        SetTimer(SSApp_OneKeyHoldToggleTimer, 0)
        if (not IsSmoothScrollingActive())
            Send("{" SSApp_hotkey1 " down}{" SSApp_hotkey1 " up}")
    }
}

; ==============================================================================
; MODE: ONE_KEY_HOLD_MOMENTARY
; ==============================================================================
; Smooth scrolling is turned on while hotkey1 is held for longer than holdDuration.
; Original functionality is retained if hotkey1 is tapped.

else if (SSApp_mode = "ONE_KEY_HOLD_MOMENTARY") {
    Hotkey("$" SSApp_hotkey1, SSApp_OneKeyHoldMomentaryDown)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_OneKeyHoldMomentaryUp)

    global SSApp_oneKeyHoldMomentaryFlipFlop := false
    global SSApp_oneKeyHoldMomentaryTapped := true

    SSApp_OneKeyHoldMomentaryTimer() {
        global SSApp_oneKeyHoldMomentaryTapped
        SSApp_oneKeyHoldMomentaryTapped := false
        ScrollingShowCursor()
    }

    SSApp_OneKeyHoldMomentaryDown(_) {
        global SSApp_oneKeyHoldMomentaryFlipFlop, SSApp_oneKeyHoldMomentaryTapped
        if (SSApp_oneKeyHoldMomentaryFlipFlop)
            return  ; ignore autorepeats
        SSApp_oneKeyHoldMomentaryFlipFlop := true

        ScrollingActivate(false)
        SSApp_oneKeyHoldMomentaryTapped := true
        SetTimer(SSApp_OneKeyHoldMomentaryTimer, -SSApp_holdDuration)
    }

    SSApp_OneKeyHoldMomentaryUp(_) {
        global SSApp_oneKeyHoldMomentaryFlipFlop
        SSApp_oneKeyHoldMomentaryFlipFlop := false

        ScrollingDeactivate()
        SetTimer(SSApp_OneKeyHoldMomentaryTimer, 0)
        if (SSApp_oneKeyHoldMomentaryTapped)
            Send("{" SSApp_hotkey1 " down}{" SSApp_hotkey1 " up}")
    }
}

; ==============================================================================
; MODE: TWO_KEY_TAP_TOGGLE
; ==============================================================================
; Smooth scrolling is toggled when hotkey1 and hotkey2 are simultaneously
; tapped for shorter than holdDuration.

else if (SSApp_mode = "TWO_KEY_TAP_TOGGLE") {
    Hotkey("$" SSApp_hotkey1, SSApp_TwoKeyTapToggleKey1Down)
    Hotkey("$" SSApp_hotkey1 " Up", SSApp_TwoKeyTapToggleKey1Up)
    Hotkey("$" SSApp_hotkey2, SSApp_TwoKeyTapToggleKey2Down)
    Hotkey("$" SSApp_hotkey2 " Up", SSApp_TwoKeyTapToggleKey2Up)

    global SSApp_twoKeyTapToggleKey1FlipFlop := false
    global SSApp_twoKeyTapToggleKey2FlipFlop := false
    global SSApp_twoKeyTapToggleKey1State := false
    global SSApp_twoKeyTapToggleKey2State := false
    global SSApp_twoKeyTapToggleTimedOut := false
    global SSApp_twoKeyTapToggleLocked := false

    SSApp_TwoKeyTapToggleTimer() {
        global SSApp_twoKeyTapToggleTimedOut
        SSApp_twoKeyTapToggleTimedOut := true
        if (SSApp_twoKeyTapToggleKey1State) {
            Send("{" SSApp_hotkey1 " down}")
        }
        if (SSApp_twoKeyTapToggleKey2State) {
            Send("{" SSApp_hotkey2 " down}")
        }
    }

    SSApp_TwoKeyTapToggleKey1Down(_) {
        global SSApp_twoKeyTapToggleKey1FlipFlop, SSApp_twoKeyTapToggleKey1State, SSApp_twoKeyTapToggleTimedOut, SSApp_twoKeyTapToggleLocked
        if (SSApp_twoKeyTapToggleKey1FlipFlop)
            return  ; ignore autorepeats
        SSApp_twoKeyTapToggleKey1FlipFlop := true

        SSApp_twoKeyTapToggleKey1State := true
        if (SSApp_twoKeyTapToggleLocked) {
            return
        }
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
            SSApp_twoKeyTapToggleLocked := true
            return
        }
        if (SSApp_twoKeyTapToggleTimedOut) {
            Send("{" SSApp_hotkey1 " down}")
            return
        }
        if (SSApp_twoKeyTapToggleKey2State) {
            SetTimer(SSApp_TwoKeyTapToggleTimer, 0)
            if (not IsSmoothScrollingActive()) {
                ScrollingActivate()
            }
        } else {
            SetTimer(SSApp_TwoKeyTapToggleTimer, -SSApp_holdDuration)
        }
    }

    SSApp_TwoKeyTapToggleKey2Down(_) {
        global SSApp_twoKeyTapToggleKey2FlipFlop, SSApp_twoKeyTapToggleKey2State, SSApp_twoKeyTapToggleTimedOut, SSApp_twoKeyTapToggleLocked
        if (SSApp_twoKeyTapToggleKey2FlipFlop)
            return  ; ignore autorepeats
        SSApp_twoKeyTapToggleKey2FlipFlop := true

        SSApp_twoKeyTapToggleKey2State := true
        if (SSApp_twoKeyTapToggleLocked) {
            return
        }
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
            SSApp_twoKeyTapToggleLocked := true
            return
        }
        if (SSApp_twoKeyTapToggleTimedOut) {
            Send("{" SSApp_hotkey2 " down}")
            return
        }
        if (SSApp_twoKeyTapToggleKey1State) {
            SetTimer(SSApp_TwoKeyTapToggleTimer, 0)
            if (not IsSmoothScrollingActive()) {
                ScrollingActivate()
            }
        } else {
            SetTimer(SSApp_TwoKeyTapToggleTimer, -SSApp_holdDuration)
        }
    }

    SSApp_TwoKeyTapToggleKey1Up(_) {
        global SSApp_twoKeyTapToggleKey1FlipFlop, SSApp_twoKeyTapToggleKey1State, SSApp_twoKeyTapToggleTimedOut, SSApp_twoKeyTapToggleLocked
        SSApp_twoKeyTapToggleKey1FlipFlop := false

        SSApp_twoKeyTapToggleKey1State := false
        if (SSApp_twoKeyTapToggleTimedOut) {
            Send("{" SSApp_hotkey1 " up}")
        } else if ((not IsSmoothScrollingActive()) and (not SSApp_twoKeyTapToggleLocked)) {
            Send("{" SSApp_hotkey1 " down}")
            Send("{" SSApp_hotkey1 " up}")
        }
        if (not SSApp_twoKeyTapToggleKey2State) {
            SetTimer(SSApp_TwoKeyTapToggleTimer, 0)
            SSApp_twoKeyTapToggleTimedOut := false
            SSApp_twoKeyTapToggleLocked := false
        }
    }

    SSApp_TwoKeyTapToggleKey2Up(_) {
        global SSApp_twoKeyTapToggleKey2FlipFlop, SSApp_twoKeyTapToggleKey2State, SSApp_twoKeyTapToggleTimedOut, SSApp_twoKeyTapToggleLocked
        SSApp_twoKeyTapToggleKey2FlipFlop := false

        SSApp_twoKeyTapToggleKey2State := false
        if (SSApp_twoKeyTapToggleTimedOut) {
            Send("{" SSApp_hotkey2 " up}")
        } else if ((not IsSmoothScrollingActive()) and (not SSApp_twoKeyTapToggleLocked)) {
            Send("{" SSApp_hotkey2 " down}")
            Send("{" SSApp_hotkey2 " up}")
        }
        if (not SSApp_twoKeyTapToggleKey1State) {
            SetTimer(SSApp_TwoKeyTapToggleTimer, 0)
            SSApp_twoKeyTapToggleTimedOut := false
            SSApp_twoKeyTapToggleLocked := false
        }
    }
}

; ==============================================================================
; INVALID MODE
; ==============================================================================
; Display an error if an unsupported mode is specified.

else {
    MsgBox("Error: Unsupported mode " SSApp_mode " in config.ini [SmoothScrolling] section.", "Smooth Scrolling Config Error", "Icon!")
}
