# Domain: Chon toc do / FPS cho video thanh pham

> Feature key: `video-speed` · scope: `app`

---

## Luat nghiep vu

| # | Dieu kien | Ket qua |
|---|-----------|---------|
| BR-1 | Nguoi dung chon "Cham" | fps_export = **5** (CHOT PO 2026-06-15) |
| BR-2 | Nguoi dung chon "Vua" | fps_export = **8** (CHOT PO 2026-06-15) |
| BR-3 | Nguoi dung chon "Nhanh" | fps_export = **12** (CHOT PO 2026-06-15) |
| BR-4 | Khong chon gi / mac dinh | fps_export = **8** ("Vua" — CHOT PO 2026-06-15) |
| BR-5 | Bam "Tao Phim" | Truyen fps_export vao VideoExporter cho CA MP4 va GIF |
| BR-6 | VideoExporter nhan fps moi | MP4 dung `-framerate fps_export`; GIF palettegen + paletteuse dung cung `-framerate fps_export` |
| BR-7 | Frame count < min_frames (5) | Khong cho export, bao loi; bo chon toc do khong bi xoa |
| BR-8 | Doi toc do sau khi da export | Khong the (NGOAI PHAM VI dot nay) — roadmap R-4 |
| BR-9 | Toggle playbackRate SuccessPage | **DA LOAI theo PO 2026-06-15** — SuccessPage giu nguyen, khong them nut |

---

## Validation

- fps_export phai la so nguyen duong trong tap gia tri duoc phep (`{5, 8, 12}` — hoac do PO chot).
- Neu gia tri fps ngoai tap: log warning, fallback ve mac dinh "Vua".
- min_frames: giu nguyen tu `config/defaults.toml:export.min_frames = 5`.

---

## State machine (don gian)

```
[App khoi dong]
      |
      v
[CapturePage — chua co frame]
  bo_chon: DISABLED, fps = mac_dinh("Vua")
      |
      | SHOOT (frame dau tien)
      v
[CapturePage — dang chup]
  bo_chon: ENABLED
  fps: nguoi_dung_chon (or mac_dinh)
      |
      | EXPORT (>= min_frames)
      v
[ExportingPage — dang ghe phim]
  VideoExporter(fps=fps_da_chon)
  MP4 + GIF ca 2 dung fps_da_chon
      |
      | export_completed
      v
[SuccessPage]
  Hien tong thong tin toc do da chon
  (neu Q3=co) Toggle playbackRate: 0.5x/1x/2x (chi UI, khong doi file)
      |
      | SHOOT / Lam phim moi
      v
[CapturePage — fresh session]
  bo_chon: reset ve mac_dinh? <!-- [BLOCKED] PO xac nhan Q2c -->
```

---

## Edge Case Matrix

| Tinh huong | Hanh vi mong doi | Ghi chu |
|-----------|------------------|---------|
| 0 frame, bo chon bi bam | Khong the bam (bo chon disabled) | UI enforce |
| < min_frames frame, bam "Tao Phim" | Bao "Can them frame"; bo chon giu nguyen | Nhu hien tai, khong thay doi |
| Chon "Cham", ma doi sang "Nhanh" truoc khi bam | File xuat dung fps "Nhanh" (gia tri cuoi cung) | State la gia tri hien tai cua bo chon |
| ffmpeg khong ho tro fps 5 | Khong co van de — 5 fps la gia tri hop le voi tat ca ffmpeg | |
| GIF 2-pass: palettegen fps != paletteuse fps | KHONG duoc xay ra — ca 2 phai nhan cung fps_export | BR-6; dev phai test rieng TS-04 |
| VideoExporter duoc khoi tao voi fps mac dinh (10) va user chon 5 | fps_export = 5 ghi de fps mac dinh khi goi export; khong ghi de config file | Khong doi defaults.toml |
| Upload that bai (catbox loi) | File local van co fps dung; thong bao loi upload; khong reset lua chon | |
| Toggle playbackRate 0.5x khi mp4Path trong | Nut disable hoac khong hien; khong crash | Neu Q3 duoc chon |
| Nhieu lan bam Toggle nhanh (0.5x → 2x → 1x) | playbackRate cap nhat dung gia tri cuoi cung; khong giat hinh | Neu Q3 duoc chon |
| App crash va khoi dong lai | Bo chon reset ve mac dinh (session-level, khong luu disk) | |
| Smoke headless (AUTOSHOOT=8, AUTOEXPORT=1) | Xuat duoc MP4+GIF; co env var de truyen fps | Can them env var `NEO_STOPMOTION_FPS` hoac tuong duong |
