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

    if (!WaitForExtensionHandshake(60)) {
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

; Monitor for session end
MonitorSessionEnd() {
    global PageTarget, ExtensionWindowID

    ; Check if we're back on the waiting students page
    WinGetClientPos(, , &winWidth, &winHeight, ExtensionWindowID)
    pageResult := FindText(, , 850, 300, 1400, 1100, 0.15, 0.10, PageTarget)

    if (pageResult) {
        WriteLog("Session end detected - back on waiting students page")
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

    ; Handle feedback result
    if (feedbackResult == "Continue") {
        ; Reset to waiting state
        InSession := false
        AppState := "WAITING_FOR_STUDENTS"
        ToolTip "⏳ Session ended - waiting for next student", 10, 10, 1
        WriteLog("Session ended - continuing monitoring")

    } else if (feedbackResult == "Pause") {
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

    continueBtn.OnEvent("Click", (*) => {
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
    })

    exitBtn.OnEvent("Click", (*) => {
        result := "Exit"
        startupGui.Destroy()
    })

    ; Show dialog and wait for result
    startupGui.Show()

    while (!result) {
        Sleep(100)
    }

    WriteLog("Startup dialog result: " . result . " (Mode: " . modeText . ")")
    return (result == "Continue")
}

; Entry point - start the application
Main()