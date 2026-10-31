---
name: audiobook-maker
description: Create, pack, and export chapter-indexed M4B audiobooks from raw audio files (MP3, M4A, WAV, FLAC, etc.) or web sources (WeChat articles, web links, podcasts). Automatically manages FFmpeg dependencies, calculates millisecond chapter boundaries, embeds cover art and standard Apple Books / Audiobookshelf metadata. Use when the user asks to "create audiobook", "convert to m4b", "pack m4b", "merge chapter audios", "制作有声书", "做有声书", "打包m4b", or "合并章节音频".
license: MIT
compatibility: Cross-platform (Windows, macOS, Linux). Requires Python 3 (standard library) and ffmpeg (auto-detected or auto-installed via WinGet/Scoop/Choco on Windows, Homebrew on macOS, or apt/dnf/pacman on Linux).
metadata:
  version: "1.1.0"
  author: lucklyt
  homepage: https://github.com/lucklyt/audiobook-maker-skill
---

# Audiobook Maker Skill

This Skill guides the AI Agent to autonomously produce standard **M4B audiobooks** (compatible with Apple Books, iPhone/iPad, Audiobookshelf, Plex, BookPlayer, etc.) from raw audio files or web sources with **zero third-party GUI software required**.

---

## 🛠️ Core Tool Scripts

The skill provides **dual-track execution**. Even if the user's system **does not have Python installed**, native zero-dependency scripts are ready out of the box:

| Execution Environment | Tool Script | Dependencies |
| :--- | :--- | :--- |
| **Universal (Recommended)** | `$SKILL_DIR/scripts/make_audiobook.py` | Python 3.8+ (standard library) + FFmpeg |
| **macOS / Linux (Zero Python)** | `$SKILL_DIR/scripts/make_audiobook.sh` | Bash / Sh + FFmpeg (Zero Python needed) |
| **Windows (Zero Python)** | `$SKILL_DIR/scripts/make_audiobook.ps1` | PowerShell + FFmpeg (Zero Python needed) |
| **Agent Native Direct Execution** | Agent generates `metadata.txt` & invokes FFmpeg directly | FFmpeg only |

---

## 💡 Fallback Strategy When Python Is Missing

When the Agent detects that Python is not available (`which python3` returns empty), choose one of the following approaches in order of preference:

### Plan A: Run Native Shell / PowerShell Scripts Directly (Recommended)
* **macOS / Linux**:
  ```bash
  bash "$SKILL_DIR/scripts/make_audiobook.sh" \
    -i "/path/to/audios" \
    -o "/path/to/Book.m4b" \
    -t "Book Title" -a "Author" -c "/path/to/cover.jpg"
  ```
* **Windows (PowerShell)**:
  ```powershell
  & "$SKILL_DIR\scripts\make_audiobook.ps1" `
    -InputDir "C:\audios" `
    -OutputFile "C:\audios\Book.m4b" `
    -Title "Book Title" -Author "Author"
  ```

### Plan B: Auto-install Python
* **Windows**: Run `winget install Python.Python.3.12 --silent`.
* **macOS**: Run `brew install python`.
* **Linux**: Run `sudo apt-get install -y python3`.

### Plan C: Agent Native Direct Pipeline
The Agent calculates chapter durations, generates `concat.txt` and `metadata.txt`, and runs a single `ffmpeg` command directly.

### Cross-Platform & Dependency Auto-Management
- **All Major Platforms**: Fully tested on **Windows 10/11**, **macOS (Intel & Apple Silicon)**, and **Linux**.
- **Hardware Acceleration**: Automatically selects `aac_at` (Apple AudioToolbox) on macOS for up to **2.5x faster encoding** while maintaining top-tier audio fidelity.
- **FFmpeg Auto-Discovery & Installation**:
  - **macOS**: Scans Homebrew paths and system PATH; runs `brew install ffmpeg` if missing.
  - **Windows**: Scans WinGet links, Scoop/Choco paths, `C:\ffmpeg`; runs WinGet (`winget install Gyan.FFmpeg`) or Scoop if missing.
  - **Linux**: Scans system paths; calls `apt-get`, `dnf`, or `pacman` if missing.
- **Pure Standard Library**: No pip packages required.

---

## 🚀 Common Execution Modes

### Mode 1: One-Click Audiobook Generation from a Folder
When audio files are placed in a directory (e.g., `01.mp3`, `02.mp3`...):

```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --input-dir "/path/to/audio_folder" \
  --output "/path/to/Book.m4b" \
  --title "Book Title" \
  --author "Author / Narrator" \
  --cover "/path/to/cover.jpg" \
  --genre "History" \
  --year "2026" \
  --publisher "Publisher" \
  --language "English" \
  --summary "Overview of the book..."
