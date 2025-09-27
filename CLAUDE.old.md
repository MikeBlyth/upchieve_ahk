# Upchieve Waiting Student Detector

This system provides automated student detection for UPchieve using both a browser extension and AutoHotkey script, with personalized student name extraction and session management.

## System Components

### Browser Extension (New - 2025)
- `extension/manifest.json` - Chrome extension manifest (Manifest v3)
- `extension/content.js` - DOM monitoring and student data extraction
- `extension/background.js` - Icon management and extension state handling
- `extension/popup.html` - Extension popup interface
- `extension/popup.js` - Popup functionality and detector controls
- `extension/README.md` - Extension installation and usage guide

### AutoHotkey Detection System (Legacy)
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

## Browser Extension Features (Recommended)

### Core Functionality
- **DOM Monitoring** - Real-time detection of new student rows via MutationObserver
- **Accurate Data Extraction** - Direct DOM access eliminates OCR recognition errors
- **Clipboard Integration** - Copies student data in AHK-friendly format: `*upchieve|name|topic|minutes`
- **Visual Status Indicator** - Green icon when active, gray when inactive
- **Native Notifications** - Browser notifications with auto-dismiss
- **Debounced Detection** - Prevents duplicate triggers within 1-second window

### Data Format
- **Structured Output**: `*upchieve|StudentName|HelpTopic|WaitMinutes`
- **Wait Time Parsing**: "< 1" becomes `0`, "3 min" becomes `3`
- **Easy AHK Integration**: Simple pipe-delimited format for AutoHotkey parsing

### Installation & Usage
1. **Load Extension**:
   - Open Chrome → Extensions → Developer Mode → Load Unpacked
   - Select the `extension/` folder
   - Extension icon appears in toolbar

2. **Activate Detection**:
   - Navigate to `https://app.upchieve.org/`
   - Click extension icon (shows current status)
   - Click "Enable Detector" button
   - Icon turns green when active

3. **Monitor Operation**:
   - Extension automatically detects new student arrivals
   - Shows brief notification with student info
   - Copies data to clipboard for potential AHK integration
   - Console shows detailed debug information

### Browser Extension Advantages
- **100% Accuracy**: Direct DOM access vs OCR pattern matching
- **Real-Time Detection**: Instant response vs periodic image scanning
- **Platform Independent**: Works on any browser/OS vs Windows-only AHK
- **No Pattern Maintenance**: No need to maintain FindText character patterns
- **Network Efficient**: Single DOM event vs continuous screen capture

## AutoHotkey Features (Legacy System)

### OCR-Based Detection
- Uses FindTextv2 library for fast image recognition with continuous wait functionality
- **Mandatory header detection** - App requires all 3 column headers before starting
- **SearchZone architecture** - Precise header-based positioning for all operations
- **FindText wait monitoring** - 60-second continuous search instead of polling
- Real-time monitoring for "< 1 minute" waiting indicators
- **Student name extraction** from detected waiting entries
- **Personalized notifications** (e.g. "Session with Camila has opened!")

### Session Management
- **Student blocking system** - Skip action for names listed in block_names.txt
- Auto-click functionality when waiting students are detected
- LIVE/TESTING mode selection with pause/resume capability
- **Sleep prevention** - Keeps laptop awake while monitoring for students
- **Session feedback system** - CSV logging with comprehensive session data
- **Enhanced end-session dialog** - Captures detailed session information for analysis

## System Integration Status

⚠️ **Current Status**: The browser extension and AutoHotkey system are **NOT YET INTEGRATED**. They operate as separate, independent detection systems.

### Browser Extension (Standalone)
- ✅ **Fully Functional**: Detects students and copies data to clipboard
- ✅ **AHK-Ready Format**: Uses `*upchieve|name|topic|minutes` format
- ❌ **No AHK Integration**: Does not automatically trigger AutoHotkey actions
- ❌ **No Session Management**: No clicking or session state tracking

### Future Integration Plans
- **Clipboard Polling**: AutoHotkey could monitor clipboard for `*upchieve` prefix
- **File Communication**: Extension could write to shared file for AHK monitoring
- **Hybrid Workflow**: Extension for detection, AHK for clicking and session management

