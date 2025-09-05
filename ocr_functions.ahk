#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Shared OCR functions for both main detector and testing app

; Character prioritization for ambiguous matches
; Returns the higher priority character when two characters occupy the same position
GetPriorityCharacter(char1, char2) {
    ; Define character pair priorities
    ; Format: "char1,char2" -> preferred character (char1 or char2)
    pairPriorities := Map(
        ; Common ambiguous pairs - lowercase
        "r,n", "n",  ; n over r
        "n,r", "n",  ; n over r (reverse order)
        "r,m", "m",  ; n over r
        "m,r", "m",  ; n over r (reverse order)
        "r,h", "h",  ; h over r  
        "h,r", "h",  ; h over r (reverse)
        "r,p", "p",  ; p over r
        "p,r", "p",  ; p over r (reverse)
        "n,h", "h",  ; h over n
        "h,n", "h",  ; h over n (reverse)
        "l,h", "h",  ; h over n
        "h,l", "h",  ; h over n (reverse)
        "c,e", "e",  ; e over c
        "e,c", "e",  ; e over c (reverse)
        "o,a", "a",  ; a over o
        "a,o", "a",  ; a over o (reverse)
        "o,e", "e",  ; a over o
        "e,o", "e",  ; a over o (reverse)
        "o,d", "d",  ; d over o
        "d,o", "d",  ; d over o (reverse)
        "l,i", "l",  ; l over i
        "i,l", "l",  ; l over i (reverse)
        "l,t", "t",  ; t over l
        "t,l", "t",  ; t over l (reverse)
        "l,d", "d",  ; d over l
        "d,l", "d",  ; d over l (reverse)
        "m,n", "m",  ; m over n
        "n,m", "m",  ; m over n (reverse)
        "q,d", "d",  ; q over d
        "d,q", "d",  ; q over d (reverse)
        
        ; Uppercase pairs
        "I,b", "b",  ; b over I
        "b,I", "b",  ; b over I (reverse)
        "I,d", "d",  ; d over I
        "d,I", "d",  ; d over I (reverse)
        "I,f", "f",  ; f over I
        "f,I", "f",  ; f over I (reverse)
        "I,l", "l",  ; l over I
        "l,I", "l",  ; l over I (reverse)
        "I,h", "h",  ; h over I
        "h,I", "h",  ; h over I (reverse)
        "I,p", "p",  ; p over I
        "p,I", "p",  ; p over I (reverse)
        "I,q", "q",  ; q over I
        "q,I", "q",  ; q over I (reverse)
        "I,t", "t",  ; t over I
        "t,I", "t",  ; t over I (reverse)
        "C,G", "G",  ; G over C
        "G,C", "G",  ; G over C (reverse)
        "O,Q", "Q",  ; Q over O
        "Q,O", "Q",  ; Q over O (reverse)
        "I,B", "B",  ; B over I
        "B,I", "B",  ; B over I (reverse)
        "I,D", "D",  ; D over I
        "D,I", "D",  ; D over I (reverse)
        "I,E", "E",  ; E over I
        "E,I", "E",  ; E over I (reverse)
        "I,F", "F",  ; F over I
        "F,I", "F",  ; F over I (reverse)
        "I,H", "H",  ; H over I
        "H,I", "H",  ; H over I (reverse)
        "I,J", "J",  ; J over I
        "J,I", "J",  ; J over I (reverse)
        "I,L", "L",  ; L over I
        "L,I", "L",  ; L over I (reverse)
        "I,M", "M",  ; M over I
        "M,I", "M",  ; M over I (reverse)
        "I,N", "N",  ; N over I
        "N,I", "N",  ; N over I (reverse)
        "I,P", "P",  ; P over I
        "P,I", "P",  ; P over I (reverse)
        "I,R", "R",  ; R over I
        "R,I", "R",  ; R over I (reverse)
        "I,T", "T",  ; T over I
        "T,I", "T",  ; T over I (reverse)
        "I,U", "U",  ; U over I
        "U,I", "U"   ; U over I (reverse)
    )
    
    ; Check for specific pair priority
    pairKey := char1.id . "," . char2.id
    if (pairPriorities.Has(pairKey)) {
        preferred := pairPriorities[pairKey]
        return (preferred == char1.id) ? char1 : char2
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

; Load alphabet characters for name extraction
LoadAlphabetCharacters() {
    global alphabet
    
    ; Re-read alphabet.ahk file to pick up any changes
    try {
        alphabetContent := FileRead("alphabet.ahk")
        
        ; Execute the file content to update the alphabet array
        ; This safely evaluates the alphabet array definition
        tempCode := ""
        inArray := false
        for line in StrSplit(alphabetContent, "`n") {
            line := Trim(line)
            if (InStr(line, "alphabet := [")) {
                inArray := true
                tempCode .= line . "`n"
            } else if (inArray) {
                tempCode .= line . "`n"
                if (InStr(line, "]")) {
                    break
                }
            }
        }
        
        ; Execute the array definition to update the global alphabet variable
        if (tempCode != "") {
            %tempCode%  ; This updates the global alphabet array
        }
    } catch {
        ; If file reading fails, fall back to existing alphabet array
    }
    
    ; Combine all patterns from the array
    Text := ""
    for pattern in alphabet {
        Text .= pattern
    }
    
    ; Register with FindText library
    FindText().PicLib(Text, 1)
}

; Extract text from a specified screen region with configurable parameters
ExtractTextFromRegion(x1, y1, x2, y2, tolerance1 := 0.15, tolerance2 := 0.10, proximityThreshold := 8, useJoinText := false) {
    ; Define character set for names
    nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
    X := ""
    Y := ""
    
    ; Choose OCR method based on parameter
    if (useJoinText) {
        ; Use JoinText for sequential character matching
        ; JoinText expects to find characters in sequence, so we search for any text
        if (ok := FindText(&X, &Y, x1, y1, x2, y2, tolerance1, tolerance2, FindText().PicN(nameChars), 1, 1, 0, 0, 0, 1)) {
            ; With JoinText, we should get sequential text results
            ; Sort results by position and build text
            if (ok.Length > 0) {
                ; Sort by X coordinate
                Loop ok.Length - 1 {
                    i := A_Index
                    Loop ok.Length - i {
                        j := A_Index
                        if (ok[j].x > ok[j+1].x) {
                            temp := ok[j]
                            ok[j] := ok[j+1] 
                            ok[j+1] := temp
                        }
                    }
                }
                
                ; Build text from sorted results
                extractedText := ""
                for char in ok {
                    extractedText .= char.id
                }
                extractedText := RegExReplace(extractedText, "[^a-zA-Z' -]", "")
                finalText := Trim(extractedText)
                
                ; Return result with JoinText data
                return {text: finalText, chars: ok, rawChars: ok, method: "JoinText"}
            }
        }
    } else {
        ; Use individual character matching (original method)
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
                
                ; Return both the final text and the raw character array for analysis
                return {text: finalText, chars: cleanChars, rawChars: ok, method: "Individual"}
            }
        }
    }
    
    return {text: "", chars: [], rawChars: []}  ; Return empty if extraction failed
}