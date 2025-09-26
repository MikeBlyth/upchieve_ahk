
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

; Check clipboard for student detection data (non-blocking)
; Returns true if new student data found, false otherwise
CheckClipboardForStudents() {
    global LastClipboardContent
    clipContent := A_Clipboard

    ; Check if clipboard has changed and contains student data
    if (clipContent != LastClipboardContent && InStr(clipContent, "*upchieve|") = 1) {
        LastClipboardContent := clipContent
        return true
    }

    return false
}

; Parse clipboard data into array of Student objects
; Expected format: *upchieve|name1|topic1|min1|name2|topic2|min2|...
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

    ; Need at least 4 parts for one student: *upchieve|name|topic|minutes
    if (parts.Length < 4) {
        WriteLog("ERROR: Insufficient clipboard data parts for a student: " . parts.Length . " (need at least 4)")
        return students
    }

    ; Parse students in groups of 3: name|topic|minutes
    studentCount := 0
    i := 2  ; Start at index 2 (after *upchieve)
    while (i <= parts.Length) {
        if (i + 2 <= parts.Length) {
            name := Trim(parts[i])
            topic := Trim(parts[i + 1])
            minutes := Trim(parts[i + 2])

            ; Validate data
            if (name != "" && topic != "") {
                ; Convert minutes to number
                minutesNum := IsNumber(minutes) ? Number(minutes) : 0

                studentObj := Student(name, topic, minutesNum)
                students.Push(studentObj)
                studentCount++

                WriteLog("PARSED: Student " . studentCount . " - " . studentObj.ToString())
            } else {
                WriteLog("WARNING: Skipping invalid student data at index " . i . ": name='" . name . "', topic='" . topic . "'")
            }
        }
        i += 3  ; Move to next student (step by 3)
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

; Get current clipboard content for debugging
GetClipboardContent() {
    return A_Clipboard
}

; Clear clipboard content
ClearClipboard() {
    A_Clipboard := ""
    LastClipboardContent := ""
}
