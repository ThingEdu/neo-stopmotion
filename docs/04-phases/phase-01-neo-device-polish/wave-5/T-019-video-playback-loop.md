---
id: T-019
title: "Phim không play trên NEO One + loop có nghỉ 5s"
assignee: "python-dev"
status: "DONE"
phase: "phase-01-neo-device-polish"
wave: "wave-5"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "no"
design_ref: "N/A"
dependencies: ["T-001"]
references:
  - "src/neo_stopmotion/media_env.py"
  - "src/neo_stopmotion/ui/qml/pages/SuccessPage.qml"
  - "src/neo_stopmotion/ui/qml/pages/LibraryPage.qml"
  - "scripts/install_on_neo.sh"
---

# T-019: Phim không play trên NEO One + loop có nghỉ 5s

## Mục tiêu
1. SuccessPage phát được phim trên NEO One thật (T-001 chưa đóng được vấn đề).
2. Phim phát xong nghỉ 5 giây rồi tự phát lại, lặp vô hạn (yêu cầu PO 2026-08-19).

## Root cause thật (đo trên NEO One 192.168.1.28, Armbian bookworm aarch64)

T-001 kết luận thiếu codec H.264 — đúng nhưng **chưa tới đáy**. Ba tầng:

1. **Thiếu decoder** — máy chỉ có `gstreamer1.0-plugins-base` + `-good`, không có
   `gstreamer1.0-libav` ⇒ không element nào decode được H.264.
   Bằng chứng: `gst-launch-1.0 playbin uri=file://…/output.mp4` →
   `Missing decoder: H.264 (High Profile)`.

2. **Qt không nạp nổi backend nào** (tầng T-001 bỏ sót, và là lý do thật khiến
   màn hình đen). App chạy trong venv với **PyQt6 6.7.1 / Qt 6.7.3 từ wheel PyPI**,
   không dùng Qt 6.4.2 của hệ thống. Qt 6.7 mặc định backend **ffmpeg**, mà
   `libffmpegmediaplugin.so` trong wheel link `libav*.so.58` (ffmpeg 4.x) trong khi
   Debian 12 có ffmpeg 5.x (`libavcodec.so.59`) ⇒ plugin nạp lỗi, **Qt bỏ cuộc luôn
   chứ không thử tiếp plugin gstreamer**:
   `No QtMultimedia backends found` / `Failed to initialize QMediaPlayer "Not available"`.
   Thêm nữa `libgstreamermediaplugin.so` thiếu `libgstphotography-1.0.so.0`.

3. **Loop `MediaPlayer.Infinite` không đáng tin** trên backend GStreamer: chạy được
   ~8 vòng rồi kẹt ở `StoppedState`, không phát ra event `EndOfMedia` nào, phim đứng
   hình ở khung cuối.

## Giải pháp
| Tầng | Cách xử lý |
|------|-----------|
| 1 | apt `gstreamer1.0-libav` (avdec_h264) |
| 2 | apt `libgstreamer-plugins-bad1.0-0` + ép `QT_MEDIA_BACKEND=gstreamer` trong `media_env.py` (chạy trước khi Qt Multimedia nạp) |
| 3 | Bỏ `loops: Infinite`, tự điều khiển: `EndOfMedia` → `position=0` + `pause()` → Timer 5s → `play()` |

Dùng `pause()` chứ không `stop()`: pipeline stopped xoá video sink làm khung phim
**đen suốt 5 giây nghỉ**; pause tại vị trí 0 giữ khung hình đầu trên màn hình.

Cố ý cài `libgstreamer-plugins-bad1.0-0` (thư viện) thay vì `gstreamer1.0-plugins-bad`
(bộ plugin): bộ plugin kéo theo `v4l2slh264dec` của Allwinner — chính con decoder
rank 257 lỗi allocation mà T-001 phải hạ rank. Guard hạ rank vẫn giữ trong
`media_env.py` để phòng máy đã lỡ cài.

## Acceptance Criteria
- [x] **AC1** — `gst-launch-1.0 playbin` chạy tới EOS sạch (trước fix: `Missing decoder`).
- [x] **AC2** — `QMediaPlayer` chạy bằng **python của venv app** nhận được frame hợp lệ
      (trước fix: `frames_received = 0`, `Error.ResourceError`).
- [x] **AC3** — App thật trên DISPLAY=:0, **không** set env tay: log không còn dòng
      `No QtMultimedia backends`; ảnh chụp SuccessPage hiện khung phim đã giải mã.
- [x] **AC4** — Loop có nghỉ: ảnh chụp cách nhau 1s cho thấy phim chạy → giữ khung đầu
      ~5s → chạy lại. Đo nhịp: phim 1.6s, khoảng cách giữa 2 lần bắt đầu phát
      **6.88s / 6.88s / 7.89s** (ổn định, không kẹt).
- [x] **AC5** — Lúc nghỉ hiện khung hình đầu phim, không phải màn đen.
- [x] **AC6** — `make test` 131 PASS; ruff/mypy sạch trên file mới.

## Bằng chứng
```
# Trước fix (app venv):
No QtMultimedia backends found. Failed to initialize QMediaPlayer "Not available"
frames_received = 0 | valid = 0 | error = Error.ResourceError Not available

# Sau fix (app venv, cùng file mp4):
status: LoadingMedia → LoadedMedia → BufferedMedia → EndOfMedia
frames_received = 32 | valid = 31 | error = Error.NoError

# Nhịp lặp (22s):
film duration = 1600 ms
play starts at (s): [0.0, 7.89, 14.77, 21.65]
gaps between starts (s): [7.89, 6.88, 6.88]
```

## Còn lại
- [ ] PO test tay trên NEO One: làm phim → xem loop + bấm Space dừng/phát.
- [ ] Đưa lên main qua `ship-to-main.sh` (chỉ đường dẫn code).
- [ ] `debian/control` (chỉ có trên main) cần thêm `libgstreamer-plugins-bad1.0-0`.
