#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Upchieve Waiting Student Detector
; Hotkeys: Ctrl+Shift+Q to quit, Ctrl+Shift+H to pause/resume, Ctrl+Shift+R to resume from session

TargetWindow := "UPchieve"
IsActive := false
SoundTimerFunc := ""
LiveMode := false

; Session state management
WAITING_FOR_STUDENT := "WAITING_FOR_STUDENT"
IN_SESSION := "IN_SESSION" 
PAUSED := "PAUSED"
SessionState := WAITING_FOR_STUDENT

; Function to play notification sound
PlayNotificationSound() {
    SoundBeep(800, 500)  ; 800Hz beep for 500ms
}

; Image targets
PageTarget := "|<WaitingStudents>*132$271.0000000000000s00007U00000000000000000000000000000000000001y00007s00000000000000000000000000000000000000zU0003w00000000000000000000000001y00z00TU0000Tk0Q01y00000000000000Dw000k000000z00TU0DU0000Ds0y00z00000000000000zzk03s000000DU0Dk07k00003s0T00TU00000000C0001zzy01w0000007k0Ds03s00000s0DU07U00000000DU001zzzU0y0000003w07y03w00000007k00000000000Dk001zUTs0T0000000y03z01w00000003s00000000000Ds000z03y0DU000000T01zU0y00000001w000000000007U000z00T07k000000DU1vk0T03z007kTzzUz0T1z000zr0000T00D1zzy3w07k7s0ww0D07zw03sDzzkTUDXzs01zzU000DU030zzz1y03s1w0SS0DU7zz01w7zzsDk7nzy03zzk0007k000TzzUz01w0y0DD07k7zzk0y3zzw7s3vzzU3zzw0003s000DzzkTU0y0T0DbU3s7w7w0T03s03w1zsTk1z1z0001y0000DU0Dk0T07k7Xs1s7s1y0DU1w01y0zk3w1y0TU000zk0007k07s0DU3s3kw1w3s0T07k0y00z0Tk1y0z07k000DzU003s03w07k1w1sS0y0Q0DU3s0T00TUDk0T0T03w0007zzU01w01y03s0y0wD0S0007k1w0DU0Dk7s0DUDU1y0001zzy00y00z01w0DUw7kD0003s0y07k07s3w07k7k0z0000DzzU0T00TU0y07kS1sDU007w0T03s03w1y03s3w0T00001zzw0DU0Dk0T03sD0w7U01zy0DU1w01y0z01w0zUzU00003zz07k07s0DU0w7US3k07zz07k0y00z0TU0y0TzzU000003zU3s03w07k0T7U7Vs0DzzU3s0T00TUDk0T07zzU000000Tk1w01y03s0DXk3lw0Dy7k1w0DU0Dk7s0DU1zzU0000003w0y00z01w07ls1sw0Dk3s0y07k07s3w07k1zz00000001y0T00TU0y01sw0wS0Dk1w0T03s03w1y03s1s000000k00z0DU0Dk0T00yw0DD07k0y0DU1w01y0z01w1s000000w00TU7k07s0TU0TS07j03s0T07k0y00z0TU0y0w000000z00DU3s01w0Dk07j03rU1w0TU3s0T00TUDk0T0S000000Tk0Dk1y00z0Ds03z01zk0zVzs1w0DksDk7s0DUDU000007y0Tk0zVUTkTw01zU0Ts0TzzzUy07zw7s3w07k7zzw0001zzzk0Dzk7zzy00Tk0Ds07zyzkT01zy3w1y03s1zzzU000Tzzk07zs3zzD00Ds07w01zwDsDU0Tz1y0z01w0Tzzs0003zzU01zw0Tz7U07s03y00Ds3s7k03w0z0TU0y0Dzzw0000Dz000Ds03y3k0000000000000000000000000T00y00000000000000000000000000000000000000000D00DU000000000000000E"

