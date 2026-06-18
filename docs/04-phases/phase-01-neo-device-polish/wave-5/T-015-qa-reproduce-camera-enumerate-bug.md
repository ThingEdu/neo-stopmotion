---
id: T-015
title: "QA: reproduce-first tests — camera enumerate bug + wording"
assignee: qa
status: TODO
phase: phase-01-neo-device-polish
wave: wave-5
priority: P0
scope: app
ui: yes
design_required: no
design_ref: N/A
dependencies: []
references:
  - "docs/01-specs/features/camera-select/spec.md"
  - "tests/unit/test_camera_select.py"
---

# T-015: QA reproduce-first — camera enumerate bug + wording

## Mục tiêu
Viết bộ test FAIL đúng lý do TRƯỚC khi python-dev sửa, theo quy trình reproduce-first bắt buộc
(WORKING-WITH-PO.md §7). Tất cả test phải FAIL với code hiện tại — nếu PASS thì test sai.

## Phạm vi
### Trong phạm vi
- Test reproduce bug "lúc nào cũng 6 camera" (enumerate không thật, hardcode % 6 và model: 6)
- Test reproduce bug "text Máy ảnh" (cần đổi thành "Camera")
- Test mới cho `list_available_indices()` (chưa tồn tại trong camera_selector.py)
- Test mới cho hot-plug re-scan guard (chỉ quét khi popup MỞ + no-camera state)
- Test verify `retry_delay_seconds=0` khi probe trong `list_available_indices()`

### Ngoài phạm vi
- Fix code (do T-016 python-dev làm)
- QML visual test (không thể headless)

## Acceptance Criteria

- [ ] **AC1**: `test_list_available_indices_returns_only_working_cameras` — FAIL trước fix
  - **File**: `tests/unit/test_camera_select.py`
  - **Vị trí**: thêm vào cuối file
  - **Thay đổi**: gọi `CameraSelector.list_available_indices()` → expect list [0] khi chỉ index 0 OK; method chưa tồn tại → AttributeError → FAIL

- [ ] **AC2**: `test_list_available_indices_empty_when_no_camera` — FAIL trước fix
  - **File**: `tests/unit/test_camera_select.py`
  - **Thay đổi**: mock tất cả index 0-5 fail → expect `[]` → FAIL vì method chưa có

- [ ] **AC3**: `test_list_available_indices_uses_zero_retry_delay` — FAIL trước fix
  - **File**: `tests/unit/test_camera_select.py`
  - **Thay đổi**: verify `CaptureEngine` được khởi tạo với `retry_delay_seconds=0` khi probe trong `list_available_indices`

- [ ] **AC4**: `test_appcontroller_slot_returns_available_indices` — FAIL trước fix
  - **File**: `tests/unit/test_camera_select.py`
  - **Thay đổi**: gọi `appController.get_available_camera_indices()` → slot chưa tồn tại → AttributeError → FAIL

- [ ] **AC5**: `test_hotplug_scan_only_when_popup_open_and_no_camera` — FAIL trước fix
  - **File**: `tests/unit/test_camera_select.py`
  - **Thay đổi**: test logic guard: scan chỉ chạy khi flag `popup_open=True AND no_camera=True`; test hiện tại không có guard này → FAIL

- [ ] **AC6**: Tất cả test AC1-AC5 chạy `pytest tests/unit/test_camera_select.py -k "reproduce"` và xuất hiện `FAILED` (không phải ERROR không liên quan)
  - **Lệnh verify**: `cd <repo_root> && make test 2>&1 | grep -E "PASSED|FAILED|ERROR"`

## Test (bắt buộc)
### Test File Mapping
| AC | Test file | Method |
|----|-----------|--------|
| AC1 | `tests/unit/test_camera_select.py` | `test_list_available_indices_returns_only_working_cameras` |
| AC2 | `tests/unit/test_camera_select.py` | `test_list_available_indices_empty_when_no_camera` |
| AC3 | `tests/unit/test_camera_select.py` | `test_list_available_indices_uses_zero_retry_delay` |
| AC4 | `tests/unit/test_camera_select.py` | `test_appcontroller_slot_returns_available_indices` |
| AC5 | `tests/unit/test_camera_select.py` | `test_hotplug_scan_only_when_popup_open_and_no_camera` |

### Lệnh
```bash
cd /Volumes/Extend_Disk/Ext_Workspace/ThingEdu/neo-stopmotion
# Chạy chỉ test reproduce:
python -m pytest tests/unit/test_camera_select.py -k "test_list_available or test_appcontroller_slot_returns_available or test_hotplug" -v
# Kết quả mong đợi: tất cả FAILED (xác nhận reproduce đúng)
```

Cổng chấp nhận:
- [ ] Mỗi test có docstring ghi rõ "EXPECTED: FAIL before fix — T-016 will make this PASS"
- [ ] ruff + mypy PASS trên file test (test code phải sạch dù FAIL)
- [ ] `git show --stat HEAD` xác nhận test file đã commit trên nhánh team

## Rủi ro / Ghi chú
- Phải dùng mock (không dùng camera thật) để CI không phụ thuộc phần cứng.
- `retry_delay_seconds=0` là ràng buộc hiệu năng quan trọng: enumerate 6 index × 1s = 6s chờ.
- Hot-plug guard: đây là test logic (unit), không test QML Timer.

## Output Contract khi xong
- [ ] File `tests/unit/test_camera_select.py` có thêm 5 test FAIL (reproduce)
- [ ] ruff + mypy PASS
- [ ] Báo cáo: paste kết quả `pytest -v` (FAILED expected)
- [ ] Sẵn sàng để T-016 python-dev implement → chuyển FAIL→PASS