## AutoHotkey Usage (Legacy System)
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
1. **Student detected and clicked** → Immediately changes to IN_SESSION state (no verification)
2. **While IN_SESSION**: Only monitors for "Waiting Students" page to detect session end
3. **Session ends** (PageTarget appears) → Shows comprehensive feedback dialog with:
   - Student name and subject (editable, pre-filled from OCR)
   - Grade, topic, and session characteristics
   - Session timing and progress metrics
   - Comments field for additional notes
   - Continue/Exit/Pause options
4. **Manual control**: Ctrl+Shift+A hotkey to manually end session and show feedback dialog

## How It Works
1. **Window Selection**: User clicks on UPchieve browser window to bind FindText operations
2. **Mandatory Header Detection**: Locates ALL 3 column headers (Student, Subject, Wait Time) with retry dialog
   - App will not proceed until all headers are found
   - Shows user-friendly dialog with reload option if headers missing
3. **SearchZone Architecture**: Creates precise search zones based on header positions
   - Student names: Header position + offset for exact column positioning
   - Subject detection: Header-based zones with pattern matching
   - WaitingTarget: Header-based zones for "< 1 minute" indicators
4. **Continuous Monitoring**: Uses FindText wait functionality for 60-second continuous search
   - No CPU-intensive polling - FindText handles waiting internally
   - Checks for upgrade popups after wait cycles
5. **Student Detection**: When WaitingTarget ("< 1 minute") appears:
   - **Fast pattern matching** for subject detection (no OCR)
   - **Visual blocking check** against `block_names.txt` patterns
   - **Click student** with window activation in LIVE mode
   - **Session state change** to IN_SESSION immediately after click
   - Shows subject-based notification (name entry handled manually at session end)

## SearchZone Architecture

### Core Components
- **SearchZone Class**: Simple object with x1, y1, x2, y2 properties and ToString() method for debugging
- **FindTextInZones Wrapper**: Unified function for searching with primary + optional secondary zones
- **Header-Based Positioning**: All search operations use precise column header coordinates
- **Mandatory Header Detection**: App requires all 3 headers before any operations begin

### Header Detection System
- **Student Header** (`StudentHeaderTarget`): "Student" column header (71×25 pixels)
- **Subject Header** (`HelpHeaderTarget`): "Help Topic" column header (71×25 pixels)
- **Wait Time Header** (`WaitTimeHeaderTarget`): "Wait Time" column header (97×25 pixels)

### Search Zone Positioning
- **Student Name Region**: StudentHeader position + 95px down, 200×35 pixels
- **Subject Detection**: SubjectHeader position + 95px down, 150×30 pixels (primary) + secondary zone
- **WaitingTarget Search**: WaitTimeHeader position + 97px down, 55×35 pixels
- **Blocking Check**: StudentHeader position + 95px down, 200×35 pixels (same as name region)

### Benefits
- **Eliminates fallback positioning** - all operations use precise header-based coordinates
- **Consistent accuracy** - no more dual code paths with different reliability levels
- **Performance optimization** - precise zones reduce search areas and improve speed
- **Window independence** - works regardless of browser window size or position

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
- **Auto-checked Math Subject**: Automatically checks if subject contains "math" or is "pre-algebra", "algebra", or "statistics"
- **Behavioral checkboxes**: Initial response, serious question, left abruptly, stopped responding
- **Progress rating**: Float value 0-1 (defaults to 1.0)
- **Timing**: Last message time, auto-calculated duration
- **Comments**: Free-text notes
- **Actions**: Continue monitoring (restart script), exit, pause, or **skip** (restart script)
- **Skip Button**: Saves name/subject corrections but does NOT log session to CSV
- **Script Restart**: Yes and Skip buttons automatically restart the script for reliable detection
- **Learning System**: Manual corrections to names/subjects are automatically saved to `student_corrections.txt`

Session data is saved to CSV format (except when skipped) with line-break protection for clean spreadsheet import.

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

### Current Window-Relative System

**PageTarget Detection**:
- **Search Zone**: 850,300 to 1400,1100 (window coordinates)
- **Verification**: Every 30 seconds with movement threshold >10 pixels
- **Position Logging**: Comprehensive tracking of PageTarget location changes

