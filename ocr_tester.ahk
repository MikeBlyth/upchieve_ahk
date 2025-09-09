#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk
#Include ocr_functions.ahk

; OCR Testing Application
; Tool for tuning OCR parameters and testing character recognition

CoordMode("Mouse", "Screen")

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
MainGui := Gui("+Resize +MinSize400x300 +AlwaysOnTop", "OCR Parameter Tester")
MainGui.OnEvent("Close", (*) => ExitApp())

; Region Selection Section
MainGui.AddText("Section", "1. Region Selection:")
RegionText := MainGui.AddText("w300 h20", "Click 'Select Region' then drag on screen to select area")
SelectBtn := MainGui.AddButton("w100 h30", "Select Region")
SelectBtn.OnEvent("Click", (*) => StartRegionSelection())

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
Tolerance2Edit := MainGui.AddEdit("w100 h20", "0.10")
Tolerance2Slider := MainGui.AddSlider("w200 h30 Range0-100 TickInterval10", 10)
Tolerance2Slider.OnEvent("Change", (*) => Tolerance2Edit.Value := Format("{:.2f}", Tolerance2Slider.Value / 100))
Tolerance2Edit.OnEvent("Change", (*) => Tolerance2Slider.Value := Float(Tolerance2Edit.Value) * 100)

; Proximity threshold
MainGui.AddText("xm", "Proximity Threshold (pixels):")
ProximityEdit := MainGui.AddEdit("w100 h20", "10")
ProximitySlider := MainGui.AddSlider("w200 h30 Range1-50 TickInterval5", 10)
ProximitySlider.OnEvent("Change", (*) => ProximityEdit.Value := ProximitySlider.Value)
ProximityEdit.OnEvent("Change", (*) => ProximitySlider.Value := Integer(ProximityEdit.Value))

; Test Section
MainGui.AddText("Section xm y+20", "3. Testing:")
AutoReloadCheckbox := MainGui.AddCheckbox("Checked", "Auto-reload alphabet on each test")
TestBtn := MainGui.AddButton("xm w100 h30", "Test OCR")
TestBtn.OnEvent("Click", (*) => RunOCRTest())

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
    global SelectionStartX, SelectionStartY, SelectionEndX, SelectionEndY, IsSelecting
    
    MainGui.Hide()
    
    ; Show instruction and wait for click
    ToolTip("Click and drag to select region. Press ESC to cancel.", A_ScreenWidth/2, A_ScreenHeight/2)
    
    ; Set up hotkey to cancel
    Hotkey("Esc", (*) => CancelRegionSelection(), "On")
    
    ; Use simple click-drag detection
    KeyWait("LButton", "D")  ; Wait for left button down
    
    ; Check if ESC was pressed
    if (GetKeyState("Esc", "P")) {
        CancelRegionSelection()
        return
    }
    
    ; Get start position
    MouseGetPos(&SelectionStartX, &SelectionStartY)
    IsSelecting := true
    
    ; Wait for drag completion
    KeyWait("LButton", "U")  ; Wait for left button up
    
    ; Get end position
    MouseGetPos(&SelectionEndX, &SelectionEndY)
    IsSelecting := false
    
    ; Debug: Show what we captured
    ToolTip("Start: " . SelectionStartX . "," . SelectionStartY . " End: " . SelectionEndX . "," . SelectionEndY, A_ScreenWidth/2, A_ScreenHeight/2)
    Sleep(2000)
    ToolTip()
    
    ; Complete selection
    CompleteRegionSelection()
}

; Complete the region selection
CompleteRegionSelection() {
    global SelectionStartX, SelectionStartY, SelectionEndX, SelectionEndY, HasSelection, CurrentRegionText
    
    ; Clean up
    Hotkey("Esc", (*) => CancelRegionSelection(), "Off")
    ToolTip()
    
    ; Debug: Check what values we have here
    MsgBox("Debug in CompleteRegionSelection:`nStart: " . SelectionStartX . "," . SelectionStartY . "`nEnd: " . SelectionEndX . "," . SelectionEndY, "Debug", "OK")
    
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
    global IsSelecting, RegionText
    
    ; Clean up
    Hotkey("Esc", (*) => CancelRegionSelection(), "Off")
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
    
    ; Check if we should reload alphabet
    if (AutoReloadCheckbox.Value) {
        ResultText.Value := "Reloading alphabet characters and testing..."
        ; Reload alphabet characters to pick up any changes
        LoadAlphabetCharacters()
    } else {
        ResultText.Value := "Testing with current alphabet..."
    }
    
    ; Get current parameter values
    tolerance1 := Float(Tolerance1Edit.Value)
    tolerance2 := Float(Tolerance2Edit.Value)  
    proximityThreshold := Integer(ProximityEdit.Value)
    
    ; Run OCR with current parameters
    result := ExtractTextFromRegion(SelectionStartX, SelectionStartY, SelectionEndX, SelectionEndY, tolerance1, tolerance2, proximityThreshold)
    
    ; Display main result with method indicator
    methodText := result.HasOwnProp("method") ? " [" . result.method . "]" : ""
    if (result.text != "") {
        ResultText.Value := "Extracted Text: '" . result.text . "'" . methodText
    } else {
        ResultText.Value := "No text extracted from selected region" . methodText
    }
    
    ; Display character details
    charDetails := "Individual Method: Found " . result.chars.Length . " clean characters"
    if (result.rawChars.Length > 0) {
        charDetails .= " (from " . result.rawChars.Length . " raw detections)`n`n"
    } else {
        charDetails .= "`n`n"
    }
    
    ; Show clean characters (after filtering and prioritization)
    if (result.chars.Length > 0) {
        charDetails .= "CLEAN CHARACTERS (final result):`n"
        for i, char in result.chars {
            charDetails .= i . ": '" . char.id . "' at (" . char.x . "," . char.y . ")`n"
        }
    }
    
    ; Always show raw detections for analysis, sorted by x-location
    if (result.rawChars.Length > 0) {
        ; Sort raw characters by X coordinate
        sortedRawChars := result.rawChars.Clone()
        Loop sortedRawChars.Length - 1 {
            i := A_Index
            Loop sortedRawChars.Length - i {
                j := A_Index
                if (sortedRawChars[j].x > sortedRawChars[j+1].x) {
                    temp := sortedRawChars[j]
                    sortedRawChars[j] := sortedRawChars[j+1] 
                    sortedRawChars[j+1] := temp
                }
            }
        }
        
        charDetails .= "`nRAW DETECTIONS (sorted by x-location):`n"
        for i, char in sortedRawChars {
            charDetails .= char.x . " " . char.id . "`n"
        }
    }
    
    ; Show filtering summary
    if (result.rawChars.Length != result.chars.Length) {
        filtered := result.rawChars.Length - result.chars.Length
        charDetails .= "`nFiltering: " . result.rawChars.Length . " raw -> " . result.chars.Length . " clean (" . filtered . " removed)`n"
    }
    
    CharDetailsText.Value := charDetails
}