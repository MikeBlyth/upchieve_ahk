// UPchieve Student Detector - Content Script
// Runs automatically on UPchieve pages with full extension permissions

console.log('🚀 UPchieve Student Detector Extension loaded');

// Configuration
let detectorEnabled = false;
let debugLevel = 1;

// Debug logging
function debugLog(level, message, ...args) {
    if (debugLevel >= level) {
        const timestamp = new Date().toLocaleTimeString();
        console.log(`[${timestamp}] ${message}`, ...args);
    }
}

// Get current window ID for AHK integration
let currentWindowId = null;

// Get window ID when content script loads
chrome.runtime.sendMessage({action: 'getWindowId'}, (response) => {
    if (response && response.windowId) {
        currentWindowId = response.windowId;
        debugLog(1, '🪟 Window ID obtained:', currentWindowId);

        // Always send handshake when window ID is available (for AHK integration)
        sendWindowIdHandshake();
    }
});

// Check if detector should be enabled (from storage)
chrome.storage.sync.get(['detectorEnabled'], function(result) {
    detectorEnabled = result.detectorEnabled || false;
    if (detectorEnabled) {
        initializeDetector();
        // Send window ID handshake when detector is enabled
        sendWindowIdHandshake();
    }

    // Update icon on load
    chrome.runtime.sendMessage({
        action: 'updateIcon',
        enabled: detectorEnabled
    });

    debugLog(1, '📊 Detector status:', detectorEnabled ? 'ENABLED' : 'DISABLED');
});

// Listen for enable/disable messages from popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === 'toggleDetector') {
        detectorEnabled = message.enabled;

        if (detectorEnabled) {
            initializeDetector();
            // Send window ID handshake when detector is enabled
            sendWindowIdHandshake();
            debugLog(1, '✅ Detector enabled via popup');
        } else {
            disableDetector();
            debugLog(1, '🛑 Detector disabled via popup');
        }

        sendResponse({ status: 'success', enabled: detectorEnabled });
    }
    else if (message.action === 'getStatus') {
        sendResponse({ enabled: detectorEnabled });
    }
    else if (message.action === 'sendHandshake') {
        // Manual handshake request from popup
        if (currentWindowId) {
            sendWindowIdHandshake();
            sendResponse({ status: 'success', windowId: currentWindowId });
        } else {
            sendResponse({ status: 'error', message: 'Window ID not available' });
        }
    }
});

// DOM monitoring variables
let domObserver = null;

