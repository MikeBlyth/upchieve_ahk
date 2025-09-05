# Upchieve Waiting Student Detector

This AutoHotkey script automatically detects and clicks on waiting students in Upchieve, with personalized student name extraction.

## Files Created
- `upchieve_waiting_detector.ahk` - Main script file
- `alphabet.ahk` - Character patterns for name recognition (array format)
- `ocr_functions.ahk` - Shared OCR functions for both detector and tester
- `ocr_tester.ahk` - Standalone OCR testing application for tuning
- `debug_log.txt` - OCR troubleshooting and results log
- `block_names.txt` - Optional list of student names to skip (one per line)

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
1. Searches full screen for PageTarget ("Waiting Students" page) to establish reference coordinates
2. Calculates upper-left reference point for window-position independence
3. Enters monitoring loop (scans every 0.05 seconds with 5-second PageTarget re-detection)
4. When WaitingTarget ("< 1 minute") is found:
   - Double-clicks student (200ms delay between clicks) in LIVE mode
   - Extracts student name from region 720px left of indicator
   - Shows personalized message: "Session with [Name] has opened" / "Found student [Name] waiting"
   - Continues monitoring for additional students (until Ctrl+Shift+Q or Ctrl+Shift+H)

## OCR System Architecture

### Core Components
- **alphabet.ahk**: Simplified array-based character patterns for A-Z, a-z, apostrophes, hyphens
- **ocr_functions.ahk**: Shared OCR functions with pair-based character prioritization
- **ocr_tester.ahk**: Standalone testing application for parameter tuning and pattern development

### Student Name Extraction
- **Search Region**: 720px left of WaitingTarget, 400px wide, 80px tall
- **Dual OCR Methods**: 
  - Individual character matching with proximity filtering and prioritization
  - JoinText sequential character matching (experimental)
- **Character Prioritization**: Pair-based priority system (e.g., 'n' over 'r', 'd' over 'l')
- **Proximity Filtering**: Configurable threshold to handle overlapping character detections
- **Dynamic Alphabet Reloading**: Patterns can be updated and reloaded without restarting

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

### Search Zones (Relative to PageTarget)
- **PageTarget (Waiting Students)**: Full screen search to find reference point
- **WaitingTarget (< 1 minute)**: Offset (382, 299) from PageTarget upper-left, size 334×235
- **UpgradeTarget (Update popup)**: Offset (702, 120) from PageTarget upper-left, size 325×300  
- **Student Name Region**: 720px left of WaitingTarget, size 400×80

### Original Absolute Coordinates (3200×2000 screen reference)
- PageTarget: (891, 889) to (1446, 1149)
- WaitingTarget: (1273, 1188) to (1607, 1423)
- UpgradeTarget: (1593, 1009) to (1918, 1309)

## Dependencies
- AutoHotkey v2.0+
- FindTextv2.ahk (included)
- alphabet.ahk (character patterns for A-Z, a-z, apostrophe, hyphen)

## Recent Improvements
- **Modular Architecture**: Separated OCR functions into shared library
- **Array-based Alphabet**: Simplified character pattern management from 60+ variables to single array
- **Pair-based Prioritization**: Fixed character conflict resolution using explicit pair priorities
- **OCR Testing Tool**: Built standalone application for rapid pattern development and parameter tuning
- **Enhanced Debug Output**: Added sorted raw character display and method comparison
- **Dynamic Reloading**: Alphabet patterns can be updated without application restart

## Known Issues
- JoinText method requires further refinement for optimal results
- Character prioritization may need adjustment for specific font variations
- Proximity threshold may need tuning based on screen resolution and font size