WaitingTarget := "|<Waiting>*150$65.00000000000000000s0000000003k000000000DU000000E01z0000003U0Di000000T00QQ006C07s000s00Bw0z0001k00TU7s0003U00w0y00007001k3k0000C003U600000Q0070D00000s00A0DU0001k00M07k0003U00k03s0007001U01y000C003000z000Q006000S000s00A000A001k00M0000003U00k00000000000E"

UpgradeTarget :="|<Upgrade>*197$75.zzzzzzzzzzzzzzzzzzzzzzzzzszss07zU7w07z7z700Ds0TU0DszssT1y31wD0z7z73y7Vy7Vy7szssTssTswDsz7z73z33z3Vz3szssTsMzzwDsT7z73z77zzVz7szssTkszzwDkz7z73w77zzVw7szss01sy0Q01z7z700z7k3U0zszssTzszsQD7z7z73zz7z3VsTsTssTzsTsQDXz3y73zzXz3VwDwDksTzwDsQDkzUsD3zzkQ3Vy6y03sTzz01wDsLw1z3zzy0TVzUzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"

EndSessionTarget :="|<EndSession>*194$193.00C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C000000000000000000000000000000060000000000000000000000000000000600000000000000000000000000000007000000000000000000000000000000030000000000000000000000000000000300000000000000000000000000000003U0000000000000000000000000000001U0000000000000000000000000000000k0000000000000000000000000000000k0000000000000000000000000000000M0000000000000000000000000000000Q0000000000000000000000000000000A000000000000000000000000000000060000000000000000S0000000000000070000000000000000D00000000000000300000000zzw000007U007w0000000001U0000000Tzy000003k00DzU000000000k0000000Dzz000001s00Dzs000000000s00000007U0000000w00D0S000000000M00000003k0000000S00D07000000000A00000001s00STU0zD007U103w03w0Ds600000000w00DTs0zzU03k007zU7zUTz300000000S007zy0zzk01w007zs7zsDzlU0000000D003w7Uw3s00zU07US7UQD1sk00000007zw1w3kS0w00DzU3U73k470MM00000003zy0w0sS0S003zw3k3Vs03k0A00000001zz0S0QD0D000TzVzzkzU1y0600000000w00D0C7U7U000zkzzsDz0Tw300000000S007U73k3k0001wTzw1zk3zVU0000000D003k3Vs1s0000SD0007w0Dsk00000007U01s1kw0w0080D7U000D00wQ00000003k00w0sD0S00C07Vs20U7V0C600000001s00S0Q7UT007k7Uw3ks3lkD300000000zzwD0C1zzU01zzUDzkTzkzzVU0000000Tzy7U70Txk00TzU3zk7zkDzUs0000000Dzz3k3U7ss003z00Tk0zU1z0A0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000M000000000000000000000000000000060000000000000000000000000000000300000000000000000000000000000001k0000000000000000000000000000000M0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000A0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001s0000000000000000000000000000E"
FinishTarget :="|<Finish>*225$127.01000000000000000000001U00000000000000000001U00000000000000000000U00000000000000000000k00000000000000000000E00000000000000000000E00000000000000000000M00000000000000000000800000000000000000000400000000000000000000400000000000000000000200000000000000000000300000000000000000000100000000000T0000w0000U0000000000DU000z0000E0000000Dzz7k000TU000M00000007zzXk0007U000800000003zzk000000000400000001s00000000000200000000w00000000000100000000S00D1tz0S0zk0U0000000D007UzzkD0zy0k00000007U03kTzw7Uzz0M00000003k01sDky3ky7kA00000001zz0w7kD1sS1k600000000zzkS3s7kwDU0300000000TzsD1s3sS7y01U0000000D007Uw1wD1zs0E00000007U03kS0y7UTz0800000003k01sD0T3k1zk400000001s00w7UDVs03s200000000w00S3k7kw60w100000000S00D1s3sS7Uy0k0000000D007Uw1wD3zz0800000007U03kS0y7Uzz0400000003k01sD0T3k7y02000000000000000000001U00000000000000000000E000000000000000000008000000000000000000002000000000000000000001000000000000000000000k0000000000000000000E"

