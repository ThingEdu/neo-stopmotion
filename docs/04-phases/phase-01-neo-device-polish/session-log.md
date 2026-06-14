# Session Log — Phase: phase-01-neo-device-polish

> Mới nhất trên cùng (đảo thời gian). Mỗi entry ≤60 dòng.

---

## Session 2026-06-14 (f) — SESSION END: State of the Union

**Nhánh:** `feat/neo-device-polish` | **Mode:** FEATURE | Phase 01, Wave 1 + Wave 2.

### Tình trạng tổng thể
Phase 01 làm trên thiết bị NEO One thật (`thingedges-neo-1`, ssh root@192.168.1.12, passwordless key).
4 task: **2 DONE, 2 REVIEW**.

| Task | Trạng thái | Ghi chú |
|------|-----------|---------|
| T-001 autoplay (codec GStreamer + demote hw decoder) | 🟣 REVIEW | Fix xong + deploy; PO **chưa xác nhận** autoplay trên màn success |
| T-002 desktop icon | 🟣 REVIEW | Launcher tạo rồi nhưng XFCE 4.18 render lỗi ("neo@..." folder); app mở từ menu OK |
| T-003 core delete_frame (TDD) | 🟢 DONE | 19 test PASS |
| T-004 UI filmstrip + xoá frame | 🟢 DONE | **PO xác nhận xoá được** trên thiết bị |

### Đã xác nhận chạy trên thiết bị
- Xoá 1 frame bất kỳ (filmstrip + dialog). App mở được (đã fix crash do projects_dir + fix layout preview che filmstrip).
- QR/cloud: KHÔNG bị mất (code nguyên như main); chỉ bị tắt runtime — đã bật lại (thiết bị có internet, catbox.moe OK).

### Chờ PO / lần sau
1. PO test autoplay + QR (chụp ≥5 frame → TẠO PHIM → video tự phát + QR).
2. **Webcam phần cứng chập chờn** (thiếu nguồn USB) → cần hub USB có nguồn. Hiện launcher để **synthetic test mode**.
3. Icon desktop: cách trust XFCE 4.18.
4. **Commit** nhánh feat/neo-device-polish (product code chưa commit) → ship-to-main khi PO duyệt.
5. Architect chạy `make lint`/`make test` trên env có PyQt6 (đóng gate chuẩn); baseline ruff dự án vốn bẩn.

### Lưu ý vận hành
- subagent `coordinator` lạc đề 2 lần (tự chạy skill phân tích quyền) → phiên này parent thực thi trực tiếp.
- Product code đã đổi (chưa commit): `__main__.py, app.py, config/settings.py, config/defaults.toml, core/frame_manager.py, services/app_controller.py, utils/signal_bus.py, ui/qml/pages/CapturePage.qml, ui/qml/components/FilmStrip.qml, scripts/install_on_neo.sh, tests/*`.

---

## Session 2026-06-14 (e) — BUG layout: filmstrip/nút bị cắt + webcam hardware

PO test: live preview lên nhưng (1) không thấy phần xoá frame, (2) không có QR, (3) không có icon desktop.

### Root cause + fix
1. **Filmstrip + nút bị CẮT khỏi cửa sổ** (đây là lý do "không thấy phần xoá"). `CapturePage.qml`
   LivePreview để `Layout.preferredHeight: 720` → preview chiếm hết chiều cao cửa sổ 800px,
   đẩy filmstrip(120)+hint(50)+nút(80) xuống dưới mép. → SỬA: LivePreview `fillHeight` +
   `minimumHeight:200`; FrameCounter `fillHeight` + `maximumHeight:320`. Verify bằng screenshot
   x11grab: giờ hiện đủ preview + filmstrip ("Chụp tấm đầu tiên đi!") + nút "XOÁ TẤM NÀY" + 3 nút.
2. **QR**: parent đã tắt cloud (`NEO_STOPMOTION_CLOUD=0`) để tránh treo → chưa có QR. Cần PO
   quyết cấu hình cloud/sharing.
3. **Icon desktop**: `/home/neo/Desktop/neo-stopmotion.desktop` hợp lệ (Name=NEO Stopmotion, +x)
   nhưng XFCE 4.18 render thành kiểu file/folder "neo@..." do chưa "trusted" (gio metadata::trusted
   không hỗ trợ trên XFCE). App mở được từ menu. Cần cách trust XFCE riêng (chưa xong).

### Webcam = vấn đề PHẦN CỨNG
- USB cam `1bcf:0951` (Web Camera) **liên tục rớt** (dmesg: USB disconnect, uvcvideo URB -19).
  Re-enumerate đổi node mỗi lần cắm lại (video1 → video2/3). → preview lỗi "Failed to get image".
