// Function to update the icon badge
const updateIcon = (enabled) => {
  const iconPath = enabled ? 'HideIconOn-128.png' : 'HideIconOff-128.png';
  chrome.action.setIcon({ path: iconPath });
};

// Set initial state on installation and startup
chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.session.set({ enabled: true });
  updateIcon(true);
});

chrome.runtime.onStartup.addListener(() => {
  chrome.storage.session.get('enabled', (data) => {
    updateIcon(!!data.enabled);
  });
});

// Listen for the extension icon to be clicked
chrome.action.onClicked.addListener((tab) => {
  // Get current state, flip it, and save it
  chrome.storage.session.get('enabled', (data) => {
    const newState = !data.enabled;
    chrome.storage.session.set({ enabled: newState });
    updateIcon(newState);

    // Send a message to the active tab to update its styling
    chrome.tabs.sendMessage(tab.id, { action: 'update-styling', enabled: newState }, (response) => {
      if (chrome.runtime.lastError) { /* Ignore errors */ }
    });
  });
});

