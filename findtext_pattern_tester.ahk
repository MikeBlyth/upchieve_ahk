#Requires AutoHotkey v2.0

; Popup Pattern Tester - Test FindText patterns with adjustable parameters
; Based on ocr_tester.ahk design

#Include "FindTextv2.ahk"

; GUI variables
myGui := ""
patternEdit := ""
err1Slider := ""
err2Slider := ""
err1Text := ""
err2Text := ""
resultsList := ""
searchBtn := ""
selectBtn := ""
statusText := ""
findAllCheck := ""
screenshotCheck := ""

; Search region variables
searchX1 := 0
searchY1 := 0
searchX2 := 0
searchY2 := 0
regionSelected := false

; Create GUI
CreateGUI()

CreateGUI() {
    global

    myGui := Gui("+Resize +AlwaysOnTop", "Popup Pattern Tester")
    myGui.SetFont("s10")

    ; Pattern input
    myGui.Add("Text", "x10 y10", "Test Patterns (separated by . or |):")
    patternEdit := myGui.Add("Edit", "x10 y35 w600 h100 VScroll")

    ; Default popup patterns
    defaultPatterns := '"|<Upgrade>*197$75.zzzzzzzzzzzzzzzzzzzzzzzzzszss07zU7w07z7z700Ds0TU0DszssT1y31wD0z7z73y7Vy7Vy7szssTssTswDsz7z73z33z3Vz3szssTsMzzwDsT7z73z77zzVz7szssTkszzwDkz7z73w77zzVw7szss01sy0Q01z7z700z7k3U0zszssTzszsQD7z7z73zz7z3VsTsTssTzsTsQDXz3y73zzXz3VwDwDksTzwDsQDkzUsD3zzkQ3Vy6y03sTzz01wDsLw1z3zzy0TVzUzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw" . '
    . '"|<Upgrade2>*197$51.60ME0Q0X1U1W00kA8MA6Ey611a7sG4sEMAlVXEVX30YM4+448F6X0zEUV68IE024AMXWW00EXWAQQFzu7klWlW81E068qAF0+03X4FWDVEwMEz4M4+4V200V0VEaAk06A4+4EoDwEvVEX3X1X1kO4AQE4A07EVV60ks1W460k21zsTUTw0M00000000000000004" . '
    . '"|<New>*132$69.0000000000000000000000000000000000000000000000k03k0000000700S00000000w03k00000007U0S00000000y03k00000007s0S00000000z03k00000006w0S01y0Q0Q0rU3k0zw3k3k6S0S0DzkS0S0ls3k3kS1k7k6D0S0w1sC0z0kw3kD071s7s67kS1s0w71r0kS3kC03UsCs61sS1k0Q71nVkDXkTzzUwAQC0wS3zzw3XXVk3nkTzzUQQCC0SS3k003XVnk1vkS000SsCS07y1k001r0vk0zkD000Cs7S03y1s001y0zk0Dk7U707k3y01y0z1s0y0Tk07k3zz07U3q00y07zU0w0Sk03k0Dk03U1o"'

    patternEdit.Text := defaultPatterns

    ; Tolerance sliders
    myGui.Add("Text", "x10 y150", "Error Tolerance 1 (Text):")
    err1Text := myGui.Add("Text", "x200 y150 w50", "0.15")
    err1Slider := myGui.Add("Slider", "x10 y170 w200 Range0-100 TickInterval10", 15)
    err1Slider.OnEvent("Change", UpdateErr1)

    myGui.Add("Text", "x10 y200", "Error Tolerance 2 (Background):")
    err2Text := myGui.Add("Text", "x200 y200 w50", "0.10")
    err2Slider := myGui.Add("Slider", "x10 y220 w200 Range0-100 TickInterval10", 10)
    err2Slider.OnEvent("Change", UpdateErr2)

    ; FindText options
    findAllCheck := myGui.Add("Checkbox", "x250 y170", "Find All Matches")
    screenshotCheck := myGui.Add("Checkbox", "x250 y200", "Use Last Screenshot")

    ; Buttons
    selectBtn := myGui.Add("Button", "x10 y260 w150 h30", "Select Search Area")
    selectBtn.OnEvent("Click", SelectSearchArea)

    searchBtn := myGui.Add("Button", "x170 y260 w100 h30", "Test Patterns")
    searchBtn.OnEvent("Click", TestPatterns)

    ; Status
    statusText := myGui.Add("Text", "x10 y300 w600", "Status: Ready. Click 'Select Search Area' to define search region.")

    ; Results
    myGui.Add("Text", "x10 y330", "Results:")
    resultsList := myGui.Add("Edit", "x10 y350 w600 h200 ReadOnly VScroll")

    myGui.Show("x100 y100 w630 h570")
}

UpdateErr1(*) {
    global
    value := err1Slider.Value / 100
    err1Text.Text := Format("{:.2f}", value)
}

UpdateErr2(*) {
    global
    value := err2Slider.Value / 100
    err2Text.Text := Format("{:.2f}", value)
}

SelectSearchArea(*) {
    global
    statusText.Text := "Status: Click and drag to select search area..."

    ; Hide GUI temporarily
    myGui.Hide()

    ; Wait for mouse click
    KeyWait("LButton", "D")
    MouseGetPos(&startX, &startY)

    ; Track mouse drag
    while GetKeyState("LButton", "P") {
        MouseGetPos(&currentX, &currentY)
        ; Could add visual feedback here
        Sleep(10)
    }

    MouseGetPos(&endX, &endY)

    ; Set search coordinates
    searchX1 := Min(startX, endX)
    searchY1 := Min(startY, endY)
    searchX2 := Max(startX, endX)
    searchY2 := Max(startY, endY)
    regionSelected := true

    ; Show GUI again
    myGui.Show()

    statusText.Text := "Status: Search region selected: " . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2
}

