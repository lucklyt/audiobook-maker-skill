<#
.SYNOPSIS
    Audiobook Maker Skill - Windows One-Click Installer
    Clones to %USERPROFILE%\.agents\skills\audiobook-maker and registers paths.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoUrl = "https://github.com/lucklyt/audiobook-maker-skill.git"
$SkillName = "audiobook-maker"
$TargetDir = Join-Path $env:USERPROFILE ".agents\skills\$SkillName"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎧 安装 Audiobook Maker Skill 到 AI 助手" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Clone or update repository
if (Test-Path (Join-Path $TargetDir ".git")) {
    Write-Host "[*] 检测到已存在安装，正在同步更新最新版本..."
    git -C $TargetDir pull --ff-only
} else {
    Write-Host "[*] 正在从 GitHub 克隆 Skill 源码..."
    $parent = Split-Path $TargetDir
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    git clone $RepoUrl $TargetDir
}

# 2. Register with assistant directories
Write-Host "`n[*] 正在检测并挂载到系统已有的 AI 智能体平台..." -ForegroundColor Yellow

# Marvis / OpenClaw on Windows
$OpenClawDir = Join-Path $env:USERPROFILE ".openclaw\skills"
if (Test-Path (Join-Path $env:USERPROFILE ".openclaw") -or (Test-Path $OpenClawDir)) {
    if (-not (Test-Path $OpenClawDir)) { New-Item -ItemType Directory -Path $OpenClawDir -Force | Out-Null }
    $link = Join-Path $OpenClawDir $SkillName
    if (-not (Test-Path $link)) {
        New-Item -ItemType SymbolicLink -Path $link -Target $TargetDir -Force | Out-Null
    }
    Write-Host "  ✓ 已挂载至 Marvis / OpenClaw ($link)" -ForegroundColor Green
}

# Antigravity on Windows
$GeminiSkills = Join-Path $env:USERPROFILE ".gemini\config\skills"
if (Test-Path (Join-Path $env:USERPROFILE ".gemini") -or (Test-Path $GeminiSkills)) {
    if (-not (Test-Path $GeminiSkills)) { New-Item -ItemType Directory -Path $GeminiSkills -Force | Out-Null }
    $link = Join-Path $GeminiSkills $SkillName
    if (-not (Test-Path $link)) {
        New-Item -ItemType SymbolicLink -Path $link -Target $TargetDir -Force | Out-Null
    }
    Write-Host "  ✓ 已挂载至 Antigravity ($link)" -ForegroundColor Green
}

Write-Host "  ✓ 已安装至通用 Agent 技能目录 ($TargetDir)" -ForegroundColor Green

# 3. Check FFmpeg
Write-Host "`n[*] 检查底层音频引擎 (FFmpeg)..."
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ FFmpeg 已就绪: $((Get-Command ffmpeg).Source)" -ForegroundColor Green
} else {
    Write-Host "  [!] 未检测到 FFmpeg。首次运行时脚本将尝试通过 WinGet 自动安装，您也可以手动运行: winget install Gyan.FFmpeg" -ForegroundColor Yellow
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "🎉 安装完成！" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "现在您只需向任何 AI 助手（豆包、Marvis、Antigravity、Cursor 等）说："
Write-Host "  👉 '帮我把这个文件夹/链接里的音频做成有声书'"
Write-Host "AI 助手将自动加载本 Skill 并完成制作！"
