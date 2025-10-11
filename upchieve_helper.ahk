#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include ahk_utilities.ahk
#Include search_targets.ahk

; UPCHIEVE HELPER
; Provides hotkeys for selecting tools and colors in the Upchieve whiteboard.
; Based on Plan 2 in upchieve_helper_plan.txt

CoordMode("Mouse", "Window")
CoordMode("Pixel", "Window")

; --- Core function to find and click one or two buttons ---
ClickButtons(button_1, button_2 := "") {
    ; Save original state so we can be a polite, non-interfering function
    originalBindingID := FindText().BindWindow(0, 0, 1, 0)
    originalMouseMode := A_CoordModeMouse

    try {
        ; Set a predictable environment: unbound and using screen coordinates
        FindText().BindWindow(0)
        CoordMode("Mouse", "Screen")

        if not WinActive("Upchieve") {
            return
        }

        WinGetPos(&winX, &winY, &winWidth, &winHeight, "A")

        Menu_Range_x1_screen := 488 + winX
        Menu_Range_y1_screen := 1600 + winY
        Menu_Range_x2_screen := 1900 + winX
        Menu_Range_y2_screen := 1800 + winY

        MouseGetPos(&OrigMouseX, &OrigMouseY)

        if (result1 := FindText(, , Menu_Range_x1_screen, Menu_Range_y1_screen, Menu_Range_x2_screen, Menu_Range_y2_screen, 0.15, 0.10, button_1)) {
            WriteLog("HELPER: Found button_1 at screen (" . result1[1].x . ", " . result1[1].y . "). Clicking.")
            Click(result1[1].x, result1[1].y)

            if (button_2 != "") {
                Sleep(100)
                found_y_screen := result1[1].y
                new_submenu_y1_screen := found_y_screen - 125
                new_submenu_y2_screen := found_y_screen - 55
                new_submenu_x1_screen := Menu_Range_x1_screen
                new_submenu_x2_screen := Menu_Range_x2_screen

                if (result2 := FindText(, , new_submenu_x1_screen, new_submenu_y1_screen, new_submenu_x2_screen, new_submenu_y2_screen, 0.15, 0.10, button_2)) {
                    WriteLog("HELPER: Found button_2 at screen (" . result2[1].x . ", " . result2[1].y . "). Clicking.")
                    Click(result2[1].x, result2[1].y)
                } else {
                    WriteLog("HELPER: button_2 not found in submenu area.")
                }
            }
        } else {
            WriteLog("HELPER: button_1 not found.")
        }

        MouseMove(OrigMouseX, OrigMouseY, 0)

    } finally {
        ; Always restore the original state
        CoordMode("Mouse", originalMouseMode)
        if (originalBindingID) {
            FindText().BindWindow(originalBindingID, 4)
        }
    }
}

; --- Tool Hotkeys (Left Alt + Key) ---
~<!s::ClickButtons(MenuSelectTarget) ; Select
~<!+a::ClickButtons(MenuTextTarget, SubmenuBigTextTarget) ; A - Big Text
~<!a::ClickButtons(MenuTextTarget, SubmenuSmallTextTarget) ; a - Small Text
~<!l::ClickButtons(MenuShapesTarget, SubmenuLineTarget) ; l - Line
~<!.::ClickButtons(MenuShapesTarget, SubmenuArrowTarget) ; > - Arrow
~<!v::ClickButtons(MenuShapesTarget, SubmenuTriangleTarget) ; v - Triangle
~<![::ClickButtons(MenuShapesTarget, SubmenuSquareTarget) ; z - Rectangle
~<!c::ClickButtons(MenuShapesTarget, SubmenuCircleTarget) ; c - Circle
<!+x::ClickButtons(MenuPenTarget, SubmenuThickPenTarget) ; P - Thick Pen
~<!x::ClickButtons(MenuPenTarget, SubmenuThinPenTarget) ; p - Thin Pen

; --- Color Hotkeys (Left Alt + Key) ---
~<!k::ClickButtons(MenuColorsTarget, ColorBlackTarget) ; k - Black
~<!n::ClickButtons(MenuColorsTarget, ColorNavyTarget) ; n - Navy
~<!r::ClickButtons(MenuColorsTarget, ColorRedTarget) ; r - Red
~<!d::ClickButtons(MenuColorsTarget, ColorSandTarget) ; d - Sand
~<!t::ClickButtons(MenuColorsTarget, ColorTealTarget) ; t - Teal
~<!b::ClickButtons(MenuColorsTarget, ColorBlueTarget) ; b - Blue
~<!m::ClickButtons(MenuColorsTarget, ColorMagentaTarget) ; m - Magenta
~<!g::ClickButtons(MenuColorsTarget, ColorGreenTarget) ; g - Green
~<!o::ClickButtons(MenuColorsTarget, ColorOrangeTarget) ; o - Orange
~<!y::ClickButtons(MenuColorsTarget, ColorYellowTarget) ; y - Yellow
~<!h::ClickButtons(MenuColorsTarget, ColorClearTarget) ; h - Clear
