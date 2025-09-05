#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk
#Include ocr_functions.ahk

; OCR Testing Application
; Tool for tuning OCR parameters and testing character recognition

; Global variables
SelectionStartX := 0
SelectionStartY := 0
SelectionEndX := 0
SelectionEndY := 0
IsSelecting := false
HasSelection := false

; Load character library on startup
LoadAlphabetCharacters()

; Create main GUI
MainGui := Gui("+Resize +MinSize400x300", "OCR Parameter Tester")
MainGui.OnEvent("Close", (*) => ExitApp())

; Region Selection Section
MainGui.AddText("Section", "1. Region Selection:")
RegionText := MainGui.AddText("w300 h20", "Click 'Select Region' then drag on screen to select area")
SelectBtn := MainGui.AddButton("w100 h30", "Select Region")
SelectBtn.OnEvent("Click", StartRegionSelection)

; Current selection display
CurrentRegionText := MainGui.AddText("w300 h20", "No region selected")

; Parameter Controls Section
MainGui.AddText("Section xm y+20", "2. OCR Parameters:")

; Tolerance 1 (error1)
MainGui.AddText("", "Tolerance 1 (0.0 - 1.0):")
Tolerance1Edit := MainGui.AddEdit("w100 h20", "0.15")
Tolerance1Slider := MainGui.AddSlider("w200 h30 Range0-100 TickInterval10", 15)
Tolerance1Slider.OnEvent("Change", (*) => Tolerance1Edit.Value := Format("{:.2f}", Tolerance1Slider.Value / 100))
Tolerance1Edit.OnEvent("Change", (*) => Tolerance1Slider.Value := Float(Tolerance1Edit.Value) * 100)

; Tolerance 2 (error2) 
MainGui.AddText("xm", "Tolerance 2 (0.0 - 1.0):")
Tolerance2Edit := MainGui.AddEdit("w100 h20", "0.05")
Tolerance2Slider := MainGui.AddSlider("w200 h30 Range0-100 TickInterval10", 5)
Tolerance2Slider.OnEvent("Change", (*) => Tolerance2Edit.Value := Format("{:.2f}", Tolerance2Slider.Value / 100))
Tolerance2Edit.OnEvent("Change", (*) => Tolerance2Slider.Value := Float(Tolerance2Edit.Value) * 100)

; Proximity threshold
MainGui.AddText("xm", "Proximity Threshold (pixels):")
ProximityEdit := MainGui.AddEdit("w100 h20", "8")
ProximitySlider := MainGui.AddSlider("w200 h30 Range1-50 TickInterval5", 8)
ProximitySlider.OnEvent("Change", (*) => ProximityEdit.Value := ProximitySlider.Value)
ProximityEdit.OnEvent("Change", (*) => ProximitySlider.Value := Integer(ProximityEdit.Value))

; Test Section
MainGui.AddText("Section xm y+20", "3. Testing:")
TestBtn := MainGui.AddButton("w100 h30", "Test OCR")
TestBtn.OnEvent("Click", RunOCRTest)

; Results Section
MainGui.AddText("Section xm y+10", "4. Results:")
ResultText := MainGui.AddEdit("w400 h60 ReadOnly", "Results will appear here...")

; Character Details Section
MainGui.AddText("xm y+10", "Character Details:")
CharDetailsText := MainGui.AddEdit("w400 h100 ReadOnly", "Individual character information will appear here...")

; Show GUI
MainGui.Show()

; Function to start region selection
StartRegionSelection() {
    MainGui.Hide()
    RegionText.Value := "Click and drag on screen to select region. Press ESC to cancel."
    
    ; Set up mouse hooks for region selection
    SetupRegionSelection()
}

; Setup region selection with mouse hooks
SetupRegionSelection() {
    ; Install mouse hook
    OnMessage(0x0201, WM_LBUTTONDOWN)  ; Left button down
    OnMessage(0x0202, WM_LBUTTONUP)    ; Left button up  
    OnMessage(0x0200, WM_MOUSEMOVE)    ; Mouse move
    
    ; Show instruction tooltip
    ToolTip("Click and drag to select region. Press ESC to cancel.", A_ScreenWidth/2, A_ScreenHeight/2)
    
    ; Wait for ESC key or selection completion
    Hotkey("Esc", CancelRegionSelection, "On")
}

