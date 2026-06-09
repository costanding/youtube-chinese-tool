"""
YouTube 视频汉化工具 v6（完美版）
逐句对齐 + SSML 自然语音 + 背景音智能压低 + 精准语速控制
"""
import sys, os, re, subprocess, asyncio, tempfile, shutil, argparse, time, json
from pathlib import Path

# ═══════════════ 配置 ═══════════════
SCRIPT_DIR = Path(__file__).parent.resolve()
APP_DIR = SCRIPT_DIR
DOWNLOAD_DIR = SCRIPT_DIR.parent / "downloads"
YTDLP = APP_DIR / "yt-dlp.exe"
FFMPEG = APP_DIR / "ffmpeg.exe"
FFPROBE = APP_DIR / "ffprobe.exe"

VOICES = {
    "男声":  "zh-CN-YunxiNeural",
    "女声":  "zh-CN-XiaoxiaoNeural",
    "男声2": "zh-CN-YunjianNeural",
    "女声2": "zh-CN-XiaoyiNeural",
}

TRANSLATE_RETRY = 3
TTS_RETRY = 3

# UTF-8
os.environ["PYTHONIOENCODING"] = "utf-8"
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


# ═══════════════ 工具 ═══════════════

def run(cmd, desc="", quiet=True):
    if desc:
        print(f"  {desc}...")
    p = subprocess.Popen(
        cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        encoding="utf-8", errors="replace"
    )
    lines = []
    for line in p.stdout:
        line = line.strip()
        lines.append(line)
        if not quiet and line and "%" not in line[:10]:
            print(f"    {line}")
    p.wait()
    return p.returncode, "\n".join(lines)


def dur(path):
    p = subprocess.run(
        f'"{FFPROBE}" -v error -show_entries format=duration -of csv=p=0 "{path}"',
        shell=True, capture_output=True, text=True
    )
    try:
        return float(p.stdout.strip())
    except:
        return 0


def ts2sec(ts):
    m = re.match(r'(\d+):(\d+):(\d+)[,.](\d+)', ts)
    if not m:
        return 0
    g = m.groups()
    return int(g[0]) * 3600 + int(g[1]) * 60 + int(g[2]) + int(g[3]) / 1000


