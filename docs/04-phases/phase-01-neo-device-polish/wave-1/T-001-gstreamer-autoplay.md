---
id: T-001
title: "GStreamer H.264 codec — phim tự play trên NEO One"
assignee: "devops"
status: "REVIEW"
phase: "phase-01-neo-device-polish"
wave: "wave-1"
priority: "P0"
scope: "app"
ui: "no"
design_required: "no"
design_ref: "N/A"
dependencies: []
references:
  - "src/neo_stopmotion/core/video_exporter.py"
  - "src/neo_stopmotion/ui/qml/pages/SuccessPage.qml"
  - "scripts/install_on_neo.sh"
---

# T-001: GStreamer H.264 codec — phim tự play trên NEO One

## Mục tiêu
Sau khi xuất phim MP4 (H.264/libx264), SuccessPage.qml tự động phát video ngay trên NEO One
(Armbian Debian 12, aarch64) — hiện không phát vì thiếu bộ giải mã GStreamer cho H.264.

## Bối cảnh kỹ thuật (root-cause đã xác định)
- `src/neo_stopmotion/core/video_exporter.py` xuất MP4 với codec `libx264`, `pix_fmt=yuv420p`.
- `src/neo_stopmotion/ui/qml/pages/SuccessPage.qml` dùng `MediaPlayer` + `VideoOutput` (Qt6 Multimedia).
  - macOS: backend AVFoundation → decode H.264 natively → tự play OK.
  - NEO One Linux: backend GStreamer → cần plugin `avdec_h264` (từ `gstreamer1.0-libav`).
- Thiết bị hiện có: `gstreamer1.0-plugins-base`, `gstreamer1.0-plugins-good`, `libqt6multimedia6`, `qml6-module-qtmultimedia`.
- Thiết bị THIẾU: `gstreamer1.0-libav` (cung cấp `avdec_h264`) + `gstreamer1.0-plugins-bad`.
- Bằng chứng: `gst-inspect-1.0 | grep avdec_h264` → rỗng trên thiết bị trước fix.

## Phạm vi
### Trong phạm vi
- Cài `gstreamer1.0-libav` và `gstreamer1.0-plugins-bad` lên NEO One (thiết bị thật).
- Thêm 2 packages trên vào danh sách `apt-get install` trong `scripts/install_on_neo.sh`
  (block ARM, hàm `install_system_deps`, dòng ~156-182).
- QA verify reproduce-first: chứng minh không play TRƯỚC fix → play OK SAU fix.

### Ngoài phạm vi
- Thay đổi codec xuất phim (giữ nguyên libx264).
- Thay đổi logic QML MediaPlayer.
- Thay đổi môi trường macOS.

## Câu hỏi làm rõ
1. Trên thiết bị thật, lệnh `gst-inspect-1.0 | grep avdec_h264` trả về gì trước fix?
   (Trả lời đã biết từ root-cause: rỗng — dùng để confirm baseline.)
2. `gstreamer1.0-plugins-bad` có sẵn trên apt Armbian Debian 12 aarch64 không?
   (DevOps kiểm: `apt-cache show gstreamer1.0-plugins-bad` trước khi cài.)
3. Sau khi cài, QA chạy `gst-inspect-1.0 avdec_h264` — phải thấy plugin loaded để confirm.

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|
| 1 | avdec_h264 trước fix | rỗng (xác nhận bởi parent/PO điều tra) | 2026-06-14 |

## ⚠️ Cập nhật root-cause (2026-06-14, khi thực thi)
Cài codec là **CẦN nhưng CHƯA ĐỦ**. `decodebin`/`playbin` (Qt MediaPlayer dùng) tự chọn
decoder phần cứng Allwinner **`v4l2slh264dec`** (rank 257 > avdec_h264 256) nhưng nó lỗi
allocation → "Internal data stream error" → vẫn không play. Fix bổ sung: đặt
`GST_PLUGIN_FEATURE_RANK=v4l2slh264dec:NONE` để ép dùng `avdec_h264` (phần mềm).
Đã đặt trong **`src/neo_stopmotion/__main__.py`** (guard Linux, trước khi Qt Multimedia load,
no-op trên macOS) thay vì trong installer — để mọi cách khởi chạy (icon/terminal) đều có.
→ Files to Touch bổ sung: `src/neo_stopmotion/__main__.py`.

## Acceptance Criteria (kèm file/dòng/thay đổi)

