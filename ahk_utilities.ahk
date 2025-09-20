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
    if (result := FindText(, , zone1.x1, zone1.y1, zone1.x2, zone1.y2, err1, err2, target, 0,1)) {
        searchTime := A_TickCount - startTime
        if (IsObject(stats)) {
            stats.searchTimeMs := searchTime
            stats.foundInZone := "zone1"
        }
        ; Log all successful results
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
            ; Log all successful results
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

; Write message to debug log with timestamp
WriteLog(message) {
    logFile := "debug_log.txt"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "." . Format("{:03d}", A_MSec)
    FileAppend timestamp . " - " . message . "`n", logFile
}
