; Write message to log file with timestamp
; filename parameter is optional - defaults to debug_log.txt for backward compatibility
WriteLog(message, filename := "debug_log.txt") {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "." . Format("{:03d}", A_MSec)
    FileAppend timestamp . " - " . message . "`n", filename
}

GetTargetWindow(message := 'Select window', confirm := true) {
    ; Function to get the target window ID
    ; Window selection and binding
    startupResult := MsgBox(message, "Select Window", "OKCancel 4096")
    if (startupResult = "Cancel") {
        ; Clear any existing FindText window binding before returning
        FindText().BindWindow(0)
        return ""  ; Return empty string if cancelled
    }

    ; Wait for user to click and capture the window
    ; Show tooltip that follows mouse cursor
    while (!GetKeyState("LButton", "P")) {
        MouseGetPos(&mouseX, &mouseY)
        ToolTip "Click on the target window now...", , , 3
        Sleep(50)
    }
    KeyWait("LButton", "U")  ; Wait for button release
    MouseGetPos(&mouseX, &mouseY, &windowID)  ; Get window ID under mouse
    ToolTip "", , , 3  ; Clear tooltip

    ; Bind FindText to the selected window for improved performance and reliability
    ; Mode 4 is essential for proper window targeting
    FindText().BindWindow(windowID, 4)

    if (confirm) {
        boundID := FindText().BindWindow(0, 0, 1, 0)  ; get_id = 1
        boundMode := FindText().BindWindow(0, 0, 0, 1)  ; get_mode = 1
        MsgBox("Target window " . boundID . " in " . boundMode . " mode selected! Starting turn monitor...", "Window Selected", "OK 4096")
    }
    return windowID
}

; SearchStats class for tracking search performance
class SearchStatsClass {
    __New() {
        this.searchTimeMs := 0
        this.foundInZone := "none"
    }
}

; SearchZone class for defining search areas
class SearchZone {
    __New(x1 := 0, y1 := 0, x2 := 0, y2 := 0, width := 0, height := 0) {
        this.x1 := x1
        this.y1 := y1

        ; Use width/height if provided, otherwise use x2/y2
        if (width > 0)
            this.x2 := x1 + width
        else
            this.x2 := x2

        if (height > 0)
            this.y2 := y1 + height
        else
            this.y2 := y2
    }

    ToString() {
        return "SearchZone(" . Round(this.x1) . "," . Round(this.y1) . " to " . Round(this.x2) . "," . Round(this.y2) . ")"
    }
}

; FindText wrapper for multiple search zones
FindTextInZones(target, zone1, zone2 := "", err1 := 0.15, err2 := 0.10, &stats := "", verbose := false) {
    startTime := A_TickCount

    ; Initialize stats if not provided
    if (!IsSet(stats)) {
        stats := SearchStatsClass()
    }

    ; Extract target ID from pattern for logging
    targetId := ""
    if (target != "") {
        ; Extract ID from pattern like "|<WaitingTarget>*123$45.hex..."
        if (RegExMatch(target, "\|<([^>]+)>", &match))
            targetId := match[1]
        else if (RegExMatch(target, "<([^>]+)>", &match))
            targetId := match[1]
        else
            targetId := "Unknown"
    }

    if (verbose) {
        WriteLog("VERBOSE: FindTextInZones - target=" . targetId . " zone1=" . zone1.ToString() . " err1=" . Format("{:.2f}", err1) . " err2=" . Format("{:.2f}", err2))
        if (zone2 != "" && IsObject(zone2))
            WriteLog("VERBOSE: FindTextInZones - zone2=" . zone2.ToString())
    }

    ; Try first zone
    if (result := FindText(, , zone1.x1, zone1.y1, zone1.x2, zone1.y2, err1, err2, target)) {
        searchTime := A_TickCount - startTime
        if (IsObject(stats)) {
            stats.searchTimeMs := searchTime
            stats.foundInZone := "zone1"
        }
        ; Log successful results only if verbose
        if (verbose)
            WriteLog("DEBUG: FindTextInZones - SUCCESS in zone1: found=" . result[1].id . " at " . result[1].x . "," . result[1].y . " searchTime=" . searchTime . "ms")
        return result
    }

    ; Try second zone if provided
    if (zone2 != "" && IsObject(zone2)) {
        if (result := FindText(, , zone2.x1, zone2.y1, zone2.x2, zone2.y2, err1, err2, target)) {
            searchTime := A_TickCount - startTime
            if (IsObject(stats)) {
                stats.searchTimeMs := searchTime
                stats.foundInZone := "zone2"
            }
            ; Log successful results only if verbose
            if (verbose)
                WriteLog("DEBUG: FindTextInZones - SUCCESS in zone2: found=" . result[1].id . " at " . result[1].x . "," . result[1].y . " searchTime=" . searchTime . "ms")
            return result
        }
    }

    searchTime := A_TickCount - startTime
    if (IsObject(stats)) {
        stats.searchTimeMs := searchTime
        stats.foundInZone := "none"
    }
    if (verbose)
        WriteLog("VERBOSE: FindTextInZones - NOT FOUND: target=" . targetId . " searchTime=" . searchTime . "ms")
    return 0
}

