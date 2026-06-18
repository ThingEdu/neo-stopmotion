---
id: T-016
title: "Fix: enumerate camera thật + hot-plug guard + đổi chữ Camera"
assignee: python-dev
status: TODO
phase: phase-01-neo-device-polish
wave: wave-5
priority: P0
scope: app
ui: yes
design_required: no
design_ref: N/A
dependencies: [T-015]
references:
  - "docs/01-specs/features/camera-select/spec.md"
  - "src/neo_stopmotion/services/camera_selector.py"
  - "src/neo_stopmotion/services/app_controller.py"
  - "src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml"
---

# T-016: Fix enumerate camera thật + hot-plug guard + đổi chữ "Camera"

## Mục tiêu
Sửa 3 nhóm vấn đề trong màn "Chọn camera" — tất cả test T-015 phải chuyển từ FAIL → PASS
sau task này.

## Phạm vi
### Trong phạm vi

**Phần 1 — Enumerate camera thật (bug gốc rễ)**
- `CameraSelector.list_available_indices()` — phương thức mới, probe index 0-5 nhanh
  (`retry_delay_seconds=0`), trả về `list[int]` chỉ gồm index mở được.
- `AppController.get_available_camera_indices()` — `@pyqtSlot(result="QVariantList")` mới,
  gọi `_camera_selector.list_available_indices()`, trả `list[int]` cho QML.
- QML `CameraPickerPopup.qml`: thay `model: 6` và `% 6` bằng dynamic list từ slot;
  dots = số camera thật; text "Camera N / M" theo M thật; phím 1–M thay 1–6.
  - Khi list rỗng → hiện trạng thái "Không tìm thấy camera nào" ngay lập tức (không cần navigate).
  - Khi list có 1 item → hiện "Camera 1 / 1", không có nút trước/sau (hoặc disable).

**Phần 2 — Hot-plug re-scan**
- QML Timer re-scan ~2000ms: CHỈ chạy khi `popup.opened === true && noCamera === true`.
  Khi tìm thấy camera → `timer.stop()` ngay, gọi `get_available_camera_indices()` mới, cập nhật list.
- Nút "Quét lại" thủ công trên màn no-camera (fallback an toàn, luôn có).
- TUYỆT ĐỐI không để timer chạy khi popup đóng, không quét ở CapturePage chính.
  (Vi phạm ràng buộc này = blocker, không merge.)

**Phần 3 — Đổi chữ "Máy ảnh" → "Camera" toàn bộ**
- `CameraPickerPopup.qml`: tất cả text hiển thị
  - "Chọn máy ảnh" → "Chọn camera"
  - "Máy ảnh N / 6" → "Camera N / M"
  - "Máy trước" → "Camera trước"
  - "Máy tiếp" → "Camera sau"
  - "✓ DÙNG MÁY ẢNH NÀY" → "✓ DÙNG CAMERA NÀY"
  - hint `{ keys: "◀  ▶", desc: "đổi máy" }` → desc: "đổi camera"
- Quét toàn repo bằng grep xác nhận không còn "máy ảnh"/"Máy ảnh" trong text hiển thị user
  (exclude comments code, chỉ nhìn string literals QML + Python UI).
- Cập nhật spec `docs/01-specs/features/camera-select/spec.md` nếu còn chữ cũ trong phần
  UI states.

### Ngoài phạm vi
- Hiện tên thiết bị ("FaceTime HD") — roadmap R-3
- Tự động detect hot-plug ở CapturePage khi popup đóng
- Bất kỳ background scan nào khi app đang ở màn chụp chính

## Acceptance Criteria (kèm file/dòng/thay đổi)

- [ ] **AC1**: `CameraSelector.list_available_indices()` tồn tại, probe nhanh (`retry_delay_seconds=0`)
  - **File**: `src/neo_stopmotion/services/camera_selector.py`
  - **Vị trí**: thêm method sau `probe_any()`
  - **Thay đổi**: method mới, dùng `CaptureEngine(webcam_index=idx, retry_count=1, retry_delay_seconds=0)`

- [ ] **AC2**: `AppController.get_available_camera_indices()` là pyqtSlot trả `QVariantList`
  - **File**: `src/neo_stopmotion/services/app_controller.py`
  - **Vị trí**: nhóm T-005 slots
  - **Thay đổi**: slot mới, fallback về `[0]` nếu `_camera_selector is None`

- [ ] **AC3**: QML dùng dynamic list, không còn hardcode `% 6`, `model: 6`, text "/ 6"
  - **File**: `src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml`
  - **Thay đổi**: property `availableIndices: []`; gọi `appController.get_available_camera_indices()` khi `onOpened`; model dots = `availableIndices.length`; navigation theo index trong list

- [ ] **AC4**: Máy 1 camera → hiện "Camera 1 / 1", không có ô hỏng
  - **Test**: `tests/unit/test_camera_select.py::test_list_available_indices_returns_only_working_cameras` PASS

- [ ] **AC5**: Máy 0 camera → hiện trạng thái "Không tìm thấy camera nào" ngay khi popup mở
  - **Test**: `tests/unit/test_camera_select.py::test_list_available_indices_empty_when_no_camera` PASS

