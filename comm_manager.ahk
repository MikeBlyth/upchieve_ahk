; Communication Manager for UWD Integration
; Handles HTTP-based communication between Ruby Server and AutoHotkey

; Global variables for communication
global LastDataContent := ""
global LastErrorTime := 0
global LastServerStatus := "OK"

; Circuit breaker variables (prevents server degradation if app left running)
global ConsecutiveTimeouts := 0
global MaxTimeoutsBeforeBackoff := 5
global BackoffActive := false
global BackoffRetryTime := 0
global BackoffInterval := 30000  ; 30 seconds between retry attempts

; Check for student detection data via HTTP (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastDataContent, LastErrorTime, LastServerStatus
    global ConsecutiveTimeouts, MaxTimeoutsBeforeBackoff, BackoffActive, BackoffRetryTime, BackoffInterval
    currentData := ""
    whr := ""

    ; Check if in backoff mode
    if (BackoffActive) {
        if (A_TickCount < BackoffRetryTime) {
            ; Still in backoff period, skip polling
            return false
        } else {
            ; Backoff period expired, try to recover
            BackoffActive := false
            ConsecutiveTimeouts := 0
            WriteLog("CIRCUIT BREAKER: Attempting recovery after " . BackoffInterval . "ms backoff")
        }
    }

    try {
        startTime := A_TickCount

        ; Use WinHttpRequest for low-latency local fetching
        whr := ComObject("WinHttp.WinHttpRequest.5.1")

        ; Set timeouts: Resolve(2000), Connect(2000), Send(2000), Receive(2000)
        ; Increased from 500ms to handle occasional server slowness
        whr.SetTimeouts(2000, 2000, 2000, 2000)

        ; Use synchronous mode (false) for reliable polling and automatic connection cleanup
        try {
            whr.Open("GET", "http://127.0.0.1:54567/ahk_data", false)
            whr.Send()

            status := whr.Status
            elapsed := A_TickCount - startTime

            if (status == 200) {
                LastServerStatus := "OK"
                currentData := whr.ResponseText
                ; Success: reset timeout counter
                ConsecutiveTimeouts := 0
            } else {
                LastServerStatus := "ERROR"
                ConsecutiveTimeouts++
                ; Log non-200 status errors
                if (A_TickCount - LastErrorTime > 60000) {
                    WriteLog("ERROR: Ruby server returned status " . status . " (Time: " . elapsed . "ms) [" . ConsecutiveTimeouts . "/" . MaxTimeoutsBeforeBackoff . " timeouts]")
                    LastErrorTime := A_TickCount
                }
                ; Check if we should activate circuit breaker
                if (ConsecutiveTimeouts >= MaxTimeoutsBeforeBackoff) {
                    BackoffActive := true
                    BackoffRetryTime := A_TickCount + BackoffInterval
                    WriteLog("CIRCUIT BREAKER: Activated after " . ConsecutiveTimeouts . " consecutive failures. Backoff for " . BackoffInterval . "ms")
                }
                return false
            }

        } catch Error as e {
            elapsed := A_TickCount - startTime
            ConsecutiveTimeouts++

            ; Server might be down or busy
            if (A_TickCount - LastErrorTime > 60000) {
                WriteLog("ERROR: Connection failed after " . elapsed . "ms. Exception: " . e.Message . " [" . ConsecutiveTimeouts . "/" . MaxTimeoutsBeforeBackoff . " timeouts]")

                ; Differentiate between timeout and other errors
                if (!InStr(e.Message, "The operation timed out")) {
                     LastServerStatus := "ERROR"
                     MsgBox("⚠️ Connection Failed`n`nCould not connect to the local Ruby server (127.0.0.1:54567).`n`nPlease ensure 'ruby server.rb' is running.", "Server Offline", "OK IconError")
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

            ; Check if we should activate circuit breaker
            if (ConsecutiveTimeouts >= MaxTimeoutsBeforeBackoff) {
                BackoffActive := true
                BackoffRetryTime := A_TickCount + BackoffInterval
                WriteLog("CIRCUIT BREAKER: Activated after " . ConsecutiveTimeouts . " consecutive failures. Backoff for " . BackoffInterval . "ms")
            }

            return false
        }
    } catch Error as e {
        ; Fallback catch for the outer try block
        WriteLog("ERROR: Unexpected error in CheckForStudents: " . e.Message)
        ConsecutiveTimeouts++
        if (ConsecutiveTimeouts >= MaxTimeoutsBeforeBackoff) {
            BackoffActive := true
            BackoffRetryTime := A_TickCount + BackoffInterval
            WriteLog("CIRCUIT BREAKER: Activated after " . ConsecutiveTimeouts . " consecutive failures. Backoff for " . BackoffInterval . "ms")
        }
        return false
    } finally {
        ; Explicitly release the HTTP object to close the connection
        whr := ""
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