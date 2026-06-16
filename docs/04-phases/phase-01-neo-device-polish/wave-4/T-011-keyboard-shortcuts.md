---
id: T-011
title: "Bản đồ phím tắt đầy đủ toàn app + help overlay + fidelity màn 3/4/6"
assignee: "python-dev"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-4"
priority: "P0"
scope: "app"
ui: "yes"
design_required: "yes"
design_ref: "mockups 02-capture-B / 03-camera-picker / 04-delete-dialog / 06-success"
dependencies: ["T-010"]
references:
  - "src/neo_stopmotion/ui/qml/MainWindow.qml (Keys.onPressed, lines 22-33)"
  - "src/neo_stopmotion/ui/qml/components/FilmStrip.qml (arrow/Delete/Escape, lines 43-54)"
  - "src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml"
  - "src/neo_stopmotion/ui/qml/pages/SuccessPage.qml"
---

# T-011: Phím tắt đầy đủ + help overlay

## Mục tiêu
Triển khai mô hình điều khiển PO chốt: **3 phím cốt lõi** + **đầy đủ phím tắt bàn phím** cho mọi tính năng, mọi màn thao tác được 100% bằng bàn phím. Thêm overlay "Phím tắt" (`?`). Cập nhật fidelity màn 3/4/6 theo mockup.

## Bản đồ phím tắt (chuẩn để code & test)
**Cốt lõi (cũng là nút vật lý IO):**
| Phím | Hành động | IO |
|------|-----------|----|
| `Space` | Chụp | IO1 |
| `Delete` | Xoá (tấm đang chọn, hoặc tấm cuối nếu không chọn) | IO2 |
| `Enter`/`Return` | Tạo phim | IO3 |

**CapturePage — phụ trợ (chỉ bàn phím):**
| `◀` `▶` | Chọn tấm trong filmstrip |
| `Esc` | Bỏ chọn / đóng popup |
| `C` | Mở popup Đổi camera |
| `G` | Mở Thư viện phim |
| `1` `2` `3` | Tốc độ Chậm / Vừa / Nhanh |
| `?` / `F1` | Mở/đóng overlay phím tắt |

**Chọn camera (popup):** `◀ ▶` đổi máy · `1`–`6` chọn nhanh · `Enter` xác nhận · `Esc` huỷ.
**Xác nhận xoá (dialog):** focus mặc định "Thôi để lại"; `Esc` thôi · `Enter`/`Del` xoá.
**Phim đã xong:** `Space` phát/dừng · `S` lưu · `L` chép link · `G` thư viện · `N`/`Enter` làm phim mới.

## Acceptance Criteria
- [ ] **AC1**: Phím cốt lõi giữ nguyên ánh xạ UART (`handle_uart_command` SHOOT/UNDO→nay là DELETE/EXPORT). Phím `Del` xoá theo logic "tấm chọn hoặc tấm cuối".
  - **File**: `MainWindow.qml` (Keys.onPressed), `FilmStrip.qml`, `CapturePage.qml`.
- [ ] **AC2**: `C` mở CameraPickerPopup; `G` điều hướng Thư viện (nối với T-012); `1/2/3` gọi `select_speed`.
- [ ] **AC3**: Camera picker: `◀▶`, `1`–`6`, `Enter`, `Esc` hoạt động đúng; UI khớp mockup 03 (badge phím).
- [ ] **AC4**: Delete dialog: khớp mockup 04 (focus mặc định cancel; `Esc`/`Enter`/`Del`).
- [ ] **AC5**: SuccessPage: `Space` play/pause, `S`/`L`/`G`/`N`/`Enter` hoạt động; UI khớp mockup 06.
- [ ] **AC6**: Overlay phím tắt (`?`/`F1`) liệt kê toàn bộ bản đồ trên, đóng bằng `Esc`/`?`.
- [ ] **AC7**: Logic "xoá tấm chọn hoặc cuối" có **unit test** ở controller (tách logic khỏi QML nếu được).

## Test
| TS | Scenario | P |
|----|----------|---|
| TS-01 | Del khi có selectedIndex → xoá đúng tấm đó | P0 |
| TS-02 | Del khi không chọn → xoá tấm cuối | P0 |
| TS-03 | select_speed("Chậm"/"Vừa"/"Nhanh") set fps 5/8/12 | P0 |
```bash
make test && make lint
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
```

## Output Contract khi xong
- [ ] Phím tắt + help overlay hoạt động; màn 3/4/6 khớp mockup.
- [ ] Unit test phím Del logic PASS.
- [ ] Test guide phím tắt cho QA (mỗi phím/màn).
