#x::ExitApp  ; Win+X
#Requires AutoHotkey v2.0
;Include yaml.ahk
#Include jxon.ahk
; ###### SETUP & DEBUG OPTIONS -- CAN SKIP IN PRODUCTION OR LEAVE FOR DEBUGGING

DebugReport := 0
TimesReport := 0
target_path := "./search_images/"  ; this is where we have the images used to get page locations
TargetWindow := "UPchieve" ; Change this for testing
; ############# FUNCTION DEFINITIONS #########################

; TIMING IS FOR DEV ONLY
start_time := A_TickCount
Times := []

TimeCheck(name) {
	global Times
	global start_time
	Times.Push {name: name, time: A_TickCount - start_time}
	start_time := A_TickCount
}

; Display the collected timing data in a message box
ShowTimes() {
	global Times
	message := ""
	for index, obj in Times {
		message := "Name: " . obj.name . ", Time: " . obj.time . " ms`n"
	}
	MsgBox(message,"Timer",4096+64)
}
TimeCheck('startup')

; ########## PRODUCTION FUNCTIONS
; Maximize the window if it is not already maximized; return TRUE
MaximizeWindow() {
    if (WinGetMinMax("A") != 1) {
        WinMaximize "A"
        return true
    }
    return false
}

RestoreWindowState() {
    if (!wasAlreadyMaximized) {
        WinRestore "A"
    }
    ; If it was originally maximized, we do nothing
}

ExitFunc(*)
{
    global run_msg
    RestoreWindowState()
    ; if TimesReport
    ;     ShowTimes()
}

OnExit ExitFunc

FindImage(&x, &y, targets, click_msg:='', n:=3)
{
    found := false
    sleep 20
    Loop n {
        for target in targets {
			file_string := target.search_prefix . ' ' . target_path . target.file
            if (ImageSearch(&x, &y, target.bounds[1], target.bounds[2], target.bounds[3], target.bounds[4], file_string)) {
				offsetX := target.HasProp("offsetX") ? target.offsetX : 0
				offsetY := target.HasProp("offsetY") ? target.offsetY : 0
				x := x + offsetX
                y := y + offsetY
                found := true
				If DebugReport
					MsgBox "Found " target.file " at " x-offsetX "," y-offsetY ", returning " x "," y, "Debug", 4096+64
                return 1
            }
			else
			sleep 20
        }
	}
	if click_msg != '' {
		GetUserClick(&x,&y,click_msg)
		return 1
	}
    return 0
}

GetUserClick(&x, &y, item){
; Prompt the user
	result := MsgBox("Can't find the " item ". Press OK, then click on its center, or click cancel.", 'Looking for icon', 4096 + 1 + 32)
	; Check if the user clicked Cancel
	if (result == "Cancel") {
		ExitApp
	}
	clickCaptured := false
	captureClick(*) {
        MouseGetPos(&x, &y)
        clickCaptured := true
    }
	HotIfWinActive("A")  ; Make the hotkey active for the current window
    Hotkey("$LButton", captureClick, "On") ; Set up a hotkey to capture the click
    ; Wait for the click
    while (!clickCaptured) {
        Sleep(10)
    }
    ; Remove the hotkey
    Hotkey("LButton", captureClick, "Off")
    return true
}

ReadJsonConfig() {
    config := {}
    try {
        jsonContent := FileRead("screen_config.json")
		config := jxon_load(&jsonContent)
    } catch Error as err {
        MsgBox("Error reading screen_config.json file: " . err.Message)
        return false
    }
    return config
}

; ############### EXECUTION SECTION ###############################

; Create a custom GUI message box

SetTitleMatchMode 1 ; Initial title match
if !WinExist(TargetWindow) {
    MsgBox TargetWindow " window not found. Please make it visible and try again. Exiting script."
    ExitApp
}
WinActivate TargetWindow
CoordMode "Mouse", "Window"
CoordMode "Pixel", "Window"

