# Audiobook Maker Skill 🎧📚

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen.svg)]()
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue.svg)]()
[![Agent Compatible](https://img.shields.io/badge/Agent-Doubao%20%7C%20Marvis%20%7C%20Antigravity%20%7C%20Cursor%20%7C%20Claude-orange.svg)]()

适用于 AI 智能体（Agent）和命令行的**全自动有声书制作 Skill**。

无需用户手动下载配置繁重的独立 App，AI Agent 遵循本 Skill 规程即可自主完成从音频素材清洗、智能全网搜刮元数据与封面、自然章节排序，到生成符合 **Apple Books / iOS / Audiobookshelf** 标准的 `.m4b` 有声书全流程。

---

## ✨ 核心特性

- **🤖 广泛的 Agent 兼容**：原生适配 **豆包 (Doubao / MarsCode)**、**Marvis / OpenClaw**、**Antigravity**、**Cursor**、**Claude Code**、**Windsurf** 等主流 AI 助手。
- **🌐 智能元数据与封面全网搜刮**：若缺失封面或书籍信息，Agent 会自动联网检索（豆瓣读书、官方发布等），提取作者、出版社、分类、出版年份、内容简介并下载高清封面。
- **⚙️ 全自动底层引擎就绪**：智能按序探测 `FFmpeg`；在 macOS 上通过 Homebrew 自动补齐，在 Windows 上通过 WinGet/Scoop 自动补齐，Linux 自动调用包管理器。
- **🎛️ Apple 标准 QuickTime 章节**：采用 `TIMEBASE=1/1000` 毫秒级时间轴，生成 `-movflags +faststart+disable_chpl -movie_timescale 1000 -f ipod` 规范的高兼容 M4B，iPhone / iPad / Mac 图书 App 原生秒开。
- **💻 真正跨平台与零 Python 运行支持**：不仅支持 Python，还随包提供 **macOS/Linux 纯 Bash (`.sh`)** 和 **Windows 纯 PowerShell (`.ps1`)** 原生脚本，未安装 Python 也能丝滑运行。

---

## 🚀 安装与加载方式（支持主流 AI 助手）

你可以根据你正在使用的 AI 助手或使用习惯，选择以下任意一种方式：

### 方式 1：直接复制给你的 AI 助手（最省心，让 Agent 帮安装）

无需手动打命令，直接把下面这句话发给你的 AI 助手：

#### 🤖 发送给「豆包 (Doubao / 豆包电脑版 / MarsCode)」：
> *“请帮我安装并学习这个制作有声书的技能：https://github.com/lucklyt/audiobook-maker-skill ，请把仓库中的 `SKILL.md` 规则和脚本配置好，以便后续帮我把音频做成带章节的 M4B 有声书。”*

#### 🦁 发送给「Marvis / OpenClaw」：
> *“请帮我安装这个技能：https://github.com/lucklyt/audiobook-maker-skill ，存放到 `~/.openclaw/skills/audiobook-maker` 目录中。”*

#### 🪐 发送给「Antigravity / Gemini CLI」：
> *“请帮我把 https://github.com/lucklyt/audiobook-maker-skill 安装到我的全局技能目录 `~/.gemini/config/skills/audiobook-maker` 中。”*

#### ⚡ 发送给「Cursor / Windsurf / Claude Code / Cline」：
> *“请帮我将 https://github.com/lucklyt/audiobook-maker-skill 克隆到当前工作区或用户 Agent 目录，并按照其中的 `SKILL.md` 流程制作有声书。”*

---

### 方式 2：使用主流 Skill 工具 / 包管理器安装

如果你使用的是遵循开放智能体标准（Agent Skills / OpenClaw）的客户端工具：

```bash
# 使用 OpenClaw / Marvis CLI 安装
openclaw skills install lucklyt/audiobook-maker-skill
# 或
claw install lucklyt/audiobook-maker-skill

# 使用通用 skills-cli 安装
npx skills-cli add lucklyt/audiobook-maker-skill
```

---

### 方式 3：终端一键全自动安装脚本（推荐）

我们在仓库中内置了自适应安装脚本，它会**自动检测你电脑上已安装的 AI 平台（Antigravity、Marvis、Claude Code 等）并自动完成关联挂载**：

#### 🍎 macOS / 🐧 Linux 终端：
```bash
curl -fsSL https://raw.githubusercontent.com/lucklyt/audiobook-maker-skill/main/install.sh | bash
```

#### 🪟 Windows (PowerShell) 终端：
```powershell
irm https://raw.githubusercontent.com/lucklyt/audiobook-maker-skill/main/install.ps1 | iex
```

---

### 方式 4：手动克隆与目录挂载对照表

如果你喜欢手动管理配置，只需将仓库克隆到你的 AI 助手所指定的技能路径：

```bash
git clone https://github.com/lucklyt/audiobook-maker-skill.git <对应路径>
```

| AI 助手 / 平台 | 推荐技能存放路径 |
| :--- | :--- |
| **通用标准路径 (OpenClaw / 通用 Agent)** | `~/.agents/skills/audiobook-maker` |
| **Marvis / OpenClaw** | `~/.openclaw/skills/audiobook-maker` |
| **Antigravity (Google / AGY)** | `~/.gemini/config/skills/audiobook-maker` |
| **豆包 MarsCode / 项目本地环境** | `<项目目录>/.marscode/skills/audiobook-maker` 或 `<项目目录>/.agents/skills/audiobook-maker` |
| **Claude Code** | `~/.claude/skills/audiobook-maker` |
| **Cursor / Windsurf** | 放在项目目录中，将 `SKILL.md` 路径或规则加入 `.cursorrules` |

---

## 🛠️ 作为命令行工具独立使用

除了作为 AI Skill 外，你也可以在没有任何 AI 环境下，将其作为普通的命令行工具使用：

```bash
# 模式 1：使用 Python 引擎（全平台推荐）
python3 scripts/make_audiobook.py \
  --input-dir "/path/to/audios" \
  --output "/path/to/书名.m4b" \
  --title "书名" \
  --author "作者" \
  --cover "https://example.com/cover.jpg" \
  --genre "历史军事" \
  --year "2026" \
  --publisher "出版社" \
  --summary "书籍简介"

# 模式 2：未安装 Python 时的纯原生执行
# macOS / Linux (纯 Bash，零依赖)
bash scripts/make_audiobook.sh -i "/path/to/audios" -o "/path/to/书名.m4b" -t "书名" -a "作者"

# Windows (纯 PowerShell，零依赖)
.\scripts\make_audiobook.ps1 -InputDir "C:\audios" -OutputFile "C:\audios\书名.m4b" -Title "书名" -Author "作者"

# 模式 3：校验已有 M4B 文件的章节和元数据
python3 scripts/make_audiobook.py --inspect "/path/to/书名.m4b"
```

---

## 🤝 搭配 AI Agent 的日常对话体验

成功安装后，在日常对话中，您只需像真人对话一样下达要求：

* *“帮我把这个微信公众号文章里的系列音频提取并做成有声书”*
* *“把 ~/Downloads/三体 目录下的音频打包成 M4B，去豆瓣搜一下封面和简介填进去”*
* *“帮我把网盘下载的音频合成有声书，存到我的 Audiobook 文件夹”*

AI Agent 将自动触发本 Skill：
1. **智能解析**：扫描并按照章节自然逻辑排序（`01`, `02`, `10`...）；
2. **全网搜刮**：联网检索该书籍在豆瓣/出版方的高清封面、作者、出版年份、内容提要；
3. **专业封装**：调用底层引擎，输出具备独立章节跳转目录的标准 M4B 文件，直接在 Apple 图书或各大播放器无缝收听。

---

## 📄 开源许可

本项目基于 [MIT 许可证](LICENSE) 开源。
