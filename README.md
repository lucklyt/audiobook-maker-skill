# Audiobook Maker Skill 🎧📚

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen.svg)]()
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue.svg)]()

适用于 AI 智能体（Agent）和命令行的**全自动有声书制作 Skill**。

无需用户手动下载配置繁重的独立 App，AI Agent 遵循本 Skill 规程即可自主完成从音频素材清洗、智能全网搜刮元数据与封面、自然章节排序，到生成符合 **Apple Books / iOS / Audiobookshelf** 标准的 `.m4b` 有声书全流程。

---

## ✨ 核心特性

- **🤖 Agent 智能驱动**：专为 Antigravity、OpenClaw、Claude Code、Cursor 等 Agent 设计，规范任务指引与自动化链条。
- **🌐 智能元数据与封面搜刮**：若缺失封面或书籍信息，Agent 会自动联网检索（豆瓣读书、官方发布等），提取作者、出版社、分类、出版年份、内容简介并下载高清封面。
- **⚙️ 全自动依赖管理**：智能按序探测 `FFmpeg`；在 macOS 上自动通过 Homebrew 补齐，在 Windows 上自动通过 WinGet/Scoop/Choco 补齐，Linux 自动调用包管理器。
- **🎛️ Apple 标准 QuickTime 章节**：采用 `TIMEBASE=1/1000` 毫秒级时间轴，生成 `-movflags +faststart+disable_chpl -movie_timescale 1000 -f ipod` 规范的高兼容 M4B，iPhone / iPad / Mac 图书 App 原生秒开。
- **💻 真正跨平台**：原生兼容 **macOS** (Intel / Apple Silicon)、**Windows 10/11** 和 **Linux**。自动处理 Windows 路径正反斜杠及终端 UTF-8 编码防崩溃。
- **📦 零外部 Python 库依赖**：纯 Python 3 标准库编写，无需 `pip install` 任何第三方包。

---

## 📂 项目结构

```text
audiobook-maker/
├── SKILL.md                          # Agent 技能定义文件与操作指引
├── scripts/
│   └── make_audiobook.py             # 核心跨平台打包脚本（纯 Python 3 标准库）
└── references/
    └── apple_m4b_spec.md             # Apple Books / M4B 规范技术参考
```

---

## 🚀 安装方法

### 1. 安装为 Antigravity 全局技能

克隆本仓库到你的系统技能目录中：

```bash
git clone https://github.com/lucklyt/audiobook-maker-skill.git ~/.agents/skills/audiobook-maker
mkdir -p ~/.gemini/config/skills
ln -sf ~/.agents/skills/audiobook-maker ~/.gemini/config/skills/audiobook-maker
```

安装后，Antigravity AI 助手即可在所有会话中自动识别并激活此 Skill。

### 2. 作为独立命令行工具使用

也可以直接运行内置脚本制作有声书：

```bash
# 从音频文件夹一键制作有声书
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

# 检查已生成的 M4B 文件结构和章节
python3 scripts/make_audiobook.py --inspect "/path/to/书名.m4b"
```

---

## 📖 CLI 参数说明

| 参数 | 简写 | 说明 |
| :--- | :--- | :--- |
| `--input-dir` | `-i` | 包含音频章节的目录路径（支持 MP3、M4A、WAV、FLAC、AAC 等） |
| `--files` | `-f` | 手动指定的音频文件列表 |
| `--output` | `-o` | 导出的 `.m4b` 目标路径（默认输出至音频目录旁） |
| `--title` | `-t` | **必填**，有声书名称 |
| `--author` | `-a` | 作者 / 播音 |
| `--cover` | `-c` | 封面图片路径（支持本地 JPEG/PNG 或网络 URL 自动下载） |
| `--genre` | `-g` | 分类 / 流派（如：科幻小说、历史军事、商业经管，默认 Audiobook） |
| `--year` | `-y` | 出版年份 |
| `--publisher` | `-p` | 出版机构 / 出品方 |
| `--language` | `-l` | 语言代码（默认 Chinese） |
| `--summary` | `-s` | 内容简介 |
| `--bitrate` | `-b` | 音频码率（默认 96k AAC，兼顾音质与体积） |
| `--chapter-titles` | - | 自定义章节名称列表（若需要覆盖文件名命名） |
| `--inspect` | - | 校验模式，查看已有 M4B 的流信息、封面、时长与所有章节时间戳 |

---

## 🤝 搭配 AI Agent 的使用体验

向配置了该 Skill 的 AI 助手发送指令：
* *“帮我把微信公众号 https://... 里的系列音频提取并做成有声书”*
* *“把 ~/Downloads/三体 目录下的音频做成有声书”*

Agent 将自动完成：
1. 提取或扫描所有音频并按章节自然排序；
2. 自动全网检索缺失的作者、年份、豆瓣高分封面和官方简介；
3. 调用底层引擎完成高规格转码与嵌入；
4. 交付带有完整独立章节索引的 `.m4b` 成果文件。

---

## 📄 开源许可

本项目基于 [MIT 许可证](LICENSE) 开源。