- Nguyên nhân điển hình: **thiếu nguồn USB trên SBC ARM**. Cần hub USB có nguồn riêng / đổi cổng / đổi cam.
  KHÔNG fix được bằng phần mềm.

### Trạng thái thiết bị để PO test
- Launcher (icon+menu) tạm để **synthetic test mode** (camera giả lập, ổn định) để PO test
  feature xoá frame + autoplay ngay khi webcam còn chập chờn.
- Lưu ý: `AUTOSHOOT` mode làm app tự thoát sau khi chụp (chỉ dùng smoke test) — không dùng cho chạy thường.

### TODO
- [ ] CapturePage layout fix: commit + (cân nhắc fullscreen cho kiosk).
- [ ] Webcam: PO xử lý hardware (hub có nguồn).
- [ ] QR: PO quyết cloud config.
- [ ] Desktop icon trust trên XFCE 4.18.

---

## Session 2026-06-14 (d) — BUG: app không mở được trên NEO + deploy code mới

PO báo: không mở được app từ menu lẫn desktop; desktop chỉ thấy "1 folder rỗng".
Điều tra trực tiếp (chạy app trong phiên GUI của `neo`) → tìm ra 2 bug chặn + 1 thiếu phần cứng:

### Root cause
1. **projects_dir hardcode `/home/maker/projects`** (settings.py:56 + defaults.toml) — user thật là `neo` → bản 1.0.0 trên máy crash khi tạo session (FileNotFoundError/PermissionError). (Source HIỆN TẠI đã có fallback ở app.py:145 nhưng thiết bị chạy 1.0.0 cũ.)
2. **Không có webcam USB**: `/dev/video0` là `cedrus` (VPU giải mã, không phải cam); `/dev/video1` (app cấu hình `webcam_index=1`) không tồn tại → chế độ camera dò ~30s rồi mới fallback synthetic → trông như treo/không mở.
3. Thiết bị đang chạy **1.0.0 cũ** — chưa có fix autoplay/projects_dir, chưa có feature xoá frame.

### Đã làm
- Sửa source: `projects_dir` default `/home/maker/projects` → `~/projects` (settings.py + defaults.toml). app.py:145 đã `.expanduser()`.
- **Deploy toàn bộ source hiện tại lên thiết bị** (rsync vào dist-packages) — autoplay fix + delete feature + projects_dir fix.
- Đặt device config `[storage] projects_dir=/home/neo/projects` + tạo `/home/neo/projects`.
- **Launcher (menu + desktop) tạm để chế độ THỬ NGHIỆM**: `Exec=env NEO_STOPMOTION_CAPTURE=synthetic NEO_STOPMOTION_CLOUD=0 ...` để PO mở app test được khi chưa có webcam.
- Fix lỗi QML thật trong FilmStrip.qml:132 (shadow Rectangle anchor sai item) → gỡ block thừa (viền chọn đã do thumbContainer + scale).

### Verify (on-device, GUI session neo)
- App MỞ ĐƯỢC ở synthetic: "Session created /home/neo/projects/...", autoshoot tạo frame, **KHÔNG còn lỗi QML**.
- pytest local 30 PASS sau khi sửa settings default + FilmStrip.

### CẦN PO QUYẾT
- **Webcam**: NEO One có webcam USB để cắm không? Sản phẩm cần camera thật; hiện chỉ chạy synthetic (giả lập) để test UI. Khi có cam → bỏ synthetic khỏi launcher.

---

## Session 2026-06-14 (c) — Wave 2: build feature frame-review-delete

python-dev agent **bị treo (stall 600s)** khi chạy gate (kẹt cài PyQt6/opencv), NHƯNG
đã kịp implement xong code + test trước khi treo. Parent review + tự chạy gate.