; Remember the initial state and set to full screen if needed
global wasAlreadyMaximized := !MaximizeWindow()
if !wasAlreadyMaximized
	Sleep 100 ; Wait for the window to resize

; Get the new window dimensions
WinGetPos(&WindowX, &WindowY, &WindowWidth, &WindowHeight, "A")
WindowRight := WindowWidth
WindowBottom := WindowHeight

; Ask if user wants to read the configuration from the yaml file
getConfigFromFile() {
	if (!FileExist("screen_config.json"))
        return false
    result := MsgBox("Do you want to use the last saved configuration?", "Configuration Option", 4)
    if (result != "Yes")
        return false
    return true
}

; Either get the saved positions or find them on the screen
; msgbox "Before getConfigFromYaml"
if getConfigFromFile() {
; msgbox "Ready to readYaml"
	config := ReadJsonConfig()
	if (config) {
		Buttons := config['Buttons']
		Canvas := config['Canvas']
	} else {
        MsgBox("Failed to load configuration. Proceeding with default behavior.")
        ; Proceed with the original script logic to find controls and dimensions
    }
  Top := canvas['top']
	Left := canvas['left']
	Right := canvas['right']
	CanvasBottom := canvas['bottom']
}
else {

	global run_msg := Gui("+AlwaysOnTop +ToolWindow -SysMenu", "Notice")
	run_msg.SetFont("s16",)
	GuiBaseText := "Finding dimensions and button locations"
	text_control := run_msg.Add("Text",, GuiBaseText )
	run_msg.Show("x400 y500 AutoSize")
	TimeCheck('GUI Box')
	WinActivate TargetWindow

	; Make sure the whiteboard is open -- check for logo
	if FileExist(target_path . "up_logo_image.png") {
		try
		{
			LogoTargets := [
							{bounds: [0,0,WindowRight,300], search_prefix: "*20 *Trans00ff00", file: "up_logo_image_5s.png"},
							{bounds: [0,0,WindowRight,300], search_prefix: "*55", file: "up_logo_image.png"},
							{bounds: [0,0,WindowRight,500], search_prefix: "*55", file: "up_logo_image2.png"},
							{bounds: [0,0,WindowRight,500], search_prefix: "*20 *Trans00ff00", file: "up_logo_image3.png"},
		]
			FindImage(&LogoX, &LogoY, LogoTargets, '"P" in UPChieve logo at top')
		}
		catch as exc
			MsgBox "Could not conduct the search due to the following error:`n" exc.Message, "Error", 4096+16
		} else {
			MsgBox "Can't confirm that the UPchieve whiteboard is open. Be sure the image up_logo_image.png is in the same folder as this AHK script. Be sure whiteboard is open before trying again.", 4096+16
			ExitApp
			}
	TimeCheck('logo check')

	text_control.Text := "Upper Right"

	TopRightTargets := [
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*40", file: "panel_upper_left.png", offsetX: -33, offsetY: 11},
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*40 *Trans00ff00", file: "panel_upper_left_s.png", offsetX: -33, offsetY: 11},					
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*40", file: "panel_upper_left2.png", offsetX: -30, offsetY: 12},
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*40", file: "panel_upper_left3.png", offsetX: -54, offsetY: -3},

					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*40 *Trans00ff00", file: "panel_upper_left4_s.png", offsetX: -54, offsetY: -9},
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*30", file: "panel_upper_left5.png", offsetX: -57, offsetY: 37},
					{bounds: [LogoX, LogoY, WindowWidth-300, LogoY+180], search_prefix: "*30 *Trans00ff00", file: "panel_upper_left6.png", offsetX: -57, offsetY: 37} ]

	if ! FindImage(&Right, &Top, TopRightTargets, "", 3) {
		Sleep 100
		if PixelSearch(&Right, &Top, LogoX+100, LogoY, WindowWidth,500, 0x00D0AC, 20) {
			Top := Top + 38
			Right := Right - 81
			if DebugReport
				MsgBox "Using TR pixel: at " Right ',' Top, "Debug", 4096+64
		}
		else
			GetUserClick(&Right, &Top, "Right upper corner of canvas")
	}
	TimeCheck('Upper right')
	text_control.Text := "Upper Left"

	TopLeftTargets := [{bounds: [0, LogoY, 200, 350], search_prefix: "*20 *Trans00ff00", file: "upper_left.png", offsetX: 13, offsetY: 14},
					{bounds: [0, LogoY, 200, 350], search_prefix: "*20", file: "upper_left2.png", offsetX: 13, offsetY: 12},
					{bounds: [0, LogoY, 200, 350], search_prefix: "*50", file: "upper_left_attempting2.png", offsetX: -5, offsetY: 37},
					{bounds: [0, LogoY, 200, 350], search_prefix: "*20", file: "upper_left3.png", offsetX: 8, offsetY: 3 },
					{bounds: [0, LogoY, 200, 350], search_prefix: "*50", file: "upper_left_attempting.png", offsetX: 5, offsetY: 67}]

	FindImage(&Left, &Top, TopLeftTargets, "Top left corner of canvas", 3)

	Width := Right - Left
	TimeCheck('Upper left')

	text_control.Text := "Picker & Menu"

	PickerTargets := [
					{bounds: [0, WindowHeight-200, WindowWidth/2, WindowHeight], search_prefix: "*40", file: "picker.png", offsetX: 12, offsetY: 11},
					{bounds: [0, WindowHeight-200, WindowWidth/2, WindowHeight], search_prefix: "*40 *Trans00ff00", file: "picker_a_s.png", offsetX: -4, offsetY: -4},
					{bounds: [0, WindowHeight-200, WindowWidth/2, WindowHeight], search_prefix: "*40 *Trans00ff00", file: "picker_a.png", offsetX: -4, offsetY: -4},	
					{bounds: [0, WindowHeight-200, WindowWidth/2, WindowHeight], search_prefix: "*40*Trans00ff00", file: "picker_s1.png", offsetX: 10, offsetY: 10},
					{bounds: [0, WindowHeight-200, WindowWidth/2, WindowHeight], search_prefix: "*40", file: "picker2a.png", offsetX: 10, offsetY: 10}
					]
	FindImage(&PickerX, &PickerY, PickerTargets, "Picker tool",3)

	if A_ScreenWidth > 1920 {
		MenuLeft := PickerX - 30
		MenuTop := PickerY - 35
		MenuBottom := MenuTop + 87
		}
	else {
		MenuLeft := PickerX - 24
		MenuTop := PickerY - 32
		MenuBottom := MenuTop + 68
		}
	MenuMiddle := (MenuTop + MenuBottom)/2
	CanvasBottom := MenuTop - 15
	CanvasHeight := CanvasBottom - Top

	If DebugReport
		MsgBox "PickerX=" PickerX ', PickerY=' PickerY "\nMenuLeft= " MenuLeft ", top=" MenuTop ', bottom=' MenuBottom, "Debug", 4096+64

	; MsgBox "Searching for brush from " PickerX ',' MenuTop+17 ' to ' Width/2 ',' MenuBottom

	TimeCheck('picker')

	PenTargets := [
				{bounds: [PickerX, MenuTop, Width, MenuBottom], search_prefix: "*50 *Trans00ff00", file: "brush_tool_s.png", offsetX: 13, offsetY: 13},
				{bounds: [PickerX, MenuTop, Width, MenuBottom], search_prefix: "*50 *Trans00ff00", file: "brush_tool.png", offsetX: 13, offsetY: 13},
				{bounds: [PickerX, MenuTop, Width, MenuBottom], search_prefix: "*50 *Trans00ff00", file: "brush_tool_big.png", offsetX: 13, offsetY: 13}]
	FindImage(&PenX, &none, PenTargets, "Brush tool")
	TimeCheck('Pen')

	ShapesTargets := [
					{bounds: [PenX, MenuTop+17, A_ScreenWidth/2, MenuBottom], search_prefix: "*50", file: "shapes_tool.png", offsetX: 16, offsetY: 11},
					{bounds: [PenX, MenuTop+17, A_ScreenWidth/2, MenuBottom], search_prefix: "*50", file: "shapes_tool_s.png", offsetX: 16, offsetY: 11},
					{bounds: [PenX, MenuTop+17, A_ScreenWidth/2, MenuBottom], search_prefix: "*50 *Trans00ff00", file: "shapes_tool_big_masked.png", offsetX: 16, offsetY: 17}]
	FindImage(&ShapesX, &none, ShapesTargets, "Shapes tool")
	TimeCheck('Shapes')


	TextTargets := [
					{bounds: [ShapesX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "text_tool_s.png", offsetX: 13, offsetY: 13},
					{bounds: [ShapesX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "text_tool.png", offsetX: 13, offsetY: 13},
					{bounds: [ShapesX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "text_tool2.png", offsetX: 13, offsetY: 13}]
	FindImage(&TextX,&none,TextTargets, "Text tool")
	TimeCheck('Text')

	ColorsTargets := [
					{bounds: [TextX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "colors_tool_s.png", offsetX: 13, offsetY: 13},
					{bounds: [TextX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "colors_tool.png", offsetX: 13, offsetY: 13},
					{bounds: [TextX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "colors_tool2.png", offsetX: 13, offsetY: 13}]
	FindImage(&ColorsX,&none,ColorsTargets, "Colors tool")
	TimeCheck('Colors')

	TrashTargets := [
					{bounds: [ColorsX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "trash_tool_s.png", offsetX: 13, offsetY: 13},
					{bounds: [ColorsX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "trash_tool.png", offsetX: 13, offsetY: 13},
					{bounds: [ColorsX, MenuTop+17, Right, MenuBottom], search_prefix: "*50", file: "trash_tool2.png", offsetX: 13, offsetY: 13}]
	FindImage(&TrashX,&none,TrashTargets, "Trash tool")
	TimeCheck('Trash')

	TimeCheck('Menu')

	; FIND SUBMENU ITEMS
	text_control.Text := "Shapes and Colors"

	; Will usually need to click the Shapes button first, but it just might be open already, so check first
	LineTargets := [{bounds: [MenuLeft-50, MenuTop-60, MenuLeft+300, Menutop+50], search_prefix: "*60 *Trans00ff00", file: "line_tool.png", offsetX: 20, offsetY:13},
					{bounds: [MenuLeft-50, MenuTop-60, MenuLeft+300, Menutop+50], search_prefix: "*60 *Trans00ff00", file: "line_tool2.png", offsetX: 20, offsetY:13}]
	if FindImage(&LineX,&SubmenuY,LineTargets)
	{}
	else
		{	Click ShapesX, MenuMiddle
			Sleep 100
			FindImage(&LineX,&SubmenuY,LineTargets, "Line tool")
		}
	SubMenuTop := SubMenuY - 25
	SubMenuMiddle := SubMenuY
	TimeCheck('Line')

	CircleTargets := [{bounds: [LineX, SubMenuTop, LineX+200, Menutop+50], search_prefix: "*60 *Trans00ff00", file: "circle_tool.png", offsetX: 14, offsetY:0},
			{bounds: [LineX, MenuTop-60, MenuLeft+300, Menutop+50], search_prefix: "*50 *Trans00ff00", file: "circle_tool2.png", offsetX: 7, offsetY:4}]
	FindImage(&CircleX, &dummy, CircleTargets, "Circle tool")
	TimeCheck('Circle')

	TriangleTargets := [{bounds: [LineX, SubMenuTop, LineX+200, Menutop+50], search_prefix: "*60 *Trans00ff00", file: "triangle_tool.png", offsetX: 12, offsetY:0},
			{bounds: [LineX, SubMenuTop, MenuLeft+300, Menutop+50], search_prefix: "*50 *Trans00ff00", file: "triangle_tool2.png", offsetX: 12, offsetY:0}]
	FindImage(&TriangleX, &dummy, TriangleTargets, "Triangle tool")
	TimeCheck('Triangle')

	RectangleTargets := [{bounds: [LineX, MenuTop-60, MenuLeft+300, Menutop+50], search_prefix: "*60 *Trans00ff00", file: "rectangle_tool.png", offsetX: 10, offsetY:0},
			{bounds: [LineX, SubMenuTop, MenuLeft+300, Menutop+50], search_prefix: "*50 *Trans00ff00", file: "rectangle_tool2.png", offsetX: 10, offsetY:0}]
	FindImage(&RectangleX, &dummy, RectangleTargets, "Rectangle tool")
	TimeCheck('Rectangle')

	TimeCheck('Shapes')

	Click ColorsX, MenuMiddle
	Sleep 100

	BlackTargets := [{bounds: [MenuLeft-50, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*50", file: "black_tool.png", offsetX: 9, offsetY: 5}]
	FindImage(&BlackX, &dummy, BlackTargets, "Black tool")

	BlueTargets := [{bounds: [BlackX, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*50", file: "blue_tool.png", offsetX: 14, offsetY: 4}]
	FindImage(&BlueX, &dummy, BlueTargets, "Blue tool")

	RedTargets := [{bounds: [MenuLeft-50, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*50", file: "red_tool.png", offsetX: 5, offsetY: 4}]
	FindImage(&RedX, &dummy, RedTargets, "Red tool")

	SandTargets := [{bounds: [MenuLeft-50, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*20", file: "sand_tool.png", offsetX: 9, offsetY: 4}]
	FindImage(&SandX, &dummy, SandTargets, "Sand tool")

	TealTargets := [{bounds: [MenuLeft-50, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*50", file: "teal_tool.png", offsetX: 0, offsetY: 4}]
	FindImage(&TealX, &dummy, TealTargets, "Teal tool")

	LightblueTargets := [{bounds: [MenuLeft-50, SubMenuTop, MenuLeft+800, Menutop+50], search_prefix: "*50", file: "lightblue_tool.png", offsetX: 6, offsetY: 4}]
	FindImage(&LightblueX, &dummy, LightblueTargets, "Lightblue tool")

	Click ColorsX, MenuMiddle
	TimeCheck('Colors')

	; Buttons := {
	; 	select: {x: PickerX, y: MenuMiddle},
	; 	brush: {x: PenX, y: MenuMiddle},
	; 	pen: {x: PenX, y: MenuMiddle},
	; 	shapes: {x: ShapesX, y: MenuMiddle},
	; 	text: {x: TextX, y: MenuMiddle},
	; 	colors: {x: ColorsX, y: MenuMiddle},
	; 	trash: {x: TrashX, y: MenuMiddle},
	; 	line: {x: LineX, y: SubMenuMiddle},
	; 	circle: {x: CircleX, y: SubMenuMiddle},
	; 	triangle: {x: TriangleX, y: SubMenuMiddle},
	; 	rectangle: {x: RectangleX, y: SubMenuMiddle},
	; 	black: {x: BlackX, y: SubMenuMiddle},
	; 	blue: {x: BlueX, y: SubMenuMiddle},
	; 	red: {x: RedX, y: SubMenuMiddle},
	; 	sand: {x: SandX, y: SubMenuMiddle},
	; 	teal: {x: TealX, y: SubMenuMiddle},
	; 	lightblue: {x: LightBlueX, y: SubMenuMiddle}
	; }

	; Canvas := {
	; 	top: top,
	; 	left: left,
	; 	right: right,
	; 	bottom: canvasbottom,
	; 	width: right-left,
	; 	height: canvasbottom - top
	; 	}

	; close the progress notice box
	run_msg.Destroy()


	Buttons := Map(
		"select", Map("x", PickerX, "y", MenuMiddle),
		"brush", Map("x", PenX, "y", MenuMiddle),
		"pen", Map("x", PenX, "y", MenuMiddle),
		"shapes", Map("x", ShapesX, "y", MenuMiddle),
		"text", Map("x", TextX, "y", MenuMiddle),
		"colors", Map("x", ColorsX, "y", MenuMiddle),
		"trash", Map("x", TrashX, "y", MenuMiddle),
		"line", Map("x", LineX, "y", SubMenuMiddle),
		"circle", Map("x", CircleX, "y", SubMenuMiddle),
		"triangle", Map("x", TriangleX, "y", SubMenuMiddle),
		"rectangle", Map("x", RectangleX, "y", SubMenuMiddle),
		"black", Map("x", BlackX, "y", SubMenuMiddle),
		"blue", Map("x", BlueX, "y", SubMenuMiddle),
		"red", Map("x", RedX, "y", SubMenuMiddle),
		"sand", Map("x", SandX, "y", SubMenuMiddle),
		"teal", Map("x", TealX, "y", SubMenuMiddle),
		"lightblue", Map("x", LightBlueX, "y", SubMenuMiddle)
	)

	; I don't think canvas is actually used anywhere!
	Canvas := Map(
		"top", top,
		"left", left,
		"right", right,
		"bottom", canvasbottom,
		"width", right-left,
		"height", canvasbottom - top
		)


	Config := Map("Buttons", Buttons, "Canvas", Canvas)

	; Write the parameters to a file - could use for debugging or to read latest parameters for reuse
;	config := {Buttons: buttons, Canvas: canvas}
;	yamlString := Yaml(config,4)
;	msgbox yamlstring
;	yamlString := RegexReplace(yamlString, '"(\d+(\.\d+)?)"', "$1")
;	configfile := FileOpen("screen_config.yaml", "w")
;	configfile.Write(yamlString)
	jsonString := jxon_dump(config,2)
	configfile := FileOpen("screen_config.json", "w")
	configfile.Write(jsonString)
	msgbox "Configuration saved","Mouser",4096
}

; Source metrics - Driver should override if not using these defaults

if !IsSet(SourceWidth)
    SourceWidth := 1920
if !IsSet(SourceHeight)
    SourceHeight := 1080
if !IsSet(SourceAnchorX)
    SourceAnchorX := 125
if !IsSet(SourceAnchorY)
    SourceAnchorY := 195



xscale := canvas['width']/sourcewidth
yscale := canvas['height']/sourceheight

if yscale < xscale
   scale := yscale
else
   scale := xscale

; ############ THESE FUNCTIONS ARE USED DURING RENDERING

ScaleX(x) {
	global SourceWidth
	global SourceAnchorX
	scaled := (x-SourceAnchorX)*scale + Canvas['left']
    return scaled
}
ScaleY(y) {
	global SourceHeight
	global SourceAnchorY
	scaled := (y-SourceAnchorY)*scale + Canvas['top']
    return scaled
}

ClickButton(name) {
	global Buttons
	x := Buttons[name]['x']
	y := Buttons[name]['y']
	Click X, Y
}

Clicker(x,y, options){
	xs := ScaleX(x)
	ys := ScaleY(y)
	if (xs >= Left) && (xs <= Right) && (ys >= Top) && (ys <= CanvasBottom)
		Click xs, ys, options
	else
		MsgBox "Out of bounds at (" x ", " y ") --> (" xs ", " ys ")"

}

; ########### DEBUGGING REPORT

; MsgBox 'Canvas top=' canvas['top'] ', left=' canvas['left'] ', right=' canvas['right'] ', bottom=' canvas['bottom']
; Msgbox 'ScaleX(100)=' ScaleX(100) ', ScaleY(100)=' ScaleY(100) '. SourceAnchor=(' SourceAnchorX ',' SourceAnchorY
