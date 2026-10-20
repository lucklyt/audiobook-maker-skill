#!/usr/bin/env python3
"""
Audiobook Maker CLI Script
Converts audio chapters into standard, chapter-indexed M4B audiobooks for Apple Books, Audiobookshelf, etc.
Cross-platform: Windows, macOS, Linux.
Pure Python 3 standard library; manages ffmpeg automatically.
"""

import os
import sys
import re
import json
import shutil
import platform
import tempfile
import argparse
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path

# Fix console encoding on Windows to support Chinese and emojis
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

AUDIO_EXTENSIONS = {'.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.opus', '.aiff', '.wma'}

def find_or_install_ffmpeg():
    """Find ffmpeg/ffprobe executable or guide installation across macOS, Windows, Linux."""
    system = platform.system()
    candidates = [shutil.which('ffmpeg')]

    if system == "Darwin":
        candidates.extend([
            '/opt/homebrew/bin/ffmpeg',
            '/usr/local/bin/ffmpeg',
            str(Path.home() / 'AudiobookMaker/.build/ffmpeg-engine/distribution/ffmpeg'),
            '/Applications/Audiobook Maker.app/Contents/Helpers/ffmpeg'
        ])
    elif system == "Windows":
        local_app_data = os.environ.get('LOCALAPPDATA', '')
        user_profile = os.environ.get('USERPROFILE', '')
        candidates.extend([
            os.path.join(local_app_data, 'Microsoft', 'WinGet', 'Links', 'ffmpeg.exe'),
            os.path.join(user_profile, 'scoop', 'shims', 'ffmpeg.exe'),
            r'C:\ffmpeg\bin\ffmpeg.exe',
            r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
            os.path.join(local_app_data, 'ffmpeg', 'bin', 'ffmpeg.exe'),
            str(Path.home() / '.local' / 'bin' / 'ffmpeg.exe')
        ])
    else:  # Linux
        candidates.extend([
            '/usr/bin/ffmpeg',
            '/usr/local/bin/ffmpeg',
            str(Path.home() / '.local' / 'bin' / 'ffmpeg')
        ])

    ffmpeg_bin = None
    for c in candidates:
        if c and os.path.isfile(c) and os.access(c, os.X_OK):
            ffmpeg_bin = str(Path(c).resolve())
            break

    # If missing, attempt automatic installation
    if not ffmpeg_bin:
        print(f"[!] 未检测到 ffmpeg，正在尝试为当前系统 ({system}) 自动配置...")
        if system == "Darwin":
            brew_bin = shutil.which('brew') or ('/opt/homebrew/bin/brew' if os.path.exists('/opt/homebrew/bin/brew') else None)
            if brew_bin:
                print(" -> 检测到 Homebrew，正在执行: brew install ffmpeg ...")
                res = subprocess.run([brew_bin, 'install', 'ffmpeg'])
                if res.returncode == 0:
                    ffmpeg_bin = shutil.which('ffmpeg') or '/opt/homebrew/bin/ffmpeg'
        elif system == "Windows":
            winget = shutil.which('winget')
            if winget:
                print(" -> 检测到 WinGet 包管理器，正在执行: winget install Gyan.FFmpeg ...")
                res = subprocess.run([winget, 'install', '--id', 'Gyan.FFmpeg', '-e', '--accept-package-agreements', '--accept-source-agreements'])
                if res.returncode == 0:
                    ffmpeg_bin = shutil.which('ffmpeg')
            if not ffmpeg_bin and shutil.which('scoop'):
                print(" -> 检测到 Scoop，正在执行: scoop install ffmpeg ...")
                subprocess.run(['scoop', 'install', 'ffmpeg'])
                ffmpeg_bin = shutil.which('ffmpeg')
            if not ffmpeg_bin and shutil.which('choco'):
                print(" -> 检测到 Chocolatey，正在执行: choco install ffmpeg -y ...")
                subprocess.run(['choco', 'install', 'ffmpeg', '-y'])
                ffmpeg_bin = shutil.which('ffmpeg')
        else:  # Linux
            for pm, cmd in [('apt-get', ['sudo', 'apt-get', 'update', '-y', '&&', 'sudo', 'apt-get', 'install', '-y', 'ffmpeg']),
                            ('dnf', ['sudo', 'dnf', 'install', '-y', 'ffmpeg']),
                            ('pacman', ['sudo', 'pacman', '-S', '--noconfirm', 'ffmpeg'])]:
                if shutil.which(pm):
                    print(f" -> 检测到 {pm}，正在尝试自动安装 FFmpeg...")
                    subprocess.run(' '.join(cmd), shell=True)
                    ffmpeg_bin = shutil.which('ffmpeg')
                    break

    if not ffmpeg_bin:
        sys.exit(f"[错误] 无法找到或自动安装 ffmpeg。请先手动安装 ffmpeg 并加入系统环境变量 PATH。")

    # Find ffprobe
    probe_candidates = [
        shutil.which('ffprobe'),
        str(Path(ffmpeg_bin).parent / ('ffprobe.exe' if system == 'Windows' else 'ffprobe'))
    ]
    if system == "Darwin":
        probe_candidates.extend([
            '/opt/homebrew/bin/ffprobe',
            '/usr/local/bin/ffprobe',
            str(Path.home() / 'AudiobookMaker/.build/ffmpeg-engine/distribution/ffprobe')
        ])

    ffprobe_bin = None
    for p in probe_candidates:
        if p and os.path.isfile(p) and os.access(p, os.X_OK):
            ffprobe_bin = str(Path(p).resolve())
            break

    return ffmpeg_bin, ffprobe_bin

