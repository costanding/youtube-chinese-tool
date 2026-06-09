@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   YouTube 汉化工具 - 依赖下载器
echo ========================================
echo.

set "BIN_DIR=%~dp0bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: 检查是否需要使用代理（如果有的话）
set "PROXY_PARAM="
if defined HTTP_PROXY set "PROXY_PARAM=--proxy %HTTP_PROXY%"
if defined HTTPS_PROXY set "PROXY_PARAM=--proxy %HTTPS_PROXY%"

:: 检查 yt-dlp
if exist "%BIN_DIR%\yt-dlp.exe" (
    echo [✓] yt-dlp 已存在
) else (
    echo [↓] 正在下载 yt-dlp (18MB)...
    curl -L %PROXY_PARAM% -o "%BIN_DIR%\yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    if exist "%BIN_DIR%\yt-dlp.exe" (
        echo [✓] yt-dlp 下载完成
    ) else (
        echo [✗] yt-dlp 下载失败
        echo     请手动下载：https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe
        echo     放入 %BIN_DIR% 目录
    )
)

:: 检查 ffmpeg 和 ffprobe
if exist "%BIN_DIR%\ffmpeg.exe" (
    if exist "%BIN_DIR%\ffprobe.exe" (
        echo [✓] ffmpeg/ffprobe 已存在
        goto :check_done
    )
)

echo.
echo [!] 需要下载 ffmpeg (~220MB)，解压后约 450MB
echo [!] 请确保网络稳定，下载可能需要几分钟
echo.
set /p "CONFIRM=是否下载？(Y/N): "
if /i not "!CONFIRM!"=="Y" goto :manual_hint

echo.
echo [↓] 正在下载 ffmpeg...
set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
set "FFMPEG_ZIP=%BIN_DIR%\ffmpeg.zip"

curl -L %PROXY_PARAM% --progress-bar -o "%FFMPEG_ZIP%" "%FFMPEG_URL%"
if not exist "%FFMPEG_ZIP%" (
    echo [✗] ffmpeg 下载失败
    goto :manual_hint
)

echo [↓] 正在解压 ffmpeg...
powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%BIN_DIR%\ffmpeg_temp' -Force"

:: 复制文件到 bin 目录
for /r "%BIN_DIR%\ffmpeg_temp" %%f in (ffmpeg.exe) do copy "%%f" "%BIN_DIR%\" >nul
for /r "%BIN_DIR%\ffmpeg_temp" %%f in (ffprobe.exe) do copy "%%f" "%BIN_DIR%\" >nul

:: 清理临时文件
del "%FFMPEG_ZIP%" 2>nul
rmdir /s /q "%BIN_DIR%\ffmpeg_temp" 2>nul

if exist "%BIN_DIR%\ffmpeg.exe" if exist "%BIN_DIR%\ffprobe.exe" (
    echo [✓] ffmpeg/ffprobe 下载完成
) else (
    echo [✗] 解压失败
    goto :manual_hint
)
goto :check_done

:manual_hint
echo.
echo ========================================
echo   手动下载说明
echo ========================================
echo.
echo 如果自动下载失败，请手动下载：
echo.
echo 1. yt-dlp (18MB):
echo    https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe
echo.
echo 2. ffmpeg (220MB):
echo    https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip
echo    解压后将 ffmpeg.exe 和 ffprobe.exe 放入 bin 目录
echo.
echo 下载地址：%BIN_DIR%
echo.

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

echo 现在可以双击 start.bat 启动程序了！
echo.
pause
