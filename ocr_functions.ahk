#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Shared OCR functions for both main detector and testing app

; Character prioritization for ambiguous matches
; Returns the higher priority character when two characters occupy the same position
GetPriorityCharacter(char1, char2) {
    ; Define character pair priorities using normalized pairs (alphabetically sorted)
    ; Format: "char1,char2" -> preferred character
    pairPriorities := Map(
        ; Common ambiguous pairs - lowercase
        "n,r", "n",  ; n over r
        "m,r", "m",  ; m over r
        "h,r", "h",  ; h over r  
        "p,r", "p",  ; p over r
        "h,n", "h",  ; h over n
        "h,l", "h",  ; h over l
        "c,e", "e",  ; e over c
        "a,o", "a",  ; a over o
        "e,o", "e",  ; e over o
        "d,o", "d",  ; d over o
        "i,l", "l",  ; l over i
        "l,t", "t",  ; t over l
        "d,l", "d",  ; d over l
        "m,n", "m",  ; m over n
        "d,q", "d",  ; d over q

        ; Uppercase pairs
        "I,b", "b",  ; b over I
        "I,d", "d",  ; d over I
        "I,f", "f",  ; f over I
        "I,l", "l",  ; l over I
        "I,h", "h",  ; h over I
        "I,p", "p",  ; p over I
        "I,q", "q",  ; q over I
        "I,t", "t",  ; t over I
        "C,G", "G",  ; G over C
        "O,Q", "Q",  ; Q over O
        "B,I", "B",  ; B over I
        "D,I", "D",  ; D over I
        "E,I", "E",  ; E over I
        "F,I", "F",  ; F over I
        "H,I", "H",  ; H over I
        "I,J", "J",  ; J over I
        "I,L", "L",  ; L over I
        "I,M", "M",  ; M over I
        "I,N", "N",  ; N over I
        "I,P", "P",  ; P over I
        "I,R", "R",  ; R over I
        "I,T", "T",  ; T over I
        "I,U", "U"   ; U over I
    )
    
    ; Normalize the pair by sorting characters alphabetically
    char1Id := char1.id
    char2Id := char2.id
    
    ; Early hyphen check - hyphen loses to any other character
    if (char1Id == "-" && char2Id != "-")
        return char2
    if (char2Id == "-" && char1Id != "-")
        return char1
    
    sortedPair := (StrCompare(char1Id, char2Id) <= 0) ? char1Id . "," . char2Id : char2Id . "," . char1Id
    
    ; Check for specific pair priority
    if (pairPriorities.Has(sortedPair)) {
        preferred := pairPriorities[sortedPair]
        return (preferred == char1Id) ? char1 : char2
    }
    
    ; If no specific pair rule, prefer character with longer match string
    ; Longer strings generally indicate more specific/detailed character patterns
    len1 := StrLen(char1.id)
    len2 := StrLen(char2.id)
    
    if (len1 != len2) {
        return (len1 > len2) ? char1 : char2
    }
    
    ; If both length are equal, return the first one (arbitrary but consistent)
    return char1
}

; Replace letter combinations that are misdetections of single wide characters
ReplaceLetterCombinations(text) {
    ; Handle wide M character that gets detected as MI or Ml
    text := StrReplace(text, "MI", "M")
    text := StrReplace(text, "Ml", "M")
    
    return text
}

