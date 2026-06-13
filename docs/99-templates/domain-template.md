# Domain: [Tên feature]

## Luật nghiệp vụ
| # | Điều kiện | Kết quả |
|---|-----------|---------|
| BR-1 | Số frame < 5 | Không cho export, báo cần thêm |
| BR-2 | Export | MP4 1280×720 10fps + GIF 640×360, watermark góc dưới phải 85% |
| BR-3 | ... | ... |

## Validation
- [Trường / ràng buộc / định dạng]

## State machine
[Idle → Capturing → Exporting → Success → (IO1) → Idle]

## Edge Case Matrix
| Tình huống | Hành vi mong đợi | Ghi chú |
|-----------|------------------|---------|
| 0 frame, bấm IO2 | Báo cần ≥5 frame | |
| ffmpeg thiếu | Báo lỗi rõ + hướng dẫn cài | |
| UART timeout | Bỏ qua, app vẫn chạy bằng phím tắt | scope both |
| Upload 5xx | Fallback 0x0.st | |