// Initialize the student detector
function initializeDetector() {
    if (domObserver) return; // Already initialized

    debugLog(1, '🎯 Initializing DOM monitoring...');

    // Create DOM observer for student row changes (additions and removals)
    domObserver = new MutationObserver(mutations => {
        if (!detectorEnabled) return;

        let studentListChanged = false;
        let changeDetails = [];

        mutations.forEach(mutation => {
            // Check for added student rows
            mutation.addedNodes.forEach(node => {
                if (node.nodeType === 1) { // Element node
                    // Check if the added node is a student row
                    if (node.classList && node.classList.contains('session-row')) {
                        debugLog(1, '🚨 New student added via DOM monitoring:', node);
                        studentListChanged = true;
                        changeDetails.push('student row added');
                    }

                    // Also check if student rows were added within this node
                    if (node.querySelectorAll) {
                        const newStudentRows = node.querySelectorAll('.session-row');
                        if (newStudentRows.length > 0) {
                            debugLog(1, `🚨 ${newStudentRows.length} new student(s) added in container:`, newStudentRows);
                            studentListChanged = true;
                            changeDetails.push(`${newStudentRows.length} students added in container`);
                        }
                    }
                }
            });

            // Check for removed student rows
            mutation.removedNodes.forEach(node => {
                if (node.nodeType === 1) { // Element node
                    // Check if the removed node is a student row
                    if (node.classList && node.classList.contains('session-row')) {
                        debugLog(1, '📤 Student removed via DOM monitoring:', node);
                        studentListChanged = true;
                        changeDetails.push('student row removed');
                    }

                    // Also check if student rows were removed within this node
                    if (node.querySelectorAll) {
                        const removedStudentRows = node.querySelectorAll('.session-row');
                        if (removedStudentRows.length > 0) {
                            debugLog(1, `📤 ${removedStudentRows.length} student(s) removed in container:`, removedStudentRows);
                            studentListChanged = true;
                            changeDetails.push(`${removedStudentRows.length} students removed in container`);
                        }
                    }
                }
            });
        });

        // If student list changed, trigger detection to update clipboard
        if (studentListChanged) {
            debugLog(1, '🔄 Student list changed:', changeDetails.join(', '));
            triggerStudentDetection('DOM monitoring', changeDetails.join(', '));
        }
    });

    // Start observing DOM changes
    const tableContainer = document.querySelector('.session-list tbody') ||
                          document.querySelector('.session-list') ||
                          document.querySelector('tbody') ||
                          document.body;

    if (tableContainer) {
        domObserver.observe(tableContainer, {
            childList: true,
            subtree: true
        });
        debugLog(1, '👀 DOM monitoring initialized on:', tableContainer.tagName + (tableContainer.className ? '.' + tableContainer.className : ''));
    } else {
        debugLog(1, '⚠️ Could not find student table container, monitoring document body');
        domObserver.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
}

// Disable the detector
function disableDetector() {
    if (domObserver) {
        domObserver.disconnect();
        domObserver = null;
        debugLog(1, '🛑 DOM monitoring disabled');
    }
}

// Debouncing for student detection
let lastDetectionTime = 0;
function triggerStudentDetection(method, details) {
    const now = Date.now();
    if (now - lastDetectionTime < 1000) { // Debounce multiple triggers within 1 second
        debugLog(1, '⏸️ Detection debounced (too soon after last detection)');
        return;
    }
    lastDetectionTime = now;

    debugLog(1, `🎯 Student detection triggered by ${method}: ${details}`);
    // DOM changes are immediate, no delay needed
    extractAndDisplayStudentData();
}

// Send window ID handshake to AutoHotkey
function sendWindowIdHandshake() {
    if (!currentWindowId) {
        debugLog(1, '❌ Cannot send handshake - window ID not available');
        return;
    }

    const handshakeData = `*upchieve_windowid|${currentWindowId}`;
    copyToClipboard(handshakeData);
    debugLog(1, '🤝 Window ID handshake sent:', handshakeData);
}

// Format all students for clipboard in AHK-compatible format
function formatStudentDataForClipboard(students, waitMinutes) {
    if (!currentWindowId) {
        debugLog(1, '❌ Cannot format clipboard data - window ID not available');
        return `*upchieve|unknown|${students[0].name}|${students[0].topic}|${waitMinutes}`;
    }

    // Start with identifier and window ID
    let clipboardData = `*upchieve|${currentWindowId}`;

    // Add each student's data
    students.forEach((student, index) => {
        const studentWaitMinutes = extractWaitMinutes(student.waitTime);
        clipboardData += `|${student.name}|${student.topic}|${studentWaitMinutes}`;

        debugLog(2, `📝 Added student ${index + 1}: ${student.name} (${student.topic}, ${studentWaitMinutes}min)`);
    });

    debugLog(1, '📋 Formatted clipboard data:', clipboardData);
    return clipboardData;
}

// Extract wait time in minutes as integer
function extractWaitMinutes(waitTimeText) {
    if (!waitTimeText) return 0;

    const text = waitTimeText.trim();

    // Handle "< 1" -> return 0
    if (text.includes('< 1')) {
        return 0;
    }

    // Extract number from "x min" format
    const match = text.match(/(\d+)/);
    if (match) {
        return parseInt(match[1], 10);
    }

    return 0;
}

// Extract student data from DOM
function extractAndDisplayStudentData() {
    debugLog(1, '📊 Extracting student data...');

    try {
        // Find all student rows
        const sessionRows = document.querySelectorAll('.session-row');

        if (sessionRows.length === 0) {
            debugLog(1, '❌ No session rows found - student list is empty');

            // Send empty student list to clipboard to clear stale data
            const emptyClipboardData = `*upchieve|${currentWindowId || 'unknown'}`;
            copyToClipboard(emptyClipboardData);
            debugLog(1, '📋 Sent empty student list to clipboard:', emptyClipboardData);

            // Show notification that student list is empty
            showExtensionNotification('Student List Empty', 'No students currently waiting');

            return;
        }

        debugLog(1, `✅ Found ${sessionRows.length} session row(s)`);

        // Extract data from each row
        const students = [];

        sessionRows.forEach((row, index) => {
            try {
                // Look for student name (typically in first column)
                const nameElements = row.querySelectorAll('td:first-child, .student-name, [data-testid*="name"], [class*="name"]');
                let studentName = 'Unknown Student';

                for (const element of nameElements) {
                    const text = element.textContent.trim();
                    if (text && text !== '' && !text.includes('Student') && !text.includes('Help Topic')) {
                        studentName = text;
                        break;
                    }
                }

                // Look for topic (typically in second column or help-topic class)
                const topicElements = row.querySelectorAll('td:nth-child(2), .help-topic, [data-testid*="topic"], [class*="topic"], [class*="subject"]');
                let topic = 'Unknown Topic';

                for (const element of topicElements) {
                    const text = element.textContent.trim();
                    if (text && text !== '' && !text.includes('Help Topic') && !text.includes('Student')) {
                        topic = text;
                        break;
                    }
                }

                // Look for wait time to confirm this is a waiting student
                const waitElements = row.querySelectorAll('td:last-child, .wait-time, [data-testid*="wait"], [class*="wait"]');
                let hasWaitTime = false;
                let waitTime = '';

                for (const element of waitElements) {
                    const text = element.textContent.trim();
                    if (text.includes('minute') || text.includes('<') || text.includes('sec')) {
                        hasWaitTime = true;
                        waitTime = text;
                        break;
                    }
                }

                // Only include if we found meaningful data
                if (studentName !== 'Unknown Student' || topic !== 'Unknown Topic') {
                    students.push({
                        name: studentName,
                        topic: topic,
                        waitTime: waitTime,
                        hasWaitTime: hasWaitTime,
                        rowIndex: index
                    });
                }

                debugLog(2, `📋 Row ${index}:`, {
                    name: studentName,
                    topic: topic,
                    waitTime: waitTime,
                    hasWaitTime: hasWaitTime,
                    element: row
                });

            } catch (error) {
                console.error(`Error processing row ${index}:`, error);
            }
        });

        // Display results
        if (students.length > 0) {
            // Focus on most recent/relevant student (typically first in list)
            const primaryStudent = students[0];

            // Create notification message
            const message = `Student: ${primaryStudent.name}\nTopic: ${primaryStudent.topic}` +
                (primaryStudent.waitTime ? `\nWait Time: ${primaryStudent.waitTime}` : '');

            // Extract wait time in minutes for AHK parsing
            const waitMinutes = extractWaitMinutes(primaryStudent.waitTime);

            // Copy to clipboard using extension API (no focus issues!)
            // Format: *upchieve|windowId|name1|topic1|minutes1|name2|topic2|minutes2|...
            const clipboardData = formatStudentDataForClipboard(students, waitMinutes);
            copyToClipboard(clipboardData);

            // Log all students for debugging
            debugLog(1, '🎓 All students detected:', students);
            debugLog(1, '📋 Multi-student clipboard format sent to AHK');

            // Show notification via extension
            showExtensionNotification('Student Detected!', message);

        } else {
            debugLog(1, '⚠️ DOM change detected but no student data found');
        }

    } catch (error) {
        console.error('Error extracting student data:', error);
        debugLog(1, '❌ Extraction Error: Failed to extract student data: ' + error.message);
    }
}

// Copy to clipboard using extension permissions (no focus issues!)
function copyToClipboard(text) {
    debugLog(1, '📋 Copying to clipboard via execCommand (skip modern API):', text);

    // Skip modern clipboard API entirely - go straight to execCommand
    fallbackCopy(text);
}

// Fallback clipboard method
function fallbackCopy(text) {
    try {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'absolute';
        textarea.style.left = '-9999px';
        textarea.style.opacity = '0';

        document.body.appendChild(textarea);
        textarea.focus();
        textarea.select();

        const success = document.execCommand('copy');
        document.body.removeChild(textarea);

        if (success) {
            debugLog(1, '✅ Fallback clipboard copy successful:', text);
        } else {
            debugLog(1, '❌ All clipboard methods failed');
        }

    } catch (error) {
        debugLog(1, '❌ Fallback copy error:', error);
    }
}

// Show notification via extension (could use chrome.notifications API)
function showExtensionNotification(title, message) {
    debugLog(1, `📢 EXTENSION NOTIFICATION: ${title} - ${message}`);

    // For now, just log - could implement chrome.notifications.create()
    // if you want actual system notifications

    // Create a small visual indicator
    const notification = document.createElement('div');
    notification.innerHTML = `
        <div style="font-weight: bold; color: #2d5016;">${title}</div>
        <div style="font-size: 12px; margin-top: 3px;">${message.replace(/\n/g, '<br>')}</div>
    `;

    Object.assign(notification.style, {
        position: 'fixed',
        top: '20px',
        right: '20px',
        background: '#d4edda',
        color: '#155724',
        padding: '12px',
        borderRadius: '4px',
        border: '1px solid #c3e6cb',
        zIndex: '999999',
        maxWidth: '300px',
        fontSize: '14px',
        fontFamily: 'Arial, sans-serif',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
    });

    document.body.appendChild(notification);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Debug functions for testing
window.testExtensionDetection = function() {
    debugLog(1, '🧪 Extension test triggered');
    extractAndDisplayStudentData();
};

window.setExtensionDebugLevel = function(level) {
    debugLevel = level;
    debugLog(1, `🐛 Extension debug level set to: ${level}`);
};

debugLog(1, '🎉 UPchieve Student Detector Extension ready!');
debugLog(1, '📋 Available commands:');
debugLog(1, '  • testExtensionDetection(): Manual test');
debugLog(1, '  • setExtensionDebugLevel(0-2): Set debug verbosity');