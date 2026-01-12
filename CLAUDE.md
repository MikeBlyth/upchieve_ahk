# Upchieve Student Detector

Automated student detection for UPchieve using browser extension (recommended) and AutoHotkey script.

## Current System Overview

### Browser Extension (Recommended - 2025)
- **Files**: `extension/` folder with manifest.json, content.js, background.js, popup.html/js
- **Features**: Real-time DOM monitoring, 100% accurate student detection, clipboard integration
- **Installation**: Chrome Developer Mode → Load Unpacked → Select `extension/` folder
- **Usage**: Navigate to app.upchieve.org → Click extension icon → Enable detector
- **Output Format**: `*upchieve|StudentName|HelpTopic|WaitMinutes` copied to clipboard

### AutoHotkey System
- **Main Script**: `upchieve_integrated_detector.ahk` - Integrated detection with session management
- **Dependencies**: FindTextv2.ahk for pattern detection, comm_manager.ahk
- **Data Files**: block_names.txt, upchieve_app.log (CSV export)
- **Hotkeys**: Ctrl+Shift+H (toggle Live/Scan), Ctrl+Shift+A (manual session toggle), Ctrl+Shift+Q (quit)

## Quick Start

**Browser Extension:**
1. Load extension in Chrome developer mode
2. Navigate to UPchieve and enable detector
3. Extension automatically detects new students and copies data to clipboard

**AutoHotkey Script:**
1. Run `upchieve_integrated_detector.ahk`
2. Click on UPchieve browser window when prompted
3. Select LIVE, SCAN, or TESTING mode
4. Script monitors for students (via extension or visual patterns) and manages sessions

## Key Features

### Browser Extension
- **DOM Monitoring**: MutationObserver for real-time student detection
- **Visual Indicators**: Green icon when active, notifications for new students
- **Platform Independent**: Works on any browser/OS
- **Zero Maintenance**: No pattern updates needed

### AutoHotkey Script
- **Integrated Detection**: Combines extension data with visual verification
- **Session Tracking**: Three states (WAITING_FOR_STUDENTS, IN_SESSION, PAUSED)
- **Sound Safety Check**: Prevents entering Live Mode or continuing if the tab is muted
- **Student Blocking**: Skip students listed in `block_names.txt`
- **CSV Logging**: Comprehensive session data export to `upchieve_app.log`
- **End-Session Dialog**: Detailed feedback form for session data entry

## File Structure

### Extension Files
- `extension/manifest.json` - Chrome extension config
- `extension/content.js` - DOM monitoring and data extraction
- `extension/popup.html/js` - Control interface

### AutoHotkey Files
- `upchieve_integrated_detector.ahk` - Main detection script
- `block_names.txt` - Students to skip (optional)
- `upchieve_app.log` - CSV session data

## AutoHotkey Technical Details

### Architecture
- **Header Detection**: Retries up to 10 times (2-second intervals) at startup. Periodic refresh every 60s.
- **Sound Check**: `EnsureSoundUnmuted` checks periodically and on mode switch.
- **SearchZone System**: Header-based positioning for pattern detection
- **Subject Recognition**: Direct pattern matching for 10+ subjects
- **Manual Session Handling**: If script starts during a manual session, it will wait until session ends to detect headers

### Session Management
1. **WAITING_FOR_STUDENTS**: Scans for students
2. **IN_SESSION**: Monitors for session end only
3. **Session End**: Shows feedback dialog for manual data entry
4. **CSV Export**: 21-column format for spreadsheet analysis

### Performance
- **Header detection**: Periodic refresh every 60s
- **Student detection**: ~25ms (pattern matching)
- **Subject detection**: ~25ms (pattern matching)
- **Wait monitoring**: 60-second continuous cycles

## Troubleshooting
- **Extension**: Check console (F12) for debug output
- **AutoHotkey**: Ensure all 3 column headers visible, browser zoom at 100%
- **Missing headers**: Script will retry automatically.
- **Muted Sound**: Script will pause and alert if the tab is muted in Live Mode.
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