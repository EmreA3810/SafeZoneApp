Write-Host "Starting SafeZone Notification Worker..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
node worker.js
