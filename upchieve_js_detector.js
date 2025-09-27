// UPchieve Student Detection Script
// Detects alert sound, extracts student data from DOM, and displays notification

(function() {
    'use strict';

    console.log('🚀 UPchieve JS Detector loaded');

    // Configuration
    const ALERT_DELAY_MS = 50;
    const ALERT_PATTERN = /app\.upchieve\.org\/assets\/alert-.*\.mp3/;

    // Debug logging
    let debugLevel = 1; // 0=off, 1=basic, 2=verbose
    function debugLog(level, message, ...args) {
        if (debugLevel >= level) {
            const timestamp = new Date().toLocaleTimeString();
            console.log(`[${timestamp}] ${message}`, ...args);
        }
    }

    // Monitor DOM for new student rows using MutationObserver
    const domObserver = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
            // Check for new nodes added to the DOM
            mutation.addedNodes.forEach(node => {
                if (node.nodeType === 1) { // Element node
                    // Check if the added node is a student row
                    if (node.classList && node.classList.contains('session-row')) {
                        debugLog(1, '🚨 New student detected via DOM monitoring:', node);
                        triggerStudentDetection('DOM monitoring', 'new student row added');
                    }

                    // Also check if student rows were added within this node
                    if (node.querySelectorAll) {
                        const newStudentRows = node.querySelectorAll('.session-row');
                        if (newStudentRows.length > 0) {
                            debugLog(1, `🚨 ${newStudentRows.length} new student(s) detected in added container:`, newStudentRows);
                            triggerStudentDetection('DOM monitoring', `${newStudentRows.length} student rows in container`);
                        }
                    }
                }
            });
        });
    });

    // Start observing DOM changes on the student table area
    function initializeDomMonitoring() {
        // Find the student table container
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

    // Initialize DOM monitoring when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeDomMonitoring);
    } else {
        initializeDomMonitoring();
    }

    // Detection state management
    let alertDetectionActive = true;

    // Centralized trigger function with debouncing
    let lastAlertTime = 0;
    function triggerStudentDetection(method, details) {
        const now = Date.now();
        if (now - lastAlertTime < 1000) { // Debounce multiple triggers within 1 second
            debugLog(1, '⏸️ Detection debounced (too soon after last detection)');
            return;
        }
        lastAlertTime = now;

        debugLog(1, `🎯 Student detection triggered by ${method}: ${details}`);
        // DOM changes are immediate, no delay needed
        const delay = method === 'DOM monitoring' ? 0 : ALERT_DELAY_MS;
        setTimeout(() => {
            extractAndDisplayStudentData();
        }, delay);
    }

    // DOM monitoring is already initialized above

    // Extract student data from DOM
    function extractAndDisplayStudentData() {
        debugLog(1, '📊 Extracting student data...');

        try {
            // Find all student rows
            const sessionRows = document.querySelectorAll('.session-row');

            if (sessionRows.length === 0) {
                debugLog(1, '❌ No session rows found');
                // Try alternative selectors
                const altRows = document.querySelectorAll('tr, [class*="row"], [class*="student"], [class*="session"]');
                debugLog(2, `🔍 Alternative rows found: ${altRows.length}`, altRows);
                showNotification('No students found', 'Unable to locate student data in DOM');
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

                // Copy to clipboard (skip notification for testing)
                copyToClipboard(`${primaryStudent.name}|${primaryStudent.topic}`);

                // Log all students for debugging
                debugLog(1, '🎓 All students detected:', students);

                // Skip notification for testing
                debugLog(1, '📢 SKIPPED NOTIFICATION (testing mode):', message);

            } else {
                debugLog(1, '⚠️ DOM change detected but no student data found');
            }

        } catch (error) {
            console.error('Error extracting student data:', error);
            debugLog(1, '❌ Extraction Error: Failed to extract student data: ' + error.message);
        }
    }

    // Show browser notification (non-blocking)
    function showNotification(title, message) {
        console.log(`📢 NOTIFICATION: ${title} - ${message}`);

        // Create visual notification div
        createVisualNotification(title, message);

        // Browser notification (requires permission)
        if ('Notification' in window && Notification.permission === 'granted') {
            const notification = new Notification(title, {
                body: message,
                icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y="50" font-size="50">📚</text></svg>',
                requireInteraction: false
            });

            // Auto-close after 5 seconds
            setTimeout(() => {
                notification.close();
            }, 5000);

        } else if ('Notification' in window && Notification.permission === 'default') {
            // Request permission (non-blocking)
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    const notification = new Notification(title, {
                        body: message,
                        icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y="50" font-size="50">📚</text></svg>'
                    });
                    setTimeout(() => notification.close(), 5000);
                }
            });
        }
    }

    // Create visual notification overlay
    function createVisualNotification(title, message) {
        // Remove any existing notification
        const existing = document.getElementById('upchieve-notification');
        if (existing) existing.remove();

        // Create notification element
        const notification = document.createElement('div');
        notification.id = 'upchieve-notification';
        notification.innerHTML = `
            <div style="font-weight: bold; margin-bottom: 5px;">${title}</div>
            <div style="font-size: 14px; line-height: 1.4;">${message.replace(/\n/g, '<br>')}</div>
            <div style="margin-top: 10px; text-align: right;">
                <button onclick="this.parentElement.parentElement.remove()"
                        style="background: #fff; border: 1px solid #ccc; padding: 3px 8px; border-radius: 3px; cursor: pointer;">
                    Close
                </button>
                <button onclick="window.upchieveDetectorDisabled = true; this.parentElement.parentElement.remove();"
                        style="background: #ff6b6b; color: white; border: none; padding: 3px 8px; border-radius: 3px; cursor: pointer; margin-left: 5px;">
                    Disable
                </button>
            </div>
        `;

        // Style the notification
        Object.assign(notification.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            background: '#4CAF50',
            color: 'white',
            padding: '15px',
            borderRadius: '5px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
            zIndex: '999999',
            maxWidth: '350px',
            fontSize: '16px',
            fontFamily: 'Arial, sans-serif',
            border: '2px solid #45a049'
        });

        document.body.appendChild(notification);

        // Auto-remove after 10 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 10000);
    }

    // Copy data to clipboard for AutoHotkey integration - MUST be automatic for AHK
    function copyToClipboard(text) {
        debugLog(1, 'Attempting immediate clipboard copy:', text);

        // Force immediate execCommand copy - no user interaction required
        try {
            // Create invisible, focused textarea
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'absolute';
            textarea.style.left = '-9999px';
            textarea.style.top = '0px';
            textarea.style.opacity = '0';
            textarea.style.pointerEvents = 'none';
            textarea.readOnly = false;
            textarea.contentEditable = true;

            // Add to DOM
            document.body.appendChild(textarea);

            // Force focus and select
            textarea.focus();
            textarea.select();
            textarea.setSelectionRange(0, text.length);

            // Execute copy command immediately
            const success = document.execCommand('copy');

            // Clean up
            document.body.removeChild(textarea);

            if (success) {
                debugLog(1, '✅ IMMEDIATE clipboard copy successful:', text);
                return true;
            } else {
                debugLog(1, '❌ execCommand copy failed, trying alternative method');
                return attemptAlternativeCopy(text);
            }

        } catch (error) {
            debugLog(1, '❌ execCommand error:', error);
            return attemptAlternativeCopy(text);
        }
    }

    // Alternative immediate copy method
    function attemptAlternativeCopy(text) {
        try {
            // Method 2: Use input element instead of textarea
            const input = document.createElement('input');
            input.type = 'text';
            input.value = text;
            input.style.position = 'absolute';
            input.style.left = '-9999px';
            input.style.opacity = '0';

            document.body.appendChild(input);
            input.focus();
            input.select();

            const success = document.execCommand('copy');
            document.body.removeChild(input);

            if (success) {
                debugLog(1, '✅ Alternative copy method successful:', text);
                return true;
            }

            debugLog(1, '❌ All automatic copy methods failed - AHK integration will not work');
            return false;

        } catch (error) {
            debugLog(1, '❌ Alternative copy failed:', error);
            return false;
        }
    }


    // Debug and control functions
    window.testStudentExtraction = function() {
        debugLog(1, '🧪 Manual test triggered');
        extractAndDisplayStudentData();
    };

    window.disableDetector = function() {
        window.upchieveDetectorDisabled = true;
        alertDetectionActive = false;
        debugLog(1, '🛑 UPchieve detector disabled');
    };

    window.enableDetector = function() {
        window.upchieveDetectorDisabled = false;
        alertDetectionActive = true;
        debugLog(1, '✅ UPchieve detector enabled');
    };

    window.setDebugLevel = function(level) {
        debugLevel = level;
        debugLog(1, `🐛 Debug level set to: ${level} (0=off, 1=basic, 2=verbose)`);
    };

    window.showDetectorStatus = function() {
        debugLog(1, '📊 Detector Status:', {
            alertDetectionActive,
            upchieveDetectorDisabled: window.upchieveDetectorDisabled,
            debugLevel,
            lastAlertTime: new Date(lastAlertTime).toLocaleTimeString()
        });
    };

    debugLog(1, '🎉 UPchieve JS Detector ready!');
    debugLog(1, '📋 Available commands:');
    debugLog(1, '  • testStudentExtraction(): Manual test');
    debugLog(1, '  • disableDetector(): Disable alerts');
    debugLog(1, '  • enableDetector(): Re-enable alerts');
    debugLog(1, '  • setDebugLevel(0-2): Set debug verbosity');
    debugLog(1, '  • showDetectorStatus(): Show current status');

})();