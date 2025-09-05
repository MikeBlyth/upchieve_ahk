#Requires AutoHotkey v2.0
#Include student_database.ahk

; Test the student database system
MsgBox("Testing Student Database System", "Test", "OK")

; Test 1: Exact match (should return immediately)
result1 := ValidateStudentName("Olivia")
MsgBox("Test 1 - Exact match:`nInput: 'Olivia'`nResult: '" . result1 . "'", "Test Result", "OK")

; Test 2: Close match (should ask for confirmation)
result2 := ValidateStudentName("Olvia")  ; Missing 'i'
MsgBox("Test 2 - Close match:`nInput: 'Olvia'`nResult: '" . result2 . "'", "Test Result", "OK")

; Test 3: Unknown name (should ask if correct)
result3 := ValidateStudentName("Unknown")
MsgBox("Test 3 - Unknown name:`nInput: 'Unknown'`nResult: '" . result3 . "'", "Test Result", "OK")

; Test 4: Case insensitive match
result4 := ValidateStudentName("pedro")  ; lowercase
MsgBox("Test 4 - Case insensitive:`nInput: 'pedro'`nResult: '" . result4 . "'", "Test Result", "OK")

; Test 5: Special character name
result5 := ValidateStudentName("Zyairah")  ; Missing apostrophe
MsgBox("Test 5 - Special characters:`nInput: 'Zyairah'`nResult: '" . result5 . "'", "Test Result", "OK")

MsgBox("Testing complete!", "Done", "OK")