; Load alphabet characters for name extraction
LoadAlphabetCharacters() {
    ; Combine all lowercase letters
    Text := Texta . Textb . Textc . Textd . Texte . Textf . Textg . Texth . Texti . Textj . Textk . Textl . Textm . Textn . Texto . Textp . Textq . Textr . Texts . Textt . Textu . Textv . Textw . Textx . Texty . Textz
    
    ; Add uppercase letters
    Text .= Text_A . Text_B . Text_C . Text_D . Text_E . Text_F . Text_G . Text_H . Text_I . Text_J . Text_K . Text_L . Text_M . Text_N . Text_O . Text_P . Text_Q . Text_R . Text_S . Text_T . Text_U . Text_V . Text_W . Text_X . Text_Y . Text_Z
    
    ; Add special characters
    Text .= Text_apos . Text_hyphen
    
    ; Register with FindText library
    FindText().PicLib(Text, 1)
}

; Log function
WriteLog(message) {
    logFile := "debug_log.txt"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend timestamp . " - " . message . "`n", logFile
}

; Convert FindText midpoint coordinates to upper-left coordinates
GetUpperLeft(centerX, centerY, width, height) {
    return {x: centerX - width / 2, y: centerY - height / 2}
}

; Load blocked names from block_names.txt
LoadBlockedNames() {
    blockedNames := []
    blockFile := "block_names.txt"
    
    ; Check if file exists
    if (!FileExist(blockFile)) {
        ; WriteLog("block_names.txt not found - no names will be blocked")
        return blockedNames
    }
    
    ; Read file line by line
    try {
        fileContent := FileRead(blockFile)
        lines := StrSplit(fileContent, "`n", "`r")
        
        for index, line in lines {
            trimmedName := Trim(line)
            if (trimmedName != "" && InStr(trimmedName, ";") != 1) {  ; Skip empty lines and comments
                blockedNames.Push(trimmedName)
            }
        }
        
        ; WriteLog("Loaded " . blockedNames.Length . " blocked names from " . blockFile)
    } catch Error as e {
        ; WriteLog("ERROR: Failed to read " . blockFile . " - " . e.message)
    }
    
    return blockedNames
}

; Check if student name is in blocked list
IsNameBlocked(studentName, blockedNames) {
    for index, blockedName in blockedNames {
        if (StrLower(Trim(studentName)) == StrLower(Trim(blockedName))) {
            return true
        }
    }
    return false
}


; Extract student name from region left of waiting indicator
ExtractStudentName(baseX, baseY) {
    ; Adjust for center point: WaitingTarget is 134x35, so center is at +67,+17.5 from upper-left
    ; To get upper-left of WaitingTarget: subtract half width and height
    upperLeftX := baseX - 67
    upperLeftY := baseY - 17
    
    ; Search region: Updated based on testing (720px left, 400 wide, 80 tall)
    searchX := upperLeftX - 720
    searchY := upperLeftY - 10
    searchWidth := 400 
    searchHeight := 80
    
    ; Define character set for names
    nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
    X := ""
    Y := ""
    
    ; Find text characters in the name region
    if (ok := FindText(&X, &Y, searchX, searchY, searchX + searchWidth, searchY + searchHeight, 0.15, 0.05, FindText().PicN(nameChars))) {
        ; Filter and manually assemble characters (same as test function)
        cleanChars := Array()
        for i, char in ok {
            ; Skip apostrophes and noise characters
            if (char.id == "'") {
                continue
            }
            
            tooClose := false
            for j, existingChar in cleanChars {
                if (Abs(char.x - existingChar.x) < 8 && Abs(char.y - existingChar.y) < 8) {
                    tooClose := true
                    break
                }
            }
            if (!tooClose) {
                cleanChars.Push(char)
            }
        }
        
        ; Sort characters by X coordinate and build string manually
        if (cleanChars.Length > 0) {
            ; Sort characters by X coordinate (left to right)
            Loop cleanChars.Length - 1 {
                i := A_Index
                Loop cleanChars.Length - i {
                    j := A_Index
                    if (cleanChars[j].x > cleanChars[j+1].x) {
                        temp := cleanChars[j]
                        cleanChars[j] := cleanChars[j+1] 
                        cleanChars[j+1] := temp
                    }
                }
            }
            
            ; Build string from sorted characters
            extractedName := ""
            for i, char in cleanChars {
                extractedName .= char.id
            }
            
            ; Clean up any remaining artifacts
            extractedName := RegExReplace(extractedName, "[^a-zA-Z' -]", "")
            finalName := Trim(extractedName)
            
            ; Log the final result - keep for session tracking
            ; WriteLog("Student name extracted: '" . finalName . "'")
            return finalName
        }
    }
    
    return ""  ; Return empty if extraction failed
}

