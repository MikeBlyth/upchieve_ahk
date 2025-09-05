#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk

; Shared OCR functions for both main detector and testing app

; Load alphabet characters for name extraction
LoadAlphabetCharacters() {
    ; Combine all lowercase letters
    Text := Texta . Textb . Textc . Textd . Texte . Textf . Textg . Texth . Texti . Textj . Textk . Textl . Textm . Textn . Texto . Textp . Textq . Textr . Texts . Textt . Textu . Textv . Textw . Textx . Texty . Textz
    
    ; Add uppercase letters
    Text .= Text_A . Text_B . Text_C . Text_D . Text_E . Text_F . Text_G . Text_H . Text_I . Text_J . Text_K . Text_L . Text_M . Text_N . Text_O . Text_P . Text_Q . Text_R . Text_S . Text_T . Text_U . Text_V . Text_W . Text_X . Text_Y . Text_Z
    
    ; Add special characters
    Text .= Text_apos . Text_hyphen
    
    ; Register with FindText library
    FindText().PicLib(Text, 1)
}

; Extract text from a specified screen region with configurable parameters
ExtractTextFromRegion(x1, y1, x2, y2, tolerance1 := 0.15, tolerance2 := 0.05, proximityThreshold := 8) {
    ; Define character set for names
    nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
    X := ""
    Y := ""
    
    ; Find text characters in the region
    if (ok := FindText(&X, &Y, x1, y1, x2, y2, tolerance1, tolerance2, FindText().PicN(nameChars))) {
        ; Filter and manually assemble characters
        cleanChars := Array()
        for i, char in ok {
            ; Skip apostrophes and noise characters if requested
            if (char.id == "'") {
                continue
            }
            
            ; Check proximity to existing characters
            tooClose := false
            for j, existingChar in cleanChars {
                if (Abs(char.x - existingChar.x) < proximityThreshold && Abs(char.y - existingChar.y) < proximityThreshold) {
                    tooClose := true
                    break
                }
            }
            if (!tooClose) {
                cleanChars.Push(char)
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
            return {text: finalText, chars: cleanChars, rawChars: ok}
        }
    }
    
    return {text: "", chars: [], rawChars: []}  ; Return empty if extraction failed
}