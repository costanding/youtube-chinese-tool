# ═══════════════════════════════════════════════════════════════
#  YouTube 汉化工具 - 一键启动器
#  自动检测依赖、安装缺失组件、显示界面
# ═══════════════════════════════════════════════════════════════

# 强制 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 路径配置
$AppRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir     = Join-Path $AppRoot "bin"
$DownloadDir = Join-Path $AppRoot "downloads"
$TempDir    = Join-Path $AppRoot "temp"
$YtDlpPath  = Join-Path $BinDir "yt-dlp.exe"
$FfmpegPath = Join-Path $BinDir "ffmpeg.exe"
$DubberPy   = Join-Path $BinDir "dubber.py"

# 子目录
@($DownloadDir, $TempDir,
  (Join-Path $DownloadDir "videos"),
  (Join-Path $DownloadDir "audio"),
  (Join-Path $DownloadDir "subtitles")
) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ═══════════════ 依赖检测 ═══════════════

function Find-Python {
    # 1. PATH 里的 python
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py -and (python --version 2>&1) -match "3\.(\d+)") {
        return $py.Source
    }
    # 2. 常见安装路径
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Install-Python {
    Write-Host "正在安装 Python..." -ForegroundColor Yellow
    try {
        winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        return Find-Python
    } catch {
        return $null
    }
}

function Ensure-PipPackages($pythonExe) {
    $needed = @("edge-tts", "deep-translator")
    $missing = @()
    foreach ($pkg in $needed) {
        $check = & $pythonExe -c "import $($pkg.Replace('-','_'))" 2>&1
        if ($LASTEXITCODE -ne 0) { $missing += $pkg }
    }
    if ($missing.Count -gt 0) {
        Write-Host "正在安装依赖: $($missing -join ', ')..." -ForegroundColor Yellow
        & $pythonExe -m pip install $missing --quiet --disable-pip-version-check 2>&1 | Out-Null
    }
}

# ═══════════════ 初始化 ═══════════════

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 检测 Python
$PythonExe = Find-Python
if (-not $PythonExe) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "首次使用需要安装 Python，是否自动安装？", "初始化", "YesNo", "Information")
    if ($result -eq "Yes") {
        $PythonExe = Install-Python
        if (-not $PythonExe) {
            [System.Windows.Forms.MessageBox]::Show("Python 安装失败，请手动安装 Python 3.10+", "错误", "OK", "Error")
            exit
        }
    } else { exit }
}

# 检测 pip 包
Ensure-PipPackages $PythonExe

# ═══════════════ 界面 ═══════════════

$form = New-Object System.Windows.Forms.Form
$form.Text = "YouTube 汉化工具 v5"
$form.Size = New-Object System.Drawing.Size(720, 420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E2E")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CDD6F4")
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11)

# 标题
$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "YouTube 汉化工具"
$lbl.Font = New-Object System.Drawing.Font("Microsoft YaHei", 20, [System.Drawing.FontStyle]::Bold)
$lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#89B4FA")
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(20, 12)
$form.Controls.Add($lbl)

# URL 输入
$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = "链接:"
$lblUrl.AutoSize = $true
$lblUrl.Location = New-Object System.Drawing.Point(20, 65)
$form.Controls.Add($lblUrl)

$TxtUrl = New-Object System.Windows.Forms.TextBox
$TxtUrl.Size = New-Object System.Drawing.Size(560, 30)
$TxtUrl.Location = New-Object System.Drawing.Point(75, 62)
$TxtUrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#313244")
$TxtUrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CDD6F4")
$TxtUrl.BorderStyle = "FixedSingle"
$form.Controls.Add($TxtUrl)

# 选项行
$lblVoice = New-Object System.Windows.Forms.Label
$lblVoice.Text = "语音:"
$lblVoice.AutoSize = $true
$lblVoice.Location = New-Object System.Drawing.Point(20, 108)
$form.Controls.Add($lblVoice)

