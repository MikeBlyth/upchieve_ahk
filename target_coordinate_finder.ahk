#Requires AutoHotkey v2.0
#Include FindTextv2.ahk

; Target Coordinate Finder Utility
; Allows pasting multiple search targets and finding their coordinates

; Create main GUI
mainGui := Gui("+Resize", "Target Coordinate Finder")
mainGui.OnEvent("Close", GuiClose)

; Instructions
mainGui.AddText("w400", "Paste target patterns below (one per line). Format: |<name>*tolerance$width.hexdata")

; Input area for targets
mainGui.AddText("xm y+10", "Target Patterns:")
targetEdit := mainGui.AddEdit("xm y+5 w400 h150 VScroll")

; Tolerance inputs
mainGui.AddText("xm y+10", "Tolerance 1:")
tol1Edit := mainGui.AddEdit("x+10 yp w60")
tol1Edit.Text := "0.15"

mainGui.AddText("x+20 yp", "Tolerance 2:")
tol2Edit := mainGui.AddEdit("x+10 yp w60")
tol2Edit.Text := "0.10"

; Search button
searchBtn := mainGui.AddButton("xm y+20 w100 h30", "Search All")
searchBtn.OnEvent("Click", SearchAllTargets)

; Results area
mainGui.AddText("xm y+10", "Results:")
resultsEdit := mainGui.AddEdit("xm y+5 w400 h200 VScroll ReadOnly")

; Clear button
clearBtn := mainGui.AddButton("xm y+10 w100 h30", "Clear Results")
clearBtn.OnEvent("Click", ClearResults)

; Show GUI
mainGui.Show("w420 h550")

; Event handlers
GuiClose(*) {
    ExitApp()
}

ClearResults(*) {
    resultsEdit.Text := ""
}

; Function to search for all targets
SearchAllTargets(*) {
    targets := StrSplit(Trim(targetEdit.Text), "`n")
    tol1 := Float(tol1Edit.Text)
    tol2 := Float(tol2Edit.Text)
    
    if (targets.Length == 0 || targets[1] == "") {
        MsgBox("Please enter at least one target pattern.")
        return
    }
    
    results := "Search Results:`r`n"
    results .= "================`r`n"
    results .= "Tolerance 1: " . Round(tol1, 2) . ", Tolerance 2: " . Round(tol2, 2) . "`r`n`r`n"
    
    for index, target in targets {
        target := Trim(target)
        if (target == "" || !InStr(target, "|<")) {
            continue
        }
        
        ; Extract name from target pattern
        nameStart := InStr(target, "|<") + 2
        nameEnd := InStr(target, ">", false, nameStart) - 1
        targetName := SubStr(target, nameStart, nameEnd - nameStart + 1)
        
        ; Search for target
        X := ""
        Y := ""
        found := false
        
        try {
            if (result := FindText(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, tol1, tol2, target)) {
                found := true
                
                ; Calculate left edge and middle Y coordinates
                ; Parse width from target pattern
                widthStart := InStr(target, "$") + 1
                widthEnd := InStr(target, ".", false, widthStart) - 1
                targetWidth := Integer(SubStr(target, widthStart, widthEnd - widthStart + 1))
                
                ; FindText returns center coordinates, convert to left edge
                leftX := X - (targetWidth / 2)
                middleY := Y
                
                results .= targetName . ": Found=YES, Center=(" . X . "," . Y . "), LeftEdge=" . Round(leftX) . ", MiddleY=" . middleY . ", Width=" . targetWidth . "px`r`n`r`n"
            } else {
                results .= targetName . ": Found=NO`r`n`r`n"
            }
        } catch Error as e {
            results .= targetName . ": Error=" . e.Message . "`r`n`r`n"
        }
    }
    
    resultsEdit.Text := results
    
    ; Auto-scroll to bottom
    resultsEdit.Focus()
    Send("^{End}")
}

; Hotkey to close
^q::ExitApp()