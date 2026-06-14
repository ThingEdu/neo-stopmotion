---
id: T-003
title: "Core: FrameManager.delete_frame(n) + service + signal (TDD)"
assignee: "python-dev"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-2"
priority: "P0"
scope: "app"
ui: "no"
design_required: "no"
design_ref: "N/A"
dependencies: []
spec_ref: "docs/01-specs/features/frame-review-delete/spec.md"
references:
  - "src/neo_stopmotion/core/frame_manager.py"
  - "src/neo_stopmotion/services/app_controller.py"
  - "src/neo_stopmotion/utils/signal_bus.py"
  - "src/neo_stopmotion/core/video_exporter.py"
---

# T-003: Core xoá frame bất kỳ + re-sequence (TDD)

## Mục tiêu
Thêm khả năng xoá frame ở **bất kỳ vị trí nào** (không chỉ frame cuối), giữ đánh số
`frame_%04d.png` liên tục để ffmpeg ghép phim không lỗi. Backend + service + signal,
KHÔNG đụng UI ở task này.

## Spec & quyết định PO
Theo `docs/01-specs/features/frame-review-delete/spec.md` §4.2, §5, §8b.
- n là index **1-based**. Xoá frame cuối ⇒ không cần re-sequence.
- KHÔNG thêm lệnh UART. UNDO frame cuối (`undo_last_frame`) giữ nguyên.
- Append-only sau khi xoá (add_frame không đổi).

## Acceptance Criteria
- [ ] **AC1** `FrameManager.delete_frame(n: int) -> None` trong
  `src/neo_stopmotion/core/frame_manager.py`:
  - Validate `n` trong [1, frame_count], else `raise ValueError`.
  - Xoá `frame_{n:04d}.png`; rename `frame_{n+1}` … `frame_{count}` xuống 1 bậc (tăng dần để không đè).
  - Cập nhật `metadata.frame_count -= 1`, `duration_seconds = frame_count / fps_playback`, lưu `project.json`.
- [ ] **AC2** `AppController._do_delete_frame(n)` trong
  `src/neo_stopmotion/services/app_controller.py`: gọi delete_frame, emit
  `signal_bus.frame_deleted(new_count)`, log. Thêm method public cho UI gọi (vd `handle_delete_frame(n)`).
- [ ] **AC3** `signal_bus.frame_deleted = pyqtSignal(int)` trong
  `src/neo_stopmotion/utils/signal_bus.py`.
- [ ] **AC4** pytest phủ **9 P0** (TS-01..TS-09) + nên có P1 (TS-10..TS-12) trong
  `tests/` cạnh code. TDD: viết test trước, đỏ → code → xanh.
- [ ] **AC5** `make test` + `make lint` PASS (ruff line-length 100, mypy strict).
  Nếu môi trường chưa có ruff/mypy/pytest → cài vào venv dev rồi chạy; đính kèm output.

## Test Scenarios (từ spec §7 — bắt buộc)
TS-01 xoá giữa re-sequence · TS-02 xoá cuối (không rename) · TS-03 xoá đầu ·
TS-04 xoá rồi export ffmpeg OK (dùng exporter thật hoặc kiểm danh sách file liên tục) ·
TS-05 frame_count+duration đúng · TS-06 xoá khi 0 frame → ValueError ·
TS-07 index ngoài vùng → ValueError · TS-08 undo_last_frame cũ vẫn đúng ·
TS-09 frame_deleted emit đúng giá trị · (P1) TS-10 xoá liên tiếp · TS-11 xoá frame duy nhất · TS-12 hiệu năng 100 frame < 3s.

## Files to Touch
| File | Thay đổi |
|------|---------|
| `src/neo_stopmotion/core/frame_manager.py` | + `delete_frame(n)` |
| `src/neo_stopmotion/services/app_controller.py` | + `_do_delete_frame`/`handle_delete_frame` |
| `src/neo_stopmotion/utils/signal_bus.py` | + signal `frame_deleted` |
| `tests/` | + test cho delete_frame (TS-01..TS-12) |

## Output Contract
- [ ] `make test` PASS (kèm số test) + `make lint` PASS, đính kèm output
- [ ] Không đụng UART protocol; undo_last_frame còn nguyên
- [ ] Sẵn sàng cho T-004 (UI) build lên trên
