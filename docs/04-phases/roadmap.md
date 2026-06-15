# Roadmap — neo-stopmotion (phần cần thời gian, làm sau)

> Nơi ghi các hạng mục **chiến lược / cần nhiều thời gian** tách khỏi quick-win.
> Quick-win đang làm: `phase-01-neo-device-polish/wave-3` (T-005 camera, T-006 tốc độ, T-007 lưu video).
> Mới nhất trên cùng. Cập nhật: 2026-06-15.

---

## R-1 — Đóng gói, cài đặt & phân phối bản build (CHIẾN LƯỢC, ưu tiên cao)

**Vì sao quan trọng:** PO muốn tự xuất bản build và **phân phối cho khách** mà không cần Claude cài hộ; đồng thời hình thành **một chuẩn tái dùng cho nhiều app tương lai**, không chỉ neo-stopmotion.

**Bức tranh kỹ thuật:**
- **macOS**
  - Đóng `.app` (PyInstaller / py2app) → `.dmg`. Cài cho chính mình: làm được ngay.
  - Phân phối cho người khác không bị Gatekeeper chặn "unidentified developer" ⇒ cần **Apple Developer Program ($99/năm)** để **code-sign (Developer ID) + notarize (notarytool)**.
- **NEO One (Linux ARM64)**
  - Hiện: `scripts/install_on_neo.sh` (apt + pip). Nâng cấp: **AppImage** (1 file chạy thẳng) / `.deb` / bootstrap `curl … | bash` kéo từ GitHub Release.
- **Chuẩn tái dùng:** pipeline release — gắn tag phiên bản → CI build artifact (`.dmg` Mac, installer NEO) → **GitHub Releases** → tải về cài. Tách thành template cho app sau copy lại.

**Lộ trình 3 bước:**
1. **Quick (có thể tách 1 phần ra wave sau):** `make build-mac` → `.dmg` (chưa ký) + 1 lệnh cài NEO từ Release. PO tự cài được.
2. **Vừa:** ký + notarize Mac; AppImage/.deb cho NEO → cài "1 chạm" cho khách.
3. **Chuẩn:** template CI + scripts tái dùng cho mọi app tương lai.

**Câu hỏi PO đã chốt (2026-06-15):**
- [x] Apple Developer account: **CÓ rồi** → build Mac sẽ code-sign (Developer ID) + notarize, khách cài không bị Gatekeeper chặn.
- [x] Khách: **phổ thông** (non-technical) → ưu tiên cài "1 chạm", giấu bước kỹ thuật.
- [x] Phân phối: **online** (link tải) → GitHub Releases (hoặc tương đương) làm kênh phát hành.
- [x] Update: **manual** → KHÔNG cần auto-update; chỉ cần link tải bản mới.

**Hệ quả thiết kế:** Mac ⇒ `.dmg` đã ký + notarize. NEO One ⇒ artifact tải online cài 1 lệnh/1 chạm. Không cần hạ tầng auto-update. Vì khách phổ thông + online ⇒ R-2 (landing page tải cho điện thoại) có giá trị cao.

**Bước kế:** khi PO cho lệnh khởi động R-1 → fire **PM viết Feature Brief** (`docs/01-specs/features/distribution/product-brief.md`) → BA spec → devops thiết kế pipeline.

**Ưu tiên:** P1 (cao) · **Trạng thái:** 4 câu hỏi đã chốt; chờ PO ra lệnh khởi động (đang ưu tiên quick-win wave-3 trước).

---

## R-2 — Trang đích download cho điện thoại (gộp với R-1)

Liên quan T-007. Hiện link catbox khó tải trên điện thoại (phát inline). Giải pháp đầy đủ cần **trang đích có nút "Tải về"** (thẻ `download`) → cần chỗ host → quyết cùng R-1 (hạ tầng phân phối/host).

**Ưu tiên:** P2 · **Phụ thuộc:** R-1.

---

## R-3 — Chọn camera nâng cao: tên thiết bị + Qt QCamera

Liên quan T-005 (đợt này chỉ làm preview + xoay index). Nâng cao:
- Hiển thị **tên thiết bị** ("iPhone của Anh", "FaceTime HD") qua `QMediaDevices.videoInputs()` (chỉ Mac).
- Cân nhắc chuyển capture sang **Qt QCamera** để chọn thiết bị chuẩn + có tên (đổi lớn ở `core/capture`).

**Ưu tiên:** P2 · **Phụ thuộc:** T-005 xong trước.

---

## R-4 — Re-render đổi tốc độ sau khi export

Liên quan T-006. Cho phép đổi tốc độ phim **sau khi đã tạo** (regenerate từ frames đã lưu) mà không chụp lại — thay vì chỉ chọn trước export.

**Ưu tiên:** P2 · **Phụ thuộc:** T-006 xong trước.
