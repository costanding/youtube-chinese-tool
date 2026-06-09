@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   YouTube 汉化工具 - 依赖下载器
echo ========================================
echo.

set "BIN_DIR=%~dp0bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: 检查 yt-dlp
if exist "%BIN_DIR%\yt-dlp.exe" (
    echo [✓] yt-dlp 已存在
) else (
    echo [↓] 正在下载 yt-dlp...
    curl -L -o "%BIN_DIR%\yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    if exist "%BIN_DIR%\yt-dlp.exe" (
        echo [✓] yt-dlp 下载完成
    ) else (
        echo [✗] yt-dlp 下载失败，请手动下载：https://github.com/yt-dlp/yt-dlp/releases
    )
)

:: 检查 ffmpeg 和 ffprobe
if exist "%BIN_DIR%\ffmpeg.exe" (
    if exist "%BIN_DIR%\ffprobe.exe" (
        echo [✓] ffmpeg/ffprobe 已存在
        goto :check_done
    )
)

echo [↓] 正在下载 ffmpeg（较大，请耐心等待）...

:: 下载 ffmpeg
set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
set "FFMPEG_ZIP=%BIN_DIR%\ffmpeg.zip"

curl -L -o "%FFMPEG_ZIP%" "%FFMPEG_URL%"
if exist "%FFMPEG_ZIP%" (
    echo [↓] 正在解压 ffmpeg...
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%BIN_DIR%\ffmpeg_temp' -Force"

    :: 复制文件到 bin 目录
    for /r "%BIN_DIR%\ffmpeg_temp" %%f in (ffmpeg.exe) do copy "%%f" "%BIN_DIR%\" >nul
    for /r "%BIN_DIR%\ffmpeg_temp" %%f in (ffprobe.exe) do copy "%%f" "%BIN_DIR%\" >nul

    :: 清理临时文件
    del "%FFMPEG_ZIP%"
    rmdir /s /q "%BIN_DIR%\ffmpeg_temp"

    if exist "%BIN_DIR%\ffmpeg.exe" (
        if exist "%BIN_DIR%\ffprobe.exe" (
            echo [✓] ffmpeg/ffprobe 下载完成
        )
    ) else (
        echo [✗] ffmpeg 下载失败，请手动下载：https://github.com/BtbN/FFmpeg-Builds/releases
    )
) else (
    echo [✗] ffmpeg 下载失败，请手动下载：https://github.com/BtbN/FFmpeg-Builds/releases
)

:check_done
echo.
echo ========================================
echo   检查完成！
echo ========================================
echo.

:: 列出 bin 目录内容
echo bin 目录内容：
dir /b "%BIN_DIR%\*.exe" 2>nul
echo.

pause
