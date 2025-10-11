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
    ; Only run if the Upchieve window is active
    if not WinActive("Upchieve") {
        return
    }

    Menu_Range_x1 := 488
    Menu_Range_y1 := 1600
    Menu_Range_x2 := 1900
    Menu_Range_y2 := 1800

    MouseGetPos(&OrigMouseX, &OrigMouseY)

    ; Find and click the first button, get the result
    first_click_result := FindAndClick(button_1, Menu_Range_x1, Menu_Range_y1, Menu_Range_x2, Menu_Range_y2)

    ; If the first button was found and a second button is specified...
    if (first_click_result && button_2 != "") {
        Sleep(100) ; Wait for submenu to appear

        ; Get the screen Y-coordinate where the first button was found
        found_y_screen := first_click_result[1].y

        ; Get the active window's position to convert coordinates
        WinGetPos(&winX, &winY, , , "A")

        ; Calculate the new search area for the second button.
        ; The user specified a Y-range relative to the first button's location.
        ; We convert this to the window-relative coordinates that FindAndClick expects.
        new_submenu_y1 := (found_y_screen - winY) - 125
        new_submenu_y2 := (found_y_screen - winY) - 55

        ; Use the original X-range for the submenu search
        new_submenu_x1 := Menu_Range_x1
        new_submenu_x2 := Menu_Range_x2

        ; Find and click the second button within the new, refined search area
        FindAndClick(button_2, new_submenu_x1, new_submenu_y1, new_submenu_x2, new_submenu_y2)
    }

    MouseMove(OrigMouseX, OrigMouseY, 0)
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
