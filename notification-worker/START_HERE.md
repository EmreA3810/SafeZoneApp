# Quick Start Guide

## Easy Start Methods

### Method 1: Double-click (Easiest)
Just double-click `start-worker.bat` in this folder.

### Method 2: Desktop Shortcut
1. Right-click `start-worker.bat`
2. Send to → Desktop (create shortcut)
3. Now you can launch from desktop anytime

### Method 3: Run on Windows Startup (Auto-start)
1. Press `Win + R`
2. Type: `shell:startup` and press Enter
3. Copy `start-worker.bat` into the opened folder
4. Worker will start automatically when you log in

### Method 4: PowerShell
Double-click `start-worker.ps1`

## Stop the Worker
- Press `Ctrl + C` in the terminal window
- Or just close the window

## Check if Running
You'll see console output like:
```
🚀 SafeZone Notification Worker started
📡 Monitoring /reports for new entries and status changes...
```

When notifications are sent, you'll see:
```
✅ [4:35:12 PM] FCM sent to category_roadHazard for report xyz
```
