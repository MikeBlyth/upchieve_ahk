#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Upchieve Waiting Student Detector
; Hotkeys: Ctrl+Shift+A to activate, Ctrl+Shift+Q to quit

TargetWindow := "UPchieve"
IsActive := false
SoundTimer := ""

; Function to play notification sound
PlayNotificationSound() {
    SoundBeep(800, 500)  ; 800Hz beep for 500ms
}

; Image targets
PageTarget := "|<WaitingStudents>*132$271.0000000000000s00007U00000000000000000000000000000000000001y00007s00000000000000000000000000000000000000zU0003w00000000000000000000000001y00z00TU0000Tk0Q01y00000000000000Dw000k000000z00TU0DU0000Ds0y00z00000000000000zzk03s000000DU0Dk07k00003s0T00TU00000000C0001zzy01w0000007k0Ds03s00000s0DU07U00000000DU001zzzU0y0000003w07y03w00000007k00000000000Dk001zUTs0T0000000y03z01w00000003s00000000000Ds000z03y0DU000000T01zU0y00000001w000000000007U000z00T07k000000DU1vk0T03z007kTzzUz0T1z000zr0000T00D1zzy3w07k7s0ww0D07zw03sDzzkTUDXzs01zzU000DU030zzz1y03s1w0SS0DU7zz01w7zzsDk7nzy03zzk0007k000TzzUz01w0y0DD07k7zzk0y3zzw7s3vzzU3zzw0003s000DzzkTU0y0T0DbU3s7w7w0T03s03w1zsTk1z1z0001y0000DU0Dk0T07k7Xs1s7s1y0DU1w01y0zk3w1y0TU000zk0007k07s0DU3s3kw1w3s0T07k0y00z0Tk1y0z07k000DzU003s03w07k1w1sS0y0Q0DU3s0T00TUDk0T0T03w0007zzU01w01y03s0y0wD0S0007k1w0DU0Dk7s0DUDU1y0001zzy00y00z01w0DUw7kD0003s0y07k07s3w07k7k0z0000DzzU0T00TU0y07kS1sDU007w0T03s03w1y03s3w0T00001zzw0DU0Dk0T03sD0w7U01zy0DU1w01y0z01w0zUzU00003zz07k07s0DU0w7US3k07zz07k0y00z0TU0y0TzzU000003zU3s03w07k0T7U7Vs0DzzU3s0T00TUDk0T07zzU000000Tk1w01y03s0DXk3lw0Dy7k1w0DU0Dk7s0DU1zzU0000003w0y00z01w07ls1sw0Dk3s0y07k07s3w07k1zz00000001y0T00TU0y01sw0wS0Dk1w0T03s03w1y03s1s000000k00z0DU0Dk0T00yw0DD07k0y0DU1w01y0z01w1s000000w00TU7k07s0TU0TS07j03s0T07k0y00z0TU0y0w000000z00DU3s01w0Dk07j03rU1w0TU3s0T00TUDk0T0S000000Tk0Dk1y00z0Ds03z01zk0zVzs1w0DksDk7s0DUDU000007y0Tk0zVUTkTw01zU0Ts0TzzzUy07zw7s3w07k7zzw0001zzzk0Dzk7zzy00Tk0Ds07zyzkT01zy3w1y03s1zzzU000Tzzk07zs3zzD00Ds07w01zwDsDU0Tz1y0z01w0Tzzs0003zzU01zw0Tz7U07s03y00Ds3s7k03w0z0TU0y0Dzzw0000Dz000Ds03y3k0000000000000000000000000T00y00000000000000000000000000000000000000000D00DU000000000000000E"

WaitingTarget := "|<Waiting>*150$65.00000000000000000s0000000003k000000000DU000000E01z0000003U0Di000000T00QQ006C07s000s00Bw0z0001k00TU7s0003U00w0y00007001k3k0000C003U600000Q0070D00000s00A0DU0001k00M07k0003U00k03s0007001U01y000C003000z000Q006000S000s00A000A001k00M0000003U00k00000000000E"

