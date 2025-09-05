#Requires AutoHotkey v2.0

; Student Database Management System
; Handles student name storage, fuzzy matching, and correction learning

global knownStudents := []
global correctionDatabase := Map()  ; OCR Result -> Actual Name mappings

; Load known students from file
LoadStudentDatabase() {
    global knownStudents
    
    try {
        content := FileRead("student_names.txt")
        knownStudents := []
        
        for line in StrSplit(content, "`n") {
            name := Trim(line)
            ; Skip empty lines, comments, and invalid entries
            if (name != "" && !RegExMatch(name, "^;") && !RegExMatch(name, "^\s*$") && name != "No newline at end of file") {
                knownStudents.Push(name)
            }
        }
        
        ; Remove duplicates and clean up names
        uniqueStudents := []
        for student in knownStudents {
            cleanName := Trim(student)  ; Extra trim to be sure
            ; Skip obviously invalid names
            if (cleanName == "" || StrLen(cleanName) < 2 || RegExMatch(cleanName, "^[^a-zA-Z]")) {
                continue
            }
            
            found := false
            for existing in uniqueStudents {
                if (StrLower(cleanName) == StrLower(existing)) {
                    found := true
                    break
                }
            }
            if (!found) {
                uniqueStudents.Push(cleanName)
            }
        }
        knownStudents := uniqueStudents
        
    } catch {
        ; If file doesn't exist or can't be read, start with empty array
        knownStudents := []
    }
}

; Load correction mappings from file
LoadCorrectionDatabase() {
    global correctionDatabase
    
    try {
        content := FileRead("student_corrections.txt")
        correctionDatabase := Map()
        
        for line in StrSplit(content, "`n") {
            line := Trim(line)
            if (line != "" && !RegExMatch(line, "^;") && InStr(line, "->")) {
                parts := StrSplit(line, "->")
                if (parts.Length == 2) {
                    ocrResult := Trim(parts[1])
                    actualName := Trim(parts[2])
                    correctionDatabase[ocrResult] := actualName
                }
            }
        }
    } catch {
        ; If file doesn't exist, start with empty map
        correctionDatabase := Map()
    }
}

; Save correction to file
SaveCorrection(ocrResult, actualName) {
    global correctionDatabase
    
    ; Add to memory
    correctionDatabase[ocrResult] := actualName
    
    ; Append to file
    try {
        content := ocrResult . " -> " . actualName . "`n"
        FileAppend(content, "student_corrections.txt")
    } catch {
        ; If save fails, at least we have it in memory for this session
    }
}

; Calculate edit distance between two strings (Levenshtein distance)
EditDistance(str1, str2) {
    len1 := StrLen(str1)
    len2 := StrLen(str2)
    
    ; Create matrix
    matrix := []
    Loop len1 + 1 {
        row := []
        Loop len2 + 1 {
            row.Push(0)
        }
        matrix.Push(row)
    }
    
    ; Initialize first row and column
    Loop len1 + 1 {
        matrix[A_Index][1] := A_Index - 1
    }
    Loop len2 + 1 {
        matrix[1][A_Index] := A_Index - 1
    }
    
    ; Fill the matrix
    Loop len1 {
        i := A_Index
        Loop len2 {
            j := A_Index
            cost := (StrLower(SubStr(str1, i, 1)) == StrLower(SubStr(str2, j, 1))) ? 0 : 1
            
            matrix[i + 1][j + 1] := Min(
                matrix[i][j + 1] + 1,      ; deletion
                matrix[i + 1][j] + 1,      ; insertion
                matrix[i][j] + cost        ; substitution
            )
        }
    }
    
    return matrix[len1 + 1][len2 + 1]
}

; Find best matching student name
FindBestMatch(ocrResult) {
    global knownStudents
    
    bestMatch := ""
    bestDistance := 999
    
    for student in knownStudents {
        distance := EditDistance(ocrResult, student)
        if (distance < bestDistance) {
            bestDistance := distance
            bestMatch := student
        }
    }
    
    return {name: bestMatch, distance: bestDistance}
}

; Main function to validate and correct student names
ValidateStudentName(ocrResult) {
    global knownStudents, correctionDatabase
    
    ; Clean and skip empty results
    cleanOCR := Trim(ocrResult)
    if (cleanOCR == "") {
        return ""
    }
    
    ; Check if we have a known correction for this exact OCR result (try both original and cleaned)
    if (correctionDatabase.Has(cleanOCR)) {
        return correctionDatabase[cleanOCR]
    }
    if (correctionDatabase.Has(ocrResult)) {
        return correctionDatabase[ocrResult]
    }
    
    ; Check for exact match (case-insensitive)
    for student in knownStudents {
        if (StrLower(cleanOCR) == StrLower(student)) {
            return student  ; Return with proper casing
        }
    }
    
    ; Find fuzzy match using cleaned OCR
    match := FindBestMatch(cleanOCR)
    
    ; If within 2 characters difference, ask user for confirmation
    if (match.distance <= 2 && match.name != "") {
        ; Ask user to confirm the match
        response := MsgBox("OCR detected: '" . cleanOCR . "'`nDid you mean: '" . match.name . "'?`n`nDistance: " . match.distance . " characters", "Name Confirmation", "YesNoCancel")
        
        if (response == "Yes") {
            ; Save this correction for future use (use original OCR for key)
            SaveCorrection(ocrResult, match.name)
            return match.name
        } else if (response == "No") {
            ; Ask user to enter the correct name
            actualName := InputBox("Please enter the correct student name:", "Manual Correction", "", cleanOCR).Value
            if (actualName != "") {
                ; Add to known students if not already there
                found := false
                for student in knownStudents {
                    if (StrLower(actualName) == StrLower(student)) {
                        found := true
                        actualName := student  ; Use existing casing
                        break
                    }
                }
                if (!found) {
                    knownStudents.Push(actualName)
                    ; Save to student_names.txt
                    try {
                        FileAppend(actualName . "`n", "student_names.txt")
                    } catch {
                        ; Continue even if save fails
                    }
                }
                
                ; Save the correction
                SaveCorrection(ocrResult, actualName)
                return actualName
            }
        }
        ; If Cancel, fall through to return original
    } else {
        ; No good match found, ask user for the correct name
        response := MsgBox("OCR detected: '" . cleanOCR . "'`nNo close match found in student database.`n`nIs this name correct?", "Unknown Name", "YesNo")
        
        if (response == "Yes") {
            ; Add to known students
            knownStudents.Push(cleanOCR)
            try {
                FileAppend(cleanOCR . "`n", "student_names.txt")
            } catch {
                ; Continue even if save fails
            }
            return cleanOCR
        } else {
            ; Ask for correct name
            actualName := InputBox("Please enter the correct student name:", "Manual Correction", "", cleanOCR).Value
            if (actualName != "") {
                ; Add to known students if not already there
                found := false
                for student in knownStudents {
                    if (StrLower(actualName) == StrLower(student)) {
                        found := true
                        actualName := student  ; Use existing casing
                        break
                    }
                }
                if (!found) {
                    knownStudents.Push(actualName)
                    try {
                        FileAppend(actualName . "`n", "student_names.txt")
                    } catch {
                        ; Continue even if save fails
                    }
                }
                
                ; Save the correction
                SaveCorrection(ocrResult, actualName)
                return actualName
            }
        }
    }
    
    ; If all else fails, return cleaned OCR result
    return cleanOCR
}

; Initialize the database on load
LoadStudentDatabase()
LoadCorrectionDatabase()