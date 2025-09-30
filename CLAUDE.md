# Upchieve Student Detector

Automated student detection for UPchieve using browser extension (recommended) and AutoHotkey script (legacy).

## Current System Overview

### Browser Extension (Recommended - 2025)
- **Files**: `extension/` folder with manifest.json, content.js, background.js, popup.html/js
- **Features**: Real-time DOM monitoring, 100% accurate student detection, clipboard integration
- **Installation**: Chrome Developer Mode → Load Unpacked → Select `extension/` folder
- **Usage**: Navigate to app.upchieve.org → Click extension icon → Enable detector
- **Output Format**: `*upchieve|StudentName|HelpTopic|WaitMinutes` copied to clipboard

### AutoHotkey System (Legacy - Windows Only)
- **Main Script**: `upchieve_waiting_detector.ahk` - Pattern-based detection with session management
- **Dependencies**: FindTextv2.ahk for pattern detection
- **Data Files**: block_names.txt, upchieve_app.log (CSV export)
- **Hotkeys**: Ctrl+Shift+H (pause), Ctrl+Shift+A (manual end session), Ctrl+Shift+Q (quit)

## Quick Start

**Browser Extension (Easiest):**
1. Load extension in Chrome developer mode
2. Navigate to UPchieve and enable detector
3. Extension automatically detects new students and copies data to clipboard

**AutoHotkey Script:**
1. Run `upchieve_waiting_detector.ahk`
2. Click on UPchieve browser window when prompted
3. Select LIVE or TESTING mode
4. Script monitors for "< 1 minute" indicators and auto-clicks students

## System Integration Status
⚠️ **Not Integrated**: Extension and AutoHotkey run independently. Extension detects and copies data; AutoHotkey handles clicking and session management.

## Key Features

### Browser Extension
- **DOM Monitoring**: MutationObserver for real-time student detection
- **Visual Indicators**: Green icon when active, notifications for new students
- **Platform Independent**: Works on any browser/OS
- **Zero Maintenance**: No pattern updates needed

### AutoHotkey Script
- **Pattern Detection**: FindText-based visual pattern recognition
- **Session Tracking**: Three states (WAITING_FOR_STUDENT, IN_SESSION, PAUSED)
- **Student Blocking**: Skip students listed in `block_names.txt`
- **CSV Logging**: Comprehensive session data export to `upchieve_app.log`
- **End-Session Dialog**: Detailed feedback form for session data entry

## File Structure

### Extension Files
- `extension/manifest.json` - Chrome extension config
- `extension/content.js` - DOM monitoring and data extraction
- `extension/popup.html/js` - Control interface

### AutoHotkey Files
- `upchieve_waiting_detector.ahk` - Main detection script
- `block_names.txt` - Students to skip (optional)
- `upchieve_app.log` - CSV session data

## AutoHotkey Technical Details

### Architecture
- **Header Detection**: Retries up to 10 times (2-second intervals) at startup, then proceeds to main loop even if not found. Headers are retried periodically during operation.
- **SearchZone System**: Header-based positioning for pattern detection
- **FindText Wait**: 60-second continuous monitoring (no polling)
- **Subject Recognition**: Direct pattern matching for 10+ subjects
- **Manual Session Handling**: If script starts during a manual session, it will wait until session ends to detect headers

### Session Management
1. **WAITING_FOR_STUDENT**: Scans for "< 1 minute" indicators
2. **IN_SESSION**: Monitors for session end only
3. **Session End**: Shows feedback dialog for manual data entry
4. **CSV Export**: 21-column format for spreadsheet analysis

### Performance
- **Header detection**: Up to 10 retries at startup (2s intervals), then periodic refresh every 60s
- **Student detection**: ~25ms (pattern matching) + ~25ms (blocking check)
- **Subject detection**: ~25ms (pattern matching)
- **Wait monitoring**: 60-second continuous cycles

## Troubleshooting
- **Extension**: Check console (F12) for debug output
- **AutoHotkey**: Ensure all 3 column headers visible, browser zoom at 100%
- **Missing headers**: Script will retry automatically. If starting during a manual session, script will wait for session to end before detecting headers.
- **Pattern issues**: Check that UI elements match expected visual patterns

## Dependencies
- **Extension**: Chrome/Edge with developer mode
- **AutoHotkey**: v2.0+, FindTextv2.ahk library

## AutoHotkey v2 Syntax Notes
- Use `&varName` for output parameters
- No leading `|` on first FindText pattern
- Single-line if statements must be on separate lines
- Pattern detection uses FindText library for visual element matching
- MsgBox button combinations written as one word: "OKCancel", not "OK Cancel"
- Use `Gui.Destroy()` to close GUI windows, not `Gui.Close()`
- Arrays don't have `.Sort()` method - use custom sorting functions instead