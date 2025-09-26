; Extension Bridge Functions for UWD Integration
; Handles clipboard communication between Chrome extension and AutoHotkey

; Global variables for extension communication
global ExtensionWindowID := ""
global LastClipboardContent := ""

; Student object structure
class Student {
    __New(name, topic, minutes) {
        this.name := name
        this.topic := topic
        this.minutes := minutes
    }

    ToString() {
        return this.name . " (" . this.topic . ", " . this.minutes . " min)"
    }
}

; Get window ID from extension via clipboard handshake
; Waits for extension to provide window ID in format: *upchieve_windowid|12345
; Returns window ID as string, or empty string if timeout/cancelled
GetWindowIdFromExtension(timeoutSeconds := 30) {
    ; Clear clipboard to ensure fresh data
    A_Clipboard := ""

    ; Show user message
    MsgBox("Enable the UPchieve extension and navigate to the waiting students page.`n`nThe extension will provide the window ID automatically.", "Extension Setup", "OK 4096")

    startTime := A_TickCount
    timeoutMs := timeoutSeconds * 1000

    ; Poll clipboard for window ID
    while (A_TickCount - startTime < timeoutMs) {
        clipContent := A_Clipboard

        ; Check for window ID format: *upchieve_windowid|12345
        if (InStr(clipContent, "*upchieve_windowid|") = 1) {
            parts := StrSplit(clipContent, "|")
            if (parts.Length >= 2) {
                windowId := parts[2]

                ; Validate window ID is numeric and window exists
                if (IsNumber(windowId) && WinExist("ahk_id " . windowId)) {
                    ExtensionWindowID := windowId
                    MsgBox("Window ID " . windowId . " received from extension!", "Extension Connected", "OK 4096")
                    return windowId
                }
            }
        }

        Sleep(100)
    }

    ; Timeout
    MsgBox("Timeout waiting for extension window ID.`n`nPlease ensure the extension is enabled and active on UPchieve.", "Extension Timeout", "OK 4112")
    return ""
}

; Poll clipboard for student detection data
; Blocks until clipboard changes with student data or timeout
; Returns true if student data found, false if timeout
PollClipboardForStudents(timeoutSeconds := 0) {
    startTime := A_TickCount
    timeoutMs := (timeoutSeconds > 0) ? timeoutSeconds * 1000 : 0

    while (true) {
        clipContent := A_Clipboard

        ; Check if clipboard has changed and contains student data
        if (clipContent != LastClipboardContent && InStr(clipContent, "*upchieve|") = 1) {
            LastClipboardContent := clipContent
            return true
        }

        ; Check timeout
        if (timeoutMs > 0 && A_TickCount - startTime > timeoutMs) {
            return false
        }

        Sleep(100)  ; Poll every 100ms
    }
}

; Parse clipboard data into array of Student objects
; Expected format: *upchieve|windowId|name1|topic1|min1|name2|topic2|min2|...
; Returns array of Student objects, empty array if invalid format
ParseStudentArray(clipboardData) {
    students := []

    ; Validate format
    if (InStr(clipboardData, "*upchieve|") != 1) {
        WriteLog("ERROR: Invalid clipboard format - missing *upchieve prefix: " . clipboardData)
        return students
    }

    ; Split by pipe delimiter
    parts := StrSplit(clipboardData, "|")

    ; Need at least 5 parts: *upchieve|windowId|name|topic|minutes
    if (parts.Length < 5) {
        WriteLog("ERROR: Insufficient clipboard data parts: " . parts.Length . " (need at least 5)")
        return students
    }

    ; Validate window ID matches expected
    clipWindowId := parts[2]
    if (ExtensionWindowID != "" && clipWindowId != ExtensionWindowID) {
        WriteLog("WARNING: Window ID mismatch - expected: " . ExtensionWindowID . ", got: " . clipWindowId)
    }

    ; Parse students in groups of 3: name|topic|minutes
    studentCount := 0
    for i in Range(3, parts.Length, 3) {  ; Start at index 3, step by 3
        if (i + 2 <= parts.Length) {
            name := Trim(parts[i])
            topic := Trim(parts[i + 1])
            minutes := Trim(parts[i + 2])

            ; Validate data
            if (name != "" && topic != "") {
                ; Convert minutes to number
                minutesNum := IsNumber(minutes) ? Number(minutes) : 0

                student := Student(name, topic, minutesNum)
                students.Push(student)
                studentCount++

                WriteLog("PARSED: Student " . studentCount . " - " . student.ToString())
            } else {
                WriteLog("WARNING: Skipping invalid student data at index " . i . ": name='" . name . "', topic='" . topic . "'")
            }
        }
    }

    WriteLog("SUCCESS: Parsed " . studentCount . " students from clipboard")
    return students
}

; Select student from array (currently returns first student)
; Future enhancement: priority logic, user selection, etc.
; Returns Student object or empty object if no students
SelectFirstStudent(studentArray) {
    if (studentArray.Length > 0) {
        selectedStudent := studentArray[1]
        WriteLog("SELECTED: " . selectedStudent.ToString())
        return selectedStudent
    } else {
        WriteLog("ERROR: No students to select from array")
        return Student("", "", 0)
    }
}

; Check if student is blocked via block_names.txt
; Returns true if student should be blocked, false otherwise
CheckBlockedNames(student, blockFile := "block_names.txt") {
    ; Return false if no block file exists
    if (!FileExist(blockFile)) {
        return false
    }

    ; Read block file and check each line
    try {
        blockContent := FileRead(blockFile)
        blockLines := StrSplit(blockContent, "`n")

        for lineNum, line in blockLines {
            line := Trim(line)

            ; Skip empty lines and comments
            if (line = "" || InStr(line, ";") = 1) {
                continue
            }

            ; Case-insensitive name matching
            if (InStr(StrLower(student.name), StrLower(line)) > 0) {
                WriteLog("BLOCKED: Student '" . student.name . "' matches blocked pattern '" . line . "'")
                return true
            }
        }
    } catch Error as e {
        WriteLog("ERROR: Failed to read block file " . blockFile . ": " . e.Message)
        return false
    }

    WriteLog("NOT BLOCKED: Student '" . student.name . "' is allowed")
    return false
}

; Monitor clipboard for extension handshake
; Waits for *upchieve_windowid| format to establish connection
; Returns true if handshake successful, false if timeout
WaitForExtensionHandshake(timeoutSeconds := 60) {
    WriteLog("Waiting for extension handshake...")

    windowId := GetWindowIdFromExtension(timeoutSeconds)
    if (windowId != "") {
        WriteLog("Extension handshake successful - Window ID: " . windowId)
        return true
    } else {
        WriteLog("Extension handshake failed - timeout or invalid data")
        return false
    }
}

; Get current clipboard content for debugging
GetClipboardContent() {
    return A_Clipboard
}

; Clear clipboard content
ClearClipboard() {
    A_Clipboard := ""
    LastClipboardContent := ""
}