# AI 接手指南

> 如果你是 AI 助手，正在帮助用户维护这个项目，阅读本文档。

## 快速了解

这是一个 YouTube 视频汉化工具，能将英文视频自动转为中文版。

**核心文件只有 2 个**：
- `launcher.ps1` - GUI 界面（PowerShell）
- `bin/dubber.py` - 汉化逻辑（Python）

**外部依赖 3 个**：
- `bin/yt-dlp.exe` - YouTube 下载
- `bin/ffmpeg.exe` - 音视频处理
- Python + pip 包（edge-tts, deep-translator）

## 用户可能问的问题

### "汉化失败了"
1. 检查 yt-dlp 是否需要更新（点「更新内核」）
2. 检查字幕是否下载成功（看 downloads/subtitles/）
3. 检查 Python 是否安装
4. 检查 pip 包是否安装

### "翻译不准确"
- 这是 Google Translate 的限制
- 建议用户找有中文字幕的视频（YouTube 自带的最好）
- 如果要改进翻译，修改 `dubber.py` 的 `translate_batch()` 函数

### "语音听起来机械"
- 这是 Edge TTS 的限制
- 可以尝试换语音（男声2/女声2）
- 如果要更好的语音，需要付费 API

### "下载失败"
- 大概率是 yt-dlp 版本过旧
- 让用户点「更新内核」
- 如果更新也失败，手动下载新版 yt-dlp.exe 替换 bin/ 下的文件

### "界面打不开"
- 检查 PowerShell 执行策略
- 尝试直接运行 `start.bat`
- 检查 launcher.ps1 是否存在

## 修改代码的注意事项

### 编码问题
- `launcher.ps1` 必须用 **UTF-8 BOM** 编码保存
- 保存后用这个命令重新编码：
```powershell
$content = Get-Content -Path '文件路径' -Raw -Encoding UTF8
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText('文件路径', $content, $utf8bom)
```

### dubber.py 修改后
- 直接保存即可（Python 默认 UTF-8）
- 测试时用命令行运行：
```bash
python D:\YouTube汉化工具\bin\dubber.py "YouTube链接" --mode srt
```

### launcher.ps1 修改后
- 需要重新用上面的命令保存为 UTF-8 BOM
- 测试时双击桌面快捷方式

## 文件路径

所有路径都是相对于 `D:\YouTube汉化工具\`：
- 视频下载到：`downloads\videos\`
- 音频下载到：`downloads\audio\`
- 字幕下载到：`downloads\subtitles\`
- 临时文件：系统 temp 目录（自动清理）

## 关键函数说明

### dubber.py

| 函数 | 作用 |
|------|------|
| `download(url)` | 下载视频+字幕 |
| `parse_srt(path)` | 解析 SRT 字幕文件 |
| `translate(entries)` | 翻译字幕 |
| `gen_voice_per_sentence(entries, dir, voice)` | 逐句生成 TTS |
| `merge_dub(video, tts, output)` | 合成最终视频 |
| `tts_gen(text, output, voice, rate)` | 单句 TTS 生成 |

### launcher.ps1

| 函数 | 作用 |
|------|------|
| `Find-Python` | 查找 Python 安装 |
| `Install-Python` | 自动安装 Python |
| `Ensure-PipPackages` | 检查/安装 pip 包 |
| `Run-YtDlp` | 运行 yt-dlp 命令 |
| `New-Btn` | 创建按钮控件 |

## 调试技巧

### 测试 yt-dlp
```bash
D:\YouTube汉化工具\bin\yt-dlp.exe --print title "YouTube链接"
```

### 测试 ffmpeg
```bash
D:\YouTube汉化工具\bin\ffmpeg.exe -version
```

### 测试 Python
```bash
python --version
python -c "import edge_tts; print('OK')"
python -c "import deep_translator; print('OK')"
```

### 测试 TTS
```bash
python -c "
import asyncio, edge_tts
async def test():
    c = edge_tts.Communicate('你好世界', 'zh-CN-XiaoxiaoNeural')
    await c.save('test.mp3')
asyncio.run(test())
"
```

### 测试翻译
```bash
python -c "
from deep_translator import GoogleTranslator
result = GoogleTranslator(source='en', target='zh-CN').translate('Hello world')
print(result)
"
```

## 常见修改场景

### 1. 用户想换翻译引擎
修改 `dubber.py` 的 `translate_batch()` 函数

### 2. 用户想换 TTS 声音
修改 `dubber.py` 的 `VOICES` 字典

### 3. 用户想调整背景音量
修改 `dubber.py` 的 `merge_dub()` 函数中的 `volume=0.08`

### 4. 用户想调整语速
修改 `dubber.py` 的 `gen_voice_per_sentence()` 函数中的 `rate = "+25%"`

### 5. 用户想加新按钮
修改 `launcher.ps1`，添加 Button 和对应的 Add_Click 事件

### 6. 用户想改下载目录
修改 `dubber.py` 的 `DOWNLOAD_DIR` 变量

## 不要做的事情

1. 不要删除 bin/ 下的任何文件
2. 不要修改 yt-dlp.exe 或 ffmpeg.exe
3. 不要用 ANSI 编码保存 launcher.ps1
4. 不要在 dubber.py 中用 print() 输出中文到 Windows 控制台（会乱码）
5. 不要让用户手动安装 Python（工具会自动处理）

## 测试清单

修改后至少测试：
- [ ] 双击桌面快捷方式能打开
- [ ] 粘贴链接后点「汉化视频」能运行
- [ ] 能生成 .zh.mp4 文件
- [ ] 生成的视频有中文语音
- [ ] 生成的视频时长和原视频一致
