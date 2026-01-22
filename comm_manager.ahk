; Communication Manager for UWD Integration
; Handles HTTP-based communication between Ruby Server and AutoHotkey

; Global variables for communication
global LastDataContent := ""
global LastErrorTime := 0

; Check for student detection data via HTTP (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastDataContent, LastErrorTime
    currentData := ""
    
    try {
        ; Use WinHttpRequest for low-latency local fetching
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "http://localhost:4567/ahk_data", true) ; true = async
        whr.Send()
        whr.WaitForResponse(0.1) ; Wait max 100ms
        
        if (whr.Status == 200) {
            currentData := whr.ResponseText
        } else {
            ; Log non-200 status errors (throttled)
            if (A_TickCount - LastErrorTime > 60000) {
                WriteLog("ERROR: Ruby server returned status " . whr.Status)
                LastErrorTime := A_TickCount
            }
            return false
        }
    } catch Error as e {
        ; Server might be down or busy
        if (A_TickCount - LastErrorTime > 60000) {
            WriteLog("ERROR: Failed to connect to Ruby server: " . e.Message)
            LastErrorTime := A_TickCount
        }
        return false
    }

    ; If data is empty or unchanged, do nothing
    if (currentData == "" || currentData == LastDataContent) {
        return false
    }

    ; It's different. Update our "last seen" value.
    LastDataContent := currentData

    ; Now, is this new value something we should process?
    if (InStr(currentData, "*upchieve") = 1) {
        return true
    }

    return false
}

; Get current communication content
GetCommContent() {
    global LastDataContent
    return LastDataContent
}

; Clear communication content
ClearComm() {
    global LastDataContent
    LastDataContent := ""
}