```

### Mode 2: Custom Chapter Titles List
When filenames are brief and explicit chapter names are provided:

```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --input-dir "/path/to/audio_folder" \
  --output "/path/to/Book.m4b" \
  --title "Book Title" \
  --author "Author" \
  --chapter-titles "Chapter 1: The Beginning" "Chapter 2: The Journey" "Chapter 3: The Climax"
```

### Mode 3: Inspect Existing M4B Files
```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --inspect "/path/to/Book.m4b"
```

### Mode 4: Strip Chapter Index Prefixes (Pure Titles Only)
By default, the script strips redundant file order prefixes (e.g., `10.Chapter 5 Intro` → `Chapter 5 Intro`). If the user wants to strip the chapter prefix entirely (`Chapter 5 Intro` → `Intro`):

```bash
python3 "$SKILL_DIR/scripts/make_audiobook.py" \
  --input-dir "/path/to/audio_folder" \
  --output "/path/to/Book.m4b" \
  --title "Book Title" \
  --strip-chapter-prefix
```

---

## 📋 Full Lifecycle Agent Workflow

When receiving a user request to make an audiobook, proceed through the following steps:

### Step 1: Audio Sourcing, Title Cleaning & Metadata Completion

1. **Audio Collection**:
   - Local directory: Recursively scan for MP3, M4A, WAV, FLAC, AAC, OGG files.
   - Web source: Fetch HTML, parse audio media tags or stream endpoints, and download sequentially.
2. **Natural Sorting**:
   - Sort files by natural number ordering (`01` before `02`, `2` before `10`, or Chinese numerals mapped accurately).
3. **Smart Chapter Title Sanitization**:
   - **Strip Redundant File Sequence Numbers**: When a filename starts with an audio file sequence number followed by a chapter indicator (e.g., `10.Chapter 5 Intro`, `10.第5集 去红都的道路`, `01 - Episode 1 Pilot`, `02第二回 怒鞭督邮`), **automatically remove the leading file sequence number** (`10.`, `01 - `, etc.) to avoid duplicate numbering in player chapter lists.
   - **Filter Promo & Outro Noise**: Automatically strip common advertising suffixes (e.g., "Thanks for listening!", "Follow us for more updates!", "感谢收听！").
   - **Support Pure Title Mode**: If requested or if `--strip-chapter-prefix` is specified, further strip chapter numbers to leave only pure section titles.
4. **Autonomous Web Metadata & Cover Art Search**:
   - If the user only provides raw files or a title without author/artwork:
     - **The Agent must actively use `search_web`** (e.g., query Goodreads, Google Books, Douban, or publisher websites).
     - Recommended query format: `{Title} {Author} synopsis cover` or `{Title} book review cover art`.
     - **Extract & Populate**:
       - `title`: Clean book title without extraneous marketing tags.
       - `author`: Author, translator, or narrator.
       - `year`: Publication or release year.
       - `genre`: Precise classification (e.g., Fiction, History, Sci-Fi, Business).
       - `publisher`: Publishing house or production studio.
       - `summary`: Official synopsis or overview.
       - `cover`: High-resolution cover artwork URL or local image path.
   - `scripts/make_audiobook.py` accepts both **local image paths** and **direct image URLs** for `--cover` (handles anti-hotlinking headers automatically).

### Step 2: Audio Encoding & Packaging (Apple Standard)

Invoke `scripts/make_audiobook.py` or execute the underlying compliant FFmpeg pipeline:

1. **Millisecond-Precise Timebase**:
   Use `TIMEBASE=1/1000` to mark chapter start and end milliseconds to prevent playback drift over long durations.
2. **Transcoding & Unified Audio Format**:
   - Encode audio to AAC (`-c:a aac -b:a 96k -ar 44100 -ac 2` or `-c:a aac_at` on macOS).
   - Set language tag (e.g. `language=eng` or `language=zho`).
3. **Cover Art Embedding**:
   - Multiplex as an independent video stream with `-disposition:v:0 attached_pic`.
4. **Apple QuickTime Chapter Atoms & FastStart**:
   - `-movflags +faststart+disable_chpl -movie_timescale 1000 -f ipod`

### Step 3: Verification & Delivery

Run `--inspect` on the generated file to verify:
- [x] Total duration matches the sum of chapter files.
- [x] Chapter names are cleanly formatted with zero gaps or overlaps.
- [x] Cover artwork and metadata tags (Title, Artist, Album, Genre, Year, Comment) are embedded correctly.
- [x] Provide the complete clickable file link for immediate user access.

---

## 📚 Specifications & References
Detailed Apple M4B chapter atom specifications and metadata keys are documented in:
`references/apple_m4b_spec.md`
