---
id: T-017
title: "Architect gate: PASS/FAIL camera enumerate fix"
assignee: architect
status: TODO
phase: phase-01-neo-device-polish
wave: wave-5
priority: P0
scope: app
ui: no
design_required: no
design_ref: N/A
dependencies: [T-015, T-016]
references:
  - "docs/01-specs/features/camera-select/spec.md"
  - "docs/02-architecture/two-layer-separation.md"
---

# T-017: Architect gate — camera enumerate fix (wave-5)

## Mục tiêu
Review độc lập toàn bộ thay đổi wave-5 (T-015 + T-016), xác nhận PASS hoặc
chặn BLOCKED trước khi Coordinator tạo PR lên main.

## Checklist gate

### Correctness
- [ ] `list_available_indices()` probe với `retry_delay_seconds=0` (không sleep 1s × 6 = 6s)
- [ ] QML không còn hardcode `% 6` / `model: 6` / "/ 6" — dùng dynamic list từ slot
- [ ] Khi list rỗng → noCamera state đúng, không crash, không infinite loop
- [ ] Khi list = [0] → "Camera 1 / 1", dots = 1, không có index lỗi
- [ ] Hot-plug Timer `running` bound đúng: `root.opened && root.noCamera` (không chạy khi popup đóng)
- [ ] Timer dừng (`timer.stop()`) ngay khi tìm thấy camera
- [ ] Nút "Quét lại" tồn tại trên màn no-camera
- [ ] Không còn "Máy ảnh"/"máy ảnh" trong string QML user-facing

### Test coverage
- [ ] 5 test T-015 PASS (reproduce → fix)
- [ ] Tổng test suite không giảm
- [ ] ruff + mypy PASS

### Two-layer separation
- [ ] `src/` không chứa file tầng team (`docs/`, `.claude/`, `CLAUDE.md`, `AGENTS.md`)
- [ ] `check-no-team-files.sh` PASS
- [ ] Không import đường dẫn docs trong production code

### Performance / stability
- [ ] Không có background scan khi popup đóng (grep Timer trong QML)
- [ ] Không có blocking sleep trong enumerate path
- [ ] Synthetic mode không crash (selector None → fallback [0])

## Output
Architect phải kết thúc bằng 1 trong 3:
- `ARCHITECT PASS` — tiếp tục ship-to-main
- `ARCHITECT FAIL` — liệt kê vấn đề cụ thể, python-dev fix + re-submit
- `ARCHITECT BLOCKED` — thiếu thông tin, cần PO quyết

## Output Contract khi xong
- [ ] Kết quả PASS/FAIL/BLOCKED ghi rõ trong báo cáo gửi Coordinator
- [ ] Mọi điểm FAIL phải có task card mới hoặc note sửa trong T-016
