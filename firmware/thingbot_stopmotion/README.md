# NeoStopMotion ThingBot Firmware

Firmware Arduino cho ThingBot — bảng mạch nút bấm vật lý để điều khiển NEO Stop Motion qua UART.

## Phần cứng

- **Vi điều khiển**: Arduino Uno / ESP32 DevKit / ThingBot board chuẩn
- **2× Arcade button** (đường kính 30mm, tiếp điểm NO)
- **2× LED** (xanh + đỏ, có điện trở 220Ω)
- **1× Buzzer thụ động** (tuỳ chọn)
- **USB cable** kết nối với NEO One

## Sơ đồ nối dây (Arduino Uno)

```
Arduino     Component
-------     ---------------------------------
GND ────┬── IO1 button GND pin
        ├── IO2 button GND pin
        ├── LED1 cathode (chân ngắn)
        ├── LED2 cathode
        └── Buzzer GND

D4 ────────── IO1 button signal pin   (INPUT_PULLUP)
D7 ────────── IO2 button signal pin   (INPUT_PULLUP)
D5 ──[220Ω]── LED1 anode (xanh — báo SHOOT)
D8 ──[220Ω]── LED2 anode (đỏ — báo EXPORT)
D6 ────────── Buzzer signal pin

5V ────────── (cấp qua USB)
```

## Mapping nút → lệnh UART

| Nút | GPIO | Lệnh gửi | Tương đương phím | Hành động NEO One |
|---|---|---|---|---|
| **IO1** (xanh) | D4 | `SHOOT\n` | `Space` | Chụp 1 frame, lưu PNG |
| **IO2** (đỏ) | D7 | `EXPORT\n` | `Enter` | Tạo phim MP4 + GIF |
| _(boot)_ | — | `READY\n` | — | NEO One auto-detect ThingBot |

## Flash firmware

### Cách 1: PlatformIO (khuyến nghị)

```bash
cd firmware/thingbot_stopmotion
pio run -e uno -t upload         # Arduino Uno
pio run -e esp32 -t upload       # ESP32 DevKit
pio device monitor                # quan sát Serial output
```

### Cách 2: Arduino IDE

1. Mở `thingbot_stopmotion.ino` trong Arduino IDE
2. **Tools → Board** → Arduino Uno (hoặc ESP32 Dev Module)
3. **Tools → Port** → `/dev/cu.usbmodemXXXX` (macOS) hoặc `/dev/ttyUSB0` (Linux)
4. **Sketch → Upload**

## Kiểm thử thủ công

```bash
screen /dev/cu.usbmodem* 115200
# Trên macOS, tìm port: ls /dev/cu.* | grep -i usb

# Output mong đợi:
# READY            <- ngay sau boot
# SHOOT            <- mỗi lần bấm IO1
# EXPORT           <- mỗi lần bấm IO2
```

## Thông số kỹ thuật

| Thông số | Giá trị |
|---|---|
| Baud rate | 115200 8N1 |
| Debounce | 50 ms phía firmware (+ 200 ms phía Python) |
| Tần số tone IO1 | 1200 Hz / 40 ms (tiếng "tách") |
| Tần số tone IO2 | 800 → 1600 Hz / 100 ms × 2 (tiếng "thành công") |

## Triết lý thiết kế

Theo spec gốc, ThingBot ban đầu dùng **1 nút với 3 mức nhấn** (short = SHOOT, long 1s = UNDO, long 3s = EXPORT). Bản v1.0 này đơn giản hoá thành **2 nút riêng biệt** (IO1 + IO2) theo yêu cầu vận hành thực tế:

- Trẻ 6-9 tuổi khó căn thời gian giữ nút.
- Hai nút màu khác nhau (xanh/đỏ) cho cảm giác trực quan: "chụp" vs "tạo phim".
- UNDO chuyển sang phím `Z` trên bàn phím (Thợ Cả thao tác giúp HS).

## License

MIT — theo cam kết Bình Dân Học STEM.
