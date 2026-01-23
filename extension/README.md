# UPchieve Student Detector Browser Extension

A Chrome/Edge extension that automatically detects waiting students on UPchieve and sends their information to a local Ruby server for AutoHotkey integration.

## Features

- 🎯 **Automatic Detection**: Monitors DOM for new student entries using `MutationObserver`
- 📡 **Local Server Integration**: Sends data to `http://127.0.0.1:54567/students` (JSON format)
- 🔒 **Secure**: Only communicates with localhost
- 🎛️ **Toggle Control**: Enable/disable via extension popup
- 🧪 **Testing**: Built-in test function to verify functionality
- 💾 **State Persistence**: Remembers enabled/disabled state

## Installation

1. **Open Chrome/Edge Extensions page**:
   - Chrome: `chrome://extensions/`
   - Edge: `edge://extensions/`

2. **Enable Developer Mode** (toggle in top-right corner)

3. **Load Extension**:
   - Click "Load unpacked"
   - Select the `extension` folder containing these files

4. **Pin Extension** (optional):
   - Click the extensions puzzle icon
   - Pin "UPchieve Student Detector"

## Usage

1. **Start the Local Server**: Run `upchieve_integrated_detector.ahk` (it will auto-start the server).

2. **Navigate** to `https://app.upchieve.org/dashboard` (waiting students page)

3. **Click Extension Icon** to open popup

4. **Enable Detector** by clicking the green button

5. **Monitor Console** (F12) to see activity:
   ```
   🚨 New student detected via DOM monitoring
   📤 Sending data to Ruby server: 1 students
   ✅ Successfully sent data to Ruby server
   ```

## Files Structure

```
extension/
├── manifest.json          # Extension configuration
├── content.js            # Main detection logic
├── popup.html            # Extension popup interface
├── popup.js              # Popup functionality
├── README.md             # This file
└── icon16.png...         # Icons
```

## Testing

- **Test Detection**: Click "Test Detection" button in popup
- **Console Commands**: Available on UPchieve pages:
  - `injectTestStudent()` - Injects a fake student row to test detection
  - `testExtensionDetection()` - Manual test

## Permissions Explained

- **activeTab**: Access current UPchieve tab
- **host_permissions**: `http://127.0.0.1:54567/*` (Local Server)
- **storage**: Remember enabled/disabled state

## AutoHotkey Integration

The extension sends JSON data to the local Ruby server.
Your AutoHotkey script (`upchieve_integrated_detector.ahk`) polls the server (`GET /ahk_data`) to receive this data in an optimized format:
```
*upchieve|StudentName|HelpTopic|WaitMinutes
```

## Troubleshooting

- **"Failed to connect to Ruby server"**: Ensure `upchieve_integrated_detector.ahk` is running (it starts the server).
- **Extension not loaded**: Make sure you're on `app.upchieve.org`.
- **Not detecting students**: Ensure detector is enabled (green status).
- **Server logs**: Check `server.err` in the project root if connection issues persist.

## Development

To modify the extension:
1. Edit the source files
2. Go to `chrome://extensions/`
3. Click the refresh icon on the extension
4. Reload the UPchieve page