; Suspend detection with resume option
SuspendDetection() {
    global SessionState
    previousState := SessionState
    SessionState := PAUSED
    ; WriteLog("Detection paused. Previous state: " . previousState)
    
    MsgBox("Upchieve suspended`n`nPress OK to resume", "Detection Paused", "OK")
    
    ; Resume to appropriate state
    if (previousState == IN_SESSION) {
        SessionState := IN_SESSION
        ; WriteLog("Detection resumed to IN_SESSION state")
    } else {
        SessionState := WAITING_FOR_STUDENT
        ; WriteLog("Detection resumed to WAITING_FOR_STUDENT state")
    }
}

; Prevent system from going to sleep while script is running
; 0x80000003 = ES_SYSTEM_REQUIRED | ES_CONTINUOUS (keeps system awake)
DllCall("kernel32.dll\SetThreadExecutionState", "UInt", 0x80000003)

; Initialize alphabet characters for name extraction at startup
LoadAlphabetCharacters()

; Load blocked names list
BlockedNames := LoadBlockedNames()

; Manual resume from IN_SESSION state
ResumeFromSession() {
    global SessionState
    if (SessionState == IN_SESSION) {
        SessionState := WAITING_FOR_STUDENT
        ; WriteLog("Manual resume: State changed from IN_SESSION to WAITING_FOR_STUDENT")
        MsgBox("Resumed looking for students", "Manual Resume", "OK")
    } else {
        MsgBox("Not currently in session. State: " . SessionState, "Manual Resume", "OK")
    }
}

; Clean exit function to restore normal sleep behavior
CleanExit() {
    ; Restore normal power management
    DllCall("kernel32.dll\SetThreadExecutionState", "UInt", 0x80000000)
    ExitApp
}

; Hotkey definitions
^+q::CleanExit()
^+h::SuspendDetection()
^+r::ResumeFromSession()

; Auto-start detection on script launch
StartDetector()

