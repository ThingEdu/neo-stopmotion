<div align="center">
  <img src="src/neo_stopmotion/resources/images/maker_viet_logo.png" width="180" alt="Maker Việt"/>

  # NeoStopMotion

  **Maker Việt × ThingEdu — NEO One**

  Stop-motion studio chạy trên **NEO One** (Linux ARM64) với **ThingBot** (UART nút bấm vật lý). Một phần của hệ sinh thái Bình Dân Học STEM của Maker Việt.
</div>

---

## Tính năng v1.0

- Live preview webcam + **onion skin** (frame trước hiện mờ chồng lên live preview)
- Bấm nút ThingBot (hoặc phím Space) → chụp frame, lưu PNG atomic
- Bấm nút thứ 2 (hoặc Enter) → ghép phim MP4 + GIF qua ffmpeg
- **Upload tự động lên cloud** (catbox.moe) + sinh QR code để phụ huynh quét tải về
- Phim phát loop trên SuccessPage để xem lại ngay
- Onion skin chỉ hiển thị live preview, **KHÔNG** ghi vào file (giữ chất lượng frame)
- Fallback synthetic capture cho dev không có webcam

## Phím tắt

| Phím | Hành động |
|---|---|
| `Space` (hoặc IO1 ThingBot) | Chụp 1 frame |
| `Z` | Xoá frame cuối (UNDO) |
| `Enter` (hoặc IO2 ThingBot) | Tạo phim từ frames |

## Quick start (dev macOS)

```bash
git clone https://github.com/<...>/neostopmotion.git
cd neostopmotion
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
brew install ffmpeg
make run         # mở app với webcam thật
make run-sim     # synthetic capture (không cần camera permission)
```

Test full headless:

```bash
NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion
# tự chụp 8 frame -> ghép phim -> upload -> in URL ra log
```

## Triển khai NEO One (Armbian)

```bash
sudo bash deployment/install-armbian.sh
sudo systemctl enable --now neostopmotion
```

(Chi tiết trong `DOC/DEPLOY_NEO_ONE.md`.)

## Stack

Python 3.10+ · PyQt6 · QML 6 · OpenCV · pyserial · ffmpeg · qrcode · loguru

## Tài liệu

- [Kiến trúc](DOC/ARCHITECTURE.md) — 4-lớp design + SignalBus + Worker Thread
- [Implementation plan](DOC/IMPLEMENTATION_PLAN.md) — 30 task TDD breakdown

## License

MIT — theo cam kết Bình Dân Học STEM, mã nguồn mở, Made in Vietnam.
