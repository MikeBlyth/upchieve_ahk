// Background script for UPchieve Student Detector Extension
// Manages extension icon state based on detector status

console.log('UPchieve Detector background script loaded');

// Listen for storage changes to update icon
chrome.storage.onChanged.addListener((changes, namespace) => {
    if (namespace === 'sync' && changes.detectorEnabled) {
        updateIcon(changes.detectorEnabled.newValue);
    }
});

// Listen for messages from popup and content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === 'updateIcon') {
        updateIcon(message.enabled);
        sendResponse({ status: 'success' });
    }
    else if (message.action === 'getWindowId') {
        // Get window ID from the sender tab
        if (sender.tab && sender.tab.windowId) {
            sendResponse({ windowId: sender.tab.windowId });
        } else {
            sendResponse({ windowId: null });
        }
    }
    else if (message.action === 'writeToFile') {
        // Handle file writing from content script
        handleFileWrite(message.data, sendResponse);
        return true; // Keep the message channel open for async response
    }
});

// Handle writing to the communication file
async function handleFileWrite(data, sendResponse) {
    console.log('🚀 Background: handleFileWrite called');
    console.log('📝 Background: Data received:', data);

    try {
        console.log('📁 Background: Starting file write process...');

        // Convert data to base64 data URL since URL.createObjectURL isn't available in service workers
        console.log('🔧 Background: Converting to base64...');
        const base64Data = btoa(unescape(encodeURIComponent(data)));
        const dataUrl = `data:text/plain;base64,${base64Data}`;
        console.log('✅ Background: Base64 conversion complete');

        // Use downloads API to save to a fixed location
        console.log('📥 Background: Calling chrome.downloads.download...');

        // Use a fixed filename that AHK can monitor
        // Since Chrome sometimes defaults to download.txt, let's try a different approach
        const downloadOptions = {
            url: dataUrl,
            filename: 'ext_to_ahk_communication_file.txt',
            conflictAction: 'overwrite',
            saveAs: false
        };
        console.log('⚙️ Background: Download options:', downloadOptions);

        const downloadId = await chrome.downloads.download(downloadOptions);

        console.log('✅ Background: Download initiated with ID:', downloadId);

        // Get download info to see where it was saved
        if (downloadId) {
            console.log('🔍 Background: Searching for download details...');

            // Wait a moment for download to process, then check details
            setTimeout(() => {
                chrome.downloads.search({ id: downloadId }, (downloads) => {
                    console.log('📊 Background: Download search results:', downloads);
                    if (downloads && downloads[0]) {
                        const download = downloads[0];
                        console.log('📁 Background: Filename:', download.filename);
                        console.log('📂 Background: Full path (if available):', download.filename);
                        console.log('📊 Background: State:', download.state);
                        console.log('💾 Background: Bytes received:', download.bytesReceived);
                        console.log('📍 Background: URL:', download.url);
                        console.log('🔍 Background: Full download object:', download);

                        // Also try to get the default download directory
                        chrome.downloads.search({ limit: 1, orderBy: ['-startTime'] }, (recentDownloads) => {
                            if (recentDownloads && recentDownloads[0]) {
                                console.log('📥 Background: Most recent download path example:', recentDownloads[0].filename);
                            }
                        });
                    } else {
                        console.log('⚠️ Background: No download details found');
                    }
                });
            }, 1000);
        } else {
            console.log('❌ Background: No download ID returned');
        }

        console.log('📤 Background: Sending success response...');
        sendResponse({
            success: true,
            message: 'Data written to ext_to_ahk_communication_file.txt in Downloads folder'
        });

    } catch (error) {
        console.error('❌ Background: Error in handleFileWrite:', error);
        console.log('❌ Background: Error details:', {
            name: error.name,
            message: error.message,
            stack: error.stack
        });

        sendResponse({
            success: false,
            error: 'Failed to write file: ' + error.message
        });
    }
}

// Update extension icon based on detector state
function updateIcon(enabled) {
    const iconData = enabled ? getGreenIconData() : getGrayIconData();

    chrome.action.setIcon({
        imageData: iconData
    });

    // Also update badge for extra visual feedback
    chrome.action.setBadgeText({
        text: enabled ? '●' : ''
    });

    chrome.action.setBadgeBackgroundColor({
        color: enabled ? '#28a745' : '#6c757d'
    });

    console.log(`Icon updated: ${enabled ? 'GREEN (active)' : 'GRAY (inactive)'}`);
}

// Generate green icon data (32x32 canvas)
function getGreenIconData() {
    const canvas = new OffscreenCanvas(32, 32);
    const ctx = canvas.getContext('2d');

    // Clear canvas
    ctx.clearRect(0, 0, 32, 32);

    // Draw green circular background
    ctx.fillStyle = '#28a745';
    ctx.beginPath();
    ctx.arc(16, 16, 14, 0, 2 * Math.PI);
    ctx.fill();

    // Draw white "U" letter
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 18px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('U', 16, 16);

    return ctx.getImageData(0, 0, 32, 32);
}

// Generate gray icon data (32x32 canvas)
function getGrayIconData() {
    const canvas = new OffscreenCanvas(32, 32);
    const ctx = canvas.getContext('2d');

    // Clear canvas
    ctx.clearRect(0, 0, 32, 32);

    // Draw gray circular background
    ctx.fillStyle = '#6c757d';
    ctx.beginPath();
    ctx.arc(16, 16, 14, 0, 2 * Math.PI);
    ctx.fill();

    // Draw white "U" letter
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 18px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('U', 16, 16);

    return ctx.getImageData(0, 0, 32, 32);
}

// Initialize icon state on startup
chrome.runtime.onInstalled.addListener(() => {
    chrome.storage.sync.get(['detectorEnabled'], (result) => {
        updateIcon(result.detectorEnabled || false);
    });
});

// Update icon when extension starts
chrome.storage.sync.get(['detectorEnabled'], (result) => {
    updateIcon(result.detectorEnabled || false);
});

// --- Keep-alive connection for content scripts ---
// This helps prevent content scripts from being put to sleep by the browser.
chrome.runtime.onConnect.addListener(port => {
    if (port.name === 'keep-alive') {
        console.log('✅ Keep-alive connection established from tab:', port.sender.tab.id);
        port.onDisconnect.addListener(() => {
            console.log('⚠️ Keep-alive port disconnected from tab:', port.sender.tab.id);
        });
        // We don't need to post messages, the connection itself is the goal.
    }
});