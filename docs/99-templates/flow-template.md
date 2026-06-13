# Flow: [Tên luồng]

> Mô tả luồng tương tác end-to-end (PO/BA dùng để thống nhất hành vi).

## Actors
- Trẻ (6-14) · Thợ Cả · App · ThingBot (firmware) · Cloud

## Happy path
1. ...
2. ...

## Sơ đồ
```
[Idle] --IO1--> [Capture frame] --...--> [IO2] --> [Export] --> [Success/QR] --IO1--> [Idle]
```

## Nhánh lỗi
| Bước | Lỗi | Xử lý |
|------|-----|-------|
| Chụp | mất camera | fallback synthetic + báo |
| Export | <5 frame | chặn + báo |
| Upload | mạng lỗi | fallback 0x0.st |

## Ghi chú UART (nếu firmware/both)
- IO1 → message capture · IO2 → message export (khớp `uart_protocol.py`)
