#!/usr/bin/env bash
#
# Audiobook Maker - Pure Shell Script (macOS / Linux)
# Zero Python dependency. Requires only ffmpeg/ffprobe and standard POSIX tools (awk, sed).
#

set -e

# Default values
INPUT_DIR=""
OUTPUT_FILE=""
TITLE=""
AUTHOR="未知作者"
COVER_FILE=""
GENRE="Audiobook"
YEAR="2026"
PUBLISHER=""
SUMMARY=""
BITRATE="96k"

usage() {
    echo "使用方法: $0 -i <音频目录> -o <输出.m4b> -t <书名> [选项]"
    echo ""
    echo "选项:"
    echo "  -i, --input-dir    包含音频章节的目录路径 (必填)"
    echo "  -o, --output       导出的 .m4b 文件路径 (必填)"
    echo "  -t, --title        有声书名称 (必填)"
    echo "  -a, --author       作者/播音 (默认: 未知作者)"
    echo "  -c, --cover        封面图片路径 (JPEG/PNG)"
    echo "  -g, --genre        流派分类 (默认: Audiobook)"
    echo "  -y, --year         年份 (默认: 2026)"
    echo "  -p, --publisher    出品/出版机构"
    echo "  -s, --summary      内容简介"
    echo "  -b, --bitrate      音频码率 (默认: 96k)"
    echo "  -h, --help         显示帮助信息"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input-dir) INPUT_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -t|--title) TITLE="$2"; shift 2 ;;
        -a|--author) AUTHOR="$2"; shift 2 ;;
        -c|--cover) COVER_FILE="$2"; shift 2 ;;
        -g|--genre) GENRE="$2"; shift 2 ;;
        -y|--year) YEAR="$2"; shift 2 ;;
        -p|--publisher) PUBLISHER="$2"; shift 2 ;;
        -s|--summary) SUMMARY="$2"; shift 2 ;;
        -b|--bitrate) BITRATE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "[错误] 未知参数: $1"; usage ;;
    esac
done

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_FILE" || -z "$TITLE" ]]; then
    echo "[错误] 缺少必填参数 (-i, -o, -t)"
    usage
fi

# Detect FFmpeg
FFMPEG_BIN=""
for candidate in "ffmpeg" "/opt/homebrew/bin/ffmpeg" "/usr/local/bin/ffmpeg" "$HOME/.local/bin/ffmpeg"; do
    if command -v "$candidate" >/dev/null 2>&1; then
        FFMPEG_BIN=$(command -v "$candidate")
        break
    elif [[ -x "$candidate" ]]; then
        FFMPEG_BIN="$candidate"
        break
    fi
done

if [[ -z "$FFMPEG_BIN" ]]; then
    echo "[!] 未检测到 ffmpeg，尝试自动安装..."
    if command -v brew >/dev/null 2>&1; then
        brew install ffmpeg
        FFMPEG_BIN=$(command -v ffmpeg)
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y ffmpeg
        FFMPEG_BIN=$(command -v ffmpeg)
    fi
fi

if [[ -z "$FFMPEG_BIN" ]]; then
    echo "[错误] 未找到 ffmpeg，且无法自动安装。请先安装 ffmpeg。"
    exit 1
fi

FFPROBE_BIN=""
for candidate in "ffprobe" "$(dirname "$FFMPEG_BIN")/ffprobe" "/opt/homebrew/bin/ffprobe" "/usr/local/bin/ffprobe"; do
    if command -v "$candidate" >/dev/null 2>&1; then
        FFPROBE_BIN=$(command -v "$candidate")
        break
    elif [[ -x "$candidate" ]]; then
        FFPROBE_BIN="$candidate"
        break
    fi
done

echo "[*] 使用音频引擎: $FFMPEG_BIN"

