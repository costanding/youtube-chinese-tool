@echo off
chcp 65001 >nul 2>&1
start "" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0launcher.ps1"
