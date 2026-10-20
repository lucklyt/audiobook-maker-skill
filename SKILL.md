---
name: audiobook-maker
description: Create, pack, and export chapter-indexed M4B audiobooks from raw audio files (MP3, M4A, WAV, FLAC, etc.) or web sources (WeChat articles, web links, podcasts). Automatically manages FFmpeg dependencies, calculates millisecond chapter boundaries, embeds cover art and standard Apple Books / Audiobookshelf metadata. Use when the user asks to "制作有声书", "做有声书", "打包m4b", "合并章节音频", "create audiobook", or "convert to m4b".
license: MIT
compatibility: Cross-platform (Windows, macOS, Linux). Requires Python 3 (standard library) and ffmpeg (auto-detected or auto-installed via WinGet/Scoop/Choco on Windows, Homebrew on macOS, or apt/dnf/pacman on Linux).
metadata:
  version: "1.0.0"
  author: lucklyt
  homepage: https://github.com/lucklyt/audiobook-maker-skill
---

# Audiobook Maker Skill

本 Skill 指导 Agent 全自动完成从音频素材到标准 **M4B 有声书**（兼容 Apple Books、iPhone/iPad、Audiobookshelf、Plex、BookPlayer 等）的制作全流程，**无需用户安装第三方 GUI 软件**，底层依赖自动就绪。

---

## 🛠️ 核心工具脚本

Skill 内置了全自动制作脚本：
`$SKILL_DIR/scripts/make_audiobook.py`

### 跨平台与自动依赖管理特性
- **支持全平台**：无缝支持 **Windows 10/11**、**macOS (Intel/Apple Silicon)** 以及主流 **Linux** 发行版。
- **跨平台路径与编码**：自动处理 Windows 反斜杠、FFmpeg 路径转义及 Windows CMD/PowerShell 下的中文字符集编码（UTF-8 自动重配），防止乱码或闪退。
- **FFmpeg 智能发现与自动补齐**：
  - **macOS**：自动扫描 Homebrew 目录与系统 PATH；缺失时调用 `brew install ffmpeg`。
  - **Windows**：自动探测 WinGet 链接目录、Scoop/Choco 路径、`C:\ffmpeg` 等；缺失时自动调用 WinGet（`winget install Gyan.FFmpeg`）或 Scoop/Choco。
  - **Linux**：自动探测系统路径；缺失时调用 `apt-get` / `dnf` / `pacman`。
- **纯 Python 3 标准库**：无任何 pip 第三方库依赖，环境极其纯净。

---

## 🚀 常用执行模式

### 模式 1：从文件夹一键制作有声书
当音频文件已放置在某目录下（如 `01.mp3`, `02.mp3`...）：

```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --input-dir "/path/to/audio_folder" \
  --output "/path/to/书名.m4b" \
  --title "书名" \
  --author "作者 / 播音" \
  --cover "/path/to/cover.jpg" \
  --genre "历史军事" \
  --year "2026" \
  --publisher "出品机构" \
  --language "Chinese" \
  --summary "书籍或节目简介"
```

### 模式 2：自定义章节标题列表
如果音频文件名较为简略，需要按顺序列出清晰的章节名：

```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --input-dir "/path/to/audio_folder" \
  --output "/path/to/书名.m4b" \
  --title "书名" \
  --author "作者" \
  --chapter-titles "第一集：铁血突围" "第二集：伟大转折" "第三集：突破天险"
```

### 模式 3：检查验证已生成的 M4B 文件
```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --inspect "/path/to/书名.m4b"
```

---

## 📋 有声书全流程工作流（Agent 任务指引）

当用户发出制作有声书的请求时，Agent 按照以下步骤推进：

### 步骤 1：素材准备与自动元数据补齐（核心智能步骤）
1. **获取音频**：
   - 本地目录：递归扫描 MP3、M4A、WAV、FLAC、AAC、OGG 等格式文件。
   - 网页来源：抓取 HTML，解析音频媒体标签/直链（如微信公众号的 `voice_encode_fileid` 媒体接口）并批量下载。
2. **自然排序（Natural Sorting）**：
   - 必须按章节编号自然顺序排列（例如：`01` 在 `02` 前，`2` 在 `10` 前，中文数字“第一集”、“第二集”等正确映射）。
3. **元数据与封面自动联网搜索（重点）**：
   - 若用户仅提供书名、文件夹或音频文件名，而未提供作者、简介、封面等信息：
     - **Agent 必须主动调用 `search_web` 工具联网检索**（如检索豆瓣读书、百度百科、出版方官方资料）。
     - 检索查询词推荐：`{书名} 豆瓣读书 简介 封面` 或 `{书名} {作者} 出版社 简介`。
     - **自动提取并补齐**：
       - `title`：书名（去除多余后缀）
       - `author`：作者、译者或演播播音
       - `year`：初版年份（如 2026）
       - `genre`：精准书籍分类（如科幻小说、历史纪实、经管商业）
       - `publisher`：出版社或制作方
       - `summary`：官方内容简介
       - `cover`：高清封面图片 URL 或下载保存为 `cover.jpg`。
   - 若音频来源于网页（如微信公众号文章），优先提取文章头图（`msg_cdn_url`）及官方正文导读作为封面与简介。
   - `scripts/make_audiobook.py` 的 `--cover` 参数同时支持**本地图片路径**和**网络图片 URL**（脚本会自动配置防盗链请求头下载保存）。

### 步骤 2：生成与编码（底层标准）
Agent 可直接调用 `scripts/make_audiobook.py`，其底层执行符合 Apple 官方规范的 FFmpeg 管道：

1. **毫秒级时间轴定位**：
   使用 `TIMEBASE=1/1000` 记录章节精确起止毫秒，避免长时间播放进度漂移。
2. **转码与格式统一**：
   - 音频流编码为 AAC（`c:a aac -b:a 96k -ar 44100 -ac 2`）。
   - 语言标记写入 `language=zho`。
3. **封面图嵌入**：
   - 作为独立视频流封装，附带 `-disposition:v:0 attached_pic`。
4. **Apple 快速启动与章节原子**：
   - `-movflags +faststart+disable_chpl -movie_timescale 1000 -f ipod`

### 步骤 3：验证与交付
运行 `--inspect` 确认：
- [x] 总时长与各分集之和一致。
- [x] 章节标题完整，时间点无重叠无空隙。
- [x] 封面与元数据（Title、Artist、Genre 等）正确嵌入。
- [x] 输出完整文件路径链接，方便用户点击直达。

---

## 📚 规范与参考文档
详细 Apple M4B 规范与特殊标签说明，可参阅：
`references/apple_m4b_spec.md`
