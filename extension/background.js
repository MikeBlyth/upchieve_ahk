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
});

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