# Create temporary directory
TEMP_DIR=$(mktemp -d /tmp/audiobook_maker_XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

CONCAT_FILE="$TEMP_DIR/concat.txt"
META_FILE="$TEMP_DIR/metadata.txt"

# Write FFMETADATA header
cat <<EOF > "$META_FILE"
;FFMETADATA1
title=$TITLE
artist=$AUTHOR
album_artist=$AUTHOR
album=$TITLE
genre=$GENRE
date=$YEAR
media_type=2
EOF

if [[ -n "$PUBLISHER" ]]; then
    echo "comment=Publisher: $PUBLISHER" >> "$META_FILE"
fi
if [[ -n "$SUMMARY" ]]; then
    echo "description=$SUMMARY" >> "$META_FILE"
fi

# Collect audio files (natural sort)
FILES=()
while IFS= read -r f; do
    [[ -n "$f" ]] && FILES+=("$f")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" \) | sort -V)

TOTAL_FILES=${#FILES[@]}
if [[ $TOTAL_FILES -eq 0 ]]; then
    echo "[错误] 目录中未找到支持的音频文件: $INPUT_DIR"
    exit 1
fi

echo "[*] 找到 $TOTAL_FILES 个音频章节，正在计算精确时长..."

CURRENT_MS=0
INDEX=1

for FILE in "${FILES[@]}"; do
    BASENAME=$(basename "$FILE")
    # Clean chapter title
    CH_TITLE=$(echo "$BASENAME" | sed -E 's/\.[^.]+$//' | sed -E 's/^[0-9]+[ ._:-]+//')
    [[ -z "$CH_TITLE" ]] && CH_TITLE="$BASENAME"

    # Get duration using ffprobe
    DUR=$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE" 2>/dev/null || echo "0")
    if [[ "$DUR" == "0" || -z "$DUR" ]]; then
        echo "[警告] 无法读取时长，跳过: $BASENAME"
        continue
    fi

    # Millisecond calculation via awk
    DUR_MS=$(awk -v d="$DUR" 'BEGIN { printf "%.0f", d * 1000 }')
    END_MS=$(( CURRENT_MS + DUR_MS ))

    echo "  [$INDEX/$TOTAL_FILES] $CH_TITLE ($(awk -v d="$DUR" 'BEGIN { printf "%.1fs", d }'))"

    # Append to concat.txt
    ESCAPED_PATH=$(echo "$FILE" | sed "s/'/'\\\\''/g")
    echo "file '$ESCAPED_PATH'" >> "$CONCAT_FILE"

    # Append chapter to metadata.txt
    cat <<EOF >> "$META_FILE"
[CHAPTER]
TIMEBASE=1/1000
START=$CURRENT_MS
END=$END_MS
title=$CH_TITLE
EOF

    CURRENT_MS=$END_MS
    INDEX=$(( INDEX + 1 ))
done

# Check cover
if [[ -z "$COVER_FILE" ]]; then
    for candidate in "$INPUT_DIR/cover.jpg" "$INPUT_DIR/cover.png" "$INPUT_DIR/folder.jpg"; do
        if [[ -f "$candidate" ]]; then
            COVER_FILE="$candidate"
            echo "[*] 自动采用本地封面: $COVER_FILE"
            break
        fi
    done
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "[*] 正在通过 FFmpeg 进行 AAC 编码与 M4B 封装..."

FFMPEG_CMD=(
    "$FFMPEG_BIN" -y -hide_banner
    -f concat -safe 0 -i "$CONCAT_FILE"
    -i "$META_FILE"
)

if [[ -n "$COVER_FILE" && -f "$COVER_FILE" ]]; then
    FFMPEG_CMD+=(
        -i "$COVER_FILE"
        -map 0:a:0 -map_metadata 1 -map_chapters 1
        -map 2:v:0 -c:v mjpeg -disposition:v:0 attached_pic
    )
else
    FFMPEG_CMD+=(
        -map 0:a:0 -map_metadata 1 -map_chapters 1
    )
fi

FFMPEG_CMD+=(
    -c:a aac -b:a "$BITRATE" -ar 44100 -ac 2
    -metadata:s:a:0 language=zho
    -movflags +faststart+disable_chpl
    -movie_timescale 1000
    -f ipod
    "$OUTPUT_FILE"
)

"${FFMPEG_CMD[@]}"

TOTAL_SEC=$(( CURRENT_MS / 1000 ))
TOTAL_H=$(( TOTAL_SEC / 3600 ))
TOTAL_M=$(( (TOTAL_SEC % 3600) / 60 ))
TOTAL_S=$(( TOTAL_SEC % 60 ))

echo ""
echo "[成功] 有声书制作完成 (Shell 引擎)！"
echo "  输出文件: $OUTPUT_FILE"
echo "  总 时 长: ${TOTAL_H}小时${TOTAL_M}分${TOTAL_S}秒"
echo "  章节数量: $(( INDEX - 1 )) 章"
