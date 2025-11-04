
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

// Inject a stylesheet for global page styles (text selection, hiding rows)
function injectHidingStylesheet() {
    const style = document.createElement('style');
    style.id = 'gemini-global-styles';
    style.innerHTML = `
        /* Force text selection to be enabled everywhere */
        * {
            user-select: text !important;
            -webkit-user-select: text !important;
        }

        /* Hide locked rows directly via CSS */
        .session-row.session-row-locked {
            display: none !important;
        }
    `;
    document.head.appendChild(style);
    debugLog(1, '🎨 Injected global stylesheet');
}

injectHidingStylesheet();

// Check if detector should be enabled (from storage)
chrome.storage.sync.get(['detectorEnabled'], function(result) {
    detectorEnabled = result.detectorEnabled || false;
    if (detectorEnabled) {
        initializeDetector();
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
});

// DOM monitoring variables
let domObserver = null;



// Initialize the student detector
function initializeDetector() {
    if (domObserver) return; // Already initialized

    debugLog(1, '🎯 Initializing DOM monitoring...');

    // Initial scan is no longer needed as CSS handles hiding

    // Create DOM observer for student row changes (additions and removals)
    domObserver = new MutationObserver(mutations => {
        if (!detectorEnabled) return;

        let studentListChanged = false;
        let changeDetails = [];

        mutations.forEach(mutation => {
            // Handle added/removed nodes
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType !== 1) return;
                    const rows = node.matches('.session-row') ? [node] : Array.from(node.querySelectorAll('.session-row'));
                    rows.forEach(row => {
                        // No longer hiding via JS, CSS handles it.
                        // We only care if a new student (non-locked) is added.
                        if (!row.classList.contains('session-row-locked')) {
                            debugLog(1, '🚨 New student added:', row);
                            studentListChanged = true;
                            changeDetails.push('student row added');
                        }
                    });
                });

                mutation.removedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.matches && node.matches('.session-row')) {
                        // We only care if a student (non-locked) is removed.
                        if (!node.classList.contains('session-row-locked')) {
                            debugLog(1, '📤 Student removed:', node);
                            studentListChanged = true;
                            changeDetails.push('student row removed');
                        }
                    }
                });
            }
            // Attribute changes are no longer handled by JS for hiding, CSS handles it.
            // We still need to trigger detection if a row's class changes from locked to unlocked (or vice-versa)
            else if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                const row = mutation.target;
                // If a row's class changed, and it's a session-row, re-evaluate the list.
                // This covers cases where a row might become locked/unlocked.
                if (row && row.matches && row.matches('.session-row')) {
                    debugLog(1, '🔄 Session row class changed, re-evaluating list:', row);
                    studentListChanged = true;
                    changeDetails.push('session row class changed');
                }
            }
        });

        // If a valid student was added or removed, trigger the data extraction.
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
            subtree: true,
            attributes: true,
            attributeFilter: ['class']
        });
        debugLog(1, '👀 DOM monitoring initialized on:', tableContainer.tagName + (tableContainer.className ? '.' + tableContainer.className : ''));
    } else {
        debugLog(1, '⚠️ Could not find student table container, monitoring document body');
        domObserver.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['class']
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

    // Remove the injected stylesheet when disabling the detector
    const styleElement = document.getElementById('gemini-global-styles');
    if (styleElement && styleElement.parentNode) {
        styleElement.parentNode.removeChild(styleElement);
        debugLog(1, '🎨 Removed global stylesheet');
    }
}

// Debouncing for student detection
let detectionTimeout = null;
function triggerStudentDetection(method, details) {
    // Clear any pending detection to ensure we only run once after the last change.
    if (detectionTimeout) {
        clearTimeout(detectionTimeout);
    }

    // Schedule a new detection to run after a short delay (e.g., 250ms).
    // This groups together rapid-fire mutations into a single processing event.
    detectionTimeout = setTimeout(() => {
        debugLog(1, `🎯 Student detection triggered by ${method}: ${details}`);
        extractAndDisplayStudentData();
        detectionTimeout = null; // Reset after running
    }, 250);
}

