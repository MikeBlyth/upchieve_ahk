# Upchieve Waiting Student Detector

This AutoHotkey script automatically detects and clicks on waiting students in Upchieve, with personalized student name extraction.

## Files Created
- `upchieve_waiting_detector.ahk` - Main script file
- `alphabet.ahk` - Character patterns for name recognition
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

## Usage
1. Run `upchieve_waiting_detector.ahk`
2. Navigate to the Upchieve "Waiting Students" page
3. Press **Ctrl+Shift+A** to activate the detector and choose LIVE or TESTING mode
4. The script will monitor and automatically extract student names and show personalized messages
5. Press **Ctrl+Shift+H** to pause/resume detection or **Ctrl+Shift+Q** to quit the application

## How It Works
1. Searches full screen for PageTarget ("Waiting Students" page) to establish reference coordinates
2. Calculates upper-left reference point for window-position independence
3. Enters monitoring loop (scans every 0.05 seconds with 5-second PageTarget re-detection)
4. When WaitingTarget ("< 1 minute") is found:
   - Double-clicks student (200ms delay between clicks) in LIVE mode
   - Extracts student name from region 720px left of indicator
   - Shows personalized message: "Session with [Name] has opened" / "Found student [Name] waiting"
   - Continues monitoring for additional students (until Ctrl+Shift+Q or Ctrl+Shift+H)

## Student Name Extraction
- **Search Region**: 720px left of WaitingTarget, 400px wide, 80px tall
- **Tolerance**: (0.15, 0.05) optimized for grey background
- **Filtering**: Removes noise characters (apostrophes) and proximity duplicates
- **Assembly**: Manual character sorting by X-coordinate for reliable results
- **Logging**: Results logged to debug_log.txt with timestamps

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
