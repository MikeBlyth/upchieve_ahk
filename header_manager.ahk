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
}

; Start header refresh timer
StartHeaderRefreshTimer() {
    SetTimer(RefreshHeaderPositions, 15000)  ; 60 seconds = 60000ms
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
    static lastStudentHeaderPos := "" ; Persists between calls

    WriteLog("Refreshing header positions...")

    ; Validate window ID
    if (!WinExist("ahk_id " . ExtensionWindowID)) {
        WriteLog("ERROR: Target window no longer exists - ID: " . ExtensionWindowID)
        HeadersFound := false
        return false
    }

    ; 1. Try narrow search around last known position
    if (IsObject(lastStudentHeaderPos)) {
        narrowX1 := lastStudentHeaderPos.x - 50
        narrowY1 := lastStudentHeaderPos.y - 50
        narrowX2 := lastStudentHeaderPos.x + 200 ; Approx width of header (71px) + 50px buffer either side
        narrowY2 := lastStudentHeaderPos.y + 100 ; Approx height of header (25px) + 50px buffer either side
        WriteLog("Searching in narrow zone first: " . narrowX1 . "," . narrowY1 . " to " . narrowX2 . "," . narrowY2)

        studentResult := FindText(, , narrowX1, narrowY1, narrowX2, narrowY2, 0.1, 0.1, StudentHeaderTarget)
        if (studentResult) {
            studentHeaderPos := GetUpperLeft(studentResult)
            lastStudentHeaderPos := studentHeaderPos ; Update last known position
            HeadersFound := true
;            WriteLog("SUCCESS: Student header found in narrow zone at: " . studentHeaderPos.x . "," . studentHeaderPos.y)
            return true
        }
    }

    ; 2. Perform wide search if not found in narrow zone
    WriteLog("Searching for Student header in wide area (full window)...")

    studentResult := FindText(, , 0, 0, 3000,2000, 0.1, 0.1, StudentHeaderTarget)
    if (!studentResult) {
        WriteLog("ERROR: Student header not found in wide search either.")
        
        ; Capture a debug screenshot
        debugFile := A_ScriptDir . "\debug_header_search.png"
        try {
            FindText().SavePic(debugFile, 0, 0, 3000,2000, 1)
            WriteLog("DEBUG: Saved screenshot of window for debugging to: " . debugFile)
        } catch as e {
            WriteLog("ERROR: Failed to save debug screenshot: " . e.Message)
        }

        HeadersFound := false
        return false
    }
    
    ; If found in wide search, update positions for next time
    studentHeaderPos := GetUpperLeft(studentResult)
    lastStudentHeaderPos := studentHeaderPos ; Store for next time
    HeadersFound := true
    WriteLog("SUCCESS: Student header found in wide search at: " . studentHeaderPos.x . "," . studentHeaderPos.y)
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