# Upchieve Waiting Student Detector

This AutoHotkey script automatically detects and clicks on waiting students in Upchieve, with personalized student name extraction.

## Files Created
- `upchieve_waiting_detector.ahk` - Main script file
- `alphabet.ahk` - Character patterns for name recognition
- `debug_log.txt` - OCR troubleshooting and results log

## Features
- Uses FindTextv2 library for fast image recognition
- Automatic window switching to UPchieve
- Page verification using "Waiting Students" image target
- Real-time monitoring for "< 1 minute" waiting indicators
- **Student name extraction** from detected waiting entries
- **Personalized notifications** (e.g. "Student Camila waiting!")
- Auto-click functionality when waiting students are detected

## Usage
1. Run `upchieve_waiting_detector.ahk`
2. Navigate to the Upchieve "Waiting Students" page
3. Press **Ctrl+Shift+A** to activate the detector
4. The script will monitor and automatically extract student names and show personalized messages
5. Press **Ctrl+Shift+Q** to quit the application

## How It Works
1. Switches to UPchieve window
2. Verifies correct page using PageTarget image
3. Enters monitoring loop (scans every 0.05 seconds)
4. When WaitingTarget ("< 1 minute") is found:
   - Extracts student name from region 680px left of indicator
   - Shows personalized message: "Student [Name] waiting!"
   - Goes dormant until reactivated with Ctrl+Shift+A

## Student Name Extraction
- **Search Region**: 720px left of WaitingTarget, 400px wide, 80px tall
- **Tolerance**: (0.15, 0.05) optimized for grey background
- **Filtering**: Removes noise characters (apostrophes) and proximity duplicates
- **Assembly**: Manual character sorting by X-coordinate for reliable results
- **Logging**: Results logged to debug_log.txt with timestamps

## Image Targets
- **PageTarget**: "Waiting Students" page indicator
- **WaitingTarget**: "< 1 minute" waiting time indicator  
- **UpgradeTarget**: Update popup dismissal

## Search Zones
These are the approximate locations of the search zones with a screen size of 3200 x 2000. The first pair is the upper left coord, the second pair is the width and height. 
- PageTarget (Waiting Students): (891, 889), (555, 160) [with ±100px margins]
- WaitingTarget (< 1 minute): (1273, 1188), (334, 235) [with ±100px margins]  
- UpgradeTarget (Update popup): (1593, 1009), (325, 300) [with ±100px margins]
- Student Name Region: 720px left of WaitingTarget, (400, 80) size

Screen size 3200x2000

## Dependencies
- AutoHotkey v2.0+
- FindTextv2.ahk (included)
- alphabet.ahk (character patterns for A-Z, a-z, apostrophe, hyphen)
