#Requires AutoHotkey v2.0
#Include FindTextv2.ahk

; My Turn Monitor
; Monitors for game turn targets and plays sound when found

; Game targets to search for
GameTargets := "|<GamesReady>*206$56.000000000000000000000M000s0003zk03zs003zz03zzU01y3s1w3w01w0Dzw0DU0S00zy00w0D1s7z1w703VzUUVzUslkzw00zyCQQTzU0TzVr77zw07zwRlXzz01zz7Qszzk0TzlnCDzw07zwQlXzz3Vzz7AQTzksTzln77zsT7zsQlkzw7kzyCQC7y3w7y3b3kS0zUS1nkS00Tw00ww7k0DzU0ST0w0Dzy077k70Tzzw1nw1kDzzz0Qz0M3zzzk7Dk60Tzzw1nw1k1zzs0Qz0w07zw07bkS00zw00wwD0s7y0s7D3VzUz0zUtlszw7kzwCQQTzVwDzVr77zsS7zwRlXzz3Vzz7AMzzk0Tzln6Dzw0DzwQlXzz01zz7AQTzk0Tzln77zs07zsRlkzy00zyCQC7z007z3b3kz1zkT1s0S00zy00w2"
    ; "<Game1>*163$70.00000000000000000000000000000000000000000000000000000000000001y0000000000Tw00000001k1Us0000000Tzw1U0000003XUk60000000M630M0001zznUM41U0007zzA000A0000Tzwk003U0001zzVU00600007zw3k00M0000TzU4000k0001zw0k00700007zU3001w0000Tw0A000s0001zU0k001s0007w03U003U000TU0Q00070001w030080Q0007U0801U1s000Q01UE207U001U061UA0S000400MDzk3s000001ljzkT0000003wDzzw000000300DzU000000000Tw0000000000D0000000U" . 
    ; "|<Game2>*169$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw007yDwzzzzzs00TyDlzzzzzk01zwTbzzzzzU07zwSDzzzzz00Tzswzzzzzy01zzsls3tzzw07zzlbU3nzzs0TzzkCDXbzzk1zzzUwzbDzzU7zzzVlz6Tzz0Tzzz7XyAzzy1zzzyD7wNzzw7zzzwSDslzzsTzzzsyTnXzzlzzzzlwT77zzbzzzzXw0T3zzTzzzz7w1z7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz" .
    ; "|<Game>*158$20.zzzzzzzzzzzzyzzzDzzXzzkzzsDzw3zy0zz0DzU3zk0zs0Dw03y00z00DU03k00s00DzzzzzzzzzzzzzU" .
    ; "|<Game>*160$23.zzzzzzzzzzzy003y007y00Dy00Ty00zy01zy03zy07zy0Dzy0Tzy0zzy1zzy3zzy7zzyDzzyTzzyzzzzzzzzzzzzk"


; Search area coordinates
searchX1 := 100
searchY1 := 0
searchX2 := 3000
searchY2 := 100

; Tolerance values
toleranceVar := 0.05
toleranceText := 0.15

; Sound file
soundFile := "water_drop.mp3"

; State variables
targetFound := false
lastSeenTime := 0
IsActive := true

; Window selection and binding
startupResult := MsgBox("Click in the game window...", "My Turn Monitor - Click Game Window", "OKCancel 4096")
if (startupResult = "Cancel") {
    ExitApp()  ; Exit application
}

; Wait for user to click and capture the window
global targetWindowID := ""
; Show tooltip that follows mouse cursor
while (!GetKeyState("LButton", "P")) {
    MouseGetPos(&mouseX, &mouseY)
    ToolTip "Click on the game window now...", , , 3
    Sleep(50)
}
KeyWait("LButton", "U")  ; Wait for button release
MouseGetPos(&mouseX, &mouseY, &targetWindowID)  ; Get window ID under mouse
ToolTip "", , , 3  ; Clear tooltip

; Bind FindText to the selected window for improved performance and reliability
; Mode 4 is essential for proper window targeting
bindResult := FindText().BindWindow(targetWindowID, 4)

; Confirm window selection
MsgBox("Game window selected! Starting turn monitor...", "Window Selected", "OK 4096")



; Main monitoring loop
while (IsActive) {
    ; Search for game targets (3 times per second = 333ms intervals)
    WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)
    ; Search box is in to upper-right corner of window
    searchX1 := winWidth - 600
    searchX2 := winWidth - 400
    searchy1 := 200
    searchY2 := 300

    X := ""
    Y := ""
    result := FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, toleranceVar, toleranceText, GameTargets)
    
    if (result) {
        ; Target is present
        lastSeenTime := A_TickCount
        
        if (!targetFound) {
            ; Target found for first time - start repeated beeping
            targetFound := true
        }

        ; Play sound/beep repeatedly while target is present
        if (FileExist(soundFile)) {
            SoundPlay(soundFile)
        } else {
            ; Fallback beep if sound file not found - higher frequency for more volume
            SoundBeep(1200, 300)
        }

        ; Sleep for 60 seconds before next detection cycle
        Sleep(60000)
    } else if (targetFound) {
        ; Target not found, but we think it's still there
        ; Check if it's been absent for 10 seconds (10000ms)
        if (A_TickCount - lastSeenTime > 10000) {
            ; Target has been gone for 10 seconds - consider it truly gone
            targetFound := false
        }
    }
    
    ; Check 3 times per second (333ms interval)
    Sleep(333)
}

; Hotkey to exit (Ctrl+Shift+Q)
^+q::ExitApp()