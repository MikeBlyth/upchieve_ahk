# Upchieve Waiting Student Detector

This AutoHotkey script automatically detects and clicks on waiting students in Upchieve, with personalized student name extraction.

## Files Created
- `upchieve_waiting_detector.ahk` - Main script file with optimized performance and state management
- `alphabet.ahk` - Character patterns for name recognition (array format with multiple patterns per character)
- `ocr_functions.ahk` - Shared OCR functions with pair-based prioritization and configurable tolerances
- `ocr_tester.ahk` - Standalone OCR testing application for tuning parameters and patterns
- `student_database.ahk` - Student name validation with fuzzy matching and interactive correction
- `student_names.txt` - Database of known student names for validation
- `student_corrections.txt` - Learning database of OCR corrections
- `debug_log.txt` - OCR troubleshooting and results log
- `upchieve_app.log` - CSV session data log for spreadsheet import
- `target_coordinate_finder.ahk` - Utility for measuring target coordinates
- `block_names.txt` - Optional list of student names to skip (one per line)
- `test_whitespace_fix.ahk` - Testing utility for whitespace handling validation

## Features
- Uses FindTextv2 library for fast image recognition
- Window-position independent detection with automatic re-positioning
- Page verification using "Waiting Students" image target
- Real-time monitoring for "< 1 minute" waiting indicators
- **Student name extraction** from detected waiting entries
- **Personalized notifications** (e.g. "Session with Camila has opened!")
- **Student blocking system** - Skip action for names listed in block_names.txt
- Auto-click functionality when waiting students are detected
- LIVE/TESTING mode selection with pause/resume capability
- **Sleep prevention** - Keeps laptop awake while monitoring for students
- **Session feedback system** - CSV logging with comprehensive session data
- **Enhanced end-session dialog** - Captures detailed session information for analysis

## Usage
1. Run `upchieve_waiting_detector.ahk`
2. Navigate to the Upchieve "Waiting Students" page
3. Script auto-starts and prompts for LIVE or TESTING mode
4. The script will monitor and automatically extract student names and show personalized messages
5. **Hotkeys:**
   - **Ctrl+Shift+H** - Pause/resume detection
   - **Ctrl+Shift+A** - Manual end session (shows feedback dialog)
   - **Ctrl+Shift+Q** - Quit application

## Session State Management
The script now tracks three states to prevent unwanted scanning during active sessions:

- **WAITING_FOR_STUDENT** - Actively scanning for "< 1 minute" indicators
- **IN_SESSION** - With a student, monitoring for session end only
- **PAUSED** - Manually paused via Ctrl+Shift+H

### State Flow:
1. **Student detected and clicked** → Changes to IN_SESSION state
2. **While IN_SESSION**: Only monitors for "Waiting Students" page to detect session end
3. **Session ends** (PageTarget appears) → Shows comprehensive feedback dialog with:
   - Student name and subject (editable, pre-filled from OCR)
   - Grade, topic, and session characteristics
   - Session timing and progress metrics
   - Comments field for additional notes
   - Continue/Exit/Pause options
4. **Manual control**: Ctrl+Shift+A hotkey to manually end session and show feedback dialog

## How It Works
1. **Initial Setup**: Searches full screen for PageTarget ("Waiting Students" page header) to establish reference coordinates
2. **Header Detection**: Locates Student, Help Topic, and Wait Time column headers for precise positioning
3. **Monitoring Loop**: Scans every 0.05 seconds with 10-second PageTarget/header re-detection
4. **Student Detection**: When WaitingTarget ("< 1 minute") is found in Wait Time column:
   - **Fast OCR extraction** of student name (Student column) and topic (Help Topic column)
   - **Blocking check** against `block_names.txt` list
   - **Click student** (200ms delay for window activation) in LIVE mode 
   - **Session state change** to IN_SESSION immediately after click
   - **Enhanced logging**: "Session started with [Name], [Topic]" format
   - Shows personalized message: "Session with [Name] ([Topic]) has opened"
   - Continues monitoring for additional students (until Ctrl+Shift+Q or Ctrl+Shift+A)

