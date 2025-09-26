; Header Manager for UWD Integration
; Handles periodic header position detection and click coordinate calculation

; Global variables for header positions
global studentHeaderPos := {x: 0, y: 0}
global helpHeaderPos := {x: 0, y: 0}
global waitTimeHeaderPos := {x: 0, y: 0}
global HeadersFound := false
global HeaderRefreshTimer := 0

; Initialize header management system
; Sets up 1-minute timer for periodic header detection
InitializeHeaderManager(targetWindowID) {
    global ExtensionWindowID

    ; Store window ID for header detection
    ExtensionWindowID := targetWindowID

    WriteLog("Initializing header manager for window ID: " . targetWindowID)

    ; Initial header detection
    RefreshHeaderPositions()

    ; Set up 1-minute timer for periodic refresh
    HeaderRefreshTimer := SetTimer(RefreshHeaderPositions, 60000)  ; 60 seconds = 60000ms
    WriteLog("Header refresh timer started - updates every 60 seconds")
}

; Stop header management system
StopHeaderManager() {
    if (HeaderRefreshTimer) {
        SetTimer(HeaderRefreshTimer, 0)  ; Disable timer
        HeaderRefreshTimer := 0
        WriteLog("Header refresh timer stopped")
    }
}

; Find and cache all header positions
; This function ensures ALL headers are found before proceeding
RefreshHeaderPositions() {
    global StudentHeaderTarget, HelpHeaderTarget, WaitTimeHeaderTarget
    global ExtensionWindowID, studentHeaderPos, helpHeaderPos, waitTimeHeaderPos, HeadersFound

    WriteLog("Refreshing header positions...")

    ; Validate window ID
    if (!WinExist("ahk_id " . ExtensionWindowID)) {
        WriteLog("ERROR: Target window no longer exists - ID: " . ExtensionWindowID)
        HeadersFound := false
        return false
    }

    ; Get window dimensions for search area
    WinGetClientPos(, , &winWidth, &winHeight, ExtensionWindowID)

    ; Define search area for headers (top portion of window)
    headerSearchX1 := 700
    headerSearchY1 := 300
    headerSearchX2 := winWidth - 100
    headerSearchY2 := 500

    WriteLog("Searching for headers in window area: " . headerSearchX1 . "," . headerSearchY1 . " to " . headerSearchX2 . "," . headerSearchY2)

    ; Find Student header
    studentResult := FindText(, , headerSearchX1, headerSearchY1, headerSearchX2, headerSearchY2, 0.1, 0.1, StudentHeaderTarget)
    if (!studentResult) {
        WriteLog("ERROR: Student header not found")
        HeadersFound := false
        return false
    }
    studentHeaderPos := GetUpperLeft(studentResult)
    WriteLog("Student header found at: " . studentHeaderPos.x . "," . studentHeaderPos.y)

    ; Find Help Topic header
    helpResult := FindText(, , headerSearchX1, headerSearchY1, headerSearchX2, headerSearchY2, 0.1, 0.1, HelpHeaderTarget)
    if (!helpResult) {
        WriteLog("ERROR: Help Topic header not found")
        HeadersFound := false
        return false
    }
    helpHeaderPos := GetUpperLeft(helpResult)
    WriteLog("Help Topic header found at: " . helpHeaderPos.x . "," . helpHeaderPos.y)

    ; Find Wait Time header
    waitResult := FindText(, , headerSearchX1, headerSearchY1, headerSearchX2, headerSearchY2, 0.1, 0.1, WaitTimeHeaderTarget)
    if (!waitResult) {
        WriteLog("ERROR: Wait Time header not found")
        HeadersFound := false
        return false
    }
    waitTimeHeaderPos := GetUpperLeft(waitResult)
    WriteLog("Wait Time header found at: " . waitTimeHeaderPos.x . "," . waitTimeHeaderPos.y)

    HeadersFound := true
    WriteLog("SUCCESS: All headers found and cached")
    return true
}

