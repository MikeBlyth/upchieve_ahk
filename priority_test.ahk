#Requires AutoHotkey v2.0
#Include ocr_functions.ahk

; Priority Algorithm Test Script
; Tests character prioritization with real OCR data

; Create mock character object
CreateChar(id, x) {
    return {id: id, x: x}
}

; Test the Mohammad case that should yield "Mohammad" but fails
TestMohammadCase() {
    Print("=== TESTING MOHAMMAD CASE ===")
    Print("Raw detections (sorted by x-location):")
    
    ; Create mock characters from the failing case
    rawChars := [
        CreateChar("I", 2240),
        CreateChar("M", 2249), 
        CreateChar("I", 2258),
        CreateChar("'", 2265),
        CreateChar("c", 2271),
        CreateChar("o", 2272),
        CreateChar("I", 2286),
        CreateChar("r", 2290),
        CreateChar("h", 2291),
        CreateChar("n", 2291),
        CreateChar("'", 2297),
        CreateChar("a", 2310),
        CreateChar("r", 2328),
        CreateChar("n", 2329),
        CreateChar("m", 2334),
        CreateChar("'", 2354),
        CreateChar("r", 2358),
        CreateChar("n", 2359),
        CreateChar("m", 2365),
        CreateChar("'", 2365),
        CreateChar("'", 2376),
        CreateChar("a", 2389),
        CreateChar("d", 2409),
        CreateChar("I", 2414),
        CreateChar("'", 2414),
        CreateChar("l", 2416)
    ]
    
    ; Show raw detections
    for i, char in rawChars {
        Print(char.x . " " . char.id)
    }
    
    Print("`n--- PROCESSING CHARACTERS ---")
    
    ; Simulate the proximity detection logic
    proximityThreshold := 10
    cleanChars := []
    
    for i, char in rawChars {
        ; Skip apostrophes
        if (char.id == "'") {
            Print("Skipping apostrophe at " . char.x)
            continue
        }
        
        Print("`nProcessing '" . char.id . "' at x=" . char.x)
        
        ; Check proximity to existing characters
        conflictIndex := -1
        for j, existingChar in cleanChars {
            xDiff := Abs(char.x - existingChar.x)
            if (xDiff < proximityThreshold) {
                Print("  CONFLICT with '" . existingChar.id . "' at x=" . existingChar.x . " (diff=" . xDiff . ")")
                conflictIndex := j
                break
            }
        }
        
        if (conflictIndex == -1) {
            ; No conflict, add character
            cleanChars.Push(char)
            Print("  ADDED to cleanChars (no conflict)")
        } else {
            ; Handle character priority conflict
            existingChar := cleanChars[conflictIndex]
            Print("  PRIORITY COMPARISON: '" . char.id . "' vs '" . existingChar.id . "'")
            
            priorityChar := GetPriorityCharacter(char, existingChar)
            Print("  WINNER: '" . priorityChar.id . "'")
            Print("  DEBUG: priorityChar.id = '" . priorityChar.id . "', existingChar.id = '" . existingChar.id . "'")
            
            if (priorityChar != existingChar) { ; Compare objects directly
                cleanChars[conflictIndex] := priorityChar
                Print("  REPLACED '" . existingChar.id . "' with '" . priorityChar.id . "'")
            } else {
                Print("  KEPT existing '" . existingChar.id . "'")
            }
        }
    }
    
    Print("`n--- FINAL RESULTS ---")
    finalText := ""
    for i, char in cleanChars {
        finalText .= char.id
        Print(i . ": '" . char.id . "' at x=" . char.x)
    }
    
    Print("`nFinal text: '" . finalText . "'")
    Print("Expected: 'Mohammad'")
    Print("Success: " . (finalText == "Mohammad" ? "YES" : "NO"))
}

