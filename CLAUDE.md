This simple script is designed to click on a waiting student in Upchieve.
It uses FindTextv2 to quickly scan for stored-encoded images.
PageTarget is the image for "Waiting Students" to ensure we're on the right page
WaitingTarget is the image for "< 1 minute" which appears when a student is waiting.

Flow: 
- Switch to Upchieve window
- Ensure we're on the right page by finding PageTarget
- Enter loop to search every 0.2 seconds for WaitingTarget.
- If it appears, click on it and exit the loop. Sleep until reactivated by ctl-shift-a hotkey or exited by ctl-shift-q.
