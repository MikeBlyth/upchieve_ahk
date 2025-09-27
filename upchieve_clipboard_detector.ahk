#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include student_database.ahk
#Include ahk_utilities.ahk
#include search_targets.ahk
#Include comm_manager.ahk
#Include header_manager.ahk

; Set coordinate mode to window coordinates for unified coordinate system
CoordMode("Mouse", "Window")
CoordMode("Pixel", "Window")

; UPchieve Integrated Student Detector
; Combines browser extension detection with AutoHotkey automation
; Hotkeys: Ctrl+Shift+Q to quit, Ctrl+Shift+H to pause/resume, Ctrl+Shift+A to manual session end

; Application state variables
global LiveMode := false
global ScanMode := false
global modeText := "TESTING"
global AppState := "STARTING"  ; STARTING, WAITING_FOR_STUDENTS, IN_SESSION, PAUSED

; Header manager variables (from included file)
global HeaderRefreshTimer := 0

; Session tracking variables
global InSession := false
global LastStudentName := ""
global LastStudentTopic := ""
global SessionStartTime := ""
global SessionEndTime := ""

; Window dimensions
global winWidth := 3200
global winHeight := 2000

; Statistics tracking
global SearchStats := SearchStatsClass()
global SoundTimerFunc := ""

; Hotkey handlers
^+q::CleanExit()  ; Ctrl+Shift+Q to quit
^+h::TogglePause()  ; Ctrl+Shift+H to pause/resume
^+a::HandleManualSessionToggle()  ; Ctrl+Shift+A to manually start/end session
^+d::ShowDebugInfo()  ; Ctrl+Shift+D for debug information

; Function to play notification sound
PlayNotificationSound() {
    SoundBeep(800, 500)  ; 800Hz beep for 500ms
}

; App log function for session data in CSV format
WriteAppLog(message) {
    logFile := "upchieve_app.log"

    ; Create header if file doesn't exist
    if (!FileExist(logFile)) {
        header := "Seq,,RTime,Time,Until,W,Name,Grd,Fav,Assgn,Subject,Topic,Math,Duration,Initial response,Serious question,Left abruptly,Stopped resp,Good progress,Last msg,Comments" . "`n"
        FileAppend(header, logFile)
    }

    FileAppend(message . "`n", logFile)
}


; App log function for scan data
WriteScanLog(message) {
    FileAppend(message . "`n", "scan.log")
}

; Clean exit function
CleanExit() {
    WriteLog("Application exit requested")

    ; Clear tooltips
    ToolTip ""

    ; Show exit message
    MsgBox("UPchieve Integrated Detector closed.", "Application Exit", "OK 4096")
    ExitApp
}

; Toggle pause/resume functionality
TogglePause() {
    WriteLog("Application paused via hotkey.")
    MsgBox("UPchieve Detector Paused`n`nPress OK to resume.", "Detection Paused", "OK 4096")
    WriteLog("Application resumed.")
}

; Manually start or end a session via hotkey
HandleManualSessionToggle() {
    global InSession

    if (InSession) {
        WriteLog("Manual session end requested via hotkey")
        EndCurrentSession()
    } else {
        WriteLog("Manual session start requested via hotkey")
        ; Start a session with an empty student object;
        ; the user will fill in the details in the dialog.
        StartSession(Student("", "", 0))
    }
}

; Show debug information
ShowDebugInfo() {
    debugInfo := "=== UPchieve Integrated Detector Debug ===`n`n"
    debugInfo .= "App State: " . AppState . "`n"
    debugInfo .= "Mode: " . modeText . "`n"
    debugInfo .= "In Session: " . (InSession ? "YES" : "NO") . "`n"
    debugInfo .= "Window ID: " . (ExtensionWindowID ? ExtensionWindowID : "Not Set") . "`n`n"

    debugInfo .= GetHeaderStatus()
    debugInfo .= "`nComm File Content: " . SubStr(GetCommContent(), 1, 100) . "..."

    MsgBox(debugInfo, "Debug Information", "OK 4096")
}

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

; Parse data into array of Student objects
; Expected format: *upchieve|name1|topic1|min1|name2|topic2|min2|...
; Returns array of Student objects, empty array if invalid format
ParseStudentArray(data) {
    students := []

    ; Validate format
    if (InStr(data, "*upchieve") != 1) {
        WriteLog("ERROR: Invalid data format - missing *upchieve prefix: " . data)
        return students
    }

    ; Split by pipe delimiter
    parts := StrSplit(data, "|")

    ; Need at least 4 parts for one student: *upchieve|name|topic|minutes
    if (parts.Length < 4) {
        WriteLog("ERROR: Insufficient data parts for a student: " . parts.Length . " (need at least 4)")
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

    WriteLog("SUCCESS: Parsed " . studentCount . " students from data")
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


; Find the Upchieve window by exact title
FindUpchieveWindow() {
    global ExtensionWindowID

    WriteLog("Searching for Upchieve window...")
    ExtensionWindowID := WinExist("Upchieve")

    if (ExtensionWindowID) {
        WriteLog("Found Upchieve window with ID: " . ExtensionWindowID)
        return true
    } else {
        WriteLog("Upchieve window not found.")
        MsgBox("Could not find the 'Upchieve' window.`n`nPlease ensure the UPchieve page is open in your browser and the window title is exactly 'Upchieve'.", "Window Not Found", "OK 4112")
        return false
    }
}


; Summarize student based on upchieve_app.log
SummarizeStudent(name) {
    logFile := "upchieve_app.log"
    
    ; Check if log file exists
    if (!FileExist(logFile) || name == "") {
        return "No previous session history."
    }
    
    try {
        fileContent := FileRead(logFile)
        lines := StrSplit(fileContent, "`n", "`r")
        
        studentEntries := []
        
        ; Parse CSV lines (skip header and non-CSV lines)
        for index, line in lines {
            if (index == 1 || InStr(line, "Upchieve Detector") || Trim(line) == "") {
                continue  ; Skip header and log messages
            }
            
            ; Split CSV line
            fields := StrSplit(line, ",")
            if (fields.Length < 21) {
                continue  ; Skip malformed lines
            }
            
            ; Extract relevant fields (1-indexed CSV columns)
            studentName := Trim(fields[7])   ; Column 7: Name
            date := Trim(fields[2])          ; Column 2: RTime (date)
            subject := Trim(fields[11])      ; Column 11: Subject
            topic := Trim(fields[12])        ; Column 12: Topic
            duration := Trim(fields[14])     ; Column 14: Duration
            goodProgress := Trim(fields[19]) ; Column 19: Good progress
            comments := Trim(fields[21])     ; Column 21: Comments
            
            ; Check if this entry matches the student name (case-insensitive)
            if (StrLower(studentName) == StrLower(name) && studentName != "") {
                studentEntries.Push({
                    date: date,
                    subject: subject,
                    topic: topic,
                    duration: duration,
                    goodProgress: goodProgress,
                    comments: comments
                })
            }
        }
        
        ; Sort entries by date in reverse chronological order
        if (studentEntries.Length > 1) {
            studentEntries.Sort(CompareDates)
        }
        
        ; Build summary (up to 5 most recent visits)
        summary := ""
        maxEntries := Min(5, studentEntries.Length)
        
        for i, entry in studentEntries {
            if (i > maxEntries) {
                break
            }
            
            ; Format: {date}\t{subject}: {topic} ({goodProgress}, {duration} min). {comments}
            line := entry.date . "`t"
            if (entry.subject != "") {
                line .= entry.subject
            }
            if (entry.topic != "") {
                line .= ": " . entry.topic
            }
            line .= " (" . entry.goodProgress . ", " . entry.duration . " min)"
            if (entry.comments != "") {
                line .= ". " . entry.comments
            }
            summary .= line . "`n"
        }
        
        return (studentEntries.Length > 0) ? summary : name . "`nNo sessions found."
        
    } catch Error as e {
        return name . "`nError reading log file: " . e.Message
    }
}

; Helper function to compare dates for sorting
; Returns: >0 if date1 < date2, <0 if date1 > date2, 0 if equal (for reverse chronological sort)
CompareDates(entryA, entryB) {
    ; Convert MM/d/yy to comparable format YYYYMMDD
    ConvertDate(dateStr) {
        if (RegExMatch(dateStr, "(\d{1,2})/(\d{1,2})/(\d{2})", &match)) {
            month := Format("{:02d}", Integer(match[1]))
            day := Format("{:02d}", Integer(match[2]))
            year := "20" . match[3]  ; Assume 20xx
            return year . month . day
        }
        return "00000000"  ; Invalid date sorts to beginning
    }
    
    numA := Integer(ConvertDate(entryA.date))
    numB := Integer(ConvertDate(entryB.date))
    
    ; Return negative if A should come after B (reverse order)
    return numB - numA
}

SoundMuted() {
    global winWidth, winHeight
    return FindText(,, winWidth-700, winHeight-100, winWidth, winHeight, 0.1, 0.1, MutedTarget)
}

; Main application entry point
Main() {
    global LiveMode
    WriteLog("`n=== UPchieve Integrated Detector Started ===")

    ; Show startup dialog for mode selection
    if (!ShowStartupDialog()) {
        WriteLog("User cancelled startup - exiting")
        CleanExit()
    }

    ; Find the Upchieve window
    if (!FindUpchieveWindow()) {
        CleanExit()
    }

    if (LiveMode) {
        while SoundMuted() {
            MsgBox("The Upchieve window appears to be muted. Please unmute the tab in your browser and click OK to continue.", "Tab Muted", "OK 4112")
            WriteLog("Waiting for user to unmute the Upchieve tab...")
        }
    }
    ; Bind FindText to the Upchieve window
    WriteLog("Binding FindText to window ID: " . ExtensionWindowID)
    FindText().BindWindow(ExtensionWindowID, 4)

    ; Perform initial header detection
    if (!RefreshHeaderPositions()) {
        WriteLog("Initial header detection failed - exiting")
        MsgBox("Failed to detect page headers.`n`nPlease ensure you're on the UPchieve 'Waiting Students' page with the table visible.", "Header Detection Failed", "OK 4112")
        CleanExit()
    }

    WriteLog("Initialization complete - starting main detection loop")
    AppState := "WAITING_FOR_STUDENTS"

    ; Start main detection loop
    MainDetectionLoop()
}

; Main detection loop - non-blocking poll for clipboard and periodic header refresh
MainDetectionLoop() {
    global AppState, LiveMode, modeText
    lastHeaderCheckTime := A_TickCount
    headerCheckInterval := 60 * 1000  ; 60 seconds

    WriteLog("Starting main detection loop in " . modeText . " mode")

    while (true) {
        ; Handle different application states
        if (AppState == "PAUSED") {
            ToolTip "⏸️ PAUSED - Press Ctrl+Shift+H to resume", 10, 10, 1
            Sleep(1000)
            continue
        }

        if (AppState == "IN_SESSION") {
            ; Monitor for session end
            MonitorSessionEnd()
            Sleep(2000)  ; Check every 2 seconds during session
            continue
        }

        if (AppState != "WAITING_FOR_STUDENTS") {
            ; Unknown state - reset to waiting
            WriteLog("Unknown app state: " . AppState . " - resetting to WAITING_FOR_STUDENTS")
            AppState := "WAITING_FOR_STUDENTS"
        }

        ToolTip "⏳ Waiting for students... (" . modeText . " mode)", 10, 10, 1

        ; 1. Check for headers periodically
        if (A_TickCount - lastHeaderCheckTime > headerCheckInterval) {
            WriteLog("Periodic header refresh triggered.")
            RefreshHeaderPositions()
            lastHeaderCheckTime := A_TickCount
        }

        ; 2. Check for students from the communication file
        if (CheckForStudents()) {
            ProcessStudentData()
        }

        ; Sleep to keep the loop efficient
        Sleep(250)
    }
}

; Process student data from the communication file
ProcessStudentData() {
    global AppState, LiveMode, InSession, LastStudentName, LastStudentTopic, SessionStartTime

    WriteLog("Processing student data from communication file...")

    ; Get content from communication file and parse students
    commData := GetCommContent()
    students := ParseStudentArray(commData)

    if (students.Length == 0) {
        WriteLog("No valid students found in communication file data")
        return
    }

    ; Handle Scan Mode separately
    if (ScanMode) {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        for index, student in students {
            logMessage := timestamp . " | SCAN: " . student.name . " (" . student.topic . ")"
            WriteScanLog(logMessage)
        }
        ToolTip "📈 SCAN: Logged " . students.Length . " students to scan.log", 10, 50, 2
        SetTimer(() => ToolTip("", , , 2), -5000)
        ClearComm() ; Clear communication file after processing
        return ; Exit function after logging
    }

    ; Select first student (future: implement selection logic)
    selectedStudent := SelectFirstStudent(students)
    if (selectedStudent.name == "") {
        WriteLog("No student selected from array")
        return
    }

    WriteLog("Selected student: " . selectedStudent.ToString())

    ; Check if student is blocked
    if (CheckBlockedNames(selectedStudent)) {
        WriteLog("Student blocked - skipping: " . selectedStudent.name)
        ToolTip "🚫 Blocked student: " . selectedStudent.name, 10, 50, 2
        SetTimer(() => ToolTip("", , , 2), -5000)
        return
    }

    ; Calculate click position
    clickPos := CalculateClickPosition(selectedStudent.name)
    if (clickPos.x == 0 || clickPos.y == 0) {
        WriteLog("Failed to calculate click position - skipping student")
        return
    }

    ; Perform click action based on mode
    if (LiveMode) {
        ; LIVE mode - actually click the student
        WriteLog("LIVE MODE: Clicking student at " . clickPos.x . "," . clickPos.y)

        ; Activate window and click
        WinActivate("ahk_id " . ExtensionWindowID)
        WinWaitActive("ahk_id " . ExtensionWindowID, , 2)
        Click(clickPos.x, clickPos.y)

        ; Start session
        StartSession(selectedStudent)

    } else {
        ; TESTING mode - log detection without clicking
        WriteLog("TESTING MODE: Would click student " . selectedStudent.name . " at " . clickPos.x . "," . clickPos.y)
        ToolTip "🧪 Testing: Found " . selectedStudent.name . " (" . selectedStudent.topic . ")", 10, 50, 2
        SetTimer(() => ToolTip("", , , 2), -5000)
    }

    ; Clear the communication file now that it has been processed
    ClearComm()
}

; Start a session with the selected student
StartSession(student) {
    global InSession, AppState, LastStudentName, LastStudentTopic, SessionStartTime, SoundTimerFunc

    WriteLog("Starting session with: " . student.ToString())

    ; Update session variables from extension data first
    InSession := true
    AppState := "IN_SESSION"
    LastStudentName := student.name
    LastStudentTopic := student.topic
    SessionStartTime := A_Now

    ; Maximize window for session
    WinMaximize("ahk_id " . ExtensionWindowID)

    ; Get student summary and pass it to the dialog via static var
    ShowSessionStartDialog.lastSessionInfo := SummarizeStudent(student.name)

    ; Start repeating notification sound
    PlayNotificationSound() ; Play once immediately
    SoundTimerFunc := () => PlayNotificationSound()
    SetTimer(SoundTimerFunc, 2000)
    ; Keep sounding alert until user clicks OK on msgbox
    MsgBox("Session started with " . student.name . "(" . student.topic . ") \nClick to confirm", "Session Started", "OK 4096")

    ; Stop the notification
    if (SoundTimerFunc) {
        SetTimer(SoundTimerFunc, 0)
        SoundTimerFunc := ""
    }

    ; Show session start dialog for confirmation/correction
    ShowSessionStartDialog()

    ; Show session notification with potentially updated info
    sessionMsg := "📚 Session started with " . LastStudentName
    if (LastStudentTopic != "") {
        sessionMsg .= " (" . LastStudentTopic . ")"
    }
    ToolTip sessionMsg, 10, 10, 1

    WriteLog("Session started - monitoring for session end. Final student: " . LastStudentName)
}

; Monitor for session end by searching the entire window for the target
MonitorSessionEnd() {
    global ExtensionWindowID, InSession, SessionEndedTarget

    WriteLog("Monitoring for session end...")

    ; Get window dimensions for search area
    WinGetClientPos(, , &winWidth, &winHeight, ExtensionWindowID)
    
    ; Search the entire window for the session ended target
    if (FindText(, , 0, 0, winWidth, winHeight, 0.1, 0.1, SessionEndedTarget)) {
        WriteLog("SessionEndedTarget found. Ending session.")
        EndCurrentSession()
    }
}

; End the current session
EndCurrentSession() {
    global InSession, AppState, SoundTimerFunc

    WriteLog("Ending current session")

    ; Stop notification sound
    if (SoundTimerFunc) {
        SetTimer(SoundTimerFunc, 0)
        SoundTimerFunc := ""
    }

    ; Show session feedback dialog
    feedbackResult := ShowSessionFeedbackDialog()

    ; Handle feedback result (modified to not restart script)
    if (feedbackResult == "Restart" || feedbackResult == "Continue") {
        ; Reset to waiting state (no script restart needed)
        InSession := false
        AppState := "WAITING_FOR_STUDENTS"
        ToolTip "⏳ Session ended - waiting for next student", 10, 10, 1
        WriteLog("Session ended - continuing monitoring")

    } else if (feedbackResult == "Cancel") {
        ; Pause the application
        InSession := false
        AppState := "PAUSED"
        ToolTip "⏸️ Session ended - application paused", 10, 10, 1
        WriteLog("Session ended - application paused")

    } else {
        ; Exit application
        WriteLog("Session ended - user chose to exit")
        CleanExit()
    }
}

; Show startup dialog for mode selection
ShowStartupDialog() {
    global LiveMode, ScanMode, modeText

    ; Create startup GUI
    startupGui := Gui("+AlwaysOnTop", "UPchieve Integrated Detector - Setup")
    startupGui.AddText("xm y+10", "UPchieve Integrated Detector")
    startupGui.AddText("xm y+5", "Choose operation mode:")

    ; Mode selection radio buttons
    testingRadio := startupGui.AddRadio("xm y+15 Checked", "TESTING Mode (detect only, no clicking)")
    liveRadio := startupGui.AddRadio("xm y+5", "LIVE Mode (click students automatically)")
    scanRadio := startupGui.AddRadio("xm y+5", "SCAN Mode (timing analysis only)")

    ; Information text
    startupGui.AddText("xm y+15 w300", "TESTING: Detects students and shows notifications without clicking")
    startupGui.AddText("xm y+5 w300", "LIVE: Automatically clicks detected students and manages sessions")
    startupGui.AddText("xm y+5 w300", "SCAN: Logs detection timing data for analysis")

    ; Buttons
    continueBtn := startupGui.AddButton("xm y+20 w100 h30", "Continue")
    exitBtn := startupGui.AddButton("x+10 yp w100 h30", "Exit")

    ; Button handlers
    result := ""

    ContinueHandler(*) {
        ; Determine mode based on radio selection
        if (liveRadio.Value) {
            LiveMode := true
            ScanMode := false
            modeText := "LIVE"
        } else if (scanRadio.Value) {
            LiveMode := false
            ScanMode := true
            modeText := "SCAN"
        } else {
            LiveMode := false
            ScanMode := false
            modeText := "TESTING"
        }

        result := "Continue"
        startupGui.Destroy()
    }

    ExitHandler(*) {
        result := "Exit"
        startupGui.Destroy()
    }

    continueBtn.OnEvent("Click", ContinueHandler)
    exitBtn.OnEvent("Click", ExitHandler)

    ; Show dialog and wait for result
    startupGui.Show()

    while (!result) {
        Sleep(100)
    }

    WriteLog("Startup dialog result: " . result . " (Mode: " . modeText . ")")
    return (result == "Continue")
}


; Session start dialog for name and subject entry
ShowSessionStartDialog() {
    global LastStudentName, LastStudentTopic, SessionStartTime

    ; Create session start GUI
    startGui := Gui("+AlwaysOnTop", "Session Started - Enter Information")

    ; Pre-fill start time
    startTimeFormatted := FormatTime(SessionStartTime, "h:mm tt")

    ; Student name (manual entry)
    startGui.AddText("xm y+10", "Student name:")
    nameEdit := startGui.AddEdit("xm y+5 w200")
    nameEdit.Text := (LastStudentName ? LastStudentName : "")
    ; Set focus to name field for immediate typing
    nameEdit.Focus()

    ; Subject field (pre-filled from extension)
    startGui.AddText("xm y+15", "Subject:")
    subjectEdit := startGui.AddEdit("xm y+5 w200")
    subjectEdit.Text := (LastStudentTopic ? LastStudentTopic : "")

    ; Start time (read-only, pre-filled)
    startGui.AddText("xm y+15", "Start time:")
    startTimeEdit := startGui.AddEdit("xm y+5 w200 ReadOnly")
    startTimeEdit.Text := startTimeFormatted

    ; Previous session info section (if available)
    static lastSessionInfo := ""
    if (lastSessionInfo != "") {
        startGui.AddText("xm y+20", "Previous session info:")
        startGui.AddText("xm y+5 w350", lastSessionInfo)
    }

    ; Buttons
    continueBtn := startGui.AddButton("xm y+20 w100 h30", "Continue")
    pauseBtn := startGui.AddButton("x+10 yp w100 h30", "Pause")

    ; Button event handlers
    result := ""

    ContinueHandler(*) {
        UpdateSessionInfo()  ; Capture values before destruction
        result := "Continue"
        startGui.Destroy()
    }

    PauseHandler(*) {
        UpdateSessionInfo()  ; Capture values before destruction
        result := "Pause"
        startGui.Destroy()
    }

    continueBtn.OnEvent("Click", ContinueHandler)
    pauseBtn.OnEvent("Click", PauseHandler)

    ; Update global variables from user input
    UpdateSessionInfo() {
        global LastStudentName, LastStudentTopic
        LastStudentName := Trim(nameEdit.Text)
        LastStudentTopic := Trim(subjectEdit.Text)
    }

    ; Show dialog and wait for user input
    startGui.Show()

    ; Wait for user to close dialog
    while (!result) {
        Sleep 100
    }

    return result
}

; Show session feedback dialog and return continue choice (copied from original)
ShowSessionFeedbackDialog() {
    global LastStudentName, LastStudentTopic, SessionStartTime, SessionEndTime

    ; Set session end time
    SessionEndTime := A_Now

    ; Create session feedback GUI
    feedbackGui := Gui("+AlwaysOnTop", "Session Complete - Feedback")

    ; Student name (manual entry required)
    feedbackGui.AddText("xm y+10", "Student name (enter manually):")
    nameEdit := feedbackGui.AddEdit("xm y+5 w200")
    nameEdit.Text := (LastStudentName ? LastStudentName : "")
    ; Set focus to name field for immediate typing
    nameEdit.Focus()

    ; Additional fields
    feedbackGui.AddText("xm y+15", "Grade:")
    gradeEdit := feedbackGui.AddEdit("xm y+5 w50")

    feedbackGui.AddText("x+20 yp", "Subject:")
    subjectEdit := feedbackGui.AddEdit("x+5 yp w150")
    subjectEdit.Text := (LastStudentTopic ? LastStudentTopic : "")

    feedbackGui.AddText("xm y+15", "Topic:")
    topicEdit := feedbackGui.AddEdit("xm y+5 w350")

    ; Math checkbox - auto-check if subject is math-related
    isMathSubject := false
    if (LastStudentTopic != "") {
        subjectLower := StrLower(LastStudentTopic)
        isMathSubject := (InStr(subjectLower, "math") > 0 ||
                         subjectLower == "pre-algebra" ||
                         subjectLower == "algebra" ||
                         subjectLower == "statistics")
    }
    mathCheck := feedbackGui.AddCheckbox("xm y+15" . (isMathSubject ? " Checked" : ""), "Math subject")

    ; Session characteristic checkboxes
    feedbackGui.AddText("xm y+15", "Session characteristics:")
    initialCheck := feedbackGui.AddCheckbox("xm y+5 Checked", "Initial response")
    seriousCheck := feedbackGui.AddCheckbox("x+120 yp Checked", "Serious question")
    leftCheck := feedbackGui.AddCheckbox("xm", "Left abruptly")
    stoppedCheck := feedbackGui.AddCheckbox("x+120 yp", "Stopped responding")
    feedbackGui.AddText("xm y+5", "Good progress (0-1):")
    progressEdit := feedbackGui.AddEdit("x+10 yp w60")
    progressEdit.Text := "1.0"

    ; Last response time
    feedbackGui.AddText("xm y+15", "Last message time (HH:MM):")
    lastMsgEdit := feedbackGui.AddEdit("xm y+5 w100")

    ; Comments
    feedbackGui.AddText("xm y+15", "Comments:")
    commentsEdit := feedbackGui.AddEdit("xm y+5 w350")

    ; Buttons
    feedbackGui.AddText("xm y+15", "Continue looking for students?")
    yesBtn := feedbackGui.AddButton("xm y+5 w80 h30", "Yes")
    noBtn := feedbackGui.AddButton("x+10 yp w80 h30", "No")
    pauseBtn := feedbackGui.AddButton("x+10 yp w80 h30", "Pause")
    skipBtn := feedbackGui.AddButton("x+10 yp w80 h30", "Skip")

    ; Button event handlers - use separate functions instead of lambdas
    result := ""

    YesHandler(*) {
        LogSessionFeedbackCSV()
        result := "Restart"
        feedbackGui.Destroy()
    }

    NoHandler(*) {
        LogSessionFeedbackCSV()
        result := "No"
        feedbackGui.Destroy()
    }

    PauseHandler(*) {
        LogSessionFeedbackCSV()
        result := "Cancel"
        feedbackGui.Destroy()
    }

    SkipHandler(*) {
        SaveCorrectionsOnly()
        result := "Restart"
        feedbackGui.Destroy()
    }

    yesBtn.OnEvent("Click", YesHandler)
    noBtn.OnEvent("Click", NoHandler)
    pauseBtn.OnEvent("Click", PauseHandler)
    skipBtn.OnEvent("Click", SkipHandler)

    ; Function to save corrections only (for Skip button)
    SaveCorrectionsOnly() {
        ; Note: Simplified for integrated system - no OCR corrections needed
        WriteLog("Session skipped - no CSV log entry created")
    }

    ; Function to log session feedback in CSV format
    LogSessionFeedbackCSV() {
        ; Calculate session duration in minutes
        duration := ""
        if (SessionStartTime != "" && SessionEndTime != "") {
            startSecs := DateDiff(SessionStartTime, "19700101000000", "Seconds")
            endSecs := DateDiff(SessionEndTime, "19700101000000", "Seconds")
            duration := Round((endSecs - startSecs) / 60)
        }

        ; Format times
        rtime := FormatTime(SessionStartTime, "M/d/yy")
        startTime := FormatTime(SessionStartTime, "H:mm")
        endTime := FormatTime(SessionEndTime, "H:mm")

        ; Build CSV row following exact column specification
        csvRow := ""
        csvRow .= "," ; Column 1: blank
        csvRow .= rtime . "," ; Column 2: date
        csvRow .= startTime . "," ; Column 3: starting time
        csvRow .= startTime . "," ; Column 4: starting time (same as column 3)
        csvRow .= endTime . "," ; Column 5: ending time
        csvRow .= "," ; Column 6: blank
        csvRow .= StrReplace(StrReplace(nameEdit.Text, "`n", " "), "`r", "") . "," ; Column 7: name
        csvRow .= gradeEdit.Text . "," ; Column 8: grade
        csvRow .= "," ; Column 9: blank
        csvRow .= "," ; Column 10: blank
        csvRow .= StrReplace(StrReplace(subjectEdit.Text, "`n", " "), "`r", "") . "," ; Column 11: subject
        csvRow .= StrReplace(StrReplace(topicEdit.Text, "`n", " "), "`r", "") . "," ; Column 12: Topic
        csvRow .= (mathCheck.Value ? "1" : "0") . "," ; Column 13: Math
        csvRow .= duration . "," ; Column 14: duration
        csvRow .= (initialCheck.Value ? "1" : "0") . "," ; Column 15: Initial response
        csvRow .= (seriousCheck.Value ? "1" : "0") . "," ; Column 16: Serious question
        csvRow .= (leftCheck.Value ? "1" : "0") . "," ; Column 17: Left abruptly
        csvRow .= (stoppedCheck.Value ? "1" : "0") . "," ; Column 18: Stopped resp
        csvRow .= progressEdit.Text . "," ; Column 19: Good progress (float 0-1)
        csvRow .= lastMsgEdit.Text . "," ; Column 20: last response
        csvRow .= StrReplace(StrReplace(commentsEdit.Text, "`n", " "), "`r", "") ; Column 21: comments (no trailing comma)

        WriteAppLog(csvRow)
        WriteLog("Session feedback logged to CSV")
    }

    ; Show dialog and wait for result
    feedbackGui.Show("x400 w370 h550")

    ; Wait for user action
    while (result == "") {
        Sleep(50)
    }

    return result
}


; Entry point - start the application
Main()