def natural_sort_key(s):
    """Sort strings with numbers naturally: 1, 2, 10 instead of 1, 10, 2."""
    def convert(text):
        if text.isdigit():
            return int(text)
        return text.lower()
    return [convert(c) for c in re.split(r'(\d+)', str(s))]

def get_audio_duration(file_path, ffprobe_bin, ffmpeg_bin):
    """Accurately retrieve audio duration in seconds."""
    if ffprobe_bin:
        cmd = [
            ffprobe_bin, '-v', 'quiet', '-show_entries', 'format=duration',
            '-of', 'json', str(file_path)
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            try:
                dur = float(json.loads(res.stdout)['format']['duration'])
                if dur > 0:
                    return dur
            except Exception:
                pass

    # Fallback to ffmpeg
    cmd = [ffmpeg_bin, '-i', str(file_path), '-f', 'null', '-']
    res = subprocess.run(cmd, capture_output=True, text=True)
    m = re.search(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)', res.stderr)
    if m:
        h, m, s = float(m.group(1)), float(m.group(2)), float(m.group(3))
        return h * 3600 + m * 60 + s
    return 0.0

def resolve_cover_image(cover_arg, input_dir, temp_dir):
    """Resolve cover image from URL, explicit file, or directory scan."""
    if cover_arg:
        if cover_arg.startswith(('http://', 'https://')):
            print(f"[*] 检测到封面为网络 URL，正在下载: {cover_arg} ...")
            target_file = Path(temp_dir) / "downloaded_cover.jpg"
            req = urllib.request.Request(
                cover_arg,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Referer': 'https://book.douban.com'
                }
            )
            try:
                with urllib.request.urlopen(req, timeout=15) as resp, open(target_file, 'wb') as f:
                    f.write(resp.read())
                print(f"  -> 封面下载成功: {target_file}")
                return str(target_file)
            except Exception as e:
                print(f"[警告] 封面 URL 下载失败 ({e})，将尝试使用本地封面或无封面")
                return None
        elif os.path.exists(cover_arg):
            return str(Path(cover_arg).resolve())

    # Auto-scan in input_dir
    if input_dir and os.path.isdir(input_dir):
        for candidate in ["cover.jpg", "cover.jpeg", "cover.png", "folder.jpg", "front.jpg"]:
            local_p = Path(input_dir) / candidate
            if local_p.is_file():
                print(f"[*] 在输入目录中自动发现封面: {local_p}")
                return str(local_p.resolve())
    return None