**Header Detection** (fluid container responsive):
- **Search Zone**: 700-1600px width, PageTarget+175 to PageTarget+225px height
- **Student Header** (`StudentHeaderTarget`): "Student" column header
- **Help Header** (`HelpHeaderTarget`): "Help Topic" column header  
- **Wait Time Header** (`WaitTimeHeaderTarget`): "Wait Time" column header

**OCR Zones** (positioned below headers when found):
- **Student Name Region**: Header position + 96px down, 250×90 pixels
- **Help Topic Region**: Header position + 96px down, 250×90 pixels
- **Wait Time Search**: Header position + 96px down for WaitingTarget detection

**Fallback OCR Zones** (when headers not found, PageTarget-relative):
- **Student Names**: Left edge to 930px, PageTarget+300-400px down
- **Subjects**: 940-1260px, PageTarget+300-400px down
- **Wait Time**: Uses original WaitingTarget positioning fallback

### Original Absolute Coordinates (3200×2000 screen reference)
- PageTarget: (891, 889) to (1446, 1149)
- WaitingTarget: (1273, 1188) to (1607, 1423)
- UpgradeTarget: (1593, 1009) to (1918, 1309)

## Dependencies
- AutoHotkey v2.0+
- FindTextv2.ahk (included)
- alphabet.ahk (dual character arrays: `name_characters` + `number_characters`)

## Recent Improvements

### Major Architecture Overhaul (Latest)
- **Mandatory Header Detection**: App now requires all 3 column headers before starting operations
  - Shows user-friendly retry dialog when headers missing
  - Eliminates all fallback positioning code paths
  - Guarantees consistent, accurate positioning for all operations
- **FindText Wait Integration**: Replaced 50ms polling loop with 60-second continuous wait
  - Dramatically reduced CPU usage - no more polling overhead
  - Uses FindText's optimized built-in wait functionality
  - Checks upgrade popups only after wait cycles complete
- **SearchZone Architecture**: Complete rewrite of positioning system
  - All operations use precise header-based coordinates
  - Eliminated dual code paths and fallback logic
  - Consistent performance and accuracy across all functions
- **Code Simplification**: Removed hundreds of lines of fallback/validation code
  - Single source of truth for all positioning
  - Much cleaner, more maintainable codebase

### Previous Improvements
- **Window Coordinate System**: Implemented window-relative coordinates with BindWindow for position independence
- **Direct Subject Recognition**: Replaced OCR-based subject detection with instant pattern matching using `SubjectTargets`
- **Context-Aware Character Filtering**: Student names exclude digits, subjects include grade-level numbers (6,7,8)
- **Manual Session Control**: Added Ctrl+Shift+A hotkey for manual session ending
- **Session Flow**: Enhanced session end detection with 2-second intervals and proper tolerances
- **Learning System Integration**: Session feedback dialog automatically saves manual corrections to database
- **Performance Optimization**: Subject detection ~4x faster (pattern matching vs character OCR)
- **Modular Architecture**: Separated OCR functions into shared library (`ocr_functions.ahk`)
- **Student Database Integration**: Fuzzy matching with edit distance algorithm and interactive correction
- **OCR Testing Tool**: Built standalone application for rapid pattern development and parameter tuning
- **Multiple Character Patterns**: Support for multiple patterns per character (especially 'y', 't', 'd')
- **Dynamic Reloading**: Character patterns can be updated and reloaded without application restart


## Performance Considerations
- **Header detection**: Required once at startup, uses SearchZone architecture for efficiency
- **WaitingTarget monitoring**: 60-second continuous wait using FindText built-in functionality
  - **No polling overhead**: Eliminates 50ms polling loop - CPU usage dramatically reduced
  - **Optimized waiting**: FindText handles continuous monitoring internally
- **Subject detection**: ~25ms (direct pattern matching vs ~100ms+ OCR)
- **Blocking check**: ~25ms with header-based positioning (no fallback needed)
- **Session end detection**: Every 2 seconds during IN_SESSION state (0.15, 0.10 tolerances)
- **Click response**: Immediate click using coordinates from FindText wait
- **Maintenance tasks**: Performed in main loop after 60-second wait timeouts

## JavaScript Network Integration Reference

