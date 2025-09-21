#Requires AutoHotkey v2.0

; Popup Pattern Tester - Test FindText patterns with adjustable parameters
; Based on ocr_tester.ahk design

#Include "FindTextv2.ahk"
#Include "ahk_utilities.ahk"

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
bindWindowBtn := ""
statusText := ""
bindingStatusText := ""
findAllCheck := ""
screenshotCheck := ""

; Window binding variables
boundWindowID := ""
windowBindingStatus := "No window bound"

; Search region variables
searchX1 := 0
searchY1 := 0
searchX2 := 0
searchY2 := 0
regionSelected := false

; Command storage for copying
currentCommand := ""

; Ensure clean startup - unbind any previous FindText window bindings
FindText().BindWindow(0)

; Set coordinate mode to screen for mouse operations
CoordMode("Mouse", "Screen")

; Create GUI
CreateGUI()

CreateGUI() {
    global

    myGui := Gui("+Resize +AlwaysOnTop", "Popup Pattern Tester")
    myGui.SetFont("s10")

    ; Handle window close event
    myGui.OnEvent("Close", (*) => ExitApp())

    ; Pattern input
    myGui.Add("Text", "x10 y10", "Test Patterns (separated by . or |):")
    patternEdit := myGui.Add("Edit", "x10 y35 w600 h100 VScroll")

    ; Default popup patterns - properly quoted
    defaultPatterns := '"|<Waiting>*152$38.000001k00000w00000T00400Tk0700TQ07k0770Dk001kDk000QDk0007DU0001rU0000RU00007S00001ns0000QDU00070y0001k3w000Q0Dk00700w001k03000Q0000070000008"'

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

    ; Window binding button
    bindWindowBtn := myGui.Add("Button", "x280 y260 w120 h30", "Bind Window")
    bindWindowBtn.OnEvent("Click", BindWindow)

    ; Copy command button
    copyBtn := myGui.Add("Button", "x410 y260 w100 h30", "Copy Command")
    copyBtn.OnEvent("Click", CopyCommand)

    ; Close button
    closeBtn := myGui.Add("Button", "x520 y260 w80 h30", "Close")
    closeBtn.OnEvent("Click", (*) => ExitApp())

    ; Status
    statusText := myGui.Add("Text", "x10 y300 w600", "Status: Ready. Click 'Select Search Area' to define search region.")

    ; Window binding status
    bindingStatusText := myGui.Add("Text", "x10 y320 w600", "Window Binding: " . windowBindingStatus)

    ; Results
    myGui.Add("Text", "x10 y350", "Results:")
    resultsList := myGui.Add("Edit", "x10 y370 w600 h200 ReadOnly VScroll")

    myGui.Show("x100 y100 w620 h590")
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

    ; Ensure we use screen coordinates
    CoordMode("Mouse", "Screen")

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

    statusText.Text := "Status: Search region selected: " . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2 . " (screen coords)"

    ; Debug: Show what we captured
    WriteLog("FPT Region Selection:")
    WriteLog("  Start: " . startX . "," . startY)
    WriteLog("  End: " . endX . "," . endY)
    WriteLog("  Final: " . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2)
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

    ; Show result immediately
    if (result && result.Length > 0) {
        output .= "RESULT: FOUND " . result.Length . " match(es)`r`n"
        if (result.Length > 0) {
            output .= "  First match: " . result[1].id . " at (" . result[1].x . "," . result[1].y . ")`r`n"
        }
    } else {
        output .= "RESULT: NOT FOUND`r`n"
    }

    ; Generate exact executable command string
    output .= "`r`n=== ACTUAL EXECUTABLE COMMAND ===`r`n"

    ; Parse and clean patterns - split on '.', strip quotes, rejoin
    rawPatterns := StrReplace(patterns, "`r", "")
    rawPatterns := StrReplace(rawPatterns, "`n", "")

    ; Split on '.' to handle multiple quoted patterns
    patternParts := StrSplit(rawPatterns, ".")
    cleanedParts := []

    for index, part in patternParts {
        ; Trim whitespace
        cleanPart := Trim(part)

        ; Remove surrounding quotes if present
        if (SubStr(cleanPart, 1, 1) == '"' && SubStr(cleanPart, -1) == '"') {
            cleanPart := SubStr(cleanPart, 2, StrLen(cleanPart) - 2)
        }

        ; Add to cleaned parts if not empty
        if (cleanPart != "") {
            cleanedParts.Push(cleanPart)
        }
    }

    ; Join all parts back together
    cleanPatterns := ""
    for index, part in cleanedParts {
        cleanPatterns .= part
    }

    ; Store the full executable command (for copying)
    global currentCommand
    currentCommand := "result := FindText(,, "
    currentCommand .= searchX1 . ", " . searchY1 . ", " . searchX2 . ", " . searchY2 . ", "
    currentCommand .= Format("{:.3f}", err1) . ", " . Format("{:.3f}", err2) . ", "

    ; Handle pattern quoting - patterns from edit box now need quotes
    currentCommand .= '"' . cleanPatterns . '", '

    currentCommand .= useScreenshot . ", " . findAll . ")"

    ; Show the command (truncated for display)
    displayCommand := "result := FindText(,, "
    displayCommand .= searchX1 . ", " . searchY1 . ", " . searchX2 . ", " . searchY2 . ", "
    displayCommand .= Format("{:.3f}", err1) . ", " . Format("{:.3f}", err2) . ", "
    displayCommand .= '"[PATTERN]", '
    displayCommand .= useScreenshot . ", " . findAll . ")"

    output .= displayCommand . "`r`n"
    output .= "`r`n(Full command saved for copying - use 'Copy Command' button)`r`n"

    ; Show what actually got executed with debug info
    output .= "`r`n=== DEBUG: ACTUAL EXECUTION ===`r`n"
    output .= "Parameters passed to FindText():`r`n"
    output .= "  X1=" . searchX1 . ", Y1=" . searchY1 . ", X2=" . searchX2 . ", Y2=" . searchY2 . "`r`n"
    output .= "  err1=" . Format("{:.3f}", err1) . ", err2=" . Format("{:.3f}", err2) . "`r`n"
    output .= "  useScreenshot=" . useScreenshot . " (0=reuse last, 1=take new)`r`n"
    output .= "  findAll=" . findAll . " (0=first match only, 1=all matches)`r`n"
    output .= "  pattern length=" . StrLen(cleanPatterns) . " characters`r`n"

    ; Show truncated pattern for readability
    patternDisplay := cleanPatterns
    if (StrLen(patternDisplay) > 80) {
        patternDisplay := SubStr(patternDisplay, 1, 17) . "..."
    }
    output .= "  exact pattern: [" . patternDisplay . "]`r`n"

    ; Also show alternative wait syntax
    output .= "`r`n=== WAIT SYNTAX ALTERNATIVES ===`r`n"
    output .= "Wait 10 seconds: FindText(&x:='wait', &y:=10, " . searchX1 . ", " . searchY1 . ", " . searchX2 . ", " . searchY2 . ", " . Format("{:.3f}", err1) . ", " . Format("{:.3f}", err2) . ", patterns)`r`n"
    output .= "Wait infinite: FindText(&x:='wait', &y:=-1, " . searchX1 . ", " . searchY1 . ", " . searchX2 . ", " . searchY2 . ", " . Format("{:.3f}", err1) . ", " . Format("{:.3f}", err2) . ", patterns)`r`n"
    output .= "Wait disappear: FindText(&x:='wait0', &y:=5, " . searchX1 . ", " . searchY1 . ", " . searchX2 . ", " . searchY2 . ", " . Format("{:.3f}", err1) . ", " . Format("{:.3f}", err2) . ", patterns)`r`n"

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

BindWindow(*) {
    global

    statusText.Text := "Status: Select a window to bind FindText to (or cancel to unbind)..."

    ; Use GetTargetWindow utility function (handles unbinding automatically on cancel)
    windowID := GetTargetWindow("Click on the window to bind FindText to...", false)

    if (windowID != "") {
        boundWindowID := windowID

        ; Get window title for display
        try {
            windowTitle := WinGetTitle("ahk_id " . windowID)
            if (StrLen(windowTitle) > 50) {
                windowTitle := SubStr(windowTitle, 1, 47) . "..."
            }
        } catch {
            windowTitle := "Unknown Window"
        }

        windowBindingStatus := "Bound to window ID " . windowID . " (" . windowTitle . ")"
        bindingStatusText.Text := "Window Binding: " . windowBindingStatus
        statusText.Text := "Status: Window bound successfully!"
    } else {
        ; User cancelled - GetTargetWindow already cleared the binding
        boundWindowID := ""
        windowBindingStatus := "No window bound"
        bindingStatusText.Text := "Window Binding: " . windowBindingStatus
        statusText.Text := "Status: Window binding cleared."
    }
}

CopyCommand(*) {
    global

    if (!regionSelected) {
        statusText.Text := "Status: Please select a search area first!"
        return
    }

    if (currentCommand == "") {
        statusText.Text := "Status: Please run a test first to generate a command!"
        return
    }

    ; Copy the command to clipboard
    A_Clipboard := currentCommand
    statusText.Text := "Status: Command copied to clipboard!"
}

; Hotkey to close
Esc::ExitApp()