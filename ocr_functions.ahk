#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Default OCR parameters - easy to find and modify
global DEFAULT_TOLERANCE1 := 0.14
global DEFAULT_TOLERANCE2 := 0.08
global DEFAULT_PADDING_FACTOR := -2
global DEFAULT_WIDTH_SIMILARITY_THRESHOLD := 1.5

; Shared OCR functions for both main detector and testing app

; Character prioritization for ambiguous matches
; Returns the higher priority character when two characters occupy the same position
GetPriorityCharacter(char1, char2, widthSimilarityThreshold := DEFAULT_WIDTH_SIMILARITY_THRESHOLD) {
    global characterWidths

    ; Debug: Log priority decision process
    debugPriorityLog := []
    debugPriorityLog.Push("=== PRIORITY DECISION: '" . char1.id . "' vs '" . char2.id . "' ===")

    ; First check width-based priority
    char1Width := characterWidths.Get(char1.id, 10)
    char2Width := characterWidths.Get(char2.id, 10)

    debugPriorityLog.Push("Widths: " . char1.id . "=" . char1Width . ", " . char2.id . "=" . char2Width)

    ; Calculate width similarity ratio
    maxWidth := Max(char1Width, char2Width)
    minWidth := Min(char1Width, char2Width)
    widthRatio := maxWidth / minWidth

    debugPriorityLog.Push("Width ratio: " . maxWidth . "/" . minWidth . " = " . widthRatio)
    debugPriorityLog.Push("Threshold: " . widthSimilarityThreshold)

    ; If widths are significantly different, prefer wider character
    if (widthRatio > widthSimilarityThreshold) {
        winner := (char1Width > char2Width) ? char1 : char2
        debugPriorityLog.Push("WIDTH-BASED DECISION: '" . winner.id . "' wins (ratio " . widthRatio . " > " . widthSimilarityThreshold . ")")
        ; Store debug log in global for retrieval
        global lastPriorityDebug := debugPriorityLog
        return winner
    }

    ; Widths are similar - use pair-based priority rules for visual conflicts
    ; Define character pair priorities (base pairs only - inverse pairs auto-generated)
    ; Format: "char1,char2" -> preferred character
    pairPriorities := Map(
        ; Common ambiguous pairs - lowercase
        "r,n", "n",  ; n over r
        "r,m", "m",  ; m over r
        "r,h", "h",  ; h over r  
        "r,p", "p",  ; p over r
        "n,h", "h",  ; h over n
        "l,h", "h",  ; h over l
        "i,j", "j",  ; j over i
        "l,j", "j",  ; j over l
        "I,j", "j",  ; j over I
        "I,k", "k",  ; j over I
        "l,k", "k",  ; j over I
        "c,e", "e",  ; e over c
        "o,a", "a",  ; a over o
        "o,e", "e",  ; e over o
        "o,d", "d",  ; d over o
        "l,i", "l",  ; l over i
        "l,t", "t",  ; t over l
        "l,d", "d",  ; d over l
        "m,n", "m",  ; m over n
        "q,d", "d",  ; q over d
        
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
        "O,G", "G",  ; G over O
        "O,Q", "Q",  ; Q over O
        "I,B", "B",  ; B over I
        "I,D", "D",  ; D over I
        "I,E", "E",  ; E over I
        "F,E", "E",  ; E over F
        "I,F", "F",  ; F over I
        "T,F", "F",  ; F over T
        "I,H", "H",  ; H over I
        "I,J", "J",  ; J over I
        "I,L", "L",  ; L over I
        "l,L", "L",  ; L over l
        "I,M", "M",  ; M over I
        "I,N", "N",  ; N over I
        "I,P", "P",  ; P over I
        "I,R", "R",  ; R over I
        "F,T", "T",  ; F over T
        "I,T", "T",  ; T over I
        "I,U", "U"   ; U over I
    )
    
    ; Auto-generate inverse pairs to avoid manual duplication
    inversePairs := Map()
    for pairKey, winner in pairPriorities {
        ; For "r,n" -> "n", also add "n,r" -> "n"
        chars := StrSplit(pairKey, ",")
        inversePair := chars[2] . "," . chars[1]
        if (!pairPriorities.Has(inversePair)) {
            inversePairs[inversePair] := winner
        }
    }
    
    ; Merge inverse pairs into main map
    for pairKey, winner in inversePairs {
        pairPriorities[pairKey] := winner
    }
    
    debugPriorityLog.Push("WIDTHS SIMILAR - checking pair-based rules")

    ; Early hyphen check - hyphen loses to any other character
    if (char1.id == "-" && char2.id != "-") {
        debugPriorityLog.Push("HYPHEN RULE: '" . char2.id . "' beats '-'")
        global lastPriorityDebug := debugPriorityLog
        return char2
    }
    if (char2.id == "-" && char1.id != "-") {
        debugPriorityLog.Push("HYPHEN RULE: '" . char1.id . "' beats '-'")
        global lastPriorityDebug := debugPriorityLog
        return char1
    }

    ; Check for specific pair priority
    pairKey := char1.id . "," . char2.id
    debugPriorityLog.Push("Checking pair key: '" . pairKey . "'")

    if (pairPriorities.Has(pairKey)) {
        preferred := pairPriorities[pairKey]
        winner := (preferred == char1.id) ? char1 : char2
        debugPriorityLog.Push("PAIR RULE: '" . preferred . "' preferred -> '" . winner.id . "' wins")
        global lastPriorityDebug := debugPriorityLog
        return winner
    } else {
        debugPriorityLog.Push("No pair rule found for '" . pairKey . "'")
    }

    ; If no specific pair rule, prefer character with longer match string
    ; Longer strings generally indicate more specific/detailed character patterns
    len1 := StrLen(char1.id)
    len2 := StrLen(char2.id)

    debugPriorityLog.Push("String lengths: " . char1.id . "=" . len1 . ", " . char2.id . "=" . len2)

    if (len1 != len2) {
        winner := (len1 > len2) ? char1 : char2
        debugPriorityLog.Push("LENGTH RULE: '" . winner.id . "' wins (longer)")
        global lastPriorityDebug := debugPriorityLog
        return winner
    }

    ; If both length are equal, return the first one (arbitrary but consistent)
    debugPriorityLog.Push("DEFAULT RULE: '" . char1.id . "' wins (first)")
    global lastPriorityDebug := debugPriorityLog
    return char1
}

