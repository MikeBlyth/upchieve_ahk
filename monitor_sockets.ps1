# Monitor socket usage every minute for testing socket exhaustion
# Useful to see how fast TIME_WAIT sockets accumulate

$intervals = @()
$lastCount = 0

Write-Host "Socket Monitor - Checking every minute"
Write-Host "Press Ctrl+C to stop`n"

while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Get all TIME_WAIT sockets
    $timeWaitCount = (Get-NetTCPConnection -State TimeWait -ErrorAction SilentlyContinue | Measure-Object).Count

    # Find AutoHotkey process
    $ahkProcess = Get-Process AutoHotkey64 -ErrorAction SilentlyContinue

    $ahkTimeWait = 0
    $ahkTotal = 0

    if ($ahkProcess) {
        $ahkPid = $ahkProcess.Id

        # Get TIME_WAIT sockets for AHK
        $ahkTimeWait = (Get-NetTCPConnection -State TimeWait -ErrorAction SilentlyContinue |
                       Where-Object {$_.OwningProcess -eq $ahkPid} | Measure-Object).Count

        # Get total sockets for AHK
        $ahkTotal = (Get-NetTCPConnection -ErrorAction SilentlyContinue |
                    Where-Object {$_.OwningProcess -eq $ahkPid} | Measure-Object).Count
    }

    # Calculate rate of change
    $delta = $timeWaitCount - $lastCount
    $deltaPer10s = [math]::Round($delta / 6, 1)  # per ~10 second avg
    $lastCount = $timeWaitCount

    # Show results
    Write-Host "[$timestamp]" -ForegroundColor Cyan
    Write-Host "  System TIME_WAIT sockets: $timeWaitCount (Δ $delta/min, ~$deltaPer10s/sec)"

    if ($ahkProcess) {
        Write-Host "  AutoHotkey (PID $ahkPid):" -ForegroundColor Yellow
        Write-Host "    TIME_WAIT: $ahkTimeWait"
        Write-Host "    Total TCP: $ahkTotal"
    } else {
        Write-Host "  AutoHotkey: not running" -ForegroundColor Red
    }

    # Warn if getting close to limits
    if ($timeWaitCount -gt 15000) {
        Write-Host "  ⚠️  WARNING: High socket count!" -ForegroundColor Red
    }

    Write-Host ""
    Start-Sleep -Seconds 60
}
