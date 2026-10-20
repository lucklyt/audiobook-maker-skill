<#
.SYNOPSIS
    Audiobook Maker - Pure PowerShell Script (Windows)
    Zero Python dependency. Requires only ffmpeg/ffprobe.
.EXAMPLE
    .\make_audiobook.ps1 -InputDir "C:\Audio" -OutputFile "C:\Audio\Book.m4b" -Title "书名" -Author "作者"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputDir,

    [Parameter(Mandatory=$true)]
    [string]$OutputFile,

    [Parameter(Mandatory=$true)]
    [string]$Title,

    [string]$Author = "未知作者",
    [string]$Cover = "",
    [string]$Genre = "Audiobook",
    [string]$Year = "2026",
    [string]$Publisher = "",
    [string]$Summary = "",
    [string]$Bitrate = "96k"
)

# Set UTF-8 encoding for console output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Locate ffmpeg
$ffmpegBin = $null
$candidates = @(
    "ffmpeg",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe",
    "$env:USERPROFILE\scoop\shims\ffmpeg.exe",
    "C:\ffmpeg\bin\ffmpeg.exe",
    "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
)

foreach ($c in $candidates) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        $ffmpegBin = (Get-Command $c).Source
        break
    }
}

if (-not $ffmpegBin) {
    Write-Host "[!] 未检测到 ffmpeg，尝试通过 winget 自动安装..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
        if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
            $ffmpegBin = (Get-Command ffmpeg).Source
        }
    }
}

if (-not $ffmpegBin) {
    Write-Error "[错误] 无法找到或自动安装 ffmpeg，请先安装 ffmpeg 并配置环境变量 PATH。"
    exit 1
}

$ffprobeBin = Join-Path (Split-Path $ffmpegBin) "ffprobe.exe"
if (-not (Test-Path $ffprobeBin)) {
    $ffprobeBin = "ffprobe"
}

Write-Host "[*] 使用音频引擎: $ffmpegBin"

# Get audio files
$audioExtensions = @(".mp3", ".m4a", ".wav", ".flac", ".aac", ".ogg")
$files = Get-ChildItem -Path $InputDir -File | Where-Object { $audioExtensions -contains $_.Extension.ToLower() } | Sort-Object { [int]($_.BaseName -replace '\D') }

if ($files.Count -eq 0) {
    Write-Error "[错误] 目录中未找到音频文件: $InputDir"
    exit 1
}

Write-Host "[*] 找到 $($files.Count) 个音频章节，正在计算精确时长..."

$tempDir = Join-Path $env:TEMP ("audiobook_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$concatFile = Join-Path $tempDir "concat.txt"
$metaFile = Join-Path $tempDir "metadata.txt"

# Build FFMETADATA
$metaLines = @(
    ";FFMETADATA1",
    "title=$Title",
    "artist=$Author",
    "album_artist=$Author",
    "album=$Title",
    "genre=$Genre",
    "date=$Year",
    "media_type=2"
)
if ($Publisher) { $metaLines += "comment=Publisher: $Publisher" }
if ($Summary) { $metaLines += "description=$Summary" }

$currentMs = 0
$concatLines = @()
$index = 1

foreach ($file in $files) {
    $chTitle = $file.BaseName -replace '^\d+[\s._\-:]+', ''
    if (-not $chTitle) { $chTitle = $file.BaseName }

    # Call ffprobe
    $durStr = & $ffprobeBin -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file.FullName
    $dur = 0.0
    [double]::TryParse($durStr, [ref]$dur) | Out-Null
    if ($dur -le 0) { continue }

    $durMs = [int64][Math]::Round($dur * 1000)
    $endMs = $currentMs + $durMs

    Write-Host "  [$index/$($files.Count)] $chTitle ($([Math]::Round($dur, 1))s)"

    # Format forward slashes for FFmpeg concat
    $cleanPath = $file.FullName.Replace('\', '/').Replace("'", "'\''")
    $concatLines += "file '$cleanPath'"

    $metaLines += "[CHAPTER]"
    $metaLines += "TIMEBASE=1/1000"
    $metaLines += "START=$currentMs"
    $metaLines += "END=$endMs"
    $metaLines += "title=$chTitle"

    $currentMs = $endMs
    $index++
}

[System.IO.File]::WriteAllLines($concatFile, $concatLines, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllLines($metaFile, $metaLines, [System.Text.Encoding]::UTF8)

# Check cover
if (-not $Cover) {
    foreach ($cand in @("cover.jpg", "cover.png", "folder.jpg")) {
        $p = Join-Path $InputDir $cand
        if (Test-Path $p) { $Cover = $p; break }
    }
}

$outputDir = Split-Path $OutputFile
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "[*] 正在通过 FFmpeg 进行 AAC 编码与 M4B 封装..."

$ffmpegArgs = @(
    "-y", "-hide_banner",
    "-f", "concat", "-safe", "0", "-i", $concatFile,
    "-i", $metaFile
)

if ($Cover -and (Test-Path $Cover)) {
    $ffmpegArgs += @("-i", $Cover, "-map", "0:a:0", "-map_metadata", "1", "-map_chapters", "1", "-map", "2:v:0", "-c:v", "mjpeg", "-disposition:v:0", "attached_pic")
} else {
    $ffmpegArgs += @("-map", "0:a:0", "-map_metadata", "1", "-map_chapters", "1")
}

$ffmpegArgs += @(
    "-c:a", "aac", "-b:a", $Bitrate, "-ar", "44100", "-ac", "2",
    "-metadata:s:a:0", "language=zho",
    "-movflags", "+faststart+disable_chpl",
    "-movie_timescale", "1000",
    "-f", "ipod",
    $OutputFile
)

& $ffmpegBin $ffmpegArgs

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

$totalSec = [int]($currentMs / 1000)
$th = [int]($totalSec / 3600)
$tm = [int](($totalSec % 3600) / 60)
$ts = [int]($totalSec % 60)

Write-Host "`n[成功] 有声书制作完成 (PowerShell 引擎)！" -ForegroundColor Green
Write-Host "  输出文件: $OutputFile"
Write-Host "  总 时 长: ${th}小时${tm}分${ts}秒"
Write-Host "  章节数量: $($index - 1) 章"