- [ ] **AC1 — Reproduce baseline (QA, TRƯỚC fix)**: SSH vào NEO One, chạy:
  ```bash
  gst-inspect-1.0 | grep avdec_h264
  ```
  Kết quả: **rỗng** (xác nhận bug tồn tại).

- [ ] **AC2 — Cài packages trên thiết bị**: DevOps chạy trên NEO One:
  ```bash
  sudo apt-get install -y gstreamer1.0-libav gstreamer1.0-plugins-bad
  ```
  Kết quả: cài thành công, không lỗi.

- [ ] **AC3 — GStreamer plugin khả dụng sau fix**: Chạy:
  ```bash
  gst-inspect-1.0 avdec_h264
  ```
  Kết quả: hiển thị thông tin plugin (không còn "No such element").

- [ ] **AC4 — Phim tự play trên SuccessPage**: Chạy app (`neo-stopmotion`) trên NEO One
  với GUI session user `neo`, thực hiện chụp + xuất phim, vào SuccessPage.
  Kết quả: video tự phát trong vài giây sau khi xuất xong (không cần bấm nút).

- [ ] **AC5 — Fix gốc vào installer**: File `scripts/install_on_neo.sh`, hàm
  `install_system_deps`, block ARM (dòng ~156-182), thêm 2 dòng:
  ```
  gstreamer1.0-libav \
  gstreamer1.0-plugins-bad \
  ```
  vào danh sách `apt-get install -y -qq`. Tái chạy installer trên thiết bị sạch
  (hoặc `--uninstall` + chạy lại) → không cần cài tay nữa.

## Files to Touch
| File | Thay đổi |
|------|---------|
| `scripts/install_on_neo.sh` | Thêm `gstreamer1.0-libav` và `gstreamer1.0-plugins-bad` vào block ARM apt-get install (dòng ~156-182) |

## Test (bắt buộc — không có kết quả test = chưa xong)

### Test Scenarios
| TS-ID | Scenario | Priority | Cần test? |
|-------|----------|----------|-----------|
| TS-001 | avdec_h264 rỗng trước fix (baseline) | P0 | YES — reproduce-first |
| TS-002 | avdec_h264 khả dụng sau cài package | P0 | YES |
| TS-003 | Video tự play trên SuccessPage sau xuất | P0 | YES — on-device |
| TS-004 | Installer chạy lại từ đầu → packages được cài tự động | P1 | YES |

### Lệnh verify on-device
```bash
# Reproduce-first (trước fix — QA chụp màn hình/copy output):
ssh root@192.168.1.12 "gst-inspect-1.0 2>/dev/null | grep avdec_h264 || echo 'EMPTY — bug confirmed'"

# Sau fix:
ssh root@192.168.1.12 "gst-inspect-1.0 avdec_h264 | head -5"

# App test (chạy với GUI session neo):
# → vào màn hình XFCE, mở terminal, chạy: neo-stopmotion
# → chụp frame → export → SuccessPage hiện → video tự play
```

Cổng chấp nhận:
- [ ] AC1 reproduce bug (output rỗng) có bằng chứng (terminal output)
- [ ] AC3 plugin khả dụng sau fix (output gst-inspect có thông tin)
- [ ] AC4 video tự play trên thiết bị thật
- [ ] AC5 installer cập nhật — `scripts/install_on_neo.sh` diff đã thêm 2 gói
- [ ] `make lint` PASS trên macOS (install_on_neo.sh là bash — ruff/mypy không check; kiểm bash syntax: `bash -n scripts/install_on_neo.sh`)

## Rủi ro / Ghi chú
- `gstreamer1.0-plugins-bad` tên package có thể khác trên Armbian (thường là `gstreamer1.0-plugins-bad`); DevOps kiểm trước khi cài.
- Cài GStreamer plugin không ảnh hưởng phần encode (ffmpeg dùng libx264 độc lập với GStreamer).
- Không cần sửa QML — logic `onSourceChanged: play()` đã đúng, chỉ cần backend có codec.

## Output Contract khi xong
- [ ] `scripts/install_on_neo.sh` đã thêm 2 gói GStreamer
- [ ] Bằng chứng reproduce (trước fix) + verify (sau fix) đính kèm trong báo cáo agent
- [ ] Video tự play trên NEO One thật đã xác nhận on-device
- [ ] `bash -n scripts/install_on_neo.sh` PASS (syntax check)
- [ ] Sẵn sàng cho architect review
- [ ] Đưa lên main qua `ship-to-main.sh` (chỉ `scripts/install_on_neo.sh` — không lẫn tầng team)
