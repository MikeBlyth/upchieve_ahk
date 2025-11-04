; Communication Manager for UWD Integration
; Handles clipboard-based communication between Chrome extension and AutoHotkey

; Global variables for communication
global LastClipboardContent := ""

; Check for student detection data in the clipboard (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastClipboardContent
    clipboardContent := A_Clipboard

    ; If clipboard is the same as last time, do nothing.
    if (clipboardContent == LastClipboardContent) {
        return false
    }

    ; It's different. Log everything for debugging.
    WriteLog("DEBUG_CHECK: Change detected!")
    WriteLog("DEBUG_CHECK: Current clipboard: '" . clipboardContent . "'")
    WriteLog("DEBUG_CHECK: Last content: '" . LastClipboardContent . "'")

    ; Update our "last seen" value.
    LastClipboardContent := clipboardContent

    ; Now, is this new value something we should process?
    if (InStr(clipboardContent, "*upchieve") = 1) {
        WriteLog("DEBUG_CHECK: New content is valid. Returning true.")
        return true
    }

    WriteLog("DEBUG_CHECK: New content is NOT valid. Returning false.")
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