@echo off
title SafeZone Notification Worker
cd /d "%~dp0"
echo Starting SafeZone Notification Worker...
echo.
node worker.js
pause