TestPatterns(*) {
    global

    if (!regionSelected) {
        statusText.Text := "Status: Please select a search area first!"
        return
    }

    patterns := patternEdit.Text
    if (patterns == "") {
        statusText.Text := "Status: Please enter patterns to test!"
        return
    }

    err1 := err1Slider.Value / 100
    err2 := err2Slider.Value / 100
    findAll := findAllCheck.Value ? 1 : 0
    useScreenshot := screenshotCheck.Value ? 0 : 1  ; 0=use last screenshot, 1=take new

    statusText.Text := "Status: Testing patterns..."
    resultsList.Text := ""

/*     ; Hard-coded single test for comparison
    student := "<Student>*146$71.00000000000000000000001w3z00k000003sTzUDU000007nzzkT000000Djzzky000000TTUT1w000000yy0QTznw7k3txw0EzzbsDUTvvy01zzDkT1zzrzk3zyTUy3zzjzw0y0z1wDkzDzy1w1y3sT0yDzy3s3w7ky1w3zw7k7sDVw3s0TsDUDkT3s7m0DkT0TUy7kDa0DUy0z1wDUTT0z1w1y7sTVzzzy3zlzzkzzxzzs7zXzzUzztzzU7z3zD0znkTs03w3wS0T7U00000000000000000000001"
    result := FindText(,, 0,0,3200,2000, 0.15,0.10, student)
    if (result) {
        MsgBox("Found student at " . result[1].1  . "," . result[1].2)
    } else {
        MsgBox("Student not found")
    }
 */
    ; Test combined patterns
    startTime := A_TickCount
    result := FindText(,, searchX1, searchY1, searchX2, searchY2, err1, err2, patterns, useScreenshot, findAll)
;    result := FindText(,, searchX1, searchY1, searchX2, searchY2, err1, err2, patterns,1,0)
    searchTime := A_TickCount - startTime

    ; Log all parameters for debugging
    paramLog := "DEBUG PARAMETERS:`r`n"
    paramLog .= "  searchX1=" . searchX1 . ", searchY1=" . searchY1 . "`r`n"
    paramLog .= "  searchX2=" . searchX2 . ", searchY2=" . searchY2 . "`r`n"
    paramLog .= "  err1=" . Format("{:.3f}", err1) . ", err2=" . Format("{:.3f}", err2) . "`r`n"
    paramLog .= "  useScreenshot=" . useScreenshot . " (0=use last, 1=take new)`r`n"
    paramLog .= "  findAll=" . findAll . " (0=first only, 1=find all)`r`n"
    paramLog .= "  patterns length=" . StrLen(patterns) . " chars`r`n"
    paramLog .= "  patterns preview=" . SubStr(patterns, 1, 100) . "...`r`n"
    paramLog .= "  result=" . (result ? "object with " . result.Length . " matches" : "null/0") . "`r`n"

    output := "=== COMBINED PATTERN TEST ===`r`n"
;    output .= paramLog . "`r`n"
    output .= "Search Region: " . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2 . "`r`n"
    output .= "Tolerances: " . Format("{:.2f}", err1) . ", " . Format("{:.2f}", err2) . "`r`n"
    output .= "Options: FindAll=" . (findAll ? "Yes" : "No") . ", UseScreenshot=" . (useScreenshot ? "New" : "Last") . "`r`n"
    output .= "Search Time: " . searchTime . "ms`r`n"

    if (result && result.Length > 0) {
        output .= "FOUND " . result.Length . " match(es):`r`n"

        ; Show first 5 results
        maxResults := Min(result.Length, 5)
        loop maxResults {
            match := result[A_Index]
            output .= "  " . A_Index . ". " . match.id . " at (" . match.x . "," . match.y . "`r`n"
        }

        if (result.Length > 5) {
            output .= "  ... and " . (result.Length - 5) . " more match(es)`r`n"
        }
    } else {
        output .= "NOT FOUND`r`n"
    }

    ; Test with different tolerances
    output .= "`r`n=== TOLERANCE VARIATION TESTS ===`r`n"
    tolerancePairs := [[0.05, 0.05], [0.10, 0.08], [0.15, 1.0]]

    for pair in tolerancePairs {
        testErr1 := pair[1]
        testErr2 := pair[2]

        startTime := A_TickCount
        result := FindText(,, searchX1, searchY1, searchX2, searchY2, testErr1, testErr2, patterns, useScreenshot, findAll)
        searchTime := A_TickCount - startTime

        output .= Format("Tolerances {:.2f},{:.2f}: ", testErr1, testErr2)

        if (result && result.Length > 0) {
            output .= "FOUND " . result.Length . " match(es)"
            if (result.Length > 0) {
                output .= " - " . result[1].id . "@(" . result[1].x . "," . result[1].y . ")"
            }
        } else {
            output .= "NOT FOUND"
        }
        output .= " (" . searchTime . "ms)`r`n"
    }

    resultsList.Text := output
    statusText.Text := "Status: Pattern testing complete!"
}

; Hotkey to close
Esc::ExitApp()