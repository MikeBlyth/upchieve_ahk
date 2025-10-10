
const styleId = 'hide-locked-rows-style';

// Function to add or remove the CSS for hiding elements
function setHiding(enabled) {
  const existingStyle = document.getElementById(styleId);
  if (enabled) {
    if (!existingStyle) {
      const style = document.createElement('style');
      style.id = styleId;
      style.textContent = `.session-row-locked { display: none !important; }`;
      document.head.appendChild(style);
    }
  } else {
    if (existingStyle) {
      existingStyle.remove();
    }
  }
}

// Listen for messages from the background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'update-styling') {
    setHiding(message.enabled);
  }
});

// Apply the initial state when the page loads
// Default to true (enabled) if no state is set yet
chrome.storage.session.get('enabled', (data) => {
  const initialState = data.enabled !== false;
  setHiding(initialState);
});



