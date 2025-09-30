#Requires AutoHotkey v2.0

; ===================================================================
; Upload Image Workflow Script
; Automates saving screen capture from Snagit and uploading to UPchieve
; ===================================================================

; Include required dependencies
#Include FindTextv2.ahk
#Include search_targets.ahk
#Include ahk_utilities.ahk

; Global variables
snagitWindowTitle := "Snagit"
upchieveWindowTitle := "Baseline"

; Main workflow function
UploadImageWorkflow() {
    WriteLog("=== Starting Upload Image Workflow ===")
    ; Generate timestamped filename and navigate to C:\temp
    currentTime := FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss")
    fileName := "C:\temp\upload-" . currentTime . ".png"


    try {
        ; Step 1: Snagit Operations
        WriteLog("Step 1: Processing Snagit operations")
        if (!ProcessSnagitSave(fileName)) {
            WriteLog("ERROR: Snagit save operation failed")
            MsgBox("Failed to save image in Snagit. Please check the application.", "Error", "OK 4096")
            return false
        }

        ; Step 2: UPchieve Upload
        WriteLog("Step 2: Processing UPchieve upload")
        if (!ProcessUpchieveUpload(fileName)) {
            WriteLog("ERROR: UPchieve upload operation failed")
            MsgBox("Failed to upload image to UPchieve.`n`nPlease ensure:`n1. Baseline workspace is open in Edge`n2. UPchieve tab is active in Baseline workspace`n3. You are logged into UPchieve", "Upload Failed", "OK 4096")
            return false
        }

        WriteLog("=== Upload Image Workflow Completed Successfully ===")
        MsgBox("Image uploaded successfully!", "Success", "OK 4096")
        return true

    } catch Error as e {
        WriteLog("CRITICAL ERROR in UploadImageWorkflow: " . e.Message)
        MsgBox("Critical error: " . e.Message, "Error", "OK 4096")
        return false
    }
}

; Process Snagit save operations
ProcessSnagitSave(fileName) {
    WriteLog("Switching to Snagit window")

    ; Find and activate Snagit window
    if (!WinExist(snagitWindowTitle)) {
        WriteLog("ERROR: Snagit window not found")
        return false
    }

    WinActivate(snagitWindowTitle)
    WinWaitActive(snagitWindowTitle, , 3)

    if (!WinActive(snagitWindowTitle)) {
        WriteLog("ERROR: Failed to activate Snagit window")
        return false
    }

    WriteLog("Snagit window activated successfully")
    Sleep(500)  ; Allow window to fully activate

    ; Click File menu at relative coordinates (50,25)
    WriteLog("Clicking File menu at relative coordinates (50,25)")
    Click(50, 25)
    Sleep(300)  ; Wait for menu to open

    ; Click "File Save To" at coordinates (60,264)
    WriteLog("Clicking 'File Save To' at coordinates (60,264)")
    Click(60, 264)
    Sleep(1000)  ; Wait for save dialog to open

    ; Ensure "Save As" dialog is active for proper click position calculation
    WriteLog("Ensuring 'Save As' dialog is active for FindAndClick")
    if (!WinExist("Save As")) {
        WriteLog("ERROR: Save As dialog not found")
        return false
    }

    ; Activate the dialog to ensure FindAndClick calculates positions correctly
    WinActivate("Save As")
    WinWaitActive("Save As", , 3)
    WriteLog("Save As dialog is active for click position calculation")
    Sleep(300)  ; Allow dialog to fully activate

    WriteLog("Full path: " . fileName)

    ; Paste the full path directly in the filename field
    WriteLog("Pasting full path: " . fileName)
    Send(fileName)
    Sleep(300)

    ; Find and click Save button in bottom 150px, right half of dialog
    WriteLog("Looking for Save button in bottom-right area of Save As dialog")

    ; Get dialog window dimensions for constrained search
    WinGetPos(&dialogX, &dialogY, &dialogWidth, &dialogHeight, "Save As")

    ; Define search area: bottom 150px, right half
    searchX1 := dialogWidth // 2  ; Right half starts at middle
    searchY1 := dialogHeight - 150  ; Bottom 150px
    searchX2 := dialogWidth
    searchY2 := dialogHeight

    WriteLog("Save button search area: (" . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2 . ") within Save As dialog")

    if (!FindAndClick(SaveTarget, searchX1, searchY1, searchX2, searchY2)) {
        WriteLog("ERROR: Save button not found in bottom-right area of Save As dialog")
        return false
    }

    WriteLog("Save button clicked successfully")
    Sleep(1000)  ; Wait for save operation to complete

    return true
}

