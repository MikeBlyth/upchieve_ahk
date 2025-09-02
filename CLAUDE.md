# Upchieve Waiting Student Detector

This AutoHotkey script automatically detects and clicks on waiting students in Upchieve.

## Files Created
- `upchieve_waiting_detector.ahk` - Main script file

## Features
- Uses FindTextv2 library for fast image recognition
- Automatic window switching to UPchieve
- Page verification using "Waiting Students" image target
- Real-time monitoring for "< 1 minute" waiting indicators
- Auto-click functionality when waiting students are detected

## Usage
1. Run `upchieve_waiting_detector.ahk`
2. Navigate to the Upchieve "Waiting Students" page
3. Press **Ctrl+Shift+A** to activate the detector
4. The script will monitor and automatically click on any waiting students
5. Press **Ctrl+Shift+Q** to quit the application

## How It Works
1. Switches to UPchieve window
2. Verifies correct page using PageTarget image
3. Enters monitoring loop (scans every 0.2 seconds)
4. When WaitingTarget ("< 1 minute") is found, clicks on it
5. Goes dormant until reactivated with Ctrl+Shift+A

## Image Targets
- **PageTarget**: "Waiting Students" page indicator
- **WaitingTarget**: "< 1 minute" waiting time indicator

## Dependencies
- AutoHotkey v2.0+
- FindTextv2.ahk (included)