- [ ] **AC6**: Hot-plug Timer chỉ chạy khi `popup.opened && noCamera`; dừng ngay khi tìm thấy
  - **File**: `src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml`
  - **Thay đổi**: `Timer { interval: 2000; running: root.opened && root.noCamera; ... }`
  - **Test**: `tests/unit/test_camera_select.py::test_hotplug_scan_only_when_popup_open_and_no_camera` PASS

- [ ] **AC7**: Nút "Quét lại" xuất hiện trên màn no-camera
  - **File**: `src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml`
  - **Vị trí**: Column no-camera state
  - **Thay đổi**: thêm Button "Quét lại" gọi `rescan()`

- [ ] **AC8**: Không còn "Máy ảnh"/"máy ảnh" trong string literal QML CameraPickerPopup
  - **Verify**: `grep -n "Máy ảnh\|máy ảnh" src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml` → không kết quả
  - Tất cả text đã đổi đúng theo mapping trong phần Phạm vi

- [ ] **AC9**: `retry_delay_seconds=0` khi probe trong `list_available_indices`
  - **Test**: `tests/unit/test_camera_select.py::test_list_available_indices_uses_zero_retry_delay` PASS

- [ ] **AC10**: `get_available_camera_indices` slot tồn tại và trả list đúng
  - **Test**: `tests/unit/test_camera_select.py::test_appcontroller_slot_returns_available_indices` PASS

## Test (bắt buộc — không có kết quả test = chưa xong)
### BA Test Scenarios (từ spec + mới)
| TS-ID | Scenario | Priority | Cần test? |
|-------|----------|----------|-----------|
| TS-01 | Happy path chọn camera thành công | P0 | YES |
| TS-03 | Camera kế tiếp không hoạt động | P0 | YES |
| TS-05 | Không có camera nào (0-5 fail) | P0 | YES |
| TS-NEW-1 | list_available_indices chỉ trả index mở được | P0 | YES |
| TS-NEW-2 | list_available_indices probe với retry_delay=0 | P0 | YES |
| TS-NEW-3 | AppController slot get_available_camera_indices | P0 | YES |
| TS-NEW-4 | Hot-plug guard: timer chỉ chạy đúng điều kiện | P0 | YES |

### Test File Mapping
| TS-ID | Test file | Method |
|-------|-----------|--------|
| TS-NEW-1 | `tests/unit/test_camera_select.py` | `test_list_available_indices_returns_only_working_cameras` |
| TS-NEW-2 | `tests/unit/test_camera_select.py` | `test_list_available_indices_uses_zero_retry_delay` |
| TS-NEW-3 | `tests/unit/test_camera_select.py` | `test_appcontroller_slot_returns_available_indices` |
| TS-NEW-4 | `tests/unit/test_camera_select.py` | `test_hotplug_scan_only_when_popup_open_and_no_camera` |

### Lệnh verification gate
```bash
cd /Volumes/Extend_Disk/Ext_Workspace/ThingEdu/neo-stopmotion

# 1. Chạy toàn bộ test suite
make test

# 2. Lint
make lint

# 3. Xác nhận không còn text cũ trong QML
grep -rn "Máy ảnh\|máy ảnh\|/ 6\|% 6\|model: 6\|Key_6" \
  src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml

# 4. Xác nhận hot-plug timer có running guard
grep -n "noCamera\|running:" \
  src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml

# 5. Smoke headless (chạm capture/export)
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
```

Cổng chấp nhận:
- [ ] Tất cả test T-015 (5 test reproduce) → PASS
- [ ] Tổng test suite PASS (không giảm so với trước)
- [ ] ruff + mypy PASS
- [ ] grep không tìm thấy "Máy ảnh" trong QML string literals
- [ ] grep xác nhận timer có `running: root.opened && root.noCamera`

## Rủi ro / Ghi chú
- `list_available_indices()` sẽ tốn ~0s × 6 = nhanh (retry_delay=0). Cần xác nhận điều này.
- Nếu `_camera_selector is None` (synthetic mode): `get_available_camera_indices` trả `[0]` —
  app không crash nhưng picker hiện 1 ô "Camera 1 / 1" (hành vi hợp lý).
- QML: khi `availableIndices` thay đổi → cập nhật `currentIndex` về vị trí 0 trong list mới
  (tránh index out-of-bounds nếu list ngắn hơn).
- Hot-plug Timer `interval: 2000` (2s). Không dùng 500ms (quá tốn CPU/USB).

## Output Contract khi xong
- [ ] Code trong `src/neo_stopmotion/services/camera_selector.py` (method mới)
- [ ] Code trong `src/neo_stopmotion/services/app_controller.py` (slot mới)
- [ ] Code trong `src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml` (enumerate + hot-plug + wording)
- [ ] Test PASS (5 test T-015 + toàn bộ suite)
- [ ] Sẵn sàng cho T-017 Architect gate
- [ ] Không rò rỉ tầng team vào code (`src/` sạch)
