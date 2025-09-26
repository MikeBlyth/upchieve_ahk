; Header Manager for UWD Integration
; Handles periodic header position detection and click coordinate calculation

#Include FindTextv2.ahk
#Include ahk_utilities.ahk

; Global variables for header positions
global studentHeaderPos := {x: 0, y: 0}
global HeadersFound := false

; Simple function to convert FindText center coordinates to upper-left coordinates
; Simplified for window coordinate system
GetUpperLeft(result) {
    ; Extract upper-left coordinates directly from FindText result object
    return {x: result[1].1, y: result[1].2}
}


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
    StartHeaderRefreshTimer()
    WriteLog("Header refresh timer started - updates every 60 seconds")
}

; Start header refresh timer
StartHeaderRefreshTimer() {
    SetTimer(RefreshHeaderPositions, 60000)  ; 60 seconds = 60000ms
}

; Stop header management system
StopHeaderManager() {
    StopHeaderRefreshTimer()
}

; Stop header refresh timer
StopHeaderRefreshTimer() {
    SetTimer(RefreshHeaderPositions, 0)  ; Disable timer
    WriteLog("Header refresh timer stopped")
}

; Find and cache student header position
; Only needs Student header for click coordinate calculation
RefreshHeaderPositions() {
    global StudentHeaderTarget
    global ExtensionWindowID, studentHeaderPos, HeadersFound

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

    WriteLog("Searching for Student header in window area: " . headerSearchX1 . "," . headerSearchY1 . " to " . headerSearchX2 . "," . headerSearchY2)

    ; Find Student header only
    studentResult := FindText(, , headerSearchX1, headerSearchY1, headerSearchX2, headerSearchY2, 0.1, 0.1, StudentHeaderTarget)
    if (!studentResult) {
        WriteLog("ERROR: Student header not found")
        HeadersFound := false
        return false
    }
    studentHeaderPos := GetUpperLeft(studentResult)
    WriteLog("Student header found at: " . studentHeaderPos.x . "," . studentHeaderPos.y)

    HeadersFound := true
    WriteLog("SUCCESS: Student header found and cached")
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

; Note: Search zones not needed for integrated system
; Extension provides all student data - only need click coordinates

; Force immediate header refresh (for testing or manual triggers)
ForceHeaderRefresh() {
    WriteLog("Manual header refresh requested")
    return RefreshHeaderPositions()
}

; Get header status information
GetHeaderStatus() {
    global HeadersFound, studentHeaderPos

    status := "Student Header Found: " . (HeadersFound ? "YES" : "NO") . "`n"

    if (HeadersFound) {
        status .= "Student Header Position: " . studentHeaderPos.x . "," . studentHeaderPos.y . "`n"
    }

    return status
}

; Validate that cached header position is reasonable
; Returns true if position looks valid, false otherwise
ValidateHeaderPositions() {
    global HeadersFound, studentHeaderPos

    if (!HeadersFound) {
        return false
    }

    ; Check that position is non-zero and within reasonable screen bounds
    if (studentHeaderPos.x <= 0 || studentHeaderPos.y <= 0) {
        return false
    }

    ; Check that position is within expected range (not off-screen)
    if (studentHeaderPos.x > 2000 || studentHeaderPos.y > 1500) {
        WriteLog("WARNING: Student header position seems unusually large")
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