### UPchieve Page Structure
**Student List HTML Structure:**
```html
<div class="session-list" style="width: 100%;">
  <table class="table table-striped table-hover">
    <thead>
      <tr>
        <th scope="col">Student</th>
        <th scope="col">Help Topic</th>
        <th scope="col">Wait Time</th>
      </tr>
    </thead>
    <tbody>
      <tr id="[uuid]" data-testid="session-row-[StudentName]" class="session-row">
        <td>StudentName</td>
        <td>Subject (e.g., "8th Grade Math")</td>
        <td>&lt; 1 min</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Network Activity Patterns
- **No WebSockets**: UPchieve uses HTTP polling/long-polling only (status codes: 200, 201, 204)
- **Student Alert Detection**:
  - **URL Pattern**: `https://app.upchieve.org/assets/alert-*.mp3` (hash is random/changing)
  - **Resource Type**: `media`
  - **Method**: `GET`
  - **Detection**: `args[0].includes('app.upchieve.org/assets/alert-') && args[0].endsWith('.mp3')`
- **Data Location**: Student names/subjects likely in JSON response bodies of fetch/xhr requests
- **Real-time Updates**: HTTP polling rather than WebSocket or Server-Sent Events

### JavaScript Detection Strategy
1. **Monitor audio alert**: `alert-*.mp3` requests indicate new student arrival
2. **Extract from DOM**: Use `document.querySelectorAll('.session-row')` after alert
3. **Communication with AutoHotkey**: Via clipboard (navigator.clipboard.writeText)
4. **Data Structure**:
   ```javascript
   {
     name: "StudentName",        // From first <td>
     subject: "8th Grade Math",  // From second <td>
     timestamp: Date.now(),
     testId: "session-row-StudentName"  // From data-testid attribute
   }
   ```

### Hybrid Implementation Benefits
- **JavaScript**: Reliable student detection via network/DOM monitoring
- **AutoHotkey**: UI automation (clicking, window management, session dialogs)
- **Communication**: Clipboard-based data transfer between JavaScript and AutoHotkey

## Browser Extension Implementation (2025)

### Chrome Extension Architecture
A complete Chrome extension has been developed to replace both the manual JavaScript console approach and FindText OCR detection, providing the most reliable and user-friendly solution.

### Extension Components
- **`extension/manifest.json`**: Chrome Extension Manifest v3 configuration
- **`extension/content.js`**: DOM monitoring and student data extraction (auto-injected)
- **`extension/background.js`**: Service worker for icon management and state persistence
- **`extension/popup.html`**: User interface for extension controls
- **`extension/popup.js`**: Popup functionality and detector toggle controls

### Installation Process

#### Step 1: Enable Developer Mode
1. Open Chrome and navigate to `chrome://extensions/`
2. Toggle "Developer mode" ON (top right corner)
3. You'll see new buttons: "Load unpacked", "Pack extension", "Update"

#### Step 2: Load Extension
1. Click "Load unpacked" button
2. Navigate to your project folder and select the `extension/` directory
3. Extension should appear in the list with:
   - **Name**: "UPchieve Student Detector"
   - **ID**: Chrome-generated unique identifier
   - **Version**: 1.0

#### Step 3: Pin Extension (Optional)
1. Click the puzzle piece icon in Chrome toolbar (Extensions menu)
2. Find "UPchieve Student Detector" and click the pin icon
3. Extension icon will appear directly in the toolbar for easy access

#### Step 4: Grant Permissions
- Extension automatically requests minimal permissions:
  - `activeTab`: Access to current UPchieve tab only
  - `clipboardWrite`: Copy student data to clipboard
  - `storage`: Save detector enable/disable state

### Legacy Implementation Files (Deprecated)
- **`upchieve_js_detector.js`**: Manual console loading script (replaced by extension)
- **`upchieve_tampermonkey.js`**: Userscript version (replaced by extension)

### Extension Core Features

**DOM-Based Detection:**
- **MutationObserver Monitoring**: Real-time detection when new student rows are added to DOM
- **Direct Element Access**: Extracts data directly from `.session-row` table elements
- **Debounced Processing**: 1-second debounce prevents duplicate triggers from rapid DOM changes
- **Automatic Activation**: Starts monitoring immediately when enabled on UPchieve pages