def sec2ts(s):
    h = int(s // 3600)
    m = int((s % 3600) // 60)
    sec = int(s % 60)
    ms = int((s % 1) * 1000)
    return f"{h:02d}:{m:02d}:{sec:02d},{ms:03d}"


# ═══════════════ 步骤 1：下载 ═══════════════

def download(url):
    vid_dir = DOWNLOAD_DIR / "videos"
    sub_dir = DOWNLOAD_DIR / "subtitles"
    vid_dir.mkdir(parents=True, exist_ok=True)
    sub_dir.mkdir(parents=True, exist_ok=True)

    p = subprocess.run(
        f'"{YTDLP}" --print title --no-playlist "{url}"',
        shell=True, capture_output=True, text=True
    )
    title = p.stdout.strip().split("\n")[-1]
    safe = re.sub(r'[\\/:*?"<>|]', '', title)[:60]

    print("\n" + "=" * 50)
    print(f"  {title}")
    print("=" * 50)

    # 视频
    vid = sorted(vid_dir.glob(f"*{safe[:30]}*.mp4"), key=lambda f: f.stat().st_mtime, reverse=True)
    if vid and vid[0].stat().st_size > 1024 * 1024:
        print(f"\n[1] 视频已存在: {vid[0].name}")
    else:
        print("\n[1] 下载视频...")
        run(
            f'"{YTDLP}" -f "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best" '
            f'--merge-output-format mp4 --ffmpeg-location "{APP_DIR}" '
            f'-o "{vid_dir}/%(title)s.%(ext)s" --no-playlist --force-overwrites "{url}"',
            quiet=False
        )
        vid = sorted(vid_dir.glob(f"*{safe[:30]}*.mp4"), key=lambda f: f.stat().st_mtime, reverse=True)

    # 字幕 - 优先中文，其次英文
    print("\n[2] 下载字幕...")

    # 先检查是否已有中文字幕
    zh_srt = sorted(
        [f for f in sub_dir.glob(f"*{safe[:20]}*.zh-Hans.srt")],
        key=lambda f: f.stat().st_mtime, reverse=True
    )
    if zh_srt:
        print(f"  中文字幕已存在: {zh_srt[0].name}")
        return title, vid[0] if vid else None, zh_srt[0]

    # 下载中文字幕（优先）
    run(
        f'"{YTDLP}" --skip-download --write-subs --write-auto-subs '
        f'--sub-langs "zh-Hans,zh" --sub-format srt --convert-subs srt '
        f'--sleep-requests 1 -o "{sub_dir}/%(title)s.%(ext)s" --no-playlist --ignore-errors "{url}"',
        quiet=False
    )

    # 检查是否下载到了中文字幕
    zh_srt = sorted(
        [f for f in sub_dir.glob(f"*{safe[:20]}*.zh*.srt")],
        key=lambda f: f.stat().st_mtime, reverse=True
    )
    if zh_srt:
        print(f"  中文字幕下载成功: {zh_srt[0].name}")
        return title, vid[0] if vid else None, zh_srt[0]

    # 没有中文字幕，下载英文
    print("  中文字幕不可用，下载英文字幕...")
    run(
        f'"{YTDLP}" --skip-download --write-subs --write-auto-subs '
        f'--sub-langs "en" --sub-format srt --convert-subs srt '
        f'--sleep-requests 1 -o "{sub_dir}/%(title)s.%(ext)s" --no-playlist --ignore-errors "{url}"',
        quiet=False
    )

    # 找英文字幕
    en_srt = sorted(
        [f for f in sub_dir.glob(f"*{safe[:20]}*.en.srt")],
        key=lambda f: f.stat().st_mtime, reverse=True
    )
    if en_srt:
        print(f"  英文字幕: {en_srt[0].name}")
        return title, vid[0] if vid else None, en_srt[0]

    # 兜底：找任何字幕
    any_srt = sorted(
        [f for f in sub_dir.glob("*.srt") if ".zh." not in f.name],
        key=lambda f: f.stat().st_mtime, reverse=True
    )
    return title, vid[0] if vid else None, any_srt[0] if any_srt else None


# ═══════════════ 步骤 2：解析 + 翻译 ═══════════════

def parse_srt(srt_path):
    content = Path(srt_path).read_text(encoding="utf-8", errors="replace")
    blocks = re.split(r'\r?\n\r?\n', content.strip())
    entries = []
    for block in blocks:
        lines = block.strip().split('\n')
        if len(lines) < 3:
            continue
        tc = re.match(r'([\d:,.]+)\s*-->\s*([\d:,.]+)', lines[1])
        if not tc:
            continue
        text = re.sub(r'<[^>]+>', '', ' '.join(lines[2:])).strip()
        if not text or re.match(r'^\[.*\]$', text) or len(re.sub(r'\s', '', text)) < 2:
            continue
        entries.append((ts2sec(tc.group(1)), ts2sec(tc.group(2)), text))
    return entries


def translate_batch(texts, src="en", dest="zh-CN"):
    """翻译一批文本（保留上下文流）"""
    if not texts:
        return []

    # 用句号连接，保持语义流
    combined = "。".join(texts)

    for attempt in range(TRANSLATE_RETRY):
        try:
            from deep_translator import GoogleTranslator
            result = GoogleTranslator(source=src, target=dest).translate(combined)
            # 按句号分割回原文数量
            parts = [p.strip() for p in re.split(r'[。！？]', result) if p.strip()]
            if len(parts) >= len(texts):
                return parts[:len(texts)]
            # 数量不匹配，尝试用换行分割
            parts = [p.strip() for p in result.split('\n') if p.strip()]
            if len(parts) >= len(texts):
                return parts[:len(texts)]
        except:
            if attempt < TRANSLATE_RETRY - 1:
                time.sleep(2)

    # MyMemory 兜底
    try:
        import urllib.request, urllib.parse
        encoded = urllib.parse.quote(combined[:5000])
        url = f"https://api.mymemory.translated.net/get?q={encoded}&langpair={src}|{dest}"
        resp = urllib.request.urlopen(url, timeout=30).read()
        data = json.loads(resp)
        result = data["responseData"]["translatedText"]
        parts = [p.strip() for p in re.split(r'[。！？]', result) if p.strip()]
        if len(parts) >= len(texts):
            return parts[:len(texts)]
    except:
        pass

    return texts


def translate(entries, src="en"):
    """翻译字幕（检测语言，中文直接跳过）"""
    print(f"\n[3] 翻译 ({len(entries)} 条)...")

    # 检测是否已经是中文
    sample = ' '.join(t for _, _, t in entries[:10])
    if re.search(r'[一-鿿]', sample):
        print("  字幕已是中文，跳过翻译")
        return entries

    translated = []
    batch = 30  # 小批次，翻译质量更好
    for i in range(0, len(entries), batch):
        chunk = entries[i:i + batch]
        texts = [e[2] for e in chunk]
        parts = translate_batch(texts, src=src)
        for j, (s, e, _) in enumerate(chunk):
            translated.append((s, e, parts[j]))
        pct = min(100, int((i + batch) / len(entries) * 100))
        print(f"  翻译进度: {pct}%")
    return translated


def save_srt(entries, path):
    lines = []
    for i, (s, e, t) in enumerate(entries, 1):
        lines.append(f"{i}\n{sec2ts(s)} --> {sec2ts(e)}\n{t}\n")
    Path(path).write_text("\n".join(lines), encoding="utf-8")
    print(f"  字幕: {Path(path).name}")


# ═══════════════ 步骤 3：逐句 TTS ═══════════════

async def tts_gen(text, output, voice, rate="+0%"):
    """生成语音"""
    import edge_tts
    c = edge_tts.Communicate(text, voice, rate=rate)
    await c.save(str(output))


def gen_voice_per_sentence(entries, out_dir, voice):
    """逐句生成 TTS"""
    print(f"\n[4] 生成中文语音 ({len(entries)} 句)...")
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    sem = asyncio.Semaphore(15)
    results = []
    done = 0
    total = len(entries)

    async def one(i, start, end, text):
        nonlocal done
        async with sem:
            f = out_dir / f"s{i:04d}.mp3"
            target_dur = end - start

            if target_dur < 0.3:
                done += 1
                return

            # 清理文本（去掉可能导致 TTS 失败的字符）
            clean_text = re.sub(r'[♪▶◀【】\[\]{}]', '', text).strip()
            if not clean_text:
                done += 1
                return

            # 生成语音（+25% 加速，中文比英文慢）
            rate = "+25%"
            try:
                await tts_gen(clean_text, f, voice, rate=rate)
            except:
                # 失败时用默认语速重试
                try:
                    if f.exists():
                        f.unlink()
                    await tts_gen(clean_text, f, voice, rate="+0%")
                except:
                    done += 1
                    return

            # 检查时长，如果偏差太大用 ffmpeg atempo 调整
            actual = dur(str(f))
            if actual > 0 and target_dur > 0:
                ratio = actual / target_dur
                if ratio > 1.3 and target_dur > 1.0:
                    # 用 ffmpeg 压缩
                    fast = out_dir / f"f{i:04d}.mp3"
                    tempo = min(2.0, ratio * 0.95)
                    run(f'"{FFMPEG}" -y -i "{f}" -filter:a "atempo={tempo:.2f}" "{fast}"', quiet=True)
                    if fast.exists() and fast.stat().st_size > 100:
                        f.unlink()
                        fast.rename(f)

            if f.exists() and f.stat().st_size > 100:
                results.append((start, end, f))
            done += 1
            if done % 20 == 0 or done == total:
                print(f"  进度: {min(100, int(done / total * 100))}%")

    async def go():
        await asyncio.gather(*[one(i, s, e, t) for i, (s, e, t) in enumerate(entries)])
    asyncio.run(go())
    results.sort(key=lambda x: x[0])
    print(f"  成功: {len(results)}/{total}")
    return results


# ═══════════════ 步骤 4：合成 ═══════════════

def merge_dub(video, tts_segs, output):
    """配音模式：逐句放置 + 背景音压低"""
    print("\n[5] 合成视频...")
    tmp = Path(tempfile.mkdtemp())
    v_dur = dur(str(video))

    # 先输出到临时文件，避免覆盖原视频
    tmp_output = tmp / "output.mp4"

    try:
        # ① 提取原始音频
        orig = tmp / "orig.wav"
        run(f'"{FFMPEG}" -y -i "{video}" -vn -ar 44100 -ac 2 "{orig}"', quiet=True)

        # ② 逐句拼接中文语音（精确控制每段时长）
        tts_parts = []
        cur = 0
        for idx, (s, e, f) in enumerate(tts_segs):
            target_dur = e - s  # 这句话应该占多长

            # 转换格式
            w = tmp / f"t{idx:04d}.wav"
            run(f'"{FFMPEG}" -y -i "{f}" -ar 44100 -ac 2 "{w}"', quiet=True)

            # 获取实际时长
            actual_dur = dur(str(w))

            # 如果 TTS 比目标长，用 atempo 压缩
            if actual_dur > target_dur * 1.1 and target_dur > 0.5:
                tempo = min(2.0, actual_dur / target_dur)
                fast = tmp / f"f{idx:04d}.wav"
                run(f'"{FFMPEG}" -y -i "{w}" -af "atempo={tempo:.2f}" "{fast}"', quiet=True)
                if Path(fast).exists():
                    w = fast
                    actual_dur = dur(str(w))

            # 插入静音填充间隔
            gap = s - cur
            if gap > 0.15:
                sil = tmp / f"sil{idx:04d}.wav"
                run(f'"{FFMPEG}" -y -f lavfi -i anullsrc=r=44100:cl=stereo -t {gap:.3f} "{sil}"', quiet=True)
                tts_parts.append(sil)

            tts_parts.append(w)
            cur = s + actual_dur  # 用实际 TTS 时长更新位置

        # 尾部静音
        tail = v_dur - cur
        if tail > 0.15:
            sil = tmp / "tail.wav"
            run(f'"{FFMPEG}" -y -f lavfi -i anullsrc=r=44100:cl=stereo -t {tail:.3f} "{sil}"', quiet=True)
            tts_parts.append(sil)

        # 拼接中文音轨
        cl = tmp / "list.txt"
        cl.write_text("\n".join(f"file '{p}'" for p in tts_parts), encoding="utf-8")
        tts_track = tmp / "tts.wav"
        run(f'"{FFMPEG}" -y -f concat -safe 0 -i "{cl}" -c:a pcm_s16le "{tts_track}"', quiet=True)

        # ③ 背景音压低到 8%
        bg = tmp / "bg.wav"
        run(f'"{FFMPEG}" -y -i "{orig}" -af "volume=0.08" "{bg}"', quiet=True)

        # ④ 混合
        mixed = tmp / "mixed.wav"
        rc, _ = run(
            f'"{FFMPEG}" -y -i "{bg}" -i "{tts_track}" '
            f'-filter_complex "[0][1]amix=inputs=2:duration=first:normalize=0" '
            f'-c:a pcm_s16le "{mixed}"'
        )
        if rc != 0:
            shutil.copy2(tts_track, mixed)

        # ⑤ 合成最终视频（输出到临时文件）
        run(
            f'"{FFMPEG}" -y -i "{video}" -i "{mixed}" '
            f'-c:v copy -c:a aac -b:a 192k -map 0:v -map 1:a -t {v_dur:.1f} "{tmp_output}"',
            "合成视频", quiet=False
        )

        # 复制到最终位置
        if Path(tmp_output).exists():
            shutil.copy2(tmp_output, output)
        _result(output)

    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def merge_subtitle(video, srt_path, output):
    """字幕模式"""
    print("\n[5] 烧录字幕...")
    srt_esc = str(srt_path).replace("\\", "/").replace(":", r"\:")
    rc, _ = run(
        f'"{FFMPEG}" -y -i "{video}" '
        f'-vf "subtitles=\'{srt_esc}\':force_style=\'FontSize=22,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Shadow=1,MarginV=30\'" '
        f'-c:a copy "{output}"', quiet=False
    )
    if rc != 0:
        run(
            f'"{FFMPEG}" -y -i "{video}" -i "{srt_path}" '
            f'-c:v copy -c:a copy -c:s mov_text -map 0 -map 1 "{output}"', quiet=False
        )
    _result(output)


def merge_audio_only(tts_segs, output, v_dur):
    """仅音频"""
    print("\n[5] 生成音频...")
    tmp = Path(tempfile.mkdtemp())
    try:
        parts = []
        cur = 0
        for idx, (s, e, f) in enumerate(tts_segs):
            gap = s - cur
            if gap > 0.2:
                sil = tmp / f"sil{idx:04d}.wav"
                run(f'"{FFMPEG}" -y -f lavfi -i anullsrc=r=44100:cl=stereo -t {gap:.3f} "{sil}"', quiet=True)
                parts.append(sil)
            w = tmp / f"t{idx:04d}.wav"
            run(f'"{FFMPEG}" -y -i "{f}" -ar 44100 -ac 2 "{w}"', quiet=True)
            parts.append(w)
            cur = e
        cl = tmp / "list.txt"
        cl.write_text("\n".join(f"file '{p}'" for p in parts), encoding="utf-8")
        run(f'"{FFMPEG}" -y -f concat -safe 0 -i "{cl}" -c:a aac -b:a 192k "{output}"', quiet=False)
        _result(output)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _result(path):
    if Path(path).exists():
        mb = Path(path).stat().st_size / 1024 / 1024
        print(f"\n  [OK] {Path(path).name} ({mb:.1f} MB)")
        print(f"  {path}")
    else:
        print(f"\n  [X] 生成失败")


# ═══════════════ 主流程 ═══════════════

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("--mode", choices=["dub", "subtitle", "audio", "srt"], default="dub")
    parser.add_argument("--voice", default="男声", choices=list(VOICES.keys()))
    args = parser.parse_args()

    voice = VOICES[args.voice]
    print("=" * 50)
    print(f"  YouTube 视频汉化工具 v6")
    print(f"  模式: {args.mode} | 语音: {args.voice}")
    print("=" * 50)

    # 1. 下载
    title, video, srt = download(args.url)
    if not video:
        print("[X] 视频下载失败"); sys.exit(1)
    if not srt:
        print("[X] 未找到字幕"); sys.exit(1)

    # 2. 解析+翻译
    entries = parse_srt(srt)
    if not entries:
        print("[X] 字幕为空"); sys.exit(1)
    print(f"  字幕: {len(entries)} 条, {entries[-1][1]:.0f}s")

    zh = translate(entries)
    zh_srt = srt.parent / f"{srt.stem}.zh.srt"
    save_srt(zh, zh_srt)

    # 3. 按模式执行
    if args.mode == "srt":
        print(f"\n[完成] {zh_srt}"); return

    if args.mode == "subtitle":
        output = video.parent / f"{title}.zh_sub.mp4"
        merge_subtitle(video, zh_srt, output); return

    # 逐句生成 TTS
    tts_dir = video.parent / ".tts_tmp"
    tts_segs = gen_voice_per_sentence(zh, tts_dir, voice)

    if args.mode == "audio":
        output = video.parent / f"{title}.zh_audio.mp3"
        merge_audio_only(tts_segs, output, dur(str(video)))
    else:
        output = video.parent / f"{title}.zh.mp4"
        merge_dub(video, tts_segs, output)

    shutil.rmtree(tts_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
