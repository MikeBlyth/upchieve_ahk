; Communication Manager for UWD Integration
; Handles file-based communication between Chrome extension and AutoHotkey

; Global variables for communication
global CommFilePath := "upchieve_students.txt"
global LastFileContent := ""

; Check for student detection data in the file (non-blocking)
; Returns true if new student data found, false otherwise
CheckForStudents() {
    global LastFileContent, CommFilePath

    if (!FileExist(CommFilePath)) {
        return false
    }

    fileContent := FileRead(CommFilePath)

    ; Check if file has changed and contains student data
    if (fileContent != LastFileContent && InStr(fileContent, "*upchieve") = 1) {
        LastFileContent := fileContent
        return true
    }

    return false
}

; Get current communication file content
GetCommContent() {
    global LastFileContent
    return LastFileContent
}

; Clear communication file content
ClearComm() {
    global CommFilePath, LastFileContent
    try {
        FileDelete(CommFilePath)
    } catch Error as e {
        WriteLog("ERROR: Failed to delete communication file: " . e.Message)
    }
    LastFileContent := ""
}
