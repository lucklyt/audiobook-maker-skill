# Audiobook Maker Skill 🎧📚

<p align="center">
  <b>English</b> | <a href="README.zh-CN.md">简体中文</a>
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen.svg)]()
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue.svg)]()
[![Agent Compatible](https://img.shields.io/badge/Agent-Claude%20%7C%20Cursor%20%7C%20Antigravity%20%7C%20OpenClaw%20%7C%20Doubao-orange.svg)]()

An automated **Audiobook Maker Skill** designed for AI Agents and CLI workflows.

Convert raw audio files or web sources into standard, chapter-indexed **M4B audiobooks** fully compliant with **Apple Books (iOS / iPadOS / macOS)**, **Audiobookshelf**, **BookPlayer**, **Plex**, and more — **zero third-party GUI software required**.

---

## ✨ Key Features

- **🤖 Broad Agent Ecosystem Support**: Natively compatible with **Claude Code**, **Cursor**, **Windsurf**, **Antigravity (Google / AGY)**, **OpenClaw / Marvis**, **Doubao (MarsCode)**, and **Cline**.
- **🌐 Autonomous Metadata & Cover Art Fetching**: Missing book info or artwork? The Agent autonomously searches the web (Goodreads, Douban, Google Books, official publishers) to pull title, author, publisher, genre, release year, description, and high-res cover art.
- **🏷️ Smart Chapter Title Sanitization**:
  - Automatically detects and strips redundant file order prefixes (e.g., `10.Chapter 5 Intro` or `10.第5集 去红都的道路` → `Chapter 5 Intro` or `第5集 去红都的道路`).
  - Cleans promo watermark suffixes and outro noise (e.g., "Thanks for listening!", "Follow us for more!").
  - Supports `--strip-chapter-prefix` to eliminate chapter indices and keep only pure titles.
- **⚡ Hardware-Accelerated & Apple Compliant**:
  - Millisecond-accurate chapter boundaries (`TIMEBASE=1/1000`).
  - Native Apple AudioToolbox hardware encoder (`aac_at`) on macOS for up to **2.5x faster encoding**.
  - Apple QuickTime chapter atoms with `-movflags +faststart+disable_chpl -movie_timescale 1000 -f ipod` for instant streaming on iPhone / Mac Books app.
- **⚙️ Self-Healing Dependencies**: Auto-discovers `ffmpeg`/`ffprobe`. If missing, auto-installs via Homebrew on macOS, WinGet/Scoop/Choco on Windows, or apt/dnf/pacman on Linux.
- **💻 Zero-Python Standalone Scripts**: In addition to standard Python 3, standalone **macOS/Linux Bash (`.sh`)** and **Windows PowerShell (`.ps1`)** native scripts are included — runs out of the box even without Python installed.

---

## 🚀 Installation & Agent Setup

Choose any method based on your AI assistant or personal workflow:

### Method 1: Prompt Your AI Assistant (Recommended)

Simply copy and send one of the following prompts to your AI assistant:

#### ⚡ For **Claude Code / Cursor / Windsurf / Cline**:
> *"Please clone https://github.com/lucklyt/audiobook-maker-skill into my agent skills directory and follow its `SKILL.md` rules to help me pack audios into chapter-indexed M4B audiobooks."*

#### 🪐 For **Antigravity / Gemini CLI**:
> *"Please install https://github.com/lucklyt/audiobook-maker-skill into my global skills directory at `~/.gemini/config/skills/audiobook-maker`."*

#### 🦁 For **OpenClaw / Marvis**:
> *"Please install the skill from https://github.com/lucklyt/audiobook-maker-skill into `~/.openclaw/skills/audiobook-maker`."*

#### 🤖 For **Doubao / MarsCode**:
> *"请帮我安装并学习制作有声书的技能：https://github.com/lucklyt/audiobook-maker-skill ，将仓库中的 `SKILL.md` 规则和脚本配置好，以便帮我制作带章节的 M4B 有声书。"*

---

### Method 2: Package Manager / Skills CLI

If you use tools following the Open Agent Skills specification:

```bash
# Via OpenClaw / Marvis CLI
openclaw skills install lucklyt/audiobook-maker-skill
# or
claw install lucklyt/audiobook-maker-skill

# Via generic skills-cli
npx skills-cli add lucklyt/audiobook-maker-skill
```

---

### Method 3: One-Click Terminal Installers

Our repository includes self-adaptive installers that **auto-detect your installed AI platforms and bind the skill automatically**:

#### 🍎 macOS / 🐧 Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/lucklyt/audiobook-maker-skill/main/install.sh | bash
```

#### 🪟 Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/lucklyt/audiobook-maker-skill/main/install.ps1 | iex
```

---

### Method 4: Manual Clone & Path Reference

Clone the repository directly into your AI assistant's designated skill directory:

```bash
git clone https://github.com/lucklyt/audiobook-maker-skill.git <target_path>
```

| AI Platform / Agent | Recommended Skill Directory |
| :--- | :--- |
| **Open Agent Standard (Universal)** | `~/.agents/skills/audiobook-maker` |
| **Claude Code** | `~/.claude/skills/audiobook-maker` |
| **Antigravity (Google / AGY)** | `~/.gemini/config/skills/audiobook-maker` |
| **OpenClaw / Marvis** | `~/.openclaw/skills/audiobook-maker` |
| **Cursor / Windsurf** | Project root directory with `SKILL.md` referenced in `.cursorrules` |
| **Doubao MarsCode / Workspace** | `<workspace>/.agents/skills/audiobook-maker` |

---

## 🛠️ CLI Usage (Standalone)

You can also use Audiobook Maker as a standalone CLI tool without an AI agent:

```bash
# Mode 1: Python Engine (Cross-platform recommended)
python3 scripts/make_audiobook.py \
  --input-dir "/path/to/audios" \
  --output "/path/to/Book.m4b" \
  --title "Book Title" \
  --author "Author Name" \
  --cover "https://example.com/cover.jpg" \
  --genre "History" \
  --year "2026" \
  --publisher "Publisher" \
  --summary "Full book overview..."

# Mode 2: Zero-Python Native Execution
# macOS / Linux (Pure Bash)
bash scripts/make_audiobook.sh -i "/path/to/audios" -o "/path/to/Book.m4b" -t "Book Title" -a "Author"

# Windows (Pure PowerShell)
.\scripts\make_audiobook.ps1 -InputDir "C:\audios" -OutputFile "C:\audios\Book.m4b" -Title "Book Title" -Author "Author"

# Mode 3: Inspect Existing M4B Chapters & Metadata
python3 scripts/make_audiobook.py --inspect "/path/to/Book.m4b"

# Mode 4: Strip Chapter Index Prefixes (Pure Titles Only)
python3 scripts/make_audiobook.py -i "/path/to/audios" -t "Book Title" --strip-chapter-prefix
```

---

## 🤝 Conversational Experience with AI Agents

Once installed, just talk naturally to your AI Agent:

* *"Pack the audio files in `~/Downloads/Dune` into an M4B audiobook, grab the cover and synopsis from Goodreads, and remove the leading file numbers."*
* *"Extract the audio series from this article link and convert it into an Apple Books compatible audiobook."*
* *"Merge the chapter MP3s in my folder into `The Hobbit.m4b` with 96k AAC audio."*

The AI Agent will autonomously:
1. **Analyze & Sort**: Naturally sort chapters (`1, 2, 10` instead of alphabetical `1, 10, 2`).
2. **Fetch Metadata**: Search the web for official HD cover artwork, author, year, and description.
3. **Clean Titles**: Sanitize duplicate numbers and promotional clutter.
4. **Encode & Deliver**: Compile the `.m4b` with accurate chapters and deliver the final playable file.

---

## 📄 License

Distributed under the [MIT License](LICENSE).