def escape_ffmeta(text):
    """Escape special characters for FFMETADATA1 syntax: =, ;, #, \\ and newline."""
    if not text:
        return ""
    text = str(text)
    text = text.replace('\\', '\\\\')
    text = text.replace('=', '\\=')
    text = text.replace(';', '\\;')
    text = text.replace('#', '\\#')
    text = text.replace('\n', '\\\n')
    return text

def clean_chapter_title(filename):
    """Generate a clean chapter title from filename."""
    name = Path(filename).stem
    cleaned = re.sub(r'^\s*0*\d+[\s._\-–—:：]+', '', name)
    return cleaned if cleaned.strip() else name

def make_audiobook(
    audio_files,
    output_path,
    title,
    author="未知作者",
    cover_image=None,
    genre="Audiobook",
    year="2026",
    publisher="",
    language="Chinese",
    summary="",
    chapter_titles=None,
    bitrate="96k",
    input_dir=None
):
    ffmpeg_bin, ffprobe_bin = find_or_install_ffmpeg()
    output_path = Path(output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if not input_dir and audio_files:
        input_dir = audio_files[0].parent

    print(f"[*] 准备处理 {len(audio_files)} 个章节音频...")
    chapters = []
    total_duration = 0.0

    for i, file_path in enumerate(audio_files):
        dur = get_audio_duration(file_path, ffprobe_bin, ffmpeg_bin)
        if dur <= 0:
            print(f"[警告] 无法读取音频时长，跳过: {file_path}")
            continue

        if chapter_titles and i < len(chapter_titles) and chapter_titles[i]:
            ch_title = chapter_titles[i]
        else:
            ch_title = clean_chapter_title(file_path)

        chapters.append({
            'index': i + 1,
            'file': str(file_path),
            'title': ch_title,
            'duration': dur
        })
        total_duration += dur
        m, s = divmod(int(dur), 60)
        print(f"  [{i+1}/{len(audio_files)}] {ch_title} ({m}分{s}秒 / {dur:.1f}s)")

    if not chapters:
        sys.exit("[错误] 没有有效的音频章节输入。")

    h, rem = divmod(int(total_duration), 3600)
    m, s = divmod(rem, 60)
    print(f"[*] 识别完成，总时长: {h}小时{m}分{s}秒 ({total_duration:.1f}s)")

    # Build FFMETADATA and concat list in a temp directory
    with tempfile.TemporaryDirectory(prefix="audiobook_maker_") as temp_dir:
        temp_path = Path(temp_dir)
        meta_file = temp_path / "metadata.txt"
        concat_file = temp_path / "concat.txt"

        # Concat list: use forward slashes (Path.as_posix()) for cross-platform FFmpeg compatibility
        with open(concat_file, 'w', encoding='utf-8') as f:
            for ch in chapters:
                clean_path = Path(ch['file']).resolve().as_posix().replace("'", "'\\''")
                f.write(f"file '{clean_path}'\n")

        # FFMETADATA
        lang_map = {
            "chinese": "zho", "中文": "zho", "普通话": "zho",
            "english": "eng", "英语": "eng", "英文": "eng"
        }
        lang_code = lang_map.get(language.strip().lower(), language.strip().lower() if len(language.strip()) == 3 else "zho")

        meta_lines = [
            ";FFMETADATA1",
            f"title={escape_ffmeta(title)}",
            f"artist={escape_ffmeta(author)}",
            f"album_artist={escape_ffmeta(author)}",
            f"album={escape_ffmeta(title)}",
            f"genre={escape_ffmeta(genre)}",
            f"date={escape_ffmeta(year)}",
            "media_type=2"
        ]
        if publisher:
            meta_lines.append(f"comment={escape_ffmeta('Publisher: ' + publisher)}")
        if summary:
            meta_lines.append(f"description={escape_ffmeta(summary)}")

        current_ms = 0
        for ch in chapters:
            duration_ms = int(round(ch['duration'] * 1000))
            end_ms = current_ms + duration_ms
            meta_lines.extend([
                "[CHAPTER]",
                "TIMEBASE=1/1000",
                f"START={current_ms}",
                f"END={end_ms}",
                f"title={escape_ffmeta(ch['title'])}"
            ])
            current_ms = end_ms

        meta_file.write_text("\n".join(meta_lines) + "\n", encoding='utf-8')

        # Resolve cover image
        resolved_cover = resolve_cover_image(cover_image, input_dir, temp_dir)

        # Build ffmpeg command
        cmd = [
            ffmpeg_bin, '-y', '-hide_banner',
            '-f', 'concat', '-safe', '0', '-i', str(concat_file),
            '-i', str(meta_file)
        ]

        if resolved_cover and os.path.exists(resolved_cover):
            cmd.extend(['-i', str(resolved_cover)])
            cmd.extend([
                '-map', '0:a:0',
                '-map_metadata', '1',
                '-map_chapters', '1',
                '-map', '2:v:0',
                '-c:v', 'mjpeg',
                '-disposition:v:0', 'attached_pic'
            ])
        else:
            cmd.extend([
                '-map', '0:a:0',
                '-map_metadata', '1',
                '-map_chapters', '1'
            ])

        cmd.extend([
            '-c:a', 'aac',
            '-b:a', bitrate,
            '-ar', '44100',
            '-ac', '2',
            '-metadata:s:a:0', f'language={lang_code}',
            '-movflags', '+faststart+disable_chpl',
            '-movie_timescale', '1000',
            '-f', 'ipod',
            str(output_path)
        ])

        print(f"[*] 正在调用 FFmpeg 编码与封装 M4B (码率: {bitrate})...")
        p = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True, encoding='utf-8', errors='replace')
        for line in p.stderr:
            if "time=" in line:
                m = re.search(r'time=(\d+:\d+:\d+\.\d+)', line)
                if m:
                    print(f"\r  -> 当前编码进度时间: {m.group(1)}", end='', flush=True)
        p.wait()
        print()

        if p.returncode != 0:
            sys.exit(f"[错误] FFmpeg 转换失败，退出码: {p.returncode}")

    mb_size = output_path.stat().st_size / (1024 * 1024)
    print(f"\n[成功] 有声书制作完成！")
    print(f"  文件位置: {output_path}")
    print(f"  文件大小: {mb_size:.2f} MB")
    print(f"  章节数量: {len(chapters)} 章")
    print(f"  总 时 长: {h}小时{m}分{s}秒")
    return output_path