**Data Extraction & Processing:**
- **Multi-Column Parsing**: Extracts student name, help topic, and wait time from table columns
- **Wait Time Conversion**: Converts "< 1" to `0`, "3 min" to `3` for AHK parsing
- **Structured Output Format**: `*upchieve|StudentName|HelpTopic|WaitMinutes`
- **Fallback Selectors**: Multiple selector strategies for robust element detection

**User Interface:**
- **Dynamic Icon States**: Green icon when active, gray when inactive
- **Badge Indicators**: Visual dot indicator for active status
- **Popup Controls**: Enable/disable toggle with current status display
- **Visual Notifications**: Non-blocking overlay notifications with student information

**Clipboard & Communication:**
- **Reliable Clipboard Copy**: Uses execCommand for maximum compatibility
- **AHK-Ready Format**: Pipe-delimited format optimized for AutoHotkey parsing
- **State Persistence**: Remembers enabled/disabled state across browser sessions
- **Debug Console Logging**: Comprehensive logging for troubleshooting

**Extension Management:**
- **Storage Synchronization**: Settings sync across Chrome profile
- **Background Service Worker**: Manages icon state and cross-tab communication
- **Permission Minimal**: Only requests necessary permissions (activeTab, clipboardWrite, storage)
- **Auto-Injection**: Content script automatically loads on UPchieve pages

### Extension Detection Flow
1. **DOM Change Detection**: MutationObserver detects new `.session-row` elements added to DOM
2. **Debounced Processing**: 1-second delay prevents multiple rapid triggers
3. **Data Extraction**: Directly reads student name, help topic, and wait time from table cells
4. **Format Processing**: Converts wait time to integer minutes (`< 1` → `0`, `3 min` → `3`)
5. **Clipboard Copy**: Copies structured data as `*upchieve|name|topic|minutes`
6. **User Notification**: Shows brief overlay notification with student information
7. **Debug Logging**: Records detection event and extracted data to browser console

### Extension Usage & Testing

**Normal Operation:**
1. Load extension via Chrome Developer Mode
2. Navigate to `https://app.upchieve.org/`
3. Click extension icon and enable detector (icon turns green)
4. Extension automatically detects new students and copies data to clipboard

**Testing & Debug Commands:**
Open browser console (`F12` → Console) and use these commands:
```javascript
testExtensionDetection()    // Manual test of current page data
setExtensionDebugLevel(2)   // Enable verbose logging (0=off, 1=basic, 2=verbose)
```

**Console Output Example:**
```
🚀 UPchieve Student Detector Extension loaded
📊 Detector status: ENABLED
🚨 New student detected via DOM monitoring
✅ Found 1 session row(s)
📋 Clipboard format: *upchieve|John Smith|8th Grade Math|0
```

### Advantages Over OCR Approach
- **100% Accuracy**: Direct DOM access eliminates OCR recognition errors
- **Real-Time Detection**: Instant audio alert detection vs periodic image scanning
- **No Pattern Maintenance**: No need to maintain FindText character patterns
- **Platform Independent**: Works on any browser/OS vs Windows-only AutoHotkey
- **Network Efficiency**: Single audio request detection vs continuous screen capture
- **Reliability**: Immune to font changes, UI updates, or display scaling issues

### Performance Characteristics
- **Alert Detection**: ~1-2ms (audio event monitoring)
- **DOM Extraction**: ~5-10ms (direct DOM queries)
- **Total Response Time**: ~15ms vs ~50-200ms for OCR approach
- **CPU Usage**: Minimal event-driven vs continuous image processing
- **Memory Usage**: ~1MB JavaScript vs ~10-20MB FindText operations

### Browser Compatibility
- **Modern Browsers**: Chrome, Firefox, Edge, Safari (all versions supporting ES6+)
- **Clipboard API**: Modern clipboard API with execCommand fallback
- **Permissions**: Notification permission requested automatically
- **Cross-Origin**: Works within UPchieve domain security context

### Integration Notes
- **Hybrid Usage**: Can run alongside AutoHotkey for UI automation
- **Data Format**: Clipboard data formatted as `name|topic` for AutoHotkey parsing
- **State Management**: Independent state management with enable/disable controls
- **Error Handling**: Comprehensive error handling with fallback mechanisms

### Future Enhancements
- **Network Polling**: Could monitor gzipped polling requests for additional student data
- **Session Tracking**: Could track session state changes via DOM mutations
- **Advanced Parsing**: Could extract additional metadata (grade level, session duration)
- **Local Storage**: Could maintain student history and preferences

