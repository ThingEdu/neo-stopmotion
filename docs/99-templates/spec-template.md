# Spec: [Tên feature]

> Feature key: `<feature-key>` · scope: `app|firmware|both` · Owner: BA

## Mục tiêu
[Feature giải bài toán gì cho trẻ / cho Thợ Cả]

## Trạng thái màn hình / luồng
### Loading / Capturing
[Live preview, onion skin, phản hồi khi chụp]
### Empty
[Khi chưa có frame — CTA]
### Error
[Lỗi camera / UART / ffmpeg / upload — cách phục hồi, retry]
### Success
[MP4/GIF đã ghép, QR, auto-reset]

## Test Scenarios
| ID | Scenario | Precondition | Input/Action | Expected | Priority |
|----|----------|-------------|--------------|----------|----------|
| TS-01 | Happy path export | ≥5 frame | bấm IO2 | MP4+GIF+QR | P0 |
| TS-02 | Quá ít frame | <5 frame | bấm IO2 | Báo cần thêm frame | P0 |
| TS-03 | Mất camera | webcam rút | bấm IO1 | Lỗi + fallback synthetic | P1 |
| TS-04 | Upload fail | mạng lỗi | export | Fallback / báo lỗi | P1 |
<!-- scope=both: thêm scenario kiểm UART app↔firmware khớp -->

## Phụ thuộc
- Spec liên quan: ...
- Giao thức UART (nếu firmware/both): `src/neo_stopmotion/hardware/uart_protocol.py`
