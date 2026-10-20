# Apple Books / M4B 有声书规范与参数参考

制作高质量、兼容 Apple 设备（iPhone、iPad、Mac 图书 App）及自建服务器（Audiobookshelf、Plex）的 M4B 有声书时，遵循以下规范与参数：

## 1. 容器与封装格式

- **文件扩展名**：`.m4b`（本质为 MP4 容器，指示媒体类型为有声书）。
- **FFmpeg 容器标志**：
  - `-f ipod`：指定符合 iPod / iOS 规范的 MP4 封装。
  - `-movflags +faststart+disable_chpl`：
    - `+faststart`：将 `moov` atom（索引头）移至文件开头，支持流式加载与秒级开始播放。
    - `+disable_chpl`：禁用过时的 Nero 章节列表，强制使用 Apple 标准的 QuickTime Text Chapter Track（`tref/chap` 原子）。
  - `-movie_timescale 1000`：以毫秒（1/1000秒）为时间基准，保证在 iOS 播放器上长音频章节定位精准，防止时间漂移。

## 2. 音频编码参数

- **编码格式**：AAC（`c:a aac`）。
- **采样率**：`44100 Hz`（人声广播标准 CD 采样率，全机型兼容良好）。
- **声道数**：立体声（2 channels）或单声道（1 channel）。
- **码率推荐**：
  - 人声有声书（带配乐/音效）：`96 kbps` ~ `128 kbps` 立体声（兼顾音质与体积）。
  - 纯人声朗读：`64 kbps` 单声道。

## 3. 章节索引规范（FFMETADATA1）

每个章节通过 `[CHAPTER]` 块定义：
```ini
;FFMETADATA1
title=书名
artist=作者
album=书名
genre=Audiobook
date=2026
media_type=2
comment=Publisher: 出版社
description=内容简介

[CHAPTER]
TIMEBASE=1/1000
START=0
END=1500000
title=第一章 章节名称

[CHAPTER]
TIMEBASE=1/1000
START=1500000
END=3000000
title=第二章 章节名称
```
- 特殊字符转义：`=`、`;`、`#`、`\` 必须加 `\` 前缀转义，换行符转为 `\\n`。

## 4. 封面图片（Cover Art）

- **格式**：JPEG 或 PNG（优先正方形 1:1，如 1000×1000 或 1400×1400，也支持横幅）。
- **嵌入参数**：
  `-map 2:v:0 -c:v mjpeg -disposition:v:0 attached_pic`
  将图片流标记为 `attached_pic` 嵌入，Apple Books 和播放器会自动识别为主封面。