$cmbVoice = New-Object System.Windows.Forms.ComboBox
$cmbVoice.DropDownStyle = "DropDownList"
$cmbVoice.Items.AddRange(@("男声", "女声", "男声2", "女声2"))
$cmbVoice.SelectedIndex = 0
$cmbVoice.Size = New-Object System.Drawing.Size(80, 30)
$cmbVoice.Location = New-Object System.Drawing.Point(65, 105)
$form.Controls.Add($cmbVoice)

$lblMode = New-Object System.Windows.Forms.Label
$lblMode.Text = "模式:"
$lblMode.AutoSize = $true
$lblMode.Location = New-Object System.Drawing.Point(165, 108)
$form.Controls.Add($lblMode)

$cmbMode = New-Object System.Windows.Forms.ComboBox
$cmbMode.DropDownStyle = "DropDownList"
$cmbMode.Items.AddRange(@("配音+背景音", "仅字幕嵌入", "仅生成音频", "仅字幕文件"))
$cmbMode.SelectedIndex = 0
$cmbMode.Size = New-Object System.Drawing.Size(120, 30)
$cmbMode.Location = New-Object System.Drawing.Point(210, 105)
$form.Controls.Add($cmbMode)

# 按钮
function New-Btn($text, $x, $y, $accent) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(120, 42)
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    if ($accent) {
        $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#89B4FA")
        $btn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E2E")
        $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#74C7EC")
    } else {
        $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3B3B5C")
        $btn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CDD6F4")
        $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#585B70")
    }
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $form.Controls.Add($btn)
    return $btn
}

$y = 150
$btnDub      = New-Btn "汉化视频"   20  $y $true
$btnVideo    = New-Btn "下载视频"   150 $y $true
$btnAudio    = New-Btn "下载音频"   280 $y $true
$btnSubtitle = New-Btn "下载字幕"   410 $y $true
$btnInfo     = New-Btn "视频信息"   540 $y $false

$y2 = 205
$btnFolder = New-Btn "打开目录"    20  $y2 $false
$btnUpdate = New-Btn "更新内核"    150 $y2 $false

# 状态栏
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "就绪 - 粘贴链接后点击按钮"
$lblStatus.AutoSize = $true
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#A6ADC8")
$lblStatus.Location = New-Object System.Drawing.Point(20, 270)
$form.Controls.Add($lblStatus)

# 路径
$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "保存到: $DownloadDir"
$lblPath.AutoSize = $true
$lblPath.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6C7086")
$lblPath.Location = New-Object System.Drawing.Point(20, 300)
$form.Controls.Add($lblPath)

# 版本
$lblVer = New-Object System.Windows.Forms.Label
$lblVer.Text = "yt-dlp + ffmpeg + Python"
$lblVer.AutoSize = $true
$lblVer.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6C7086")
$lblVer.Location = New-Object System.Drawing.Point(450, 300)
$form.Controls.Add($lblVer)

# ═══════════════ 运行 yt-dlp ═══════════════

function Run-YtDlp($YtArgs, $Title) {
    $argStr = ($YtArgs | ForEach-Object {
        if ($_ -match '[\s%()\[\]^]') { '"' + $_ + '"' } else { $_ }
    }) -join ' '

    Start-Process $YtDlpPath -ArgumentList $argStr -WorkingDirectory $DownloadDir
}

function Get-Url {
    $u = $TxtUrl.Text.Trim()
    if (-not $u) {
        [System.Windows.Forms.MessageBox]::Show("请先粘贴 YouTube 链接！", "提示", "OK", "Warning")
        return $null
    }
    return $u
}

# ═══════════════ 事件 ═══════════════

