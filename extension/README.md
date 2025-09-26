# UPchieve Student Detector Browser Extension

A Chrome/Edge extension that automatically detects waiting students on UPchieve and copies their information to the clipboard for AutoHotkey integration.

## Features

- 🎯 **Automatic Detection**: Monitors DOM for new student entries
- 📋 **Clipboard Integration**: Copies student data in `Name|Topic` format
- 🔒 **Extension Permissions**: No clipboard focus issues like console scripts
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

1. **Navigate** to `https://app.upchieve.org/dashboard` (waiting students page)

2. **Click Extension Icon** to open popup

3. **Enable Detector** by clicking the green button

4. **Monitor Console** (F12) to see detection activity:
   ```
   🚨 New student detected via DOM monitoring
   ✅ Extension clipboard copy successful: StudentName|Topic
   ```

5. **AutoHotkey Integration**: The clipboard will contain data like:
   ```
   Sarah Johnson|8th Grade Math
   ```

## Files Structure

```
extension/
├── manifest.json          # Extension configuration
├── content.js            # Main detection logic
├── popup.html            # Extension popup interface
├── popup.js              # Popup functionality
├── README.md             # This file
└── icon16.png            # Extension icons (create these)
└── icon48.png
└── icon128.png
```

## Testing

- **Test Detection**: Click "Test Detection" button in popup
- **Console Commands**: Available on UPchieve pages:
  - `testExtensionDetection()` - Manual test
  - `setExtensionDebugLevel(2)` - Verbose logging

## Permissions Explained

- **activeTab**: Access current UPchieve tab
- **clipboardWrite**: Write to clipboard (no focus issues!)
- **storage**: Remember enabled/disabled state
- **host_permissions**: Only runs on `app.upchieve.org`

## Advantages Over Console Scripts

✅ **No Developer Mode** required for daily use
✅ **Persistent** across page reloads
✅ **Better clipboard permissions** - no focus issues
✅ **User-friendly toggle** via extension popup
✅ **Secure** - declared permissions and sandboxed execution

## AutoHotkey Integration

The extension copies data to clipboard in this exact format:
```
StudentName|HelpTopic
```

Your AutoHotkey script can detect clipboard changes and parse this data:
```autohotkey
; Example AHK clipboard monitoring
OnClipboardChange("ClipboardChanged")

ClipboardChanged() {
    if (InStr(A_Clipboard, "|")) {
        StudentData := StrSplit(A_Clipboard, "|")
        StudentName := StudentData[1]
        HelpTopic := StudentData[2]
        ; Process the student data...
    }
}
```

## Troubleshooting

- **"Extension not loaded"**: Make sure you're on `app.upchieve.org`
- **No clipboard data**: Check console for error messages
- **Not detecting students**: Ensure detector is enabled (green status)
- **Permission errors**: Try disabling and re-enabling the extension

## Development

To modify the extension:
1. Edit the source files
2. Go to `chrome://extensions/`
3. Click the refresh icon on the extension
4. Test changes on UPchieve page