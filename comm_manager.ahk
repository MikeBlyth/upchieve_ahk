; Communication Manager for UWD Integration
; Handles HTTP-based communication between Ruby Server and AutoHotkey

; Global variables for communication
global LastDataContent := ""
global LastErrorTime := 0
global LastServerStatus := "OK"

; Check for student detection data via HTTP (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastDataContent, LastErrorTime, LastServerStatus
    currentData := ""
    
    try {
        startTime := A_TickCount
        
        ; Use WinHttpRequest for low-latency local fetching
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        
        ; Set timeouts: Resolve(500), Connect(500), Send(500), Receive(500)
        whr.SetTimeouts(500, 500, 500, 500)
        
        ; Switch to Synchronous mode (false) for better reliability in simple polling
        whr.Open("GET", "http://127.0.0.1:4567/ahk_data", false)
        
        ; WriteLog("DEBUG: Sending HTTP request...")
        whr.Send()
        
        ; In Sync mode, Send() returns only after completion or error
        status := whr.Status
        elapsed := A_TickCount - startTime
        
        if (status == 200) {
            LastServerStatus := "OK"
            currentData := whr.ResponseText
        } else {
            LastServerStatus := "ERROR"
            ; Log non-200 status errors
            if (A_TickCount - LastErrorTime > 60000) {
                WriteLog("ERROR: Ruby server returned status " . status . " (Time: " . elapsed . "ms)")
                LastErrorTime := A_TickCount
            }
            return false
        }
    } catch Error as e {
        elapsed := A_TickCount - startTime
        ; Server might be down or busy
        if (A_TickCount - LastErrorTime > 60000) {
            WriteLog("ERROR: Connection failed after " . elapsed . "ms. Exception: " . e.Message)
            
            ; Differentiate between timeout and other errors
            if (!InStr(e.Message, "The operation timed out")) {
                 LastServerStatus := "ERROR"
                 MsgBox("⚠️ Connection Failed`n`nCould not connect to the local Ruby server (127.0.0.1:4567).`n`nPlease ensure 'ruby server.rb' is running.", "Server Offline", "IconStop")
            } else {
                 LastServerStatus := "TIMEOUT"
                 WriteLog("DEBUG: Request timed out. Is the Ruby server overloaded or blocked?")
            }
            
            LastErrorTime := A_TickCount
        } else {
            ; Update status even if we don't log to file
            if (InStr(e.Message, "The operation timed out")) {
                LastServerStatus := "TIMEOUT"
            } else {
                LastServerStatus := "ERROR"
            }
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