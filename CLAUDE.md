# Upchieve Student Detector

Automated student detection for UPchieve using a browser extension, a local Ruby server, and an AutoHotkey script.

## Current System Overview

### Architecture
The system uses a 3-tier architecture to bridge the browser and the desktop automation:
1.  **Browser Extension**: Monitors the DOM for new students and POSTs data to a local server.
2.  **Ruby Server (`server.rb`)**: A lightweight Sinatra server (port 54567) that acts as a bridge, holding the latest student data in memory.
3.  **AutoHotkey Script**: Polls the server via HTTP to detect changes and automate mouse clicks/alerts.

### Browser Extension (Recommended - 2026)
- **Files**: `extension/` folder
- **Features**: Real-time DOM monitoring (`MutationObserver`), HTTP POST to `127.0.0.1:54567`
- **Installation**: Chrome Developer Mode → Load Unpacked → Select `extension/` folder
- **Usage**: Navigate to app.upchieve.org → Click extension icon → Enable detector
- **Data Flow**: DOM Change -> Extract Data -> POST JSON to local server

### Local Server
- **File**: `server.rb`
- **Stack**: Ruby (Sinatra + WEBrick)
- **Port**: 54567
- **Endpoints**:
    - `POST /students`: Receives JSON from extension
    - `GET /ahk_data`: Serves optimized string (`*upchieve|Name|Topic...`) to AHK
- **Management**: Automatically started/restarted by the AHK script.

### AutoHotkey System
- **Main Script**: `upchieve_integrated_detector.ahk`
- **Communication**: Polls `http://127.0.0.1:54567/ahk_data` every 500ms (Synchronous HTTP)
- **Features**:
    - **Auto-Recovery**: Automatically kills and restarts `ruby.exe` if 5 consecutive timeouts occur.
    - **Session Management**: Tracks WAITING/IN_SESSION states.
    - **Sound Safety**: Prevents operation if system audio is muted.
- **Hotkeys**: Ctrl+Shift+H (toggle Live/Scan), Ctrl+Shift+A (manual session toggle), Ctrl+Shift+Q (quit)

## Quick Start

1.  **Install/Load Extension**: Load the `extension/` folder in Chrome.
2.  **Start AHK**: Run `upchieve_integrated_detector.ahk`.
    - *Note:* The script will automatically start `ruby server.rb` if it's not running.
3.  **Select Mode**: Choose LIVE (auto-click) or TESTING (notify only).
4.  **Enable Extension**: Ensure the extension icon is green on the UPchieve tab.

## Key Features

### Browser Extension
- **Non-Intrusive**: Uses `MutationObserver` to detect changes without polling.
- **Robust**: Retry logic for server connections.
- **Visual Feedback**: Notifications within the browser when students are detected.

### AutoHotkey Script
- **Reliable Polling**: Uses synchronous `WinHttpRequest` with 500ms timeouts for stability.
- **Self-Healing**: Detects "hung" server processes and restarts them automatically.
- **Integrated Detection**: Combines extension data with visual verification (FindText).
- **Session Tracking**: logs data to `upchieve_app.log` (CSV).

## Troubleshooting
- **Server Status**: Open `http://127.0.0.1:54567/ahk_data` in your browser. You should see `*upchieve...`.
- **Extension**: Check `chrome://extensions` for errors. Ensure "Allow access to file URLs" or "Host permissions" are correct if needed (though it uses localhost).
- **Logs**:
    - `upchieve_app.log`: Session history (CSV).
    - `server.err`: Ruby server errors (if piped).
    - AHK internal logs (displayed in debug mode).
- **Timeouts**: If AHK logs "Request timed out", the server might be overloaded. The script will auto-restart it after 5 failures.

## Socket Management & Long-Running Operations

### Why Server Degradation Occurs
The 500ms polling interval creates 2 requests/second. Each HTTP request opens a TCP socket that enters `TIME_WAIT` state for ~120 seconds after closing. If the app runs continuously without restart:
- At any moment: ~240 sockets in TIME_WAIT
- Over 5+ days: Potential socket pool exhaustion
- Result: New requests timeout, server appears unresponsive

This is normal system behavior, not a bug. Windows has ~16,000 ephemeral ports; TIME_WAIT sockets consume slots briefly.

### Prevention Strategies
1. **Daily Usage Pattern** (12 hours on, 12 hours off): 
   - Socket pool resets during downtime
   - No degradation expected
   
2. **Quick Reset** (if timeouts appear):
   - Close AHK (Ctrl+Shift+Q)
   - Wait 2 minutes (all sockets clear)
   - Restart AHK

3. **Circuit Breaker Pattern** (recommended for safety):
   - Track consecutive timeouts (target: 5 failures)
   - After threshold, pause polling for 30 seconds
   - Retry periodically until server recovers
   - **Benefit**: Prevents server degradation if app is accidentally left running
   - **Keeps responsiveness**: Still polls every 500ms during normal operation

### Implementation Notes
- Synchronous HTTP mode (`whr.Open(..., false)`) is used for reliable polling
- Connection timeouts set to 2000ms after experiencing 3+ second delays
- If implementing circuit breaker, use exponential backoff (1s → 2s → 4s → ... up to 30s interval)

## Dependencies
- **Runtime**: Ruby 3.x+ (with `sinatra` gem), AutoHotkey v2.0+
- **Browser**: Chrome/Edge with extension loaded

## AutoHotkey Technical Details

### Architecture
- **Communication**: `comm_manager.ahk` handles HTTP requests.
- **Polling**: 500ms loop in `MainDetectionLoop`.
- **State Machine**: WAITING -> IN_SESSION -> PAUSED.

### Session Management
1.  **WAITING**: Polls server.
2.  **IN_SESSION**: Stops polling server, monitors "Session Ended" visual target.
3.  **Session End**: Shows feedback dialog, logs to CSV, returns to WAITING.

## AutoHotkey v2 Syntax Notes
- Use `&varName` for output parameters
- `RunWait` used for server management tasks (`taskkill`).
- `try...catch` blocks essential for robust HTTP handling.