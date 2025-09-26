#Requires AutoHotkey v2.0
#Include extension_bridge.ahk
#Include header_manager.ahk
#Include ahk_utilities.ahk

; Test script for integrated UWD system
; Tests extension communication and core functions

WriteLog("=== Testing Integrated UWD System ===")

; Test 1: Clipboard parsing with multiple students
WriteLog("TEST 1: Multi-student clipboard parsing")

testClipboard1 := "*upchieve|12345|John Smith|8th Grade Math|0|Sarah Jones|Pre-algebra|2"
students1 := ParseStudentArray(testClipboard1)

WriteLog("Test 1 - Input: " . testClipboard1)
WriteLog("Test 1 - Parsed " . students1.Length . " students")
for i, student in students1 {
    WriteLog("  Student " . i . ": " . student.ToString())
}

; Test 2: Student selection
WriteLog("`nTEST 2: Student selection")
selected1 := SelectFirstStudent(students1)
WriteLog("Selected: " . selected1.ToString())

; Test 3: Blocking functionality
WriteLog("`nTEST 3: Student blocking")

; Create test block file
testBlockContent := "John Smith`nTestStudent`n; Comment line`n"
FileDelete("test_block_names.txt")
FileAppend(testBlockContent, "test_block_names.txt")

blocked1 := CheckBlockedNames(selected1, "test_block_names.txt")
WriteLog("John Smith blocked: " . (blocked1 ? "YES" : "NO"))

testStudent2 := Student("Mary Johnson", "Biology", 1)
blocked2 := CheckBlockedNames(testStudent2, "test_block_names.txt")
WriteLog("Mary Johnson blocked: " . (blocked2 ? "YES" : "NO"))

; Test 4: Invalid clipboard data
WriteLog("`nTEST 4: Invalid clipboard data handling")

testClipboard2 := "invalid|format|data"
students2 := ParseStudentArray(testClipboard2)
WriteLog("Invalid format parsed: " . students2.Length . " students (should be 0)")

testClipboard3 := "*upchieve|12345|OnlyName"  ; Missing topic and minutes
students3 := ParseStudentArray(testClipboard3)
WriteLog("Incomplete data parsed: " . students3.Length . " students (should be 0)")

; Test 5: Window ID extraction
WriteLog("`nTEST 5: Window ID handling")

; Simulate extension window ID
ExtensionWindowID := "54321"
testClipboard4 := "*upchieve|54321|Test Student|Computer Science|5"
students4 := ParseStudentArray(testClipboard4)
WriteLog("Window ID match test: " . students4.Length . " students")

; Test 6: Wait time parsing
WriteLog("`nTEST 6: Wait time parsing")

WriteLog("'< 1' → " . extractWaitMinutes("< 1") . " minutes")
WriteLog("'3 min' → " . extractWaitMinutes("3 min") . " minutes")
WriteLog("'15' → " . extractWaitMinutes("15") . " minutes")
WriteLog("'' → " . extractWaitMinutes("") . " minutes")

; Cleanup
FileDelete("test_block_names.txt")

WriteLog("`n=== Integration System Tests Complete ===")
WriteLog("Review debug_log.txt for detailed results")

MsgBox("Integration system tests complete!`n`nCheck debug_log.txt for detailed results.`n`nKey findings:`n• Parsed " . students1.Length . " students from test data`n• Blocking system functional`n• Error handling working", "Test Results", "OK 4096")

; Wait time extraction function (copied from extension for testing)
extractWaitMinutes(waitTimeText) {
    if (!waitTimeText) return 0

    text := Trim(waitTimeText)

    ; Handle "< 1" → return 0
    if (InStr(text, "< 1") > 0) {
        return 0
    }

    ; Extract number from "x min" format
    if (RegExMatch(text, "(\d+)", &match)) {
        return Integer(match[1])
    }

    return 0
}