### Thay đổi (theo file)
| File | Loại | Mô tả |
|------|------|-------|
| `src/neo_stopmotion/core/frame_manager.py` | UPDATED | + `delete_frame(n)` (1-based, re-sequence, cập nhật metadata) |
| `src/neo_stopmotion/utils/signal_bus.py` | UPDATED | + signal `frame_deleted(int)` |
| `src/neo_stopmotion/services/app_controller.py` | UPDATED | + `handle_delete_frame`, `_do_delete_frame`, `get_frame_paths` (file:// cache-busting) |
| `src/neo_stopmotion/app.py` | UPDATED | bridge `frameDeleted` ra QML |
| `src/neo_stopmotion/ui/qml/components/FilmStrip.qml` | CREATED | dải thumbnail ngang, chọn chuột/phím, nút xoá |
| `src/neo_stopmotion/ui/qml/pages/CapturePage.qml` | UPDATED | nhúng FilmStrip + dialog xác nhận + Connections refresh |
| `tests/conftest.py` | UPDATED | stub PyQt6 để test core chạy không cần GUI stack |
| `tests/unit/test_delete_frame.py`, `test_delete_frame_controller.py` | CREATED | 19 test (9 P0 + P1) |
| `docs/01-specs/features/frame-review-delete/spec.md` | UPDATED | + §8b quyết định PO |

### Verification gate (parent chạy bằng venv /tmp, deps ghim ruff 0.1.6/mypy 1.7.0)
- **pytest feature: 19 PASS** (TS-01..TS-09 P0 + TS-10..TS-12 P1).
- Full suite: 47 passed, **2 error pre-existing** (test_signal_bus cần `pytest-qt`/`qtbot` — môi trường thiếu, KHÔNG phải hồi quy).
- **ruff**: file của ta sạch sau --fix + noqa; còn 2 lỗi N (`frameCountChanged`, `frameCount`) là **tên Qt có sẵn từ trước** (pattern toàn dự án). Phát hiện: **baseline ruff dự án vốn bẩn** (I001/F401 ở nhiều file cũ không đụng) → `make lint` đã fail từ trước; cần dọn riêng.
- **mypy**: core (`frame_manager`, `signal_bus`) sạch; các lỗi "subclass Any"/"untyped decorator" là **artifact do máy chưa cài PyQt6** (xuất hiện cả ở hàm cũ) → cần env có PyQt6 (CI/architect) để chạy chuẩn.
- **UI**: không chạy headless được (thiếu PyQt6). Code review OK: context property `signalBusBridge`/`appController` khớp app.py; token `error`/`warning` tồn tại; theo design-spec.

### Trạng thái — T-003, T-004 → 🟣 REVIEW
- T-003 core: tests PASS, logic verified.
- T-004 UI: code review OK; **chờ PO verify GUI trên thiết bị** (bấm thumbnail giữa → xoá → đúng tấm biến mất, export vẫn ra phim).

### Việc kế tiếp
1. [ ] PO test feature trên thiết bị (cần đẩy code mới lên NEO — hiện thiết bị vẫn chạy 1.0.0 patch tay).
2. [ ] Architect chạy `make lint`/`make test` trên env có PyQt6 (đóng gate chuẩn) + cân nhắc dọn baseline ruff.
3. [ ] Gom commit feat/neo-device-polish; ship product code lên main qua ship-to-main.sh khi PO duyệt.

---

## Session 2026-06-14 (b) — EXECUTE Wave 1: áp fix lên thiết bị NEO + sửa installer

PO ủy quyền "chủ động làm + build lên thiết bị". Coordinator agent bị lỗi (tự chạy nhầm
skill phân tích quyền 2 lần) → parent thực thi trực tiếp.

### Thay đổi (theo file)
| File | Loại | Mô tả |
|------|------|-------|
| `src/neo_stopmotion/__main__.py` | UPDATED | Set `GST_PLUGIN_FEATURE_RANK=v4l2slh264dec:NONE` trên Linux trước khi Qt Multimedia load (fix autoplay) |
| `scripts/install_on_neo.sh` | UPDATED | Thêm `gstreamer1.0-libav` + `gstreamer1.0-plugins-bad` vào apt ARM; tạo Desktop launcher trong `install_desktop_entry`; sửa Categories hợp lệ (AudioVideo) |
| NEO One (thiết bị) | DEPLOYED | apt cài 2 gói codec; patch `__main__.py` đã cài (1.0.0); tạo `/home/neo/Desktop/neo-stopmotion.desktop` (+x, owner neo) |

### Phát hiện root-cause SÂU HƠN dự đoán (T-001)
- Cài `gstreamer1.0-libav` (avdec_h264) là **cần nhưng CHƯA ĐỦ**.
- `decodebin`/`playbin` (Qt MediaPlayer dùng) **tự chọn decoder phần cứng Allwinner `v4l2slh264dec`** (rank 257 > avdec_h264 256) nhưng nó **lỗi allocation** → "Internal data stream error" → không play.
- Fix: hạ rank `v4l2slh264dec` qua env `GST_PLUGIN_FEATURE_RANK` → playbin/decodebin chạy EXIT=0. Đặt env trong app code (`__main__.py`) để mọi cách khởi chạy đều có (icon/terminal), no-op trên macOS.

### Bằng chứng (headless, on-device)
- TRƯỚC: `gst-inspect-1.0 avdec_h264` → No such element; `/home/neo/Desktop` không tồn tại.
- SAU: `gst-inspect-1.0 avdec_h264` → "libav H.264 ... decoder" (loaded).
- `filesrc ! qtdemux ! h264parse ! avdec_h264 ! fakesink` → EXIT=0.
- `GST_PLUGIN_FEATURE_RANK=v4l2slh264dec:NONE playbin uri=file://app_like.mp4` → EXIT=0 (không demote thì lỗi not-negotiated).
- `/home/neo/Desktop/neo-stopmotion.desktop` → `-rwxr-xr-x neo neo`, `desktop-file-validate` không còn error.

### Verification gate
- `bash -n scripts/install_on_neo.sh` → OK. `py_compile __main__.py` + ast → OK.
- ⚠️ ruff/mypy/pytest KHÔNG cài trong env máy dev này → chưa chạy được lint/type/test đầy đủ. Thay đổi nhỏ, E402 đã xử lý bằng `# noqa`. Cần Architect/QA chạy lint trên env có ruff trước khi ship.

### Trạng thái — T-001, T-002 → 🟣 REVIEW
- Phần vera headless + deploy thiết bị: XONG.
- Chờ PO test GUI: (a) bấm đúp icon mở app; (b) làm phim → SuccessPage phim tự play. Xem `wave-1/test-guide.md`.

### Việc kế tiếp
1. [ ] PO test GUI theo test-guide → báo PASS/FAIL.
2. [ ] Nếu PASS → Architect review (chạy ruff/mypy) → ship-to-main (chỉ `src/neo_stopmotion/__main__.py` + `scripts/install_on_neo.sh`).
3. [ ] Lưu ý: bản trên thiết bị đang patch tay file 1.0.0; release chuẩn nên bump version + publish PyPI sau.

---

## Session 2026-06-14 — PHASE START: khởi tạo phase + Wave 1 structure

### Thay đổi (theo file)
| File | Loại | Mô tả |
|------|------|-------|
| `docs/04-phases/phase-01-neo-device-polish/session-log.md` | CREATED | File này — khởi tạo phase |
| `docs/04-phases/phase-01-neo-device-polish/task-board.md` | CREATED | Task board Wave 1 với T-001, T-002 |
| `docs/04-phases/phase-01-neo-device-polish/wave-1/T-001-gstreamer-autoplay.md` | CREATED | Task card: cài GStreamer H.264 codec trên NEO One |
| `docs/04-phases/phase-01-neo-device-polish/wave-1/T-002-desktop-launcher.md` | CREATED | Task card: tạo icon desktop launcher trên NEO One |
| `docs/04-phases/claude-active-phase.md` | UPDATED | Trỏ tới phase-01-neo-device-polish, wave-1 |

### Trạng thái hiện tại
- **Nhánh**: `feat/neo-device-polish` (tạo từ `feat-team-workflow-setup` — nhánh base hiện tại)
- **Wave**: Wave 1 — 0/2 task xong (cả 2 ở TODO)
- **scope**: app (scripts/install_on_neo.sh + môi trường thiết bị)
- **Blockers**: Không — đang chờ PO confirm wave structure trước khi sang Gate 3

### Quyết định của PO
| # | Quyết định | Ngày |
|---|-----------|------|
| 1 | Mở phase-01-neo-device-polish, làm 2 issue thiết bị trước | 2026-06-14 |
| 2 | Tên phase: neo-device-polish, nhánh: feat/neo-device-polish | 2026-06-14 |

### 3 việc kế tiếp
1. [ ] PO confirm wave structure (bảng T-001/T-002) → Gate 3
2. [ ] Giao T-001 cho devops: cài gstreamer1.0-libav + thêm vào install_on_neo.sh
3. [ ] Giao T-002 cho devops: tạo Desktop launcher + thêm vào install_on_neo.sh

### Câu hỏi cần PO
- Wave structure đã đúng chưa? Anh confirm để em sang Gate 3 giao việc cho agent.
- T-001 (GStreamer): QA sẽ verify trên thiết bị bằng cách chạy app sau fix, xác nhận phim tự play. Anh chấp nhận reproduce-first (QA chứng minh không play TRƯỚC fix)?
- T-002 (Desktop icon): Exec trong .desktop trỏ về `/usr/local/bin/neo-stopmotion` (system pip) hay `neo-stopmotion` (rely on PATH)? Đề xuất: `/usr/local/bin/neo-stopmotion` cho chắc.

---