## OCR System Architecture

### Core Components
- **alphabet.ahk**: Dual array system with `name_characters` (A-Z, a-z, apostrophes, hyphens) and `number_characters` (6, 7, 8)
- **ocr_functions.ahk**: Shared OCR functions with context-aware character filtering and pair-based prioritization
- **ocr_tester.ahk**: Standalone testing application for parameter tuning and pattern development

### Student Name Extraction
- **Search Region**: Header-based positioning (250×90px) or fallback to WaitingTarget relative positioning
- **Character Context**: Uses `name_characters` only (excludes digits 6,7,8 to prevent false matches)
- **Default Tolerances**: (0.15, 0.10) optimized for grey background text
- **Dual OCR Methods**: 
  - Individual character matching with proximity filtering and prioritization
  - JoinText sequential character matching (experimental)
- **Character Prioritization**: Comprehensive pair-based priority system (e.g., 'n' over 'r', 'd' over 'l', 'h' over 'r')
- **Multiple Pattern Support**: Characters like 'y', 't', 'd' have multiple patterns for font variations
- **Proximity Filtering**: Configurable 8px threshold to handle overlapping character detections
- **Dynamic Alphabet Reloading**: Patterns can be updated and reloaded without restarting

### Student Database System
- **Fuzzy Matching**: Edit distance algorithm for finding similar student names
- **Interactive Correction**: User dialogs for OCR validation with up to 3 alternatives
- **Learning System**: Automatically saves corrections to `student_corrections.txt`
- **Performance Optimization**: Fast raw OCR extraction followed by post-click validation
- **Whitespace Handling**: Proper trimming of leading/trailing spaces in student names

### Subject Detection System
- **Direct Pattern Matching**: Uses `SubjectTargets` array with pre-defined subject patterns for instant recognition
- **Supported Subjects**: 
  - 7th Grade Math, 8th Grade Math, 9th Grade Math
  - Pre-algebra, Algebra, Integrated Math, Statistics
  - Middle School Science, Computer Science A (CSA), Computer Science Principles (CSP)
- **Performance**: Direct pattern recognition (~25ms) vs OCR character assembly (~100ms+)
- **Accuracy**: 100% accurate pattern matches, no OCR errors
- **Fallback**: Returns empty string if no patterns match (manual entry in session dialog)
- **Tolerances**: 0.15/0.10 for pattern matching to handle font variations

### OCR Testing Application
- **Region Selection**: Click-and-drag screen region selection
- **Parameter Controls**: Adjustable tolerance values and proximity thresholds
- **Method Comparison**: Test both Individual and JoinText approaches
- **Real-time Results**: Shows both clean characters and raw detections
- **Pattern Development**: Auto-reload alphabet patterns for rapid iteration

## CSV Session Logging

### Session Data Export
The script automatically logs comprehensive session data in CSV format to `upchieve_app.log` for easy import into spreadsheets:

**CSV Columns (21 total):**
1. Seq (blank for manual numbering)
2. Date (M/d/yy format)  
3. Start time (H:mm)
4. Start time (duplicate)
5. End time (H:mm)
6. Blank
7. Student name (from OCR, editable)
8. Grade (user input)
9. Blank
10. Blank  
11. Subject (from OCR, editable)
12. Topic (user input)
13. Math subject (1/0 checkbox)
14. Duration (auto-calculated minutes)
15. Initial response (1/0 checkbox) 
16. Serious question (1/0 checkbox)
17. Left abruptly (1/0 checkbox)
18. Stopped responding (1/0 checkbox)
19. Good progress (float 0-1)
20. Last message time (user input)
21. Comments (user input)

### End-Session Dialog
When a session ends (automatically detected or manually triggered with Ctrl+Shift+A), a comprehensive feedback dialog appears with:
- **Pre-filled fields**: Student name (from OCR) and subject (from pattern matching or OCR)
- **Session metrics**: Grade, topic, math subject indicator
- **Behavioral checkboxes**: Initial response, serious question, left abruptly, stopped responding
- **Progress rating**: Float value 0-1 (defaults to 1.0)
- **Timing**: Last message time, auto-calculated duration
- **Comments**: Free-text notes
- **Actions**: Continue monitoring, exit, or pause
- **Learning System**: Manual corrections to names/subjects are automatically saved to `student_corrections.txt`