; Calculate click position based on student name and cached header positions
; Returns coordinates object {x, y} for clicking on the student
CalculateClickPosition(studentName) {
    global studentHeaderPos, HeadersFound

    ; Verify headers are available
    if (!HeadersFound) {
        WriteLog("ERROR: Cannot calculate click position - headers not found")
        return {x: 0, y: 0}
    }

    ; Calculate click coordinates based on student header position
    ; Student names appear in rows starting ~95 pixels below the header
    ; Use the first row for now (can be enhanced to search for specific student)
    clickX := studentHeaderPos.x + 100  ; Center of student name column
    clickY := studentHeaderPos.y + 110  ; First student row

    WriteLog("Calculated click position for '" . studentName . "': " . clickX . "," . clickY)
    return {x: clickX, y: clickY}
}

; Get waiting target search zone based on cached header positions
; Returns SearchZone object for waiting indicator detection
GetWaitingSearchZone() {
    global waitTimeHeaderPos, HeadersFound

    if (!HeadersFound) {
        WriteLog("ERROR: Cannot create waiting search zone - headers not found")
        return SearchZone(0, 0, 0, 0)  ; Empty zone
    }

    ; Create search zone based on wait time header position
    ; Wait indicators appear in the wait time column
    zone := SearchZone(
        waitTimeHeaderPos.x,
        waitTimeHeaderPos.y + 95,
        waitTimeHeaderPos.x + 97,
        waitTimeHeaderPos.y + 130
    )

    WriteLog("Waiting search zone: " . zone.ToString())
    return zone
}

; Get student name search zone based on cached header positions
; Returns SearchZone object for student name extraction (if needed)
GetStudentNameSearchZone() {
    global studentHeaderPos, HeadersFound

    if (!HeadersFound) {
        WriteLog("ERROR: Cannot create student name search zone - headers not found")
        return SearchZone(0, 0, 0, 0)  ; Empty zone
    }

    ; Create search zone based on student header position
    zone := SearchZone(
        studentHeaderPos.x,
        studentHeaderPos.y + 95,
        studentHeaderPos.x + 250,
        studentHeaderPos.y + 130
    )

    WriteLog("Student name search zone: " . zone.ToString())
    return zone
}

; Force immediate header refresh (for testing or manual triggers)
ForceHeaderRefresh() {
    WriteLog("Manual header refresh requested")
    return RefreshHeaderPositions()
}

; Get header status information
GetHeaderStatus() {
    global HeadersFound, studentHeaderPos, helpHeaderPos, waitTimeHeaderPos

    status := "Headers Found: " . (HeadersFound ? "YES" : "NO") . "`n"

    if (HeadersFound) {
        status .= "Student Header: " . studentHeaderPos.x . "," . studentHeaderPos.y . "`n"
        status .= "Help Header: " . helpHeaderPos.x . "," . helpHeaderPos.y . "`n"
        status .= "Wait Time Header: " . waitTimeHeaderPos.x . "," . waitTimeHeaderPos.y . "`n"
    }

    return status
}

; Validate that all cached header positions are reasonable
; Returns true if positions look valid, false otherwise
ValidateHeaderPositions() {
    global HeadersFound, studentHeaderPos, helpHeaderPos, waitTimeHeaderPos

    if (!HeadersFound) {
        return false
    }

    ; Check that positions are non-zero and within reasonable screen bounds
    if (studentHeaderPos.x <= 0 || studentHeaderPos.y <= 0 ||
        helpHeaderPos.x <= 0 || helpHeaderPos.y <= 0 ||
        waitTimeHeaderPos.x <= 0 || waitTimeHeaderPos.y <= 0) {
        return false
    }

    ; Check that headers are roughly aligned horizontally (same Y coordinate within tolerance)
    yTolerance := 10
    if (Abs(studentHeaderPos.y - helpHeaderPos.y) > yTolerance ||
        Abs(helpHeaderPos.y - waitTimeHeaderPos.y) > yTolerance) {
        WriteLog("WARNING: Headers not horizontally aligned - may indicate detection error")
        return false
    }

    ; Check that headers are in logical left-to-right order
    if (studentHeaderPos.x >= helpHeaderPos.x || helpHeaderPos.x >= waitTimeHeaderPos.x) {
        WriteLog("WARNING: Headers not in expected left-to-right order")
        return false
    }

    return true
}

; Manual header detection for troubleshooting
; Shows user dialog with header positions
ShowHeaderDebugInfo() {
    headerInfo := GetHeaderStatus()
    isValid := ValidateHeaderPositions() ? "VALID" : "INVALID"

    MsgBox(headerInfo . "`nValidation: " . isValid, "Header Debug Info", "OK 4096")
}