; Find and click on a target string within specified coordinates
; If coordinates not provided, uses the active window's dimensions
; Returns: Object with found location if successful, 0 if not found
FindAndClick(TargetString, x1 := "", y1 := "", x2 := "", y2 := "", err1 := 0.15, err2 := 0.10) {
    ; Save current coordinate modes
    originalMouseMode := A_CoordModeMouse
    originalPixelMode := A_CoordModePixel

    ; Set coordinate modes to screen for FindText compatibility
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")

    ; Get active window position for coordinate conversion
    activeWindow := WinGetID("A")
    WinGetPos(&winX, &winY, &winWidth, &winHeight, "ahk_id " . activeWindow)
    WriteLog("FindAndClick: Window at (" . winX . "," . winY . ") size " . winWidth . "x" . winHeight)

    ; Convert window coordinates to screen coordinates
    if (x1 == "" || y1 == "" || x2 == "" || y2 == "") {
        ; Use full window dimensions if coordinates not provided
        x1 := (x1 != "") ? x1 + winX : winX
        y1 := (y1 != "") ? y1 + winY : winY
        x2 := (x2 != "") ? x2 + winX : winX + winWidth
        y2 := (y2 != "") ? y2 + winY : winY + winHeight
        WriteLog("FindAndClick: Using full window - window coords (0,0 to " . winWidth . "," . winHeight . ") -> screen coords (" . x1 . "," . y1 . " to " . x2 . "," . y2 . ")")
    } else {
        ; Convert provided window coordinates to screen coordinates
        origX1 := x1, origY1 := y1, origX2 := x2, origY2 := y2
        x1 := x1 + winX
        y1 := y1 + winY
        x2 := x2 + winX
        y2 := y2 + winY
        WriteLog("FindAndClick: Converting provided coords - window coords (" . origX1 . "," . origY1 . " to " . origX2 . "," . origY2 . ") -> screen coords (" . x1 . "," . y1 . " to " . x2 . "," . y2 . ")")
    }

    result := FindText(, , x1, y1, x2, y2, err1, err2, TargetString)

    if (result) {
        ; Click at the found location (already in screen coordinates)
        Click result[1].x, result[1].y
        WriteLog("FindAndClick: Clicked target at screen coords " . result[1].x . "," . result[1].y)
    } else {
        WriteLog("FindAndClick: Target not found in screen search area (" . x1 . "," . y1 . " to " . x2 . "," . y2 . ")")
    }

    ; Restore original coordinate modes
    CoordMode("Mouse", originalMouseMode)
    CoordMode("Pixel", originalPixelMode)

    return result
}

