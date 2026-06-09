# YouTube 汉化工具

把英文 YouTube 视频变成中文版。

## 功能

- **汉化视频**：下载 + 翻译 + 中文配音
- **下载视频**：最高画质 H.264 MP4
- **下载音频**：提取为 MP3
- **下载字幕**：英/中/日字幕
- **视频信息**：查看标题、时长等

## 汉化模式

| 模式 | 说明 |
|------|------|
| 配音+背景音 | 中文语音替换英文，保留背景音乐（推荐） |
| 仅字幕嵌入 | 不配音，只把中文字幕烧到视频画面上 |
| 仅生成音频 | 只生成中文音频文件（MP3） |
| 仅字幕文件 | 只生成 SRT 字幕 |

## 使用方法

1. 双击 `start.bat` 启动
2. 粘贴 YouTube 链接
3. 选择男声/女声
4. 点「汉化视频」
5. 等待完成

## 文件结构

```
YouTube汉化工具/
├── bin/              # 引擎文件
│   ├── yt-dlp.exe   # YouTube 下载
│   ├── ffmpeg.exe    # 视频处理
│   ├── ffprobe.exe   # 视频信息读取
│   └── dubber.py     # 汉化核心代码
├── downloads/        # 下载的内容
├── launcher.ps1      # 界面
├── start.bat         # 启动器
└── README.md
```

## 语音选择

- 男声：自然男声（默认）
- 女声：自然女声
- 男声2/女声2：备选声音

## 常见问题

**Q: 提示 Python 未安装？**
A: 点「是」自动安装，或手动安装 Python 3.10+

**Q: 翻译失败？**
A: 工具会自动重试 3 次，并使用备用翻译引擎

**Q: 字幕下载失败？**
A: YouTube 限流，等几分钟重试

**Q: 汉化后音画不同步？**
A: 工具会自动调整语速对齐，如有偏差可选「仅字幕嵌入」模式

## 系统要求

- Windows 10/11
- 联网
- Python 3.10+（首次使用自动安装）

## 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/costanding/youtube-chinese-tool.git
```

### 2. 下载依赖工具
由于文件较大，以下工具需要单独下载并放入 `bin/` 目录：

- **yt-dlp**: https://github.com/yt-dlp/yt-dlp/releases
- **ffmpeg**: https://github.com/BtbN/FFmpeg-Builds/releases
- **ffprobe**: 随 ffmpeg 一起提供

下载后将 `yt-dlp.exe`、`ffmpeg.exe`、`ffprobe.exe` 放入 `bin/` 目录。

### 3. 运行
双击 `start.bat` 启动程序。

## 分享给朋友

双击 `pack.bat`，会生成一个 zip 文件，发给朋友解压后双击 `start.bat` 即可。