StartDetector() {
    global
    
    ; Combined startup dialog with mode selection
    modeResult := MsgBox("Upchieve detector will search for 'Waiting Students' page and start monitoring automatically.`n`nYes = LIVE mode (clicks students)`nNo = TESTING mode (no clicking)`nCancel = Exit", "Upchieve Detector Startup", "YNC Default2")
    if (modeResult = "Cancel") {
        CleanExit()  ; Exit application
    }
    
    LiveMode := (modeResult = "Yes")
    modeText := LiveMode ? "LIVE" : "TESTING"
    
    ; Wait for PageTarget to appear with debug info
    pageCheckCount := 0
    X := ""
    Y := ""
    while (!(result := FindText(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, PageTarget))) {
        pageCheckCount++
        ToolTip "Looking for 'Waiting Students' page... Check #" pageCheckCount, 10, 50
        Sleep 100
    }
    
    ; PageTarget found - calculate upper-left reference point
    ; PageTarget dimensions: width=320, height=45
    ; TODO: Consider converting to modern FindTextv2 object syntax in the future
    pageUpperLeft := GetUpperLeft(X, Y, 320, 45)
    pageRefX := pageUpperLeft.x
    pageRefY := pageUpperLeft.y
    lastPageCheck := A_TickCount  ; Track when we last found PageTarget
    lastTooltipShow := A_TickCount  ; Track tooltip display timing
    
    ToolTip "Found 'Waiting Students' page! Starting " . modeText . " mode detector...", 10, 50
    Sleep 1000
    ToolTip ""
    
    ; Log application start
    WriteLog("Upchieve Detector started in " . modeText . " mode")
    
    IsActive := true
    
    ; Main detection loop
    while (IsActive) {
        ; Periodic PageTarget re-detection (every 10 seconds) to handle window movement
        if (A_TickCount - lastPageCheck > 10000) {
            tempX := ""
            tempY := ""
            if (tempResult := FindText(&tempX, &tempY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, PageTarget)) {
                ; PageTarget found - update reference point
                newUpperLeft := GetUpperLeft(tempX, tempY, 320, 45)
                if (newUpperLeft.x != pageRefX || newUpperLeft.y != pageRefY) {
                    ; WriteLog("PageTarget moved: (" . pageRefX . "," . pageRefY . ") -> (" . newUpperLeft.x . "," . newUpperLeft.y . ")")
                    pageRefX := newUpperLeft.x
                    pageRefY := newUpperLeft.y
                }
                lastPageCheck := A_TickCount
            } else {
                ; PageTarget not found - keep using previous coordinates
                ; Reduced frequency: only warn every 60 seconds instead of every 5 seconds
                if (A_TickCount - lastPageCheck > 60000) {
                    ; WriteLog("WARNING: PageTarget re-detection failed for >60 seconds")
                }
                lastPageCheck := A_TickCount  ; Reset timer to avoid spam
            }
        }
        
        ; Check for session end: PageTarget appears while we're IN_SESSION  
        if (SessionState == IN_SESSION) {
            tempX := ""
            tempY := ""
            if (tempResult := FindText(&tempX, &tempY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, PageTarget)) {
                ; Session ended - show continuation dialog
                WriteLog("Session ended")
                continueResult := MsgBox("Session ended.`n`nDo you want to continue looking for students?", "Session Complete", "YNC Default1")
                
                if (continueResult = "Yes") {
                    global SessionState
                    SessionState := WAITING_FOR_STUDENT
                    ; Use the coordinates we just found  
                    newUpperLeft := GetUpperLeft(tempX, tempY, 320, 45)
                    pageRefX := newUpperLeft.x
                    pageRefY := newUpperLeft.y
                    lastPageCheck := A_TickCount
                } else if (continueResult = "No") {
                    CleanExit()
                } else {  ; Cancel
                    global SessionState
                    SessionState := PAUSED
                    SuspendDetection()
                    SessionState := WAITING_FOR_STUDENT  ; Resume after pause dialog
                }
            }
        }
        
        ; Debug: Show current state briefly (1 second every 5 seconds)
        if (A_TickCount - lastTooltipShow > 5000) {
            ; Time to show tooltip again
            stateText := "State: " . SessionState . " | "
            if (SessionState == WAITING_FOR_STUDENT) {
                ToolTip stateText . "Scanning for upgrade popup and waiting students...", 10, 10
            } else if (SessionState == IN_SESSION) {
                ToolTip stateText . "In session - monitoring for session end...", 10, 10
            } else {
                ToolTip stateText . "Paused", 10, 10
            }
            lastTooltipShow := A_TickCount
        } else if (A_TickCount - lastTooltipShow > 1000) {
            ; Hide tooltip after 1 second
            ToolTip ""
        }
        
        ; Check for upgrade popup first (relative to PageTarget)
        upgradeX1 := pageRefX + 702
        upgradeY1 := pageRefY + 120
        upgradeX2 := upgradeX1 + 325
        upgradeY2 := upgradeY1 + 300
        X := ""
        Y := ""
        if (UpgradeTarget != "" && (result := FindText(&X, &Y, upgradeX1, upgradeY1, upgradeX2, upgradeY2, 0, 0, UpgradeTarget))) {
            ToolTip "Found upgrade popup! Clicking...", 10, 10
            Click X, Y
            MsgBox "Clicked upgrade popup at " X ", " Y
            Sleep 1000
            continue  ; Skip to next iteration after handling upgrade
        }
        
        ; Only scan for waiting students if we're in the right state
        if (SessionState == WAITING_FOR_STUDENT) {
            ; Search for waiting student indicator (relative to PageTarget)
            waitingX1 := pageRefX + 382
            waitingY1 := pageRefY + 299
            waitingX2 := waitingX1 + 334
            waitingY2 := waitingY1 + 235
            X := ""
            Y := ""
            if (result := FindText(&X, &Y, waitingX1, waitingY1, waitingX2, waitingY2, 0, 0, WaitingTarget)) {
            global LiveMode
            ToolTip "Found waiting student! Extracting name...", 10, 10
            
            ; Step 1: Extract student name from region left of waiting indicator
            studentName := ExtractStudentName(X, Y)
            
            ; Step 2: Check if student name is blocked BEFORE clicking
            global BlockedNames
            if (studentName != "" && IsNameBlocked(studentName, BlockedNames)) {
                WriteLog("BLOCKED: " . studentName . " - student on block list")
                continue  ; Skip this student and continue monitoring
            }
            
            ; Step 3: Click on the WaitingTarget (only in LIVE mode and if not blocked)
            if (LiveMode) {
                ; First click to activate window
                Click X, Y
                Sleep 200  ; Wait 200ms to avoid double-click detection
                ; Second click to select student
                Click X, Y
                ; Log session start with student name
                if (studentName != "") {
                    WriteLog("Session started with " . studentName)
                } else {
                    WriteLog("Session started with unknown student")
                }
                ; Change state to IN_SESSION after clicking
                global SessionState
                SessionState := IN_SESSION
            } else {
                ; Log session start in testing mode  
                if (studentName != "") {
                    WriteLog("TESTING: Session started with " . studentName)
                } else {
                    WriteLog("TESTING: Session started with unknown student")
                }
                ; In testing mode, also simulate being in session for state testing
                global SessionState
                SessionState := IN_SESSION
            }
            
            ; Step 4: Start repeating notification sound (every 2 seconds)
            global SoundTimerFunc
            PlayNotificationSound()  ; Play immediately
            SoundTimerFunc := PlayNotificationSound  ; Store function reference
            SetTimer SoundTimerFunc, 2000  ; Then every 2 seconds
            
            ToolTip ""  ; Clear tooltip
            
            ; Step 5: Show message box with session message
            modePrefix := LiveMode ? "Session with " : "Found student "
            if (studentName != "") {
                MsgBox(modePrefix . studentName . (LiveMode ? " has opened" : " waiting"), LiveMode ? "Session Started" : "Student Detected", "OK")
            } else {
                MsgBox(LiveMode ? "A session has opened" : "A student is waiting", LiveMode ? "Session Started" : "Student Detected", "OK")
            }
            
            ; Step 6: When OK is clicked, stop the sound and continue monitoring
            if (SoundTimerFunc != "") {
                SetTimer SoundTimerFunc, 0  ; Stop the timer
                SoundTimerFunc := ""
            }
            
            ; Continue monitoring for more students (removed break statement)
            }
        }
        
        ; Wait 50ms before next scan (faster detection)
        Sleep 50
        
        ; Continue monitoring (removed window existence check)
    }
    
    ; Clear tooltip when done
    ToolTip ""
}