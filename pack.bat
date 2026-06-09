@echo off
chcp 65001 >nul 2>&1
echo ══════════════════════════════════════
echo   YouTube 汉化工具 - 打包分享
echo ══════════════════════════════════════
echo.

:: 删除旧包
if exist "%~dp0YouTube汉化工具.zip" del "%~dp0YouTube汉化工具.zip"

:: 删除临时文件和下载内容
if exist "%~dp0temp" rmdir /s /q "%~dp0temp"
if exist "%~dp0downloads" rmdir /s /q "%~dp0downloads"
mkdir "%~dp0temp"
mkdir "%~dp0downloads\videos"
mkdir "%~dp0downloads\audio"
mkdir "%~dp0downloads\subtitles"

:: 用 PowerShell 压缩
echo 正在打包...
powershell.exe -Command "Compress-Archive -Path 'D:\YouTube汉化工具\bin','D:\YouTube汉化工具\启动器.ps1','D:\YouTube汉化工具\启动.bat','D:\YouTube汉化工具\启动.vbs','D:\YouTube汉化工具\打包分享.bat','D:\YouTube汉化工具\使用说明.txt' -DestinationPath 'D:\YouTube汉化工具\YouTube汉化工具.zip' -Force"

if exist "%~dp0YouTube汉化工具.zip" (
    echo.
    echo 打包完成！
    echo 文件: %~dp0YouTube汉化工具.zip
    echo.
    echo 分享给朋友后，对方只需：
    echo 1. 解压到任意文件夹
    echo 2. 双击"启动.bat"
    echo 3. 首次会自动安装 Python（需要联网）
    echo.
) else (
    echo 打包失败！
)
pause