UpgradeTarget :="|<Upgrade>*197$75.zzzzzzzzzzzzzzzzzzzzzzzzzszss07zU7w07z7z700Ds0TU0DszssT1y31wD0z7z73y7Vy7Vy7szssTssTswDsz7z73z33z3Vz3szssTsMzzwDsT7z73z77zzVz7szssTkszzwDkz7z73w77zzVw7szss01sy0Q01z7z700z7k3U0zszssTzszsQD7z7z73zz7z3VsTsTssTzsTsQDXz3y73zzXz3VwDwDksTzwDsQDkzUsD3zzkQ3Vy6y03sTzz01wDsLw1z3zzy0TVzUzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"

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
            
            ; Log the final result
            WriteLog("Student name extracted: '" . finalName . "'")
            return finalName
        }
    }
    
    return ""  ; Return empty if extraction failed
}

; Hotkey definitions
^+a::ActivateDetector()
^+q::ExitApp

ActivateDetector() {
    global
    
    ; Initialize alphabet characters for name extraction
    LoadAlphabetCharacters()
    
    ; Show waiting message that will disappear when PageTarget is found
    MsgBox("Waiting for 'Waiting Students' page to appear...", "Page Detection", "T5")
    
    ; Wait for PageTarget to appear with debug info
    pageCheckCount := 0
    X := ""
    Y := ""
    while (!(result := FindText(&X, &Y, 891, 889, 1446, 1149, 0, 0, PageTarget))) {
        pageCheckCount++
        ToolTip "Looking for 'Waiting Students' page... Check #" pageCheckCount, 10, 50
        Sleep 100
    }
    
    ; PageTarget found
    ToolTip "Found 'Waiting Students' page! Starting detector...", 10, 50
    Sleep 1000
    ToolTip ""
    
    ; PageTarget found, close the waiting message if still open
    try {
        WinClose("Page Detection")
    }
    
    IsActive := true
    MsgBox "Detector activated! Monitoring for waiting students... Press Ctrl+Shift+Q to quit."
    
    ; Main detection loop
    while (IsActive) {
        ; Debug: Show what we're looking for
        ToolTip "Scanning for upgrade popup and waiting students...", 10, 10
        
        ; Check for upgrade popup first
        X := ""
        Y := ""
        if (UpgradeTarget != "" && (result := FindText(&X, &Y, 1593, 1009, 1918, 1309, 0, 0, UpgradeTarget))) {
            ToolTip "Found upgrade popup! Clicking...", 10, 10
            Click X, Y
            MsgBox "Clicked upgrade popup at " X ", " Y
            Sleep 1000
            continue  ; Skip to next iteration after handling upgrade
        }
        
        ; Search for waiting student indicator
        X := ""
        Y := ""
        if (result := FindText(&X, &Y, 1273, 1188, 1607, 1423, 0, 0, WaitingTarget)) {
            ToolTip "Found waiting student! Clicking and extracting name...", 10, 10
            
            ; Step 1: Click on the WaitingTarget
            Click X, Y
            
            ; Step 2: Extract student name from region left of waiting indicator
            studentName := ExtractStudentName(X, Y)
            
            ; Step 3: Start repeating notification sound (every 2 seconds)
            global SoundTimer
            PlayNotificationSound()  ; Play immediately
            SoundTimer := SetTimer(PlayNotificationSound, 2000)  ; Then every 2 seconds
            
            ToolTip ""  ; Clear tooltip
            
            ; Step 4: Show message box with session opened message
            if (studentName != "") {
                MsgBox("A session with " . studentName . " has opened", "Session Started", "OK")
            } else {
                MsgBox("A session has opened", "Session Started", "OK")
            }
            
            ; Step 5: When OK is clicked, stop the sound
            if (SoundTimer != "") {
                SetTimer(SoundTimer, 0)  ; Stop the timer
                SoundTimer := ""
            }
            
            IsActive := false
            break
        }
        
        ; Wait 50ms before next scan (faster detection)
        Sleep 50
        
        ; Continue monitoring (removed window existence check)
    }
    
    ; Clear tooltip when done
    ToolTip ""
}