## Troubleshooting
- **Missing column headers**: App will show dialog if headers not found - adjust browser window size/position and click Reload
- **No WaitingTarget found**: Ensure all 3 column headers are visible and properly detected at startup
- **Subject detection issues**: Verify SubjectTargets patterns match current UPchieve subject display
- **Performance problems**: Monitor `debug_log.txt` for timing patterns - should show 60-second wait cycles
- **Window scaling issues**: Ensure browser zoom is at 100% for optimal pattern matching
- **Blocking not working**: Check that `block_names.txt` exists and blocked patterns are current

## Known Issues
- **BindWindow coordinate system**: BindWindow mode 4 may not properly convert coordinates to window-relative (requires maximized window for reliability)
- **FindText OCR accuracy**: Character-by-character pattern matching struggles with antialiasing, font variations, and complex text rendering
- **Speed vs accuracy tradeoff**: Better OCR solutions (Tesseract, Windows OCR) are too slow for competitive student claiming (200-400ms delay)
- **No click verification**: Click verification was removed to prevent false negatives - session detection relies on session end monitoring
- JoinText method requires further refinement for optimal results
- Some characters (especially 'y') require multiple patterns due to descender positioning
- Window occlusion/shading significantly impacts FindText performance (3-5 seconds vs 170-200ms)
- Character prioritization may need adjustment for specific font variations or new text rendering

## OCR Investigation and Alternatives

### Windows OCR API Investigation (2024)
An attempt was made to integrate Windows 10/11 built-in OCR API to improve student name extraction accuracy beyond FindText's character-by-character pattern matching.

**Investigation Results:**
- **Windows OCR not available**: Testing revealed that Windows OCR API is not available on the target system
- **PowerShell integration challenges**: Multiple approaches tried (multi-line strings, COM objects, file-based) all failed due to missing Windows Runtime components
- **Speed requirements**: Even if available, Windows OCR (100-300ms) and Tesseract OCR (200-400ms) are too slow for competitive student claiming

**Critical Timing Constraints:**
- **Competitive environment**: Multiple tutors race to claim students when "< 1 minute" appears
- **Blocking requirement**: Must extract student name BEFORE clicking to check against `block_names.txt`
- **No parallel processing**: Cannot click first and extract name later due to blocking checks
- **FindText speed**: ~25-50ms for name extraction (acceptable for competitive clicking)

**Alternative Solutions Evaluated:**
1. **Tesseract OCR**: High accuracy but 200-400ms too slow for competitive claiming
2. **Online OCR APIs**: Excellent accuracy but network latency unacceptable
3. **COM-based Windows OCR**: Not available on target system
4. **PowerShell Windows OCR**: Runtime components missing

**Current Approach:**
Continue with FindText character-by-character pattern matching despite accuracy limitations, focusing on:
- **Pattern optimization**: Expanding `alphabet.ahk` character patterns for better recognition
- **Tolerance tuning**: Using `ocr_tester.ahk` to optimize detection parameters
- **Prioritization rules**: Improving character conflict resolution in `ocr_functions.ahk`
- **Multiple pattern support**: Adding font variations for problematic characters

**Future Considerations:**
- **System upgrade**: If Windows OCR becomes available, could implement hybrid approach (fast detection + accurate fallback)
- **Preprocessing**: Could add image enhancement (contrast, sharpening) to improve FindText accuracy
- **ML training**: Could train custom character recognition models optimized for Upchieve's specific fonts

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

