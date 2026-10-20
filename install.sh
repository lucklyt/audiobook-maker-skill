#!/usr/bin/env bash
#
# Audiobook Maker Skill - Universal One-Click Installer (macOS / Linux)
# Installs to ~/.agents/skills/audiobook-maker and links to supported AI assistants (Antigravity, Marvis/OpenClaw, etc.)
#

set -e

REPO_URL="https://github.com/lucklyt/audiobook-maker-skill.git"
SKILL_NAME="audiobook-maker"
TARGET_DIR="$HOME/.agents/skills/$SKILL_NAME"

echo "=========================================="
echo "🎧 安装 Audiobook Maker Skill 到 AI 助手"
echo "=========================================="

# 1. Clone or update repository
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "[*] 检测到已存在安装，正在同步更新最新版本..."
    git -C "$TARGET_DIR" pull --ff-only
else
    echo "[*] 正在从 GitHub 克隆 Skill 源码..."
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# Make scripts executable
chmod +x "$TARGET_DIR/scripts/make_audiobook.py" 2>/dev/null || true
chmod +x "$TARGET_DIR/scripts/make_audiobook.sh" 2>/dev/null || true

echo ""
echo "[*] 正在自动检测并挂载到系统已有的 AI 智能体平台..."

MOUNT_COUNT=0

# Antigravity (Google / AGY)
GEMINI_SKILLS="$HOME/.gemini/config/skills"
if [[ -d "$HOME/.gemini" || -d "$GEMINI_SKILLS" ]]; then
    mkdir -p "$GEMINI_SKILLS"
    ln -sf "$TARGET_DIR" "$GEMINI_SKILLS/$SKILL_NAME"
    echo "  ✓ 已挂载至 Antigravity (~/.gemini/config/skills/$SKILL_NAME)"
    MOUNT_COUNT=$(( MOUNT_COUNT + 1 ))
fi

# Marvis / OpenClaw / Claw
OPENCLAW_DIR="$HOME/.openclaw/skills"
if [[ -d "$HOME/.openclaw" || -d "$OPENCLAW_DIR" ]]; then
    mkdir -p "$OPENCLAW_DIR"
    ln -sf "$TARGET_DIR" "$OPENCLAW_DIR/$SKILL_NAME"
    echo "  ✓ 已挂载至 Marvis / OpenClaw (~/.openclaw/skills/$SKILL_NAME)"
    MOUNT_COUNT=$(( MOUNT_COUNT + 1 ))
fi

# Claude Code
CLAUDE_DIR="$HOME/.claude/skills"
if [[ -d "$HOME/.claude" || -d "$CLAUDE_DIR" ]]; then
    mkdir -p "$CLAUDE_DIR"
    ln -sf "$TARGET_DIR" "$CLAUDE_DIR/$SKILL_NAME"
    echo "  ✓ 已挂载至 Claude Code (~/.claude/skills/$SKILL_NAME)"
    MOUNT_COUNT=$(( MOUNT_COUNT + 1 ))
fi

# 通用 .agents 目录
echo "  ✓ 已安装至通用 Agent 技能目录 (~/.agents/skills/$SKILL_NAME)"

# Check FFmpeg
echo ""
echo "[*] 检查底层音频引擎 (FFmpeg)..."
if command -v ffmpeg >/dev/null 2>&1; then
    echo "  ✓ FFmpeg 已就绪: $(command -v ffmpeg)"
else
    echo "  [!] 未检测到 FFmpeg。制作脚本会在首次运行时通过包管理器自动安装，您也可以手动执行: brew install ffmpeg"
fi

echo ""
echo "=========================================="
echo "🎉 安装完成！"
echo "=========================================="
echo "现在您只需向任何 AI 助手（豆包、Marvis、Antigravity、Cursor 等）说："
echo "  👉 '帮我把这个文件夹/链接里的音频做成有声书'"
echo "AI 助手将自动加载本 Skill 并完成制作！"
