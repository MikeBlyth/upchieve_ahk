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
    ; Generate timestamped filename
    currentTime := FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss")
    fileName := "C:\temp\upload-" . currentTime . ".png"

    try {
        if (!ProcessSnagitSave(fileName)) {
            MsgBox("Failed to save image in Snagit. Please check the application.", "Error", "OK 4096")
            return false
        }

        if (!ProcessUpchieveUpload(fileName)) {
            MsgBox("Failed to upload image to UPchieve.`n`nPlease ensure:`n1. Baseline workspace is open in Edge`n2. UPchieve tab is active in Baseline workspace`n3. You are logged into UPchieve", "Upload Failed", "OK 4096")
            return false
        }
        return true

    } catch Error as e {
        MsgBox("Critical error: " . e.Message, "Error", "OK 4096")
        return false
    }
}

; Process Snagit save operations
ProcessSnagitSave(fileName) {
    if (!WinExist(snagitWindowTitle))
        return false

    WinActivate(snagitWindowTitle)
    WinWaitActive(snagitWindowTitle, , 3)

    if (!WinActive(snagitWindowTitle))
        return false

    Click(50, 25)
    Sleep(200)

    Click(60, 264)

    if (!WinWait("Save As", , 5))
        return false

    WinActivate("Save As")
    WinWaitActive("Save As", , 3)
    Sleep(100)

    Send(fileName)
    Sleep(200)

    WinGetPos(&dialogX, &dialogY, &dialogWidth, &dialogHeight, "Save As")
    searchX1 := dialogWidth // 2
    searchY1 := dialogHeight - 150
    searchX2 := dialogWidth
    searchY2 := dialogHeight

    if (!FindAndClick(SaveTarget, searchX1, searchY1, searchX2, searchY2))
        return false

    Sleep(1000)
    return true
}

; Process UPchieve upload operations
ProcessUpchieveUpload(fileName) {
    SetTitleMatchMode(3)
    if (!WinExist(upchieveWindowTitle)) {
        SetTitleMatchMode(2)
        return false
    }

    WinActivate(upchieveWindowTitle)
    WinWaitActive(upchieveWindowTitle, , 3)
    WinGetPos(&winX, &winY, &winWidth, &winHeight)

    if (!WinActive(upchieveWindowTitle)) {
        SetTitleMatchMode(2)
        return false
    }
    SetTitleMatchMode(2)

    if (!FindAndClick(UploadIconTarget, 600, winHeight - 250, 1700, winHeight - 100))
        return false

    if (!WinWait("Open", , 5))
        return false

    WinActivate("Open")
    WinWaitActive("Open", , 3)
    Sleep(300)

    Send(fileName)
    Sleep(300)

    WinGetPos(&dialogX, &dialogY, &dialogWidth, &dialogHeight, "Open")
    searchX1 := dialogWidth // 2
    searchY1 := dialogHeight - 150
    searchX2 := dialogWidth
    searchY2 := dialogHeight

    if (!FindAndClick(OpenFileTarget, searchX1, searchY1, searchX2, searchY2))
        return false

    return true
}

; Hotkey assignment - Ctrl+Shift+U
^+u::UploadImageWorkflow()

; Display help message on startup
; MsgBox("Upload Image Workflow Script loaded successfully!`n`nHotkey: Ctrl+Shift+U`n`nThis script will:`n1. Save screen capture from Snagit`n2. Upload the image to UPchieve`n`nBefore using, ensure:`n• Snagit is open`n• Baseline workspace is open in Edge`n• UPchieve tab is ACTIVE in Baseline workspace", "Upload Image Script", "OK 4096")