def inspect_m4b(m4b_path):
    """Inspect M4B file structure, chapters, and metadata across platforms."""
    ffmpeg_bin, ffprobe_bin = find_or_install_ffmpeg()
    if not ffprobe_bin:
        sys.exit("[错误] 需要 ffprobe 才能检查文件详情。")

    cmd = [ffprobe_bin, '-v', 'quiet', '-show_format', '-show_streams', '-show_chapters', '-of', 'json', str(m4b_path)]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')
    if res.returncode != 0:
        sys.exit(f"[错误] ffprobe 读取失败: {res.stderr}")

    data = json.loads(res.stdout)
    fmt = data.get('format', {})
    tags = fmt.get('tags', {})

    print(f"=== 有声书信息: {Path(m4b_path).name} ===")
    print(f"书名 (Title):       {tags.get('title', 'N/A')}")
    print(f"作者 (Artist):      {tags.get('artist', 'N/A')}")
    print(f"专辑 (Album):       {tags.get('album', 'N/A')}")
    print(f"分类 (Genre):       {tags.get('genre', 'N/A')}")
    print(f"出版年份 (Date):    {tags.get('date', 'N/A')}")
    print(f"出版机构 (Comment): {tags.get('comment', 'N/A')}")
    dur = float(fmt.get('duration', 0))
    h, rem = divmod(int(dur), 3600)
    m, s = divmod(rem, 60)
    print(f"总时长:             {h}小时{m}分{s}秒 ({dur:.1f}s)")
    print(f"大小:               {int(fmt.get('size', 0))/1024/1024:.2f} MB")

    streams = data.get('streams', [])
    for s in streams:
        if s.get('codec_type') == 'audio':
            print(f"音频流:             {s.get('codec_name')} / {s.get('sample_rate')}Hz / {s.get('channels')}ch / 语言: {s.get('tags', {}).get('language', 'und')}")
        elif s.get('codec_type') == 'video':
            print(f"封面图:             {s.get('codec_name')} ({s.get('width')}x{s.get('height')})")

    chapters = data.get('chapters', [])
    print(f"\n=== 章节列表 ({len(chapters)} 章) ===")
    for ch in chapters:
        st = float(ch.get('start_time', 0))
        et = float(ch.get('end_time', 0))
        sh, sm, ss = int(st//3600), int((st%3600)//60), int(st%60)
        eh, em, es = int(et//3600), int((et%3600)//60), int(et%60)
        ch_title = ch.get('tags', {}).get('title', '未命名')
        print(f"  [{sh:02d}:{sm:02d}:{ss:02d} -> {eh:02d}:{em:02d}:{es:02d}] {ch_title}")

def main():
    parser = argparse.ArgumentParser(description="Cross-platform Audiobook Maker CLI")
    parser.add_argument('--input-dir', '-i', help="包含音频章节的目录路径")
    parser.add_argument('--files', '-f', nargs='+', help="手动指定的音频文件列表")
    parser.add_argument('--output', '-o', help="导出的 .m4b 文件路径")
    parser.add_argument('--title', '-t', help="有声书名称 (必填)")
    parser.add_argument('--author', '-a', default="未知作者", help="作者/播音")
    parser.add_argument('--cover', '-c', help="封面图片路径或网络 URL (JPEG/PNG)")
    parser.add_argument('--genre', '-g', default="Audiobook", help="分类/流派")
    parser.add_argument('--year', '-y', default="2026", help="年份")
    parser.add_argument('--publisher', '-p', default="", help="出版机构")
    parser.add_argument('--language', '-l', default="Chinese", help="语言 (默认 Chinese)")
    parser.add_argument('--summary', '-s', default="", help="内容简介")
    parser.add_argument('--bitrate', '-b', default="96k", help="音频码率 (默认 96k)")
    parser.add_argument('--chapter-titles', nargs='+', help="自定义章节标题列表")
    parser.add_argument('--inspect', help="检查已生成的 M4B 文件结构")

    args = parser.parse_args()

    if args.inspect:
        inspect_m4b(args.inspect)
        return

    if not args.title:
        parser.error("制作有声书必须提供 --title 参数。")

    audio_files = []
    if args.files:
        audio_files = [Path(f) for f in args.files]
    elif args.input_dir:
        input_dir = Path(args.input_dir)
        if not input_dir.is_dir():
            sys.exit(f"[错误] 目录不存在: {args.input_dir}")
        for f in input_dir.iterdir():
            if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS:
                audio_files.append(f)
        audio_files.sort(key=natural_sort_key)
    else:
        parser.error("必须通过 --input-dir 或 --files 提供输入音频。")

    if not args.output:
        if args.input_dir:
            args.output = str(Path(args.input_dir).parent / f"{args.title}.m4b")
        else:
            args.output = f"./{args.title}.m4b"

    make_audiobook(
        audio_files=audio_files,
        output_path=args.output,
        title=args.title,
        author=args.author,
        cover_image=args.cover,
        genre=args.genre,
        year=args.year,
        publisher=args.publisher,
        language=args.language,
        summary=args.summary,
        chapter_titles=args.chapter_titles,
        bitrate=args.bitrate,
        input_dir=args.input_dir
    )

if __name__ == '__main__':
    main()
