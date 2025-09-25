// ==UserScript==
// @name         UPchieve Student Detector
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Automatically detect waiting students and extract their information
// @author       Mike
// @match        https://app.upchieve.org/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    console.log('🚀 UPchieve JS Detector loaded (Tampermonkey)');

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

    // Store original fetch function
    const originalFetch = window.fetch;

    // Intercept fetch requests to detect alert sound
    window.fetch = function(...args) {
        const url = args[0];

        // Log all fetch requests at verbose level
        debugLog(2, '🌐 Fetch request:', url);

        // Check if this is an alert sound request
        if (typeof url === 'string' && ALERT_PATTERN.test(url)) {
            debugLog(1, '🚨 Alert detected via fetch:', url);
            triggerStudentDetection('fetch', url);
        }

        // Call original fetch
        return originalFetch.apply(this, args);
    };

    // Enhanced audio monitoring
    let alertDetectionActive = true;

    // Monitor all audio elements (existing and new)
    function monitorAudioElements() {
        // Monitor existing audio elements
        document.querySelectorAll('audio').forEach(audio => {
            setupAudioMonitoring(audio);
        });

        // Monitor new audio elements
        const originalCreateElement = document.createElement;
        document.createElement = function(tagName) {
            const element = originalCreateElement.call(this, tagName);

            if (tagName.toLowerCase() === 'audio') {
                setupAudioMonitoring(element);
            }

            return element;
        };

        // Use MutationObserver to catch dynamically added audio elements
        const observer = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === 1) { // Element node
                        if (node.tagName === 'AUDIO') {
                            setupAudioMonitoring(node);
                        }
                        // Check for audio elements within added nodes
                        node.querySelectorAll && node.querySelectorAll('audio').forEach(audio => {
                            setupAudioMonitoring(audio);
                        });
                    }
                });
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
        debugLog(1, '🎧 Audio monitoring setup complete');
    }

    // Setup monitoring for individual audio element
    function setupAudioMonitoring(audioElement) {
        debugLog(2, '🎵 Setting up monitoring for audio element:', audioElement);

        // Monitor src changes
        const originalSrcDescriptor = Object.getOwnPropertyDescriptor(HTMLAudioElement.prototype, 'src') ||
                                    Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');

        if (originalSrcDescriptor) {
            Object.defineProperty(audioElement, 'src', {
                set: function(value) {
                    debugLog(2, '🎵 Audio src being set to:', value);
                    if (value && ALERT_PATTERN.test(value) && alertDetectionActive) {
                        debugLog(1, '🚨 Audio alert detected via src change:', value);
                        triggerStudentDetection('src change', value);
                    }
                    originalSrcDescriptor.set.call(this, value);
                },
                get: function() {
                    return originalSrcDescriptor.get.call(this);
                },
                configurable: true
            });
        }

        // Monitor play events
        audioElement.addEventListener('play', function() {
            debugLog(2, '▶️ Audio play event:', this.src || this.currentSrc);
            const src = this.src || this.currentSrc;
            if (src && ALERT_PATTERN.test(src) && alertDetectionActive) {
                debugLog(1, '🚨 Audio alert detected via play event:', src);
                triggerStudentDetection('play event', src);
            }
        });

        // Monitor loadstart events (when audio starts loading)
        audioElement.addEventListener('loadstart', function() {
            debugLog(2, '⏳ Audio loadstart event:', this.src || this.currentSrc);
            const src = this.src || this.currentSrc;
            if (src && ALERT_PATTERN.test(src) && alertDetectionActive) {
                debugLog(1, '🚨 Audio alert detected via loadstart:', src);
                triggerStudentDetection('loadstart', src);
            }
        });

        // Monitor canplay events (when audio can start playing)
        audioElement.addEventListener('canplay', function() {
            debugLog(2, '✅ Audio canplay event:', this.src || this.currentSrc);
            const src = this.src || this.currentSrc;
            if (src && ALERT_PATTERN.test(src) && alertDetectionActive) {
                debugLog(1, '🚨 Audio alert detected via canplay:', src);
                triggerStudentDetection('canplay', src);
            }
        });
    }

    // Centralized trigger function with debouncing
    let lastAlertTime = 0;
    function triggerStudentDetection(method, url) {
        const now = Date.now();
        if (now - lastAlertTime < 1000) { // Debounce multiple triggers within 1 second
            debugLog(1, '⏸️ Alert detection debounced (too soon after last alert)');
            return;
        }
        lastAlertTime = now;

        debugLog(1, `🎯 Student detection triggered by ${method}: ${url}`);
        setTimeout(() => {
            extractAndDisplayStudentData();
        }, ALERT_DELAY_MS);
    }

    // Initialize audio monitoring when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', monitorAudioElements);
    } else {
        monitorAudioElements();
    }

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

                showNotification('Student Detected!', message);

                // Log all students for debugging
                debugLog(1, '🎓 All students detected:', students);

                // Copy to clipboard for AutoHotkey integration (optional)
                copyToClipboard(`${primaryStudent.name}|${primaryStudent.topic}`);

            } else {
                showNotification('Alert Detected', 'Audio alert played but no student data found');
            }

        } catch (error) {
            console.error('Error extracting student data:', error);
            showNotification('Extraction Error', 'Failed to extract student data: ' + error.message);
        }
    }

    // Show browser notification (non-blocking)
    function showNotification(title, message) {
        debugLog(1, `📢 NOTIFICATION: ${title} - ${message}`);

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

    // Copy data to clipboard for AutoHotkey integration
    function copyToClipboard(text) {
        debugLog(1, 'Attempting to copy to clipboard:', text);

        // Method 1: Focus document and use modern clipboard API
        try {
            window.focus();
            document.body.focus();

            navigator.clipboard.writeText(text).then(() => {
                debugLog(1, '✅ Data copied to clipboard via modern API:', text);
            }).catch(err => {
                debugLog(1, 'Modern clipboard failed, trying fallback:', err);
                copyToClipboardFallback(text);
            });
        } catch (error) {
            debugLog(1, 'Modern clipboard API not available, using fallback:', error);
            copyToClipboardFallback(text);
        }
    }

    // Fallback clipboard methods
    function copyToClipboardFallback(text) {
        // Method 2: execCommand (deprecated but widely supported)
        try {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();

            const success = document.execCommand('copy');
            document.body.removeChild(textarea);

            if (success) {
                debugLog(1, '✅ Data copied to clipboard via execCommand:', text);
                return;
            }
        } catch (error) {
            debugLog(1, 'execCommand clipboard failed:', error);
        }

        // Method 3: Manual selection (user must Ctrl+C)
        try {
            const div = document.createElement('div');
            div.textContent = text;
            div.style.position = 'fixed';
            div.style.top = '10px';
            div.style.left = '10px';
            div.style.background = 'yellow';
            div.style.padding = '5px';
            div.style.zIndex = '9999';
            div.style.border = '2px solid red';
            div.id = 'clipboard-helper';

            document.body.appendChild(div);

            // Select the text
            const range = document.createRange();
            range.selectNodeContents(div);
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);

            debugLog(1, '📋 Text selected (yellow box) - Press Ctrl+C to copy:', text);

            // Auto-remove after 10 seconds
            setTimeout(() => {
                const helper = document.getElementById('clipboard-helper');
                if (helper) helper.remove();
            }, 10000);

        } catch (error) {
            console.error('All clipboard methods failed:', error);
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