$btnDub.Add_Click({
    $url = Get-Url; if (-not $url) { return }
    $voice = $cmbVoice.SelectedItem.ToString()
    $modeMap = @{ "配音+背景音"="dub"; "仅字幕嵌入"="subtitle"; "仅生成音频"="audio"; "仅字幕文件"="srt" }
    $mode = $modeMap[$cmbMode.SelectedItem.ToString()]
    $lblStatus.Text = "汉化已启动，请查看控制台窗口"
    $form.Refresh()
    Start-Process $PythonExe -ArgumentList "`"$DubberPy`" `"$url`" --voice `"$voice`" --mode $mode" -WorkingDirectory $DownloadDir
})

$btnVideo.Add_Click({
    $url = Get-Url; if (-not $url) { return }
    $lblStatus.Text = "下载视频中..."
    $form.Refresh()
    $outDir = Join-Path $DownloadDir "videos"
    Run-YtDlp @("-f", "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best",
        "--merge-output-format", "mp4", "--ffmpeg-location", $BinDir,
        "-o", (Join-Path $outDir "%(title)s.%(ext)s"),
        "--no-playlist", "--force-overwrites", $url) "下载视频"
    $lblStatus.Text = "视频下载已启动"
})

$btnAudio.Add_Click({
    $url = Get-Url; if (-not $url) { return }
    $lblStatus.Text = "下载音频中..."
    $form.Refresh()
    $outDir = Join-Path $DownloadDir "audio"
    Run-YtDlp @("-f", "bestaudio/best", "-x", "--audio-format", "mp3", "--audio-quality", "192K",
        "--ffmpeg-location", $BinDir, "-o", (Join-Path $outDir "%(title)s.%(ext)s"),
        "--no-playlist", $url) "下载音频"
    $lblStatus.Text = "音频下载已启动"
})

$btnSubtitle.Add_Click({
    $url = Get-Url; if (-not $url) { return }
    $lblStatus.Text = "下载字幕中..."
    $form.Refresh()
    $outDir = Join-Path $DownloadDir "subtitles"
    Run-YtDlp @("--skip-download", "--write-subs", "--write-auto-subs",
        "--sub-langs", "en,zh-Hans,ja", "--sub-format", "srt", "--convert-subs", "srt",
        "-o", (Join-Path $outDir "%(title)s.%(ext)s"),
        "--no-playlist", "--ignore-errors", $url) "下载字幕"
    $lblStatus.Text = "字幕下载已启动"
})

$btnInfo.Add_Click({
    $url = Get-Url; if (-not $url) { return }
    $lblStatus.Text = "获取信息中..."
    $form.Refresh()
    Run-YtDlp @("--dump-json", "--no-playlist", $url) "视频信息"
    $lblStatus.Text = "信息获取已启动"
})

$btnFolder.Add_Click({
    Start-Process explorer.exe $DownloadDir
})

$btnUpdate.Add_Click({
    $current = & $YtDlpPath --version 2>&1 | Out-String
    $current = $current.Trim()

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "当前版本: v$current`n`n是否检查更新？", "更新内核", "YesNo", "Information")
    if ($confirm -ne "Yes") { return }

    $lblStatus.Text = "检查更新中..."
    $form.Refresh()

    try {
        # 备份当前版本
        $backup = "$YtDlpPath.bak"
        Copy-Item $YtDlpPath $backup -Force

        $output = & $YtDlpPath -U 2>&1 | Out-String

        $after = & $YtDlpPath --version 2>&1 | Out-String
        $after = $after.Trim()

        if ($current -eq $after) {
            $lblStatus.Text = "已是最新版本 v$after"
        } else {
            $lblStatus.Text = "已更新: v$current -> v$after"
        }

        # 更新成功，删除备份
        Remove-Item $backup -Force -ErrorAction SilentlyContinue

    } catch {
        # 更新失败，恢复备份
        if (Test-Path $backup) {
            Copy-Item $backup $YtDlpPath -Force
            Remove-Item $backup -Force
            $lblStatus.Text = "更新失败，已恢复原版本"
        } else {
            $lblStatus.Text = "更新失败"
        }
    }
})

$TxtUrl.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") { $btnDub.PerformClick() }
})

# ═══════════════ 启动 ═══════════════

[void]$form.ShowDialog()
