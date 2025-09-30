#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include ahk_utilities.ahk

; Test script for FindAndClick function
; Allows user to enter search parameters and test the function

; Create GUI for input
testGui := Gui("+AlwaysOnTop", "FindAndClick Test")

; Target string input
testGui.AddText("xm y+10", "Target String (FindText pattern):")
targetEdit := testGui.AddEdit("xm y+5 w400")
targetEdit.Text := "|<test>*50$20.zzs7zw7zy"  ; Example pattern

; Coordinates input
testGui.AddText("xm y+15", "Search Coordinates (leave blank to use full window):")
testGui.AddText("xm y+5", "X1:")
x1Edit := testGui.AddEdit("x+5 yp w60")
testGui.AddText("x+10 yp", "Y1:")
y1Edit := testGui.AddEdit("x+5 yp w60")
testGui.AddText("x+10 yp", "X2:")
x2Edit := testGui.AddEdit("x+5 yp w60")
testGui.AddText("x+10 yp", "Y2:")
y2Edit := testGui.AddEdit("x+5 yp w60")

; Error tolerance input
testGui.AddText("xm y+15", "Error Tolerance 1:")
err1Edit := testGui.AddEdit("x+5 yp w60")
err1Edit.Text := "0.15"
testGui.AddText("x+10 yp", "Error Tolerance 2:")
err2Edit := testGui.AddEdit("x+5 yp w60")
err2Edit.Text := "0.10"

; Buttons
testBtn := testGui.AddButton("xm y+20 w100 h30", "Test")
clearBtn := testGui.AddButton("x+10 yp w100 h30", "Clear Log")
exitBtn := testGui.AddButton("x+10 yp w100 h30", "Exit")

; Results area
testGui.AddText("xm y+20", "Results:")
resultsEdit := testGui.AddEdit("xm y+5 w400 h200 ReadOnly VScroll")

; Button handlers
testBtn.OnEvent("Click", TestFindAndClick)
clearBtn.OnEvent("Click", ClearResults)
exitBtn.OnEvent("Click", (*) => ExitApp())

; Show GUI
testGui.Show()

; Test function
TestFindAndClick(*) {
    ; Get input values
    targetString := targetEdit.Text
    x1 := (x1Edit.Text != "") ? Integer(x1Edit.Text) : ""
    y1 := (y1Edit.Text != "") ? Integer(y1Edit.Text) : ""
    x2 := (x2Edit.Text != "") ? Integer(x2Edit.Text) : ""
    y2 := (y2Edit.Text != "") ? Integer(y2Edit.Text) : ""
    err1 := Float(err1Edit.Text)
    err2 := Float(err2Edit.Text)

    if (targetString == "") {
        AddResult("ERROR: Target string cannot be empty")
        return
    }

    ; Prompt user to select target window
    AddResult("=== Starting FindAndClick Test ===")
    AddResult("Target: " . targetString)

    coordStr := ""
    if (x1 != "" && y1 != "" && x2 != "" && y2 != "") {
        coordStr := "(" . x1 . "," . y1 . " to " . x2 . "," . y2 . ")"
    } else {
        coordStr := "(using full window)"
    }
    AddResult("Search area: " . coordStr)
    AddResult("Error tolerance: " . err1 . ", " . err2)
    AddResult("")

    ; Get target window
    windowID := GetTargetWindow("Click on the target window to search in...", false)
    if (windowID == "") {
        AddResult("Test cancelled by user")
        return
    }

    ; Activate the target window
    WinActivate("ahk_id " . windowID)
    Sleep(500)  ; Give window time to activate

    AddResult("Target window selected: " . windowID)
    AddResult("Performing FindAndClick...")

    ; Record start time
    startTime := A_TickCount

    ; Call FindAndClick
    result := FindAndClick(targetString, x1, y1, x2, y2, err1, err2)

    ; Record end time
    endTime := A_TickCount
    searchTime := endTime - startTime

    ; Report results
    if (result) {
        AddResult("SUCCESS!")
        AddResult("Found at: (" . result[1].x . "," . result[1].y . ")")
        AddResult("Search time: " . searchTime . "ms")
        AddResult("Clicked on target")
    } else {
        AddResult("FAILED - Target not found")
        AddResult("Search time: " . searchTime . "ms")
    }

    AddResult("")
    AddResult("=== Test Complete ===")
    AddResult("")
}

; Clear results
ClearResults(*) {
    resultsEdit.Text := ""
}

; Add result to results area
AddResult(text) {
    timestamp := FormatTime(A_Now, "HH:mm:ss")
    newText := "[" . timestamp . "] " . text . "`r`n"
    resultsEdit.Text := resultsEdit.Text . newText

    ; Auto-scroll to bottom
    resultsEdit.Focus()
    Send("^{End}")
}