; Replace letter combinations that are misdetections of single wide characters
ReplaceLetterCombinations(text) {
    ; Handle wide M character that gets detected as MI or Ml
    text := StrReplace(text, "MI", "M",1)
    text := StrReplace(text, "Ml", "M",1)
    text := StrReplace(text, "NI", "N",1)
    text := StrReplace(text, "UI", "U",1)
    
    return text
}

; Global character width table built from alphabet patterns
global characterWidths := Map()

; Extract true visual width from a FindText pattern by analyzing ink pixels
GetInkWidthFromPattern(pattern) {
    ; Parse pattern format: "|<char>*threshold$width.hexdata"
    ; Extract the width and bitmap data portion
    if (!RegExMatch(pattern, "\|<(.+?)>\*.*?\$(\d+)\.(.+)", &match)) {
        return -1  ; Invalid pattern format
    }

    char := match[1]
    patternWidth := Integer(match[2])
    hexData := match[3]

    try {
        ; Use FindText's base64tobit function to decode bitmap data
        bitmapData := FindText().base64tobit(hexData)
        dataLength := StrLen(bitmapData)

        ; Calculate height from data length and width
        height := dataLength // patternWidth

        ; Validate dimensions
        if (patternWidth < 1 || height < 1 || dataLength != patternWidth * height) {
            return -1  ; Invalid bitmap dimensions
        }

        ; Scan bitmap to find ink boundaries
        leftmostInk := patternWidth  ; Start with max possible
        rightmostInk := 0            ; Start with min possible

        ; Scan each column (x position)
        Loop patternWidth {
            col := A_Index - 1  ; 0-based column index
            hasInk := false

            ; Scan this column for any ink pixels
            Loop height {
                row := A_Index - 1  ; 0-based row index
                pixelIndex := row * patternWidth + col + 1  ; 1-based for AutoHotkey

                if (pixelIndex <= dataLength) {
                    pixel := SubStr(bitmapData, pixelIndex, 1)
                    ; Check if pixel represents ink (non-zero/non-space)
                    if (pixel != "0" && pixel != " ") {
                        hasInk := true
                        break
                    }
                }
            }

            ; Update boundaries if this column has ink
            if (hasInk) {
                leftmostInk := Min(leftmostInk, col)
                rightmostInk := Max(rightmostInk, col)
            }
        }

        ; Calculate ink width
        if (leftmostInk <= rightmostInk) {
            inkWidth := rightmostInk - leftmostInk + 1
            return inkWidth
        } else {
            ; No ink found - return pattern width as fallback
            return patternWidth
        }
    } catch {
        ; If decoding fails, return pattern width as fallback
        return patternWidth
    }
}

; Build character width lookup table from alphabet patterns
BuildCharacterWidthTable() {
    global name_characters, characterWidths

    characterWidths := Map()

    if (!IsObject(name_characters)) {
        return characterWidths
    }

    ; Parse each pattern to extract character and calculate ink width
    for pattern in name_characters {
        ; Match pattern like "|<i>*100$3.hex..." to extract character
        if (RegExMatch(pattern, "\|<(.+?)>\*\d+\$(\d+)\.", &match)) {
            char := match[1]
            patternWidth := Integer(match[2])

            ; Try to get true ink width from bitmap analysis
            inkWidth := GetInkWidthFromPattern(pattern)

            ; Use ink width if successful, otherwise fall back to pattern width
            width := (inkWidth > 0) ? inkWidth : patternWidth

            ; Keep minimum width if multiple patterns exist for same character (tightest ink bounds)
            if (!characterWidths.Has(char) || width < characterWidths[char]) {
                characterWidths[char] := width
            }
        }
    }

    return characterWidths
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

    ; Build character width table from loaded patterns
    BuildCharacterWidthTable()
}

