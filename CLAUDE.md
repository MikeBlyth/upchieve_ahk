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

## Usage
1. Run `upchieve_waiting_detector.ahk`
2. Navigate to the Upchieve "Waiting Students" page
3. Script auto-starts and prompts for LIVE or TESTING mode
4. The script will monitor and automatically extract student names and show personalized messages
5. **Hotkeys:**
   - **Ctrl+Shift+H** - Pause/resume detection
   - **Ctrl+Shift+R** - Manual resume from IN_SESSION state  
   - **Ctrl+Shift+Q** - Quit application

## Session State Management
The script now tracks three states to prevent unwanted scanning during active sessions:

- **WAITING_FOR_STUDENT** - Actively scanning for "< 1 minute" indicators
- **IN_SESSION** - With a student, monitoring for session end only
- **PAUSED** - Manually paused via Ctrl+Shift+H

### State Flow:
1. **Student detected and clicked** → Changes to IN_SESSION state
2. **While IN_SESSION**: Only monitors for "Waiting Students" page to detect session end
3. **Session ends** (PageTarget appears) → Shows dialog: "Session ended. Continue looking for students?"
   - Yes: Resume to WAITING_FOR_STUDENT state
   - No: Exit application
   - Cancel: Pause (shows pause dialog, then resumes to WAITING_FOR_STUDENT)
4. **Manual control**: Ctrl+Shift+R hotkey to manually resume from IN_SESSION state

## How It Works
1. **Initial Setup**: Searches full screen for PageTarget ("Waiting Students" page header) to establish reference coordinates
2. **Header Detection**: Locates Student, Help Topic, and Wait Time column headers for precise positioning
3. **Monitoring Loop**: Scans every 0.05 seconds with 10-second PageTarget/header re-detection
4. **Student Detection**: When WaitingTarget ("< 1 minute") is found in Wait Time column:
   - **Immediately clicks** student (200ms delay between clicks) in LIVE mode for minimal delay
   - **Simultaneous OCR extraction** of student name (Student column) and topic (Help Topic column)
   - **Post-click validation** with fuzzy matching and interactive correction dialog
   - **Enhanced logging**: "Session started with [Name], [Topic]" format
   - Shows personalized message: "Session with [Name] ([Topic]) has opened"
   - Continues monitoring for additional students (until Ctrl+Shift+Q or Ctrl+Shift+H)

## OCR System Architecture

### Core Components
- **alphabet.ahk**: Simplified array-based character patterns for A-Z, a-z, apostrophes, hyphens
- **ocr_functions.ahk**: Shared OCR functions with pair-based character prioritization
- **ocr_tester.ahk**: Standalone testing application for parameter tuning and pattern development

### Student Name Extraction
- **Search Region**: 720px left of WaitingTarget, 400px wide, 80px tall
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

### Topic Validation System
- **Known Subjects Database**: Pre-defined list of 10 official Upchieve subjects
  - 6th Grade Math, 7th Grade Math, 8th Grade Math
  - Pre-algebra, Algebra, Integrated Math, Statistics
  - Middle School Science, Computer Science A, Computer Science Principles
- **Automatic Validation**: Fuzzy matching with edit distance algorithm
- **Tolerance Levels**: 3-character tolerance for short topics, 4-character for longer names
- **Fallback Processing**: Returns cleaned OCR result if no close match found
- **Silent Correction**: Corrects common OCR errors without user intervention

### OCR Testing Application
- **Region Selection**: Click-and-drag screen region selection
- **Parameter Controls**: Adjustable tolerance values and proximity thresholds
- **Method Comparison**: Test both Individual and JoinText approaches
- **Real-time Results**: Shows both clean characters and raw detections
- **Pattern Development**: Auto-reload alphabet patterns for rapid iteration

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
- alphabet.ahk (character patterns for A-Z, a-z, apostrophe, hyphen)

## Recent Improvements
- **Modular Architecture**: Separated OCR functions into shared library (`ocr_functions.ahk`)
- **Array-based Alphabet**: Simplified character pattern management from 60+ variables to single array
- **Pair-based Prioritization**: Comprehensive character conflict resolution using explicit pair priorities
- **Student Database Integration**: Fuzzy matching with edit distance algorithm and interactive correction
- **Performance Optimization**: Separated fast raw OCR from slower validation for minimal click delays
- **OCR Testing Tool**: Built standalone application for rapid pattern development and parameter tuning
- **Multiple Character Patterns**: Support for multiple patterns per character (especially 'y', 't', 'd')
- **Enhanced Debug Output**: Added sorted raw character display and method comparison
- **Dynamic Reloading**: Alphabet patterns can be updated without application restart
- **PageTarget Optimization**: Updated coordinates for smaller PageTarget4 (143×16 vs original 271×45)
- **Tolerance Tuning**: Default OCR tolerances optimized to (0.15, 0.10) for better accuracy

## Performance Considerations
- **Initial PageTarget search**: 170-200ms (full screen)
- **WaitingTarget detection**: <50ms (localized search area)
- **Student click response**: Immediate (raw OCR extraction is fast)
- **Name validation**: Post-click (doesn't delay student interaction)
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
