#Requires AutoHotkey v2.0
#Include student_database.ahk

; Test whitespace handling
MsgBox("Testing Whitespace Handling", "Test", "OK")

; Test with trailing space
result1 := ValidateStudentName("Olivia ")  ; With trailing space
MsgBox("Test 1 - Trailing space:`nInput: 'Olivia '`nResult: '" . result1 . "'", "Test Result", "OK")

; Test with leading space  
result2 := ValidateStudentName(" Pedro")  ; With leading space
MsgBox("Test 2 - Leading space:`nInput: ' Pedro'`nResult: '" . result2 . "'", "Test Result", "OK")

; Test with both
result3 := ValidateStudentName(" Camila ")  ; With both spaces
MsgBox("Test 3 - Both spaces:`nInput: ' Camila '`nResult: '" . result3 . "'", "Test Result", "OK")

; Show some loaded student names for verification
sampleNames := ""
global knownStudents
for i, name in knownStudents {
    if (i <= 5) {  ; Show first 5
        sampleNames .= i . ": '" . name . "'`n"
    }
}
MsgBox("First 5 loaded names:`n" . sampleNames, "Database Sample", "OK")

MsgBox("Whitespace test complete!", "Done", "OK")