; Mouse event handlers for region selection
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global
    if (!IsSelecting) {
        IsSelecting := true
        SelectionStartX := lParam & 0xFFFF
        SelectionStartY := lParam >> 16
        SetCapture(hwnd)
    }
}

WM_LBUTTONUP(wParam, lParam, msg, hwnd) {
    global
    if (IsSelecting) {
        IsSelecting := false
        SelectionEndX := lParam & 0xFFFF
        SelectionEndY := lParam >> 16
        ReleaseCapture()
        CompleteRegionSelection()
    }
}

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global
    if (IsSelecting) {
        ; Update selection end point for visual feedback if implemented
        SelectionEndX := lParam & 0xFFFF
        SelectionEndY := lParam >> 16
    }
}

; Complete the region selection
CompleteRegionSelection() {
    global
    
    ; Clean up hooks
    OnMessage(0x0201, WM_LBUTTONDOWN, 0)  ; Remove hook
    OnMessage(0x0202, WM_LBUTTONUP, 0) 
    OnMessage(0x0200, WM_MOUSEMOVE, 0)
    Hotkey("Esc", CancelRegionSelection, "Off")
    ToolTip()
    
    ; Ensure proper coordinate order (top-left to bottom-right)
    x1 := Min(SelectionStartX, SelectionEndX)
    y1 := Min(SelectionStartY, SelectionEndY)
    x2 := Max(SelectionStartX, SelectionEndX)
    y2 := Max(SelectionStartY, SelectionEndY)
    
    ; Update coordinates
    SelectionStartX := x1
    SelectionStartY := y1
    SelectionEndX := x2
    SelectionEndY := y2
    
    HasSelection := true
    
    ; Update display
    width := x2 - x1
    height := y2 - y1
    CurrentRegionText.Value := "Region: (" . x1 . "," . y1 . ") to (" . x2 . "," . y2 . ") [" . width . "x" . height . "]"
    
    MainGui.Show()
}

; Cancel region selection
CancelRegionSelection() {
    global
    
    ; Clean up hooks
    OnMessage(0x0201, WM_LBUTTONDOWN, 0)
    OnMessage(0x0202, WM_LBUTTONUP, 0)
    OnMessage(0x0200, WM_MOUSEMOVE, 0)
    Hotkey("Esc", CancelRegionSelection, "Off")
    ToolTip()
    
    IsSelecting := false
    MainGui.Show()
    RegionText.Value := "Selection cancelled. Click 'Select Region' to try again."
}

; Run OCR test on selected region
RunOCRTest() {
    global
    
    if (!HasSelection) {
        ResultText.Value := "Please select a region first!"
        return
    }
    
    ; Get current parameter values
    tolerance1 := Float(Tolerance1Edit.Value)
    tolerance2 := Float(Tolerance2Edit.Value)  
    proximityThreshold := Integer(ProximityEdit.Value)
    
    ; Run OCR with current parameters
    result := ExtractTextFromRegion(SelectionStartX, SelectionStartY, SelectionEndX, SelectionEndY, tolerance1, tolerance2, proximityThreshold)
    
    ; Display main result
    if (result.text != "") {
        ResultText.Value := "Extracted Text: '" . result.text . "'"
    } else {
        ResultText.Value := "No text extracted from selected region"
    }
    
    ; Display character details
    charDetails := "Found " . result.chars.Length . " clean characters"
    if (result.rawChars.Length > 0) {
        charDetails .= " (from " . result.rawChars.Length . " raw detections)`n`n"
    } else {
        charDetails .= "`n`n"
    }
    
    ; Show individual character info
    for i, char in result.chars {
        charDetails .= i . ": '" . char.id . "' at (" . char.x . "," . char.y . ")`n"
    }
    
    if (result.chars.Length == 0 && result.rawChars.Length > 0) {
        charDetails .= "`nRaw detections (filtered out):`n"
        for i, char in result.rawChars {
            charDetails .= i . ": '" . char.id . "' at (" . char.x . "," . char.y . ")`n"
        }
    }
    
    CharDetailsText.Value := charDetails
}