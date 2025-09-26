// Popup script for UPchieve Student Detector Extension

document.addEventListener('DOMContentLoaded', function() {
    const statusDiv = document.getElementById('status');
    const statusText = document.getElementById('status-text');
    const toggleBtn = document.getElementById('toggle-btn');
    const testBtn = document.getElementById('test-btn');

    // Get current status from content script
    getCurrentStatus();

    // Toggle button click handler
    toggleBtn.addEventListener('click', function() {
        const isCurrentlyEnabled = toggleBtn.classList.contains('disable');
        const newState = !isCurrentlyEnabled;

        // Send message to content script
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {
                action: 'toggleDetector',
                enabled: newState
            }, function(response) {
                if (chrome.runtime.lastError) {
                    console.error('Extension communication error:', chrome.runtime.lastError);
                    showError('Unable to communicate with UPchieve page. Make sure you\'re on app.upchieve.org');
                    return;
                }

                if (response && response.status === 'success') {
                    updateUI(response.enabled);

                    // Save state to storage
                    chrome.storage.sync.set({
                        detectorEnabled: response.enabled
                    });

                    // Update extension icon via background script
                    chrome.runtime.sendMessage({
                        action: 'updateIcon',
                        enabled: response.enabled
                    });
                }
            });
        });
    });

    // Test button click handler
    testBtn.addEventListener('click', function() {
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            // Execute test function on the page
            chrome.scripting.executeScript({
                target: { tabId: tabs[0].id },
                function: function() {
                    if (typeof window.testExtensionDetection === 'function') {
                        window.testExtensionDetection();
                        return 'Test executed - check console for results';
                    } else {
                        return 'Extension not loaded on this page';
                    }
                }
            }, function(results) {
                if (results && results[0]) {
                    showMessage(results[0].result);
                }
            });
        });
    });

    // Get current status from storage and content script
    function getCurrentStatus() {
        chrome.storage.sync.get(['detectorEnabled'], function(result) {
            const enabled = result.detectorEnabled || false;
            updateUI(enabled);
        });

        // Also check with content script
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            if (tabs[0].url && tabs[0].url.includes('app.upchieve.org')) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    action: 'getStatus'
                }, function(response) {
                    if (response) {
                        updateUI(response.enabled);
                    }
                });
            }
        });
    }

    // Update UI based on current state
    function updateUI(enabled) {
        if (enabled) {
            statusDiv.className = 'status enabled';
            statusText.textContent = 'Active - Monitoring for students';
            toggleBtn.textContent = 'Disable Detector';
            toggleBtn.className = 'toggle-btn disable';
            statusDiv.querySelector('.status-icon').textContent = '✅';
        } else {
            statusDiv.className = 'status disabled';
            statusText.textContent = 'Inactive - Click Enable to start';
            toggleBtn.textContent = 'Enable Detector';
            toggleBtn.className = 'toggle-btn enable';
            statusDiv.querySelector('.status-icon').textContent = '⭕';
        }
    }

    // Show error message
    function showError(message) {
        const originalText = statusText.textContent;
        statusText.textContent = message;
        statusText.style.color = '#dc3545';

        setTimeout(() => {
            statusText.textContent = originalText;
            statusText.style.color = '';
        }, 3000);
    }

    // Show temporary message
    function showMessage(message) {
        const originalText = statusText.textContent;
        statusText.textContent = message;
        statusText.style.color = '#007bff';

        setTimeout(() => {
            statusText.textContent = originalText;
            statusText.style.color = '';
        }, 2000);
    }

    // Check if we're on the right page
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        if (!tabs[0].url || !tabs[0].url.includes('app.upchieve.org')) {
            showError('Navigate to app.upchieve.org to use this extension');
            toggleBtn.disabled = true;
            testBtn.disabled = true;
        }
    });
});