; Load alphabet characters for name extraction
LoadAlphabetCharacters() {
    global name_characters
    
    ; Re-read alphabet.ahk file to pick up any changes
    try {
        alphabetContent := FileRead("alphabet.ahk")
        
        ; Parse the file to extract name_characters array
        lines := StrSplit(alphabetContent, "`n")
        newCharacters := []
        inNameCharacters := false
        
        for line in lines {
            line := Trim(line)
            
            ; Start of name_characters array
            if (InStr(line, "name_characters := [")) {
                inNameCharacters := true
                continue
            }
            
            ; End of array
            if (inNameCharacters && InStr(line, "]") && !InStr(line, "|<")) {
                break
            }
            
            ; Extract patterns from array lines
            if (inNameCharacters) {
                ; Remove comments and whitespace
                if (InStr(line, ";")) {
                    line := Trim(SubStr(line, 1, InStr(line, ";") - 1))
                }
                
                ; Extract quoted patterns
                if (InStr(line, '"|<') > 0) {
                    ; Find the pattern between quotes
                    startPos := InStr(line, '"|<')
                    if (startPos > 0) {
                        endPos := InStr(line, '",', startPos)
                        if (endPos == 0) {
                            endPos := InStr(line, '"', startPos + 1)
                        }
                        if (endPos > startPos) {
                            pattern := SubStr(line, startPos + 1, endPos - startPos - 1)
                            if (pattern != "") {
                                newCharacters.Push(pattern)
                            }
                        }
                    }
                }
            }
        }
        
        ; Update the global array if we found patterns
        if (newCharacters.Length > 0) {
            name_characters := newCharacters
        }
    } catch as e {
        ; If file reading fails, fall back to existing array
        ; Optional: could log the error for debugging
    }
    
    ; Combine all patterns from the array for FindText library registration
    Text := ""
    if (IsObject(name_characters)) {
        for pattern in name_characters {
            Text .= pattern
        }
    }
    
    ; Register with FindText library
    FindText().PicLib(Text, 1)
}

; Extract text from a specified screen region with configurable parameters
ExtractTextFromRegion(x1, y1, x2, y2, tolerance1 := 0.15, tolerance2 := 0.10, proximityThreshold := 10) {
    ; Define character set for names
    nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
    X := ""
    Y := ""
    
    ; Use individual character matching
    if (ok := FindText(&X, &Y, x1, y1, x2, y2, tolerance1, tolerance2, FindText().PicN(nameChars))) {
        ; Filter and manually assemble characters
        cleanChars := Array()
        for i, char in ok {
            ; Skip apostrophes and noise characters if requested
            if (char.id == "'") {
                continue
            }
            
            ; Check proximity to existing characters and handle prioritization
            conflictIndex := -1
            for j, existingChar in cleanChars {
                if (Abs(char.x - existingChar.x) < proximityThreshold && Abs(char.y - existingChar.y) < proximityThreshold) {
                    conflictIndex := j
                    break
                }
            }
            
            if (conflictIndex == -1) {
                ; No conflict, add character
                cleanChars.Push(char)
            } else {
                ; Handle character priority conflict
                existingChar := cleanChars[conflictIndex]
                priorityChar := GetPriorityCharacter(char, existingChar)
                ; Debug: Track priority decisions
                if (priorityChar.id != existingChar.id) {
                    ; Replace existing character with higher priority one
                    cleanChars[conflictIndex] := priorityChar
                }
                ; Always log the conflict for debugging
                ; (This will be visible in the results if we add it to return data)
            }
        }
        
        ; Sort characters by X coordinate and build string manually
        if (cleanChars.Length > 0) {
            ; Sort characters by X coordinate (left to right)
            Loop cleanChars.Length - 1 {
                i := A_Index
                Loop cleanChars.Length - i {
                    j := A_Index
                    if (cleanChars[j].x > cleanChars[j+1].x) {
                        temp := cleanChars[j]
                        cleanChars[j] := cleanChars[j+1] 
                        cleanChars[j+1] := temp
                    }
                }
            }
            
            ; Build string from sorted characters
            extractedText := ""
            for i, char in cleanChars {
                extractedText .= char.id
            }
            
            ; Clean up any remaining artifacts
            extractedText := RegExReplace(extractedText, "[^a-zA-Z' -]", "")
            finalText := Trim(extractedText)
            
            ; Apply letter combination replacements
            finalText := ReplaceLetterCombinations(finalText)
            
            ; Return both the final text and the raw character array for analysis
            return {text: finalText, chars: cleanChars, rawChars: ok, method: "Individual"}
        }
    }
    
    return {text: "", chars: [], rawChars: []}  ; Return empty if extraction failed
}