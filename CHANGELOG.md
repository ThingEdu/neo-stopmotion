# Changelog — NeoStopMotion

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/) và tuân thủ [SemVer](https://semver.org/).

---

## [1.0.2] — 2026-08-19

🐞 **Sửa lỗi phát video trên NEO One + hành vi phím Enter.**

### Fixed — sửa lỗi

- **Phim không phát trên NEO One (màn hình đen)** — Qt 6.7 mặc định dùng backend ffmpeg,
  nhưng `libffmpegmediaplugin.so` trong wheel PyQt6 link `libav*.so.58` (ffmpeg 4.x) còn
  Debian 12 có `libavcodec.so.59` ⇒ plugin nạp lỗi và Qt **không thử tiếp backend
  GStreamer** (`No QtMultimedia backends found`). Nay ép `QT_MEDIA_BACKEND=gstreamer`
  trước khi Qt Multimedia nạp (`src/neo_stopmotion/media_env.py`, no-op trên macOS).
- **Thiếu gói hệ thống** — thêm `libgstreamer-plugins-bad1.0-0` vào `debian/control`:
  plugin GStreamer của Qt cần `libgstphotography-1.0.so.0`. (Cố ý dùng gói thư viện
  thay vì `gstreamer1.0-plugins-bad` để không kéo theo `v4l2slh264dec` của Allwinner —
  decoder này rank cao hơn `avdec_h264` nhưng lỗi cấp phát bộ đệm; app cũng hạ rank nó
  để phòng máy đã cài sẵn.)
- **Phim đứng hình sau vài vòng lặp** — `MediaPlayer.Infinite` kẹt ở `StoppedState` trên
  backend GStreamer của máy này. Thay bằng vòng lặp tự điều khiển.
- **Enter không kết thúc làm phim** — trên màn hình kết quả, Enter gọi EXPORT lần nữa và
  ghép lại chính bộ ảnh cũ; bấm 2 lần lúc đang ghép thì chạy 2 tiến trình ffmpeg song
  song. Nay EXPORT chỉ chạy đúng một lần cho mỗi phim (chặn ở `AppController` nên nút đỏ
  ThingBot cũng được bảo vệ); export lỗi thì vẫn bấm lại được.

### Fixed — sửa sau khi phát hành (installer, không nằm trong .deb)

- **Gói .deb bị bản pip cũ che hoàn toàn** — `install_on_neo.sh` thường chạy qua `sudo`,
  lúc đó `$HOME` là `/root` nên bước dọn bản pip cũ không đụng tới `/home/<user>/.local`.
  Hậu quả nặng hơn PATH: `~/.local/lib/pythonX/site-packages` được python tìm **trước**
  `/usr/lib/python3/dist-packages`, nên `/usr/bin/neo-stopmotion` vẫn nạp code CŨ trong
  khi `dpkg -s` báo đã cài 1.0.2. Nay installer resolve `SUDO_USER` và dọn đúng home của
  người dùng desktop, cảnh báo nếu còn bản venv cũ, và kiểm tra lại xem gói hệ thống có
  còn bị che không.

### Changed — thay đổi

- **Phát phim có nhịp nghỉ** — phim phát xong nghỉ 5 giây rồi tự phát lại, lặp vô hạn.
  Lúc nghỉ giữ khung hình đầu trên màn hình (không để đen).
- `MediaPlayer` nay ghi log khi lỗi (`onErrorOccurred`) — trước đây hỏng thì im lặng.

---

## [1.0.0] — 2026-05-10

🎉 **Bản v1.0 đầu tiên — sẵn sàng pilot tại Làng Maker.**

### Added — tính năng mới

- **Capture pipeline** — webcam OpenCV + onion skin (`cv2.addWeighted` 30% opacity) + atomic PNG write
- **2-nút ThingBot** — IO1 (xanh) chụp ảnh, IO2 (đỏ) tạo phim. Firmware Arduino + ESP32 đính kèm.
- **UART listener** — auto-detect serial port (`/dev/cu.usbmodem*`, `/dev/ttyUSB*`, `/dev/thingbot`) + reconnect 2s loop khi mất kết nối.
- **UART simulator** — drop-in replacement cho dev không có ThingBot (env `NEO_STOPMOTION_UART=simulator`).
- **Synthetic capture** — fallback khi webcam không available (env `NEO_STOPMOTION_CAPTURE=synthetic`); sinh frame test pattern animation.
- **Keyboard fallback** — Space (= IO1), Enter (= IO2), Z (= UNDO).
- **Export pipeline** — ffmpeg MP4 (libx264, 1280×720, 10fps) + GIF (640×360, 2-pass palette lanczos), QThread non-blocking với progress bar.
- **Watermark Maker Việt** — logo nhúng góc dưới phải mỗi frame video (110px, 85% opacity), áp dụng cho cả MP4 và GIF.
- **Cloud share** — auto-upload lên catbox.moe (vĩnh viễn, 200MB free) với fallback 0x0.st (30 ngày).
- **QR code** — sinh local 360px PNG trỏ tới link cloud, hiển thị trên SuccessPage.
- **Auto-reset on SHOOT** — bấm Space/IO1 trên SuccessPage tự động tạo session mới + chụp frame đầu tiên ngay.
- **UI** — QML 6 + PyQt6, 4 page (Splash → Capture → Exporting → Success), Singleton design tokens NeoConstants + AppState, StackView navigation.
- **Branding** — logo Maker Việt với halo trắng quanh chữ (đọc được trên nền tối), label "NEO One — ThingEdu" thống nhất Splash/Capture/Success.
- **Universal copy** — text dùng "bạn" thay vì "con" để phù hợp đa đối tượng (HS + PH + Thợ Cả).

### Documentation

- `README.md` — landing page với logo, feature highlights, quick-start, file system layout
- `DOC/ARCHITECTURE.md` — kiến trúc 4-lớp + design rationale (1079 dòng)
- `DOC/IMPLEMENTATION_PLAN.md` — 30-task TDD breakdown gốc (4955 dòng)
- `DOC/USER_GUIDE.md` — hướng dẫn Thợ Cả vận hành tại trạm
- `DOC/EXPERIENCE_GUIDE.md` — kịch bản trải nghiệm 25-30 phút cho HS
- `DOC/SYSTEM_GUIDE.md` — cấu hình, env vars, deploy, mở rộng (cho dev)
- `firmware/thingbot_stopmotion/README.md` — sơ đồ nối dây + flash firmware

### Stack

Python 3.10+ · PyQt6 ≥ 6.5 · QML 6 · OpenCV 4.8+ · pyserial 3.5+ · ffmpeg 5.x+ · qrcode + Pillow · loguru · catbox.moe / 0x0.st HTTP API

### Verified end-to-end

- macOS dev (Python 3.14, PyQt6 6.11): real webcam capture × 75 frames → MP4 7.5s + GIF + watermark + catbox upload + QR + auto-reset
- 29 unit tests + 1 integration test passing
- GitHub Actions CI ready (cần `gh auth refresh -s workflow` để add lại workflow file)

### Known limitations (lùi v1.1+)

- T3.5 integration test simulator→frame chưa viết đầy đủ (UI drives via keyboard works)
- T5.4 NeoAudio (tiếng "tách") chưa làm — buzzer trên ThingBot có thay thế
- T5.5 CountdownOverlay 3-2-1 chưa làm
- T5.6 ThumbnailStrip 5 frame gần nhất + TitleInputDialog chưa làm
- T6.1 install-armbian.sh chưa test trên ARM64 thật
- T6.2 systemd service file chưa test trên NEO One thật

---

## [0.1.0] — 2026-05-09

### Initial design

- `DOC/ARCHITECTURE.md` v0.1
- `DOC/IMPLEMENTATION_PLAN.md` 30 task
- Project skeleton (`pyproject.toml`, Makefile, .gitignore)
