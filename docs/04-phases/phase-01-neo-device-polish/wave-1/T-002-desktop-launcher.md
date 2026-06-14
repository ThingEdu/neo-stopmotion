---
id: T-002
title: "Desktop launcher icon — icon ngoài màn hình XFCE trên NEO One"
assignee: "devops"
status: "TODO"
phase: "phase-01-neo-device-polish"
wave: "wave-1"
priority: "P0"
scope: "app"
ui: "no"
design_required: "no"
design_ref: "N/A"
dependencies: []
references:
  - "scripts/install_on_neo.sh"
---

# T-002: Desktop launcher icon — icon ngoài màn hình XFCE trên NEO One

## Mục tiêu
Tạo icon NEO Stopmotion ngoài màn hình desktop XFCE của user `neo` trên NEO One,
để PO/trẻ bấm đúp chuột mở app trực tiếp — không cần mở terminal hay menu.

## Bối cảnh kỹ thuật (root-cause đã xác định)
- App + menu entry đã có: `/home/neo/.local/share/applications/neo-stopmotion.desktop`
  → hiện trong menu Whisker (Education/Graphics/Video).
- CẦN KIỂM: `Exec=` trong file trên có thể đang trỏ `/root/.local/bin/neo-stopmotion`
  (chạy installer với root) → user `neo` không chạy được vì không có quyền /root/.
  Phải sửa thành `/usr/local/bin/neo-stopmotion` (system pip install).
- `/home/neo/Desktop` KHÔNG tồn tại → XFCE không hiện icon desktop.
- XFCE đọc icon desktop từ `~/Desktop/`. File `.desktop` đặt ở đó cần:
  1. `owner = neo` (chown neo:neo)
  2. `chmod +x`
  3. Đánh dấu "trusted" (XFCE metadata) — nếu không XFCE hỏi "Launch/Mark executable?" mỗi lần bấm.
- Cách đánh dấu trusted XFCE: `gio set <file> metadata::trusted true` (chạy với user neo trong session GUI).
- App cài system-wide (`pip install` bởi root → `/usr/local/bin/neo-stopmotion`) → Exec phải trỏ `/usr/local/bin/neo-stopmotion`.

## Phạm vi
### Trong phạm vi
- Kiểm tra + sửa `Exec=` trong `/home/neo/.local/share/applications/neo-stopmotion.desktop`
  nếu đang trỏ sai (phải là `/usr/local/bin/neo-stopmotion`).
- Tạo `/home/neo/Desktop/` (nếu chưa có), chown `neo:neo`.
- Tạo `/home/neo/Desktop/neo-stopmotion.desktop` với nội dung đúng, owner `neo`, `chmod +x`.
- Đánh dấu trusted: `gio set /home/neo/Desktop/neo-stopmotion.desktop metadata::trusted true`
  (chạy với session user neo, hoặc dùng `runuser -l neo -c "..."` nếu từ root).
- Thêm logic tạo Desktop launcher vào `scripts/install_on_neo.sh` (fix gốc, Product code).

### Ngoài phạm vi
- Thay đổi icon hình ảnh (dùng asset sẵn có trong package).
- Sửa app source code Python/QML.
- Cài autostart hay systemd service.

## Câu hỏi làm rõ
1. `Exec=` trong `/home/neo/.local/share/applications/neo-stopmotion.desktop` hiện tại trỏ về đâu?
   (DevOps kiểm: `grep Exec /home/neo/.local/share/applications/neo-stopmotion.desktop`)
2. `/usr/local/bin/neo-stopmotion` có tồn tại và chạy được bởi user `neo` không?
   (DevOps kiểm: `ls -la /usr/local/bin/neo-stopmotion && sudo -u neo /usr/local/bin/neo-stopmotion --version`)
3. `gio` command có sẵn trên Armbian Debian 12 không?
   (DevOps kiểm: `which gio` hoặc `apt-cache show libglib2.0-bin`)

**Trả lời từ PO:**
| # | Câu hỏi | Trả lời | Ngày |
|---|---------|---------|------|
| 1 | Exec= hiện tại | Nghi trỏ /root/.local/bin/ — cần kiểm xác nhận | 2026-06-14 |

## Acceptance Criteria (kèm file/dòng/thay đổi)

- [ ] **AC1 — Verify Exec= menu entry**: Kiểm tra và đảm bảo:
  ```
  /home/neo/.local/share/applications/neo-stopmotion.desktop
  ```
  có dòng `Exec=/usr/local/bin/neo-stopmotion` (không phải `/root/...`).
  Bằng chứng: output `grep Exec /home/neo/.local/share/applications/neo-stopmotion.desktop`.

- [ ] **AC2 — Desktop folder tồn tại**: `/home/neo/Desktop/` tồn tại, owner `neo:neo`.
  ```bash
  ls -la /home/neo/ | grep Desktop
  # kỳ vọng: drwxr-xr-x ... neo neo ... Desktop
  ```

- [ ] **AC3 — Desktop launcher file tạo đúng**:
  - File: `/home/neo/Desktop/neo-stopmotion.desktop`
  - Owner: `neo:neo`
  - Permissions: `-rwxr-xr-x` (chmod +x)
  - Nội dung `Exec=/usr/local/bin/neo-stopmotion`
  Bằng chứng: `ls -la /home/neo/Desktop/` + `cat /home/neo/Desktop/neo-stopmotion.desktop`.