// Format all students for clipboard in AHK-compatible format
function formatStudentDataForClipboard(students) {
    // Start with the identifier
    let clipboardData = `*upchieve`;

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
    debugLog(2, `🕐 extractWaitMinutes called with: "${waitTimeText}"`);

    if (!waitTimeText) {
        debugLog(2, `❌ No wait time text provided, returning 0`);
        return 0;
    }

    const text = waitTimeText.trim();
    debugLog(2, `🕐 Trimmed text: "${text}"`);

    // Handle "< 1" -> return 0
    if (text.includes('< 1')) {
        debugLog(2, `🕐 Found "< 1" pattern, returning 0`);
        return 0;
    }

    // Extract number from "x min" format
    const match = text.match(/(\d+)/);
    if (match) {
        const minutes = parseInt(match[1], 10);
        debugLog(2, `🕐 Extracted ${minutes} minutes from "${text}"`);
        return minutes;
    }

    debugLog(2, `❌ No number found in "${text}", returning 0`);
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
            const emptyClipboardData = `*upchieve`;
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
            // Skip any rows that are locked (hidden by CSS)
            if (row.classList.contains('session-row-locked')) {
                debugLog(2, `🙈 Skipping locked row ${index}`);
                return; // Continue to next iteration
            }

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
                    debugLog(2, `🔍 Checking wait element text: "${text}"`);
                    if (text.includes('min') || text.includes('<') || text.includes('sec')) {
                        hasWaitTime = true;
                        waitTime = text;
                        debugLog(2, `✅ Found wait time: "${waitTime}"`);
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

            // Copy to clipboard using extension API (no focus issues!)
            // Format: *upchieve|name1|topic1|minutes1|name2|topic2|minutes2|...
            const clipboardData = formatStudentDataForClipboard(students);
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

// Test student data for injection
const testStudentData = [
    { name: 'Alex Test', subject: '8th Grade Math', waitTime: '< 1 min' },
    { name: 'Jordan Demo', subject: 'Algebra', waitTime: '2 min' },
    { name: 'Sam Practice', subject: 'Pre-algebra', waitTime: '5 min' },
    { name: 'Casey Trial', subject: 'Statistics', waitTime: '3 min' },
    { name: 'Riley Mock', subject: 'Computer Science A', waitTime: '< 1 min' },
    { name: 'Taylor Fake', subject: '7th Grade Math', waitTime: '1 min' }
];

// Track injected test students
let injectedTestStudents = [];

// Inject test student into the page
window.injectTestStudent = function() {
    console.log('🧪 injectTestStudent function called');
    debugLog(1, '🧪 Injecting test student data...');

    try {
        // Find the student table tbody
        const tbody = document.querySelector('.session-list tbody') ||
                     document.querySelector('tbody') ||
                     document.querySelector('.session-list table tbody');

        if (!tbody) {
            debugLog(1, '❌ Could not find student table tbody');
            return 'Error: Student table not found';
        }

        // Check if we already have test students - if so, clear them first
        if (injectedTestStudents.length > 0) {
            clearTestStudents();
        }

        // Randomly select 1-2 test students
        const numStudents = Math.random() > 0.7 ? 2 : 1;
        const selectedStudents = [];

        for (let i = 0; i < numStudents; i++) {
            const randomIndex = Math.floor(Math.random() * testStudentData.length);
            const student = testStudentData[randomIndex];

            // Avoid duplicates
            if (!selectedStudents.find(s => s.name === student.name)) {
                selectedStudents.push(student);
            }
        }

        // Inject each selected student
        selectedStudents.forEach(student => {
            const testId = 'test-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);

            const row = document.createElement('tr');
            row.className = 'session-row';
            row.id = testId;
            row.setAttribute('data-testid', `session-row-${student.name.replace(' ', '')}`);
            row.setAttribute('data-test-student', 'true'); // Mark as test student

            row.innerHTML = `
                <td>${student.name}</td>
                <td>${student.subject}</td>
                <td>${student.waitTime}</td>
            `;

            // Insert at the beginning of the table
            tbody.insertBefore(row, tbody.firstChild);

            // Track for cleanup
            injectedTestStudents.push({
                element: row,
                id: testId,
                name: student.name,
                subject: student.subject,
                waitTime: student.waitTime
            });

            debugLog(1, `✅ Injected test student: ${student.name} (${student.subject})`);
        });

        // Auto-cleanup after 30 seconds
        setTimeout(() => {
            if (injectedTestStudents.length > 0) {
                debugLog(1, '🧹 Auto-cleanup: Removing test students after 30 seconds');
                clearTestStudents();
            }
        }, 30000);

        const message = `Injected ${selectedStudents.length} test student(s): ${selectedStudents.map(s => s.name).join(', ')}`;
        debugLog(1, '🎯 Test injection complete:', message);

        return message;

    } catch (error) {
        console.error('Error injecting test student:', error);
        debugLog(1, '❌ Test injection failed:', error.message);
        return 'Error: Failed to inject test student';
    }
};

// Clear all injected test students
window.clearTestStudents = function() {
    debugLog(1, '🧹 Clearing test students...');

    injectedTestStudents.forEach(student => {
        if (student.element && student.element.parentNode) {
            student.element.remove();
            debugLog(1, `🗑️ Removed test student: ${student.name}`);
        }
    });

    injectedTestStudents = [];
    debugLog(1, '✅ All test students cleared');

    return 'Test students cleared';
};

// Manual test function for current page data
window.testExtensionDetection = function() {
    debugLog(1, '🧪 Manual test: Extracting current page data...');

    try {
        extractAndDisplayStudentData();
        return 'Manual test completed - check console for results';
    } catch (error) {
        console.error('Manual test error:', error);
        return 'Manual test failed: ' + error.message;
    }
};

// Set debug level
window.setExtensionDebugLevel = function(level) {
    debugLevel = parseInt(level) || 0;
    debugLog(1, `🔧 Debug level set to: ${debugLevel}`);
    return `Debug level set to ${debugLevel}`;
};

// Extension debugging info
debugLog(1, '🎉 UPchieve Student Detector Extension ready!');
debugLog(1, '🔧 UPchieve Extension Functions Available:');
debugLog(1, '  • injectTestStudent(): Inject fake student data for testing');
debugLog(1, '  • clearTestStudents(): Remove all test students');
debugLog(1, '  • testExtensionDetection(): Manual test of current page data');
debugLog(1, '  • setExtensionDebugLevel(0-2): Set debug verbosity');

// Confirm functions are available
console.log('🔧 Extension functions registered:', {
    injectTestStudent: typeof window.injectTestStudent,
    clearTestStudents: typeof window.clearTestStudents,
    testExtensionDetection: typeof window.testExtensionDetection,
    setExtensionDebugLevel: typeof window.setExtensionDebugLevel
});