All data is automatically saved to CSV format with line-break protection for clean spreadsheet import.

## Student Blocking System
- **Block File**: `block_names.txt` (optional, created by user)
- **Format**: One student name per line, case-insensitive matching
- **Comments**: Lines starting with `;` are ignored
- **Behavior**: When blocked student detected, script logs the encounter and continues monitoring without taking action
- **Example block_names.txt**:
  ```
  ; Students to skip
  John Smith
  Mary Johnson
  TestStudent
  ```

## Image Targets
- **PageTarget**: "Waiting Students" page indicator
- **WaitingTarget**: "< 1 minute" waiting time indicator  
- **UpgradeTarget**: Update popup dismissal
- **SubjectTargets**: Direct pattern recognition for 10 Upchieve subjects
- **SessionEndedTarget**: Session completion detection
- **PencilTipTarget**: Additional UI element detection

## Positioning System
The script uses **window-position independent** relative positioning:

### FindText Coordinate Conversion
FindText returns midpoint coordinates. To get upper-left corner:
```
Upper-left x-coordinate: OutputVar.1.x - OutputVar.1.w / 2
Upper-left y-coordinate: OutputVar.1.y - OutputVar.1.h / 2
```

### Header-Based Search Zones (Current System)
The system now uses column headers to precisely locate search areas:

- **Student Header** (`StudentHeaderTarget`): "Student" column header (71×25 pixels)
- **Help Header** (`HelpHeaderTarget`): "Help Topic" column header (71×25 pixels)  
- **Wait Time Header** (`WaitTimeHeaderTarget`): "Wait Time" column header (97×25 pixels)

**Search Areas** (positioned below headers):
- **Student Name Region**: StudentHeader position + 100px down ± 25px slack, 450×80 pixels
- **Help Topic Region**: HelpHeader position + 100px down ± 25px slack, 450×80 pixels
- **Wait Time Search**: WaitTimeHeader position + 100px down ± 25px slack, 384×235 pixels

**Fallback Zones** (when headers not found):
- **WaitingTarget (< 1 minute)**: Offset (334, 309) from PageTarget4 upper-left, size 334×235
- **UpgradeTarget (Update popup)**: Offset (654, 130) from PageTarget4 upper-left, size 325×300

### Original Absolute Coordinates (3200×2000 screen reference)
- PageTarget: (891, 889) to (1446, 1149)
- WaitingTarget: (1273, 1188) to (1607, 1423)
- UpgradeTarget: (1593, 1009) to (1918, 1309)

## Dependencies
- AutoHotkey v2.0+
- FindTextv2.ahk (included)
- alphabet.ahk (dual character arrays: `name_characters` + `number_characters`)

## Recent Improvements
- **Dual Array System**: Separated character patterns into `name_characters` and `number_characters` for context-aware OCR
- **Direct Subject Recognition**: Replaced OCR-based subject detection with instant pattern matching using `SubjectTargets`
- **Context-Aware Character Filtering**: Student names exclude digits, subjects include grade-level numbers (6,7,8)  
- **Manual Session Control**: Added Ctrl+Shift+A hotkey for manual session ending
- **Improved Session Flow**: Enhanced session end detection with 2-second intervals and proper tolerances (0.15, 0.10)
- **Learning System Integration**: Session feedback dialog automatically saves manual corrections to database
- **Performance Optimization**: Subject detection now ~4x faster (pattern matching vs character OCR)
- **Scan Timing Analysis**: Added 20-scan average timing measurement for performance monitoring
- **Modular Architecture**: Separated OCR functions into shared library (`ocr_functions.ahk`)
- **Pair-based Prioritization**: Comprehensive character conflict resolution using explicit pair priorities
- **Student Database Integration**: Fuzzy matching with edit distance algorithm and interactive correction
- **OCR Testing Tool**: Built standalone application for rapid pattern development and parameter tuning
- **Multiple Character Patterns**: Support for multiple patterns per character (especially 'y', 't', 'd')
- **Dynamic Reloading**: Character patterns can be updated and reloaded without application restart

