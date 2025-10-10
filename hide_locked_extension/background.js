// Function to update the icon badge
const updateIcon = (enabled) => {
  const badgeText = enabled ? 'ON' : 'OFF';
  const badgeColor = enabled ? '#4CAF50' : '#F44336'; // Green for ON, Red for OFF
  chrome.action.setBadgeText({ text: badgeText });
  chrome.action.setBadgeBackgroundColor({ color: badgeColor });
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

