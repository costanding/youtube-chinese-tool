@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: 检查依赖工具
set "MISSING="
if not exist "%~dp0bin\yt-dlp.exe" set "MISSING=1"
if not exist "%~dp0bin\ffmpeg.exe" set "MISSING=1"
if not exist "%~dp0bin\ffprobe.exe" set "MISSING=1"

if defined MISSING (
    echo.
    echo ========================================
    echo   缺少必要的工具文件
    echo ========================================
    echo.
    echo 首次使用需要下载 yt-dlp 和 ffmpeg
    echo.
    set /p "DOWNLOAD=是否现在下载？(Y/N): "
    if /i "!DOWNLOAD!"=="Y" (
        call "%~dp0download_tools.bat"
    ) else (
        echo.
        echo 请手动运行 download_tools.bat 下载工具
        echo 或将 yt-dlp.exe、ffmpeg.exe、ffprobe.exe 放入 bin 目录
        echo.
        pause
        exit /b
    )
)

:: 启动程序
start "" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0launcher.ps1"
