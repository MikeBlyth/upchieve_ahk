; Communication Manager for UWD Integration
; Handles clipboard-based communication between Chrome extension and AutoHotkey

; Global variables for communication
global LastClipboardContent := ""

; Check for student detection data in the clipboard (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastClipboardContent

    ; Get current clipboard content
    clipboardContent := ""
    try {
        clipboardContent := A_Clipboard
    } catch Error as e {
        ; Clipboard access failed - ignore and continue
        return false
    }

    ; Check if clipboard has changed and contains student data
    if (clipboardContent != LastClipboardContent && InStr(clipboardContent, "*upchieve") = 1) {
        LastClipboardContent := clipboardContent
;        WriteLog("New student data detected in clipboard: " . SubStr(clipboardContent, 1, 100) . "...")
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