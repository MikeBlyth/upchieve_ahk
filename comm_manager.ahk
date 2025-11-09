; Communication Manager for UWD Integration
; Handles clipboard-based communication between Chrome extension and AutoHotkey

; Global variables for communication
global LastClipboardContent := ""

; Check for student detection data in the clipboard (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastClipboardContent
    clipboardContent := ""
    try {
        clipboardContent := A_Clipboard
    } catch Error as e {
        WriteLog("ERROR: Failed to read clipboard: " . e.Message)
        return false
    }

    ; If clipboard is the same as last time, do nothing.
    if (clipboardContent == LastClipboardContent) {
        return false
    }

    ; It's different. Update our "last seen" value.
    LastClipboardContent := clipboardContent

    ; Now, is this new value something we should process?
    if (InStr(clipboardContent, "*upchieve") = 1) {
        return true
    }

    return false
}

; Get current communication content (from clipboard)
GetCommContent() {
    global LastClipboardContent
    return LastClipboardContent
}

; Clear communication content (clear clipboard)
ClearComm() {
    global LastClipboardContent
    try {
        A_Clipboard := ""
;        WriteLog("Clipboard cleared")
    } catch Error as e {
        WriteLog("ERROR: Failed to clear clipboard: " . e.Message)
    }
    LastClipboardContent := ""
}