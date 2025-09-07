#Requires AutoHotkey v2.0
#Include FindTextv2.ahk

; My Turn Monitor
; Monitors for game turn targets and plays sound when found

; Game targets to search for
GameTargets := "|<Game1>*163$70.00000000000000000000000000000000000000000000000000000000000001y0000000000Tw00000001k1Us0000000Tzw1U0000003XUk60000000M630M0001zznUM41U0007zzA000A0000Tzwk003U0001zzVU00600007zw3k00M0000TzU4000k0001zw0k00700007zU3001w0000Tw0A000s0001zU0k001s0007w03U003U000TU0Q00070001w030080Q0007U0801U1s000Q01UE207U001U061UA0S000400MDzk3s000001ljzkT0000003wDzzw000000300DzU000000000Tw0000000000D0000000U" . "|<Game2>*169$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw007yDwzzzzzs00TyDlzzzzzk01zwTbzzzzzU07zwSDzzzzz00Tzswzzzzzy01zzsls3tzzw07zzlbU3nzzs0TzzkCDXbzzk1zzzUwzbDzzU7zzzVlz6Tzz0Tzzz7XyAzzy1zzzyD7wNzzw7zzzwSDslzzsTzzzsyTnXzzlzzzzlwT77zzbzzzzXw0T3zzTzzzz7w1z7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

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

; Main monitoring loop
while (IsActive) {
    ; Search for game targets (3 times per second = 333ms intervals)
    X := ""
    Y := ""
    result := FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, toleranceVar, toleranceText, GameTargets)
    
    if (result) {
        ; Target is present
        lastSeenTime := A_TickCount
        
        if (!targetFound) {
            ; Target found for first time - play sound
            if (FileExist(soundFile)) {
                SoundPlay(soundFile)
            } else {
                ; Fallback beep if sound file not found
                SoundBeep(800, 300)
            }
            targetFound := true
        }
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