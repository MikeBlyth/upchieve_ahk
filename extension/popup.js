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
            if (tabs && tabs[0]) {
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
            }
        });
    });

    // Test button click handler
    testBtn.addEventListener('click', function() {
        console.log('🧪 Test button clicked');

        // Check if chrome.scripting is available
        if (!chrome.scripting) {
            console.error('❌ chrome.scripting not available');
            showError('Scripting API not available - check manifest permissions');
            return;
        }

        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            console.log('📋 Current tabs:', tabs);

            if (!tabs || !tabs[0]) {
                console.log('❌ No active tab found');
                showError('No active tab found');
                return;
            }

            const tab = tabs[0];
            console.log('🎯 Target tab:', tab.url);

            // Check if we're on the right domain
            if (!tab.url || !tab.url.includes('upchieve.org')) {
                console.log('⚠️ Not on UPchieve domain');
                showError('Please navigate to app.upchieve.org first');
                return;
            }

            // Simple test injection without complex content script dependency
            console.log('🚀 Attempting simple script injection...');

            chrome.scripting.executeScript({
                target: { tabId: tab.id },
                func: function() {
                    // Check if the content script injection function is available
                    if (typeof window.injectTestStudent === 'function') {
                        console.log('✅ Using content script injectTestStudent function');
                        return window.injectTestStudent();
                    } else {
                        console.log('⚠️ Content script not available, using simple fallback');

                        // Fallback: simple test injection
                        const tbody = document.querySelector('.session-list tbody') ||
                                     document.querySelector('tbody') ||
                                     document.querySelector('table tbody');

                        if (!tbody) {
                            return 'Error: Could not find student table. Make sure you are on the student waiting list page.';
                        }

                        // Create a simple test student with proper name
                        const row = document.createElement('tr');
                        row.className = 'session-row';
                        row.setAttribute('data-testid', 'session-row-TestStudent');
                        row.style.backgroundColor = '#fffacd'; // Light yellow background
                        row.innerHTML = `
                            <td>Alex Test</td>
                            <td>8th Grade Math</td>
                            <td>&lt; 1 min</td>
                        `;

                        console.log('📝 Creating simple test row:', row);
                        tbody.insertBefore(row, tbody.firstChild);

                        // Auto-remove after 15 seconds
                        setTimeout(() => {
                            if (row.parentNode) {
                                row.remove();
                                console.log('🧹 Test student removed');
                            }
                        }, 15000);

                        return 'Simple test student injected (refresh page to use full content script features)';
                    }
                }
            }, function(results) {
                console.log('📤 Script execution completed, results:', results);

                if (chrome.runtime.lastError) {
                    console.error('❌ Script execution error:', chrome.runtime.lastError);
                    showError('Script error: ' + chrome.runtime.lastError.message);
                    return;
                }

                if (results && results[0] && results[0].result) {
                    console.log('✅ Success:', results[0].result);
                    showMessage(results[0].result);
                } else {
                    console.log('⚠️ No result returned');
                    showError('Script executed but no result returned');
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
            if (tabs && tabs[0] && tabs[0].url && tabs[0].url.includes('app.upchieve.org')) {
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

    // Check if we're on the right page and set button states
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        if (tabs && tabs[0] && tabs[0].url && tabs[0].url.includes('app.upchieve.org')) {
            toggleBtn.disabled = false;
            testBtn.disabled = false;
        } else {
            toggleBtn.disabled = true;
            testBtn.disabled = true;
        }
    });

});