## Performance Considerations
- **Initial PageTarget search**: 170-200ms (full screen)
- **WaitingTarget detection**: ~25ms average (measured over 20 scans, localized search area)
- **Subject detection**: ~25ms (direct pattern matching vs ~100ms+ OCR)
- **Student name OCR**: Context-aware character filtering (excludes digits 6,7,8)
- **Session end detection**: Every 2 seconds during IN_SESSION state (0.15, 0.10 tolerances)
- **Click response**: 200ms window activation + immediate click
- **PageTarget re-detection**: Every 10 seconds to handle window movement

## Troubleshooting
- **No WaitingTarget found**: Check PageTarget coordinates match current page layout
- **OCR accuracy issues**: Use `ocr_tester.ahk` to tune tolerance values and test patterns
- **Performance problems**: Monitor `debug_log.txt` for timing and detection patterns
- **Window scaling issues**: Ensure browser zoom is at 100% for optimal pattern matching

## Known Issues
- JoinText method requires further refinement for optimal results  
- Some characters (especially 'y') require multiple patterns due to descender positioning
- Window occlusion/shading significantly impacts FindText performance (3-5 seconds vs 170-200ms)
- Character prioritization may need adjustment for specific font variations or new text rendering

## FindText Library Usage Patterns

This section documents the correct usage patterns for the FindText library to avoid future implementation errors.

### Object-Oriented Search Syntax (Recommended)

**Pattern Definition:**
```autohotkey
; Correct: First pattern has no leading |, subsequent patterns do
SubjectTargets := 
    "|<7th Grade Math>*126$48.hexdata..." .
    "|<8th grade math>*128$48.hexdata..." .
    "|<Pre-algebra>*128$45.hexdata..."

; WRONG: Leading | on first pattern (deprecated, may prevent first pattern from being found)
SubjectTargets := 
    "|<7th Grade Math>*126$48.hexdata..." .
```

**Search Syntax:**
```autohotkey
; Correct: New object syntax returns array of match objects
if (result := FindText(x1, y1, x2, y2, tolerance1, tolerance2, patterns)) {
    foundID := result[1].id        ; Pattern name like "7th Grade Math"
    foundX := result[1].x          ; Center X coordinate  
    foundY := result[1].y          ; Center Y coordinate
    foundWidth := result[1].w      ; Pattern width
    foundHeight := result[1].h     ; Pattern height
}

; WRONG: Old coordinate syntax (doesn't return .id property correctly)
if (result := FindText(&X, &Y, x1, y1, x2, y2, tolerance1, tolerance2, patterns)) {
    // X and Y contain coordinates, but result.id may not work properly
}
```

**OCR Character Search:**
```autohotkey
; Correct: Use PicN with simple character strings
nameChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'-"
if (result := FindText(x1, y1, x2, y2, tolerance1, tolerance2, FindText().PicN(nameChars))) {
    // Process character results
}

; WRONG: Trying to use PicN with pattern arrays  
characterPatterns := ["|<a>*100$18.hex...", "|<b>*133$21.hex..."]
FindText().PicN(characterPatterns*)  // ERROR: Too many parameters
```

### Key Differences

1. **New Object Syntax**: Returns array of match objects with `.id`, `.x`, `.y`, `.w`, `.h` properties
2. **Old Coordinate Syntax**: Primarily for getting X,Y coordinates, `.id` property may not work correctly
3. **Leading Pipe**: Deprecated on first pattern, can cause first pattern to never be found
4. **PicN Usage**: Only for simple character strings like "abc123", not for complex pattern arrays

### Migration Notes

- **Subject Detection**: Uses new object syntax with direct pattern concatenation
- **Name OCR**: Uses PicN with simple character strings, registered via PicLib
- **Pattern Registration**: PicLib(patterns, 1) for registration, PicLib("name1|name2") for retrieval