From documentation:
```
;--------------------------------
;  FindText - Capture screen image into text and then find it
;  Version : 10.0  (2024-10-06)
;--------------------------------
;  returnArray:=FindText(
;      &OutputX --> The name of the variable used to store the returned X coordinate
;    , &OutputY --> The name of the variable used to store the returned Y coordinate
;    , X1 --> the search scope's upper left corner X coordinates
;    , Y1 --> the search scope's upper left corner Y coordinates
;    , X2 --> the search scope's lower right corner X coordinates
;    , Y2 --> the search scope's lower right corner Y coordinates
;    , err1 --> Fault tolerance percentage of text       (0.1=10%)
;    , err0 --> Fault tolerance percentage of background (0.1=10%)
;      Setting err1<0 or err0<0 can enable the left and right dilation algorithm
;      to ignore slight misalignment of text lines, the fault tolerance must be very small
;      In FindPic mode, err0 can set the number of rows and columns to be skipped
;    , Text --> can be a lot of text parsed into images, separated by '|'
;    , ScreenShot --> if the value is 0, the last screenshot will be used
;    , FindAll --> if the value is 0, Just find one result and return
;    , JoinText --> if you want to combine find, it can be 1, or an array of words to find
;    , offsetX --> Set the max text offset (X) for combination lookup
;    , offsetY --> Set the max text offset (Y) for combination lookup
;    , dir --> Nine directions for searching: up, down, left, right and center
;      Default dir=0, the returned result will be sorted by the smallest error,
;      Even if set a large fault tolerance, the first result still has the smallest error
;    , zoomW --> Zoom percentage of image width  (1.0=100%)
;    , zoomH --> Zoom percentage of image height (1.0=100%)
;  )
;
;  The function returns an Array containing all lookup results,
;  any result is a object with the following values:
;  {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}
;  If no image is found, the function returns 0.
;  All coordinates are relative to Screen, colors are in RGB format
;  All 'RRGGBB' can use 'Black', 'White', 'Red', 'Green', 'Blue', 'Yellow'
;  All 'DRDGDB' can use similarity '1.0'(100%), it's floating-point number
;
;  If the return variable is set to 'ok', ok[1] is the first result found.
;  ok[1].1, ok[1].2 is the X, Y coordinate of the upper left corner of the found image,
;  ok[1].3, ok[1].4 is the width, height of the found image,
;  ok[1].x <==> ok[1].1+ok[1].3//2 ( is the Center X coordinate of the found image ),
;  ok[1].y <==> ok[1].2+ok[1].4//2 ( is the Center Y coordinate of the found image ),
;  ok[1].id is the comment text, which is included in the <> of its parameter.
;
;  If OutputX is equal to 'wait' or 'wait1'(appear), or 'wait0'(disappear)
;  it means using a loop to wait for the image to appear or disappear.
;  the OutputY is the wait time in seconds, time less than 0 means infinite waiting
;  Timeout means failure, return 0, and return other values means success
;  If you want to appear and the image is found, return the found array object
;  If you want to disappear and the image cannot be found, return 1
;  Example 1: FindText(&X:='wait', &Y:=3, 0,0,0,0,0,0,Text)   ; Wait 3 seconds for appear
;  Example 2: FindText(&X:='wait0', &Y:=-1, 0,0,0,0,0,0,Text) ; Wait indefinitely for disappear
;
;  <FindMultiColor> or <FindColor> : FindColor is FindMultiColor with only one point
;  Text:='|<>##DRDGDB $ 0/0/RRGGBB1-DRDGDB1/RRGGBB2, xn/yn/-RRGGBB3/RRGGBB4, ...'
;  Color behind '##' (0xDRDGDB) is the default allowed variation for all colors
;  Initial point (0,0) match 0xRRGGBB1(+/-0xDRDGDB1) or 0xRRGGBB2(+/-0xDRDGDB),
;  point (xn,yn) match not 0xRRGGBB3(+/-0xDRDGDB) and not 0xRRGGBB4(+/-0xDRDGDB)
;  Starting with '-' after a point coordinate means excluding all subsequent colors
;  Each point can take up to 10 sets of colors (xn/yn/RRGGBB1/.../RRGGBB10)
;
;  <FindShape> : Similar to FindMultiColor, just replacing the color with
;  whether the point is similar in color to the first point
;  Text:='|<>##DRDGDB $ 0/0/1, x1/y1/0, x2/y2/1, xn/yn/0, ...'
;
;  <FindPic> : Text parameter require manual input
;  Text:='|<>##DRDGDB/RRGGBB1-DRDGDB1/RRGGBB2... $ d:\a.bmp'
;  Color behind '##' (0xDRDGDB) is the default allowed variation for all colors
;  the 0xRRGGBB1(+/-0xDRDGDB1) and 0xRRGGBB2(+/-0xDRDGDB) both transparent colors
;
;--------------------------------
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
- FindText saves its editor content between sessions in:

  A_Temp "\~scr2.tmp"

  This is typically located at:
  C:\Users\[Username]\AppData\Local\Temp\~scr2.tmp
## FindText Wait Functionality

This application leverages FindText's built-in wait capability for efficient continuous monitoring, replacing traditional polling loops.

### Wait Syntax
```autohotkey
; Wait for target to appear (60-second timeout)
result := FindText(&waitingX:='wait', &waitingY:=60, x1, y1, x2, y2, 0.15, 0.05, WaitingTarget)