- [ ] **AC4 — Trusted metadata đã đặt**: Metadata trusted đã set để XFCE không hỏi:
  ```bash
  gio info /home/neo/Desktop/neo-stopmotion.desktop | grep trusted
  # kỳ vọng: metadata::trusted: true
  ```

- [ ] **AC5 — App mở được bằng chuột (on-device)**: Trên GUI session XFCE của `neo`,
  bấm đúp icon ngoài desktop → app neo-stopmotion mở ra (không hỏi "Launch/Mark executable?",
  không báo lỗi permission).

- [ ] **AC6 — Fix gốc vào installer**: `scripts/install_on_neo.sh`, hàm `install_desktop_entry`
  (dòng ~264-310), thêm logic:
  1. Tạo `$HOME/Desktop/` nếu chưa có.
  2. Tạo `$HOME/Desktop/neo-stopmotion.desktop` với `Exec=/usr/local/bin/neo-stopmotion` (hoặc `Exec=$(command -v neo-stopmotion)`).
  3. `chmod +x "$HOME/Desktop/neo-stopmotion.desktop"`.
  4. `gio set "$HOME/Desktop/neo-stopmotion.desktop" metadata::trusted true 2>/dev/null || true`.
  Exec trong cả 2 file (applications/ và Desktop/) phải dùng đường dẫn tìm được lúc cài,
  không hardcode `/root/...`.

## Files to Touch
| File | Thay đổi |
|------|---------|
| `scripts/install_on_neo.sh` | Hàm `install_desktop_entry` (~dòng 264-310): thêm tạo Desktop launcher, sửa Exec để không hardcode /root |
| `/home/neo/.local/share/applications/neo-stopmotion.desktop` | (trực tiếp trên thiết bị) Sửa Exec nếu sai |
| `/home/neo/Desktop/neo-stopmotion.desktop` | (trực tiếp trên thiết bị) Tạo mới |

## Test (bắt buộc — không có kết quả test = chưa xong)

### Test Scenarios
| TS-ID | Scenario | Priority | Cần test? |
|-------|----------|----------|-----------|
| TS-001 | Kiểm tra Exec= menu entry (baseline) | P0 | YES |
| TS-002 | Desktop folder + file tồn tại đúng owner+perm | P0 | YES |
| TS-003 | gio trusted metadata set | P0 | YES |
| TS-004 | Bấm đúp chuột mở app (on-device GUI) | P0 | YES |
| TS-005 | Chạy lại installer → Desktop launcher tự tạo | P1 | YES |

### Lệnh verify on-device
```bash
# Baseline check:
ssh root@192.168.1.12 "grep Exec /home/neo/.local/share/applications/neo-stopmotion.desktop"
ssh root@192.168.1.12 "ls -la /home/neo/Desktop/ 2>/dev/null || echo 'Desktop NOT found'"

# Sau fix:
ssh root@192.168.1.12 "ls -la /home/neo/Desktop/neo-stopmotion.desktop"
ssh root@192.168.1.12 "cat /home/neo/Desktop/neo-stopmotion.desktop"
ssh root@192.168.1.12 "gio info /home/neo/Desktop/neo-stopmotion.desktop | grep trusted"
# GUI test: thực hiện thủ công trên màn hình XFCE của neo
```

Cổng chấp nhận:
- [ ] AC1-AC4 có bằng chứng terminal (copy output)
- [ ] AC5 on-device: bấm đúp mở được (chụp màn hình hoặc mô tả)
- [ ] AC6: `scripts/install_on_neo.sh` diff thêm Desktop logic
- [ ] `bash -n scripts/install_on_neo.sh` PASS (syntax check)

## Rủi ro / Ghi chú
- `gio` có thể không có trên Armbian tối giản; fallback: `xdg-open` hoặc tạo file
  `.directory` trong Desktop. DevOps kiểm trước.
- Nếu XFCE không nhận "trusted" qua gio, alternative: thêm dòng
  `X-XFCE-Exec-Param=true` vào .desktop file (xfce-specific). Hoặc dùng
  `xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/<hash>/trusted -n -t bool -s true`.
- Exec phải resolve được bởi user `neo` (không phải root). Ưu tiên `/usr/local/bin/neo-stopmotion`
  (system pip) thay vì `~/.local/bin/` (user pip của root).
- Thay đổi trực tiếp trên thiết bị (AC1-AC5) độc lập với fix gốc installer (AC6) —
  cả 2 đều required để DONE.

## Output Contract khi xong
- [ ] `scripts/install_on_neo.sh` đã cập nhật Desktop launcher logic
- [ ] Bằng chứng baseline + verify đính kèm trong báo cáo agent
- [ ] App mở được bằng icon desktop trên NEO One thật đã xác nhận on-device
- [ ] `bash -n scripts/install_on_neo.sh` PASS
- [ ] Sẵn sàng cho architect review
- [ ] Đưa lên main qua `ship-to-main.sh` (chỉ `scripts/install_on_neo.sh`)