; Extract text from a specified screen region with configurable parameters
ExtractTextFromRegion(x1, y1, x2, y2, tolerance1 := DEFAULT_TOLERANCE1, tolerance2 := DEFAULT_TOLERANCE2, proximityThreshold := 10, paddingFactor := DEFAULT_PADDING_FACTOR, widthSimilarityThreshold := DEFAULT_WIDTH_SIMILARITY_THRESHOLD) {
    ; Define character set for names
    nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
    X := ""
    Y := ""

    ; Initialize debug tracking
    debugLog := []
    conflictLog := []

    ; Use individual character matching
    if (ok := FindText(&X, &Y, x1, y1, x2, y2, tolerance1, tolerance2, FindText().PicN(nameChars))) {
        ; Sort raw characters by X coordinate BEFORE conflict detection
        ; This ensures left-to-right processing order for proper overlap detection
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

        ; Filter and manually assemble characters
        cleanChars := Array()

        debugLog.Push("=== PROCESSING " . ok.Length . " RAW CHARACTERS (sorted by X position) ===")

        for i, char in ok {
            debugLog.Push("Processing char " . i . ": '" . char.id . "' at (" . char.x . "," . char.y . ")")

            ; Skip apostrophes and noise characters if requested
            if (char.id == "'") {
                debugLog.Push("  -> SKIPPED (apostrophe)")
                continue
            }

            ; Check for bounding box overlap and handle prioritization
            conflictIndex := -1
            debugLog.Push("  -> Checking conflicts against " . cleanChars.Length . " existing chars")

            for j, existingChar in cleanChars {
                ; True bounding box overlap detection using character width lookup table: (x2-x1) < (w1+w2)/2 + padding
                charWidth := characterWidths.Get(char.id, 10)
                existingWidth := characterWidths.Get(existingChar.id, 10)
                overlapThreshold := (charWidth + existingWidth) / 2 + paddingFactor

                distance := Abs(char.x - existingChar.x)

                debugLog.Push("    vs existing[" . j . "] '" . existingChar.id . "' at (" . existingChar.x . "," . existingChar.y . ")")
                debugLog.Push("      widths: " . char.id . "=" . charWidth . ", " . existingChar.id . "=" . existingWidth)
                debugLog.Push("      threshold: (" . charWidth . "+" . existingWidth . ")/2 + " . paddingFactor . " = " . overlapThreshold)
                debugLog.Push("      distance: |" . char.x . "-" . existingChar.x . "| = " . distance)
                debugLog.Push("      overlap? " . distance . " < " . overlapThreshold . " = " . (distance < overlapThreshold ? "YES" : "NO"))

                if (distance < overlapThreshold) {
                    conflictIndex := j
                    debugLog.Push("      -> CONFLICT DETECTED at index " . j)
                    break
                } else {
                    debugLog.Push("      -> No overlap")
                }
            }

            if (conflictIndex == -1) {
                ; No conflict, add character
                cleanChars.Push(char)
                debugLog.Push("  -> ADDED to cleanChars[" . cleanChars.Length . "]")
            } else {
                ; Handle character priority conflict
                existingChar := cleanChars[conflictIndex]
                debugLog.Push("  -> RESOLVING CONFLICT: '" . char.id . "' vs '" . existingChar.id . "'")

                priorityChar := GetPriorityCharacter(char, existingChar, widthSimilarityThreshold)

                conflictLog.Push("CONFLICT: '" . char.id . "' vs '" . existingChar.id . "' -> '" . priorityChar.id . "' chosen")

                ; Debug: Track priority decisions
                if (priorityChar != existingChar) {
                    ; Replace existing character with higher priority one
                    debugLog.Push("    -> REPLACING existing[" . conflictIndex . "] '" . existingChar.id . "' with '" . priorityChar.id . "'")
                    cleanChars[conflictIndex] := priorityChar
                } else {
                    debugLog.Push("    -> KEEPING existing[" . conflictIndex . "] '" . existingChar.id . "', rejecting '" . char.id . "'")
                }
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

            debugLog.Push("=== FINAL RESULT ===")
            debugLog.Push("Clean chars count: " . cleanChars.Length)
            debugLog.Push("Final text: '" . finalText . "'")

            ; Return comprehensive debug information
            return {
                text: finalText,
                chars: cleanChars,
                rawChars: ok,
                method: "Individual",
                debugLog: debugLog,
                conflictLog: conflictLog,
                priorityDebug: (IsSet(lastPriorityDebug) ? lastPriorityDebug : [])
            }
        }
    }

    return {text: "", chars: [], rawChars: [], debugLog: ["No characters found"], conflictLog: [], priorityDebug: []}  ; Return empty if extraction failed
}