; Test the I, l, L case
TestILlCase() {
    Print("`n`n=== TESTING I, l, L CASE ===")
    Print("Raw detections (sorted by x-location):")
    
    rawChars := [
        CreateChar("I", 2462),
        CreateChar("l", 2463),
        CreateChar("L", 2467)
    ]
    
    for i, char in rawChars {
        Print(char.x . " " . char.id)
    }
    
    Print("`n--- PROCESSING CHARACTERS ---")
    
    proximityThreshold := 10
    cleanChars := []
    
    for i, char in rawChars {
        Print("`nProcessing '" . char.id . "' at x=" . char.x)
        
        conflictIndex := -1
        for j, existingChar in cleanChars {
            xDiff := Abs(char.x - existingChar.x)
            if (xDiff < proximityThreshold) {
                Print("  CONFLICT with '" . existingChar.id . "' at x=" . existingChar.x . " (diff=" . xDiff . ")")
                conflictIndex := j
                break
            }
        }
        
        if (conflictIndex == -1) {
            cleanChars.Push(char)
            Print("  ADDED to cleanChars (no conflict)")
        } else {
            existingChar := cleanChars[conflictIndex]
            Print("  PRIORITY COMPARISON: '" . char.id . "' vs '" . existingChar.id . "'")
            
            priorityChar := GetPriorityCharacter(char, existingChar)
            Print("  WINNER: '" . priorityChar.id . "'")
            Print("  DEBUG: priorityChar.id = '" . priorityChar.id . "', existingChar.id = '" . existingChar.id . "'")
            
            if (priorityChar != existingChar) { ; Compare objects directly
                cleanChars[conflictIndex] := priorityChar
                Print("  REPLACED '" . existingChar.id . "' with '" . priorityChar.id . "'")
            } else {
                Print("  KEPT existing '" . existingChar.id . "'")
            }
        }
    }
    
    Print("`n--- FINAL RESULTS ---")
    finalText := ""
    for i, char in cleanChars {
        finalText .= char.id
        Print(i . ": '" . char.id . "' at x=" . char.x)
    }
    
    Print("`nFinal text: '" . finalText . "'")
    Print("Expected: 'L'")
    Print("Success: " . (finalText == "L" ? "YES" : "NO"))
}

; Test direct priority comparisons
TestDirectPriorities() {
    Print("`n`n=== TESTING DIRECT PRIORITY COMPARISONS ===")
    
    testCases := [
        ["h", "l"],  ; Should return h
        ["l", "h"],  ; Should return h  
        ["h", "r"],  ; Should return h
        ["r", "h"],  ; Should return h
        ["n", "r"],  ; Should return n
        ["r", "n"],  ; Should return n
        ["I", "l"],  ; Should return l
        ["l", "I"],  ; Should return l
        ["o", "c"],  ; Should return o (fallback to length)
        ["c", "o"]   ; Should return o (fallback to length)
    ]
    
    for testCase in testCases {
        char1 := CreateChar(testCase[1], 100) 
        char2 := CreateChar(testCase[2], 105)
        
        result := GetPriorityCharacter(char1, char2)
        Print("GetPriorityCharacter('" . char1.id . "', '" . char2.id . "') = '" . result.id . "'")
    }
}

; Test edge cases at proximity boundary  
TestProximityEdgeCases() {
    Print("`n`n=== TESTING PROXIMITY EDGE CASES ===")
    
    ; Test characters exactly at proximity threshold
    char1 := CreateChar("h", 100)
    char2 := CreateChar("l", 110)  ; Exactly 10 pixels apart
    char3 := CreateChar("r", 109)  ; 9 pixels apart (should conflict)
    
    Print("Distance between h(100) and l(110): " . Abs(char1.x - char2.x) . " pixels")
    Print("Should conflict with threshold=10? " . (Abs(char1.x - char2.x) < 10 ? "YES" : "NO"))
    
    Print("Distance between h(100) and r(109): " . Abs(char1.x - char3.x) . " pixels") 
    Print("Should conflict with threshold=10? " . (Abs(char1.x - char3.x) < 10 ? "YES" : "NO"))
}

; Simple print function  
Print(text) {
    FileAppend(text . "`n", "priority_test_results.txt")
}

; Run all tests
Print("PRIORITY ALGORITHM TEST RESULTS")
Print("===============================")

TestMohammadCase()
TestILlCase()
TestDirectPriorities() 
TestProximityEdgeCases()

Print("`n`nTest completed. Check results above.")