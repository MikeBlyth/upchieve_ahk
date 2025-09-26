#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include student_database.ahk
#Include ahk_utilities.ahk
#include search_targets.ahk
#Include extension_bridge.ahk
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

; Statistics tracking
global SearchStats := SearchStatsClass()
global SoundTimerFunc := ""

; Hotkey handlers
^+q::CleanExit()  ; Ctrl+Shift+Q to quit
^+h::TogglePause()  ; Ctrl+Shift+H to pause/resume
^+a::ManualEndSession()  ; Ctrl+Shift+A to manually end session
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

; Clean exit function
CleanExit() {
    WriteLog("Application exit requested")

    ; Stop header manager timer
    StopHeaderManager()

    ; Clear tooltips
    ToolTip ""

    ; Show exit message
    MsgBox("UPchieve Integrated Detector closed.", "Application Exit", "OK 4096")
    ExitApp
}

; Toggle pause/resume functionality
TogglePause() {
    global AppState

    if (AppState == "PAUSED") {
        AppState := "WAITING_FOR_STUDENTS"
        WriteLog("Application RESUMED - returning to student monitoring")
        ToolTip "▶️ RESUMED - Monitoring for students", 10, 10, 1
    } else if (AppState == "WAITING_FOR_STUDENTS") {
        AppState := "PAUSED"
        WriteLog("Application PAUSED - student monitoring stopped")
        ToolTip "⏸️ PAUSED - Press Ctrl+Shift+H to resume", 10, 10, 1
    } else {
        WriteLog("Pause toggle ignored - current state: " . AppState)
    }
}

; Manual session end
ManualEndSession() {
    global InSession, AppState

    if (InSession) {
        WriteLog("Manual session end requested")
        EndCurrentSession()
    } else {
        WriteLog("Manual session end ignored - no active session")
        ToolTip "No active session to end", 10, 50, 2
        SetTimer(() => ToolTip("", , , 2), -3000)
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
    debugInfo .= "`nClipboard: " . SubStr(GetClipboardContent(), 1, 100) . "..."

    MsgBox(debugInfo, "Debug Information", "OK 4096")
}

; Main application entry point
Main() {
    WriteLog("=== UPchieve Integrated Detector Started ===")

    ; Show startup dialog for mode selection
    if (!ShowStartupDialog()) {
        WriteLog("User cancelled startup - exiting")
        CleanExit()
    }

    ; Initialize extension communication
    WriteLog("Initializing extension communication...")
    AppState := "STARTING"
    ToolTip "🔗 Waiting for extension connection...", 10, 10, 1

    if (!WaitForExtensionHandshake(120)) {
        WriteLog("Extension handshake failed - exiting")
        MsgBox("Failed to connect to extension.`n`nPlease ensure:`n• Extension is installed and enabled`n• You're on the UPchieve waiting students page`n• Extension icon is green (active)", "Extension Connection Failed", "OK 4112")
        CleanExit()
    }

    ; Initialize header management with the window ID from extension
    WriteLog("Initializing header management with window ID: " . ExtensionWindowID)

    ; Bind FindText to the extension window
    FindText().BindWindow(ExtensionWindowID, 4)

    ; Initialize header manager
    InitializeHeaderManager(ExtensionWindowID)

    ; Verify initial header detection
    if (!HeadersFound) {
        WriteLog("Initial header detection failed - exiting")
        MsgBox("Failed to detect page headers.`n`nPlease ensure you're on the UPchieve 'Waiting Students' page with the table visible.", "Header Detection Failed", "OK 4112")
        CleanExit()
    }

    WriteLog("Initialization complete - starting main detection loop")
    AppState := "WAITING_FOR_STUDENTS"

    ; Start main detection loop
    MainDetectionLoop()
}

; Main detection loop - monitors clipboard for student data
MainDetectionLoop() {
    global AppState, LiveMode, modeText

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

        ; Main detection state - wait for students
        ToolTip "⏳ Waiting for students... (" . modeText . " mode)", 10, 10, 1

        ; Poll clipboard for student data (blocks until data received or timeout)
        if (PollClipboardForStudents(60)) {  ; 60 second timeout
            ProcessClipboardStudentData()
        } else {
            ; Timeout - continue loop (allows for pause checks, etc.)
            WriteLog("Clipboard polling timeout - continuing main loop")
        }
    }
}

; Process student data from clipboard
ProcessClipboardStudentData() {
    global AppState, LiveMode, InSession, LastStudentName, LastStudentTopic, SessionStartTime

    WriteLog("Processing clipboard student data...")

    ; Get clipboard content and parse students
    clipData := GetClipboardContent()
    students := ParseStudentArray(clipData)

    if (students.Length == 0) {
        WriteLog("No valid students found in clipboard data")
        return
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
}

; Start a session with the selected student
StartSession(student) {
    global InSession, AppState, LastStudentName, LastStudentTopic, SessionStartTime, SoundTimerFunc

    WriteLog("Starting session with: " . student.ToString())

    ; Update session variables
    InSession := true
    AppState := "IN_SESSION"
    LastStudentName := student.name
    LastStudentTopic := student.topic
    SessionStartTime := A_Now

    ; Maximize window for session
    WinMaximize("ahk_id " . ExtensionWindowID)

    ; Show session notification
    sessionMsg := "📚 Session started with " . student.name
    if (student.topic != "") {
        sessionMsg .= " (" . student.topic . ")"
    }
    ToolTip sessionMsg, 10, 10, 1

    ; Start notification sound timer (every 2 seconds)
    SoundTimerFunc := () => PlayNotificationSound()
    SetTimer(SoundTimerFunc, 2000)

    WriteLog("Session started - monitoring for session end")
}

; Monitor for session end in a dedicated loop
MonitorSessionEnd() {
    global targetWindowID, InSession, SessionEndedTarget

    ; Monitor for session end
    WriteLog("DEBUG: Starting session end monitoring")

    while (InSession) {  ; Check InSession instead of infinite loop
        sessionEndZone := SearchZone(3000-822, 320, 3000, 485)
        
        if (tempResult := FindTextInZones(SessionEndedTarget, sessionEndZone,, 0.15, 0.10, &SearchStats)) {
            WriteLog("DEBUG: SessionEndedTarget found at " . tempResult[1].x . "," . tempResult[1].y)
            break
        }

        Sleep 1000  ; Check every 2 seconds
    }
    WriteLog("DEBUG: Session end monitoring stopped")
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