; Wait indefinitely for target to appear
result := FindText(&waitingX:='wait', &waitingY:=-1, x1, y1, x2, y2, 0.15, 0.05, WaitingTarget)

; Wait for target to disappear
result := FindText(&waitingX:='wait0', &waitingY:=10, x1, y1, x2, y2, 0.15, 0.05, SomeTarget)
```

### Return Values
- **Target Found**: Returns array object with match details (same as normal FindText results)
- **Timeout**: Returns 0 when wait time expires without finding target
- **Disappear Success**: Returns 1 when waiting for disappearance and target not found

### Application Usage
The script uses 60-second continuous wait cycles for optimal performance:

```autohotkey
; Primary monitoring loop
result := FindText(&waitingX:='wait', &waitingY:=60,
    waitingZone.x1, waitingZone.y1, waitingZone.x2, waitingZone.y2,
    0.15, 0.05, WaitingTarget)

if (result) {
    ; Student detected - process immediately
    ProcessStudent(result)
} else {
    ; 60-second timeout - execution falls through to main loop for maintenance tasks
    ; No explicit timeout handling needed - natural code flow handles maintenance
}
```

### Benefits Over Polling
- **CPU Efficiency**: Native C++ wait loop vs AutoHotkey Sleep() cycles
- **Instant Response**: No polling delays - triggers immediately when pattern appears
- **Configurable Timeout**: Allows periodic maintenance tasks via natural main loop flow
- **Zero False Negatives**: Continuous monitoring eliminates gaps between polling intervals
- **Resource Conservation**: Single FindText operation vs multiple rapid searches

### Integration Notes
- **Natural Timeout Flow**: 60-second timeouts naturally continue to main loop for maintenance tasks
- **State Management**: Wait operations only run during WAITING_FOR_STUDENT state
- **Upgrade Handling**: Timeout cycles provide opportunity to dismiss upgrade popups via main loop
- **Performance**: Replaces 50ms polling loop that consumed significant CPU resources

## AutoHotkey v2 Syntax Reminders

Common syntax errors to avoid when coding in AutoHotkey v2:

### Functions and Control Flow
- **No Range function**: Use `while` loops instead of `for i in Range(start, end, step)`
- **Single-line if statements**: Must be on separate lines from action
  ```autohotkey
  ; WRONG:
  if (condition) return value

  ; CORRECT:
  if (condition)
      return value
  ```
- **Loop variable names**: Avoid reserved words like `student` in `for i, student in array`
  ```autohotkey
  ; WRONG:
  for i, student in students

  ; CORRECT:
  for i, studentObj in students
  ```

### Data Types and Operations
- **No sort function**: Use loops or alternative sorting methods
- **String functions**: Use `InStr()`, `SubStr()`, `StrReplace()` instead of v1 equivalents
- **Array access**: Use `array[index]` not `array.%index%`

### Variable Declarations
- **Reserved words**: Cannot use `return`, `if`, `for`, etc. as variable names
- **Global declarations**: Use `global varName := value` syntax

### File Operations
- **FileDelete safety**: Always check `FileExist()` before `FileDelete()` to avoid system errors

### Function Parameters
- **Parameter skipping**: Empty parameters with commas `FindText(, , x1, y1, ...)` IS valid in AutoHotkey v2
- **Variable references**: Use `&varName` for output parameters in function calls
- **Function warnings**: Some functions may show warnings about unassigned variables even when syntax is correct
- **Event handlers**: Use separate functions instead of inline lambdas: `OnEvent("Click", HandlerFunc)` not `OnEvent("Click", (*) => {...})`

### Include Dependencies
- **Missing includes**: Functions like `FindText` require `#Include FindTextv2.ahk` at the top of each file that uses them
- **Include order**: Include dependencies before using any functions from those files