; Process UPchieve upload operations
ProcessUpchieveUpload(fileName) {
    WriteLog("Switching to UPchieve window")

    ; Find and activate Baseline workspace using exact title matching
    SetTitleMatchMode(3)  ; Exact title match for Baseline workspace
    if (!WinExist(upchieveWindowTitle)) {
        WriteLog("ERROR: Baseline workspace window not found")
        SetTitleMatchMode(2)  ; Reset to default
        return false
    }

    WinActivate(upchieveWindowTitle)
    WinWaitActive(upchieveWindowTitle, , 3)
    WinGetPos(&winX, &winY, &winWidth, &winHeight)

    if (!WinActive(upchieveWindowTitle)) {
        WriteLog("ERROR: Failed to activate Baseline workspace window")
        SetTitleMatchMode(2)  ; Reset to default
        return false
    }
    SetTitleMatchMode(2)  ; Reset to default for subsequent operations

    WriteLog("UPchieve window activated successfully")
    Sleep(500)  ; Allow window to fully activate

    ; Find and click Upload Icon (this also validates we're on the UPchieve tab)
    WriteLog("Looking for Upload Icon to validate UPchieve tab and start upload")
    if (!FindAndClick(UploadIconTarget, 600, winHeight - 250, 1700, winHeight - 100)) {
        WriteLog("ERROR: Upload Icon not found - ensure UPchieve tab is active in Baseline workspace")
        return false
    }

    WriteLog("Upload Icon clicked successfully")
    Sleep(1000)  ; Wait for file dialog to open

    ; Ensure "Open" file dialog is active for proper click position calculation
    WriteLog("Ensuring 'Open' file dialog is active for FindAndClick")
    if (!WinExist("Open")) {
        WriteLog("ERROR: Open file dialog not found")
        return false
    }

    ; Activate the dialog to ensure FindAndClick calculates positions correctly
    WinActivate("Open")
    WinWaitActive("Open", , 3)
    WriteLog("Open file dialog is active for click position calculation")
    Sleep(300)  ; Allow dialog to fully activate

    ; Paste the full path directly in the filename field
    WriteLog("Pasting full path: " . fileName)
    Send(fileName)
    Sleep(300)

    ; Find and click Open button in bottom 150px, right half of dialog
    WriteLog("Looking for Open button in bottom-right area of Open file dialog")

    ; Get dialog window dimensions for constrained search
    WinGetPos(&dialogX, &dialogY, &dialogWidth, &dialogHeight, "Open")

    ; Define search area: bottom 150px, right half
    searchX1 := dialogWidth // 2  ; Right half starts at middle
    searchY1 := dialogHeight - 150  ; Bottom 150px
    searchX2 := dialogWidth
    searchY2 := dialogHeight

    WriteLog("Open button search area: (" . searchX1 . "," . searchY1 . " to " . searchX2 . "," . searchY2 . ") within Open dialog")

    if (!FindAndClick(OpenFileTarget, searchX1, searchY1, searchX2, searchY2)) {
        WriteLog("ERROR: Open button not found in bottom-right area of Open file dialog")
        return false
    }

    WriteLog("Open button clicked successfully")
    Sleep(1000)  ; Wait for upload to begin

    return true
}

; Hotkey assignment - Ctrl+Shift+U
^+u::UploadImageWorkflow()

; Display help message on startup
MsgBox("Upload Image Workflow Script loaded successfully!`n`nHotkey: Ctrl+Shift+U`n`nThis script will:`n1. Save screen capture from Snagit`n2. Upload the image to UPchieve`n`nBefore using, ensure:`n• Snagit is open`n• Baseline workspace is open in Edge`n• UPchieve tab is ACTIVE in Baseline workspace", "Upload Image Script", "OK 4096")