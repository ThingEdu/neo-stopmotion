# Spec: Luu / tai video thanh pham ve may

> Feature key: `save-video` · scope: `app` · Owner: BA
> Task ref: T-007 · Status: **draft** · design_required: yes

---

## Muc tieu

Sau khi xuat phim xong, nguoi van hanh (Tho Ca) hoac hoc sinh co the luu file video
tu may tram NEO One / macOS ve may tinh / USB chi voi 1 thao tac, va biet ngay
file da luu o dau — thay vi phai tu mo thu muc kin ben duoi `session_dir`.

Bai toan PO gap: link catbox tren dien thoai Safari phat inline, khong ro nut "Tai
ve"; luu local thi can biet duong dan — hien tai SuccessPage chi hien text duong dan
nho, khong co nut hanh dong.

---

## Pham vi

### Trong pham vi (quick win — dot nay)
- Them nut **"Luu video"** tren SuccessPage.
- Nhan nut → mo hop chon thu muc (native file dialog, macOS + Linux) → sao chep
  `output.mp4` (+ `output.gif` neu PO chon) vao thu muc nguoi dung chon.
- Hien thong bao ro rang: "Da luu phim tai: /home/user/Desktop/output.mp4".
- Them nut **"Sao chep link"**: copy `share_url` vao clipboard.

### Ngoai pham vi (roadmap R-2, gop voi feature phan phoi)
- Trang dich download cho dien thoai (can host trang web co nut Download).
- Doi host upload sang dich vu co san trang download.
- Tu dong nhan USB mount va sao chep.

---

## Trang thai man hinh / luong

### Trang thai nen (SuccessPage hien tai)
SuccessPage nhan 4 prop tu ExportService: `mp4Path`, `gifPath`, `shareUrl`, `qrPath`.
Video da chay loop, QR hien (neu co shareUrl), duong dan hien text nho.
Chua co nut hanh dong luu file.

### Idle — cho nguoi dung hanh dong
Man hinh hien day du: video preview + QR + URL text + 2 nut moi:
- Nut "Luu video" (noi bat, P0).
- Nut "Sao chep link" (phu, chi hien khi `shareUrl != ""`).

**Precondition**: `mp4Path` da co (ExportService phat `export_completed`).

### In-progress — dang sao chep
Sau khi nguoi dung chon thu muc:
- Nut "Luu video" chuyen sang trang thai loading (spinner hoac text "Dang luu...").
- Thao tac sao chep chay tren background thread (khong block UI).

### Success — luu thanh cong
- Nut doi lai chu binh thuong.
- Hien toast / banner: "Da luu phim tai: <duong dan day du>".
  Duong dan phai ro rang (khong tat, khong cat bo).
- <!-- TODO: [BLOCKED Q1] Neu chon "thu muc co dinh", banner can hien them "Doi thu
  muc: bam giu nut 3 giay" hay khong? Can PO quyet -->

### Error — sao chep that bai
Cac nguyen nhan co the:
- Thu muc nguoi chon khong con ton tai (USB rut truoc khi luu).
- Khong du quyen ghi.
- Dia day.

Hien thong bao loi ro rang + nut "Thu lai" quay ve trang thai Idle.
Khong mat du lieu goc (file van o `session_dir/output.mp4`).

### Trang thai khong co mp4 (edge case)
Neu `mp4Path == ""` (export that bai o buoc truoc), nut "Luu video" bi disable
kem tooltip "Chua co phim de luu".

---

## Cau hoi lam ro (BA de xuat — can PO quyet)

<!-- BLOCKED: 3 cau hoi nay can PO tra loi truoc khi spec duoc dung -->

### Q1 — Luu ra dau?

| Lua chon | Mo ta | Uu | Nhuoc | De xuat BA |
|----------|-------|----|-------|-----------|
| (a) Hoi moi lan | Mo hop chon thu muc moi khi bam "Luu video" | Nguoi dung tu chon, linh hoat | Them 1 thao tac moi lan | **(a) — don gian nhat, hop le cho ca Mac + NEO** |
| (b) Thu muc co dinh | Luu vao `~/Desktop/NeoStopMotion/` khong hoi | 1 bam la xong | Nguoi dung co the khong biet o dau | (b) neu doi tuong chinh la Tho Ca quen may |
| (c) USB tu nhan | Tu detect USB mount va luu vao USB | Rat tien loi cho truong hop tram | Phuc tap, can xu ly platform (macOS khac Linux), de loi | De roadmap |

**De xuat BA: (a) hoi moi lan** — don gian, chay tren ca Mac + NEO One Linux ma khong
can xu ly USB mount phuc tap. Option (c) de roadmap.

**Tra loi PO:**
| Ngay | Quyet dinh |
|------|-----------|
| 2026-06-15 | (a) Hoi thu muc moi lan bang file dialog |

---

### Q2 — Luu MP4 hay ca MP4 + GIF?

| Lua chon | Mo ta | De xuat BA |
|----------|-------|-----------|
| (a) Chi MP4 | Don gian; MP4 la dinh dang chinh | **(a) — du dung cho chia se** |
| (b) Ca MP4 + GIF | Luu ca 2 file cung luc | Neu hoc sinh can GIF cho mang xa hoi |

**De xuat BA: (a) chi MP4** cho dot nay. Neu PO muon GIF: them option "Luu GIF rieng"
sau (khong lam phuc tap luong chinh).

**Tra loi PO:**
| Ngay | Quyet dinh |
|------|-----------|
| 2026-06-15 | (a) Chi MP4 dot nay; GIF de sau |

---

### Q3 — Doi tuong chinh la ai?

| Lua chon | Anh huong den |
|----------|--------------|
| (a) Nguoi van hanh (Tho Ca) | UX copy dung "ban", luong don gian, luu vao may tram |
| (b) Hoc sinh / khach (6-14 tuoi) | UX copy dung "con" / "ban nho", icon lon, chu to |

Hien tai SuccessPage dung "ban" (nguoi lon). **De xuat BA: (a) Tho Ca la nguoi bam
"Luu video"**, tuc la UX copy co the giu nguyen phong cach hien tai. Neu PO muon
hoc sinh tu luu → chuyen huong design sang icon/chu to hon, ux-designer can biet.

**Tra loi PO:**
| Ngay | Quyet dinh |
|------|-----------|
| 2026-06-15 | (a) Tho Ca / nguoi van hanh; UX copy + co nut theo phong cach nguoi lon |

---

## User Stories

### US-01 — Luu video ve may
> Voi tu cach nguoi van hanh tram stop-motion,  
> khi phim da xuat xong va hien tren SuccessPage,  
> toi muon bam 1 nut de luu file MP4 ve thu muc toi chon,  
> de toi co the giu lai va chia se sau.

**Acceptance Criteria:**

| # | Tieu chi | Do uu tien |
|---|----------|-----------|
| AC1 | Nut "Luu video" hien tren SuccessPage khi `mp4Path != ""` | P0 |
| AC2 | Bam nut → hop chon thu muc mo ra (native dialog) | P0 |
| AC3 | Sau khi chon thu muc → file sao chep thanh cong | P0 |
| AC4 | Hien thong bao ro: "Da luu phim tai: <duong dan day du>" | P0 |
| AC5 | File goc `session_dir/output.mp4` khong bi xoa / doi | P0 |
| AC6 | Neu sao chep loi → hien loi ro rang + nut "Thu lai" | P1 |
| AC7 | Nut disable + tooltip khi `mp4Path == ""` | P1 |

### US-02 — Sao chep link chia se
> Voi tu cach nguoi van hanh,  
> khi phim da upload len cloud (shareUrl co gia tri),  
> toi muon bam 1 nut de copy link vao clipboard,  
> de toi dan link do vao Zalo / nhom phu huynh.

**Acceptance Criteria:**

| # | Tieu chi | Do uu tien |
|---|----------|-----------|
| AC8 | Nut "Sao chep link" hien khi `shareUrl != ""` | P1 |
| AC9 | Bam nut → link vao clipboard, hien toast "Da sao chep!" | P1 |
| AC10 | Nut an khi `shareUrl == ""` (upload that bai) | P1 |

---

## Test Scenarios

| ID | Scenario | Precondition | Input / Hanh dong | Ket qua mong doi | Priority |
|----|----------|-------------|-------------------|-----------------|----------|
| TS-01 | Happy path: luu MP4 thanh cong | SuccessPage hien, `mp4Path` hop le, thu muc dich co quyen ghi | Bam "Luu video" → chon thu muc `/tmp/test_save` | File `output.mp4` xuat hien trong `/tmp/test_save/`; toast hien "Da luu phim tai: /tmp/test_save/output.mp4" | P0 |
| TS-02 | File goc khong bi anh huong | Nhu TS-01, sau khi luu xong | Kiem tra `session_dir/output.mp4` | File goc van ton tai va co kich thuoc == kich thuoc truoc luu | P0 |
| TS-03 | mp4Path rong — nut disable | SuccessPage hien voi `mp4Path = ""` (export that bai o buoc truoc) | Quan sat nut "Luu video" | Nut bi disable; tooltip "Chua co phim de luu" hien khi hover | P1 |
| TS-04 | Thu muc dich khong ton tai / USB rut | SuccessPage hien, nguoi dung chon thu muc tren USB → rut USB truoc khi luu xong | Bam "Luu video" → chon duong dan USB → xac nhan | Hien loi "Khong the luu: thu muc khong truy cap duoc" + nut "Thu lai"; file goc nguyen ven | P1 |
| TS-05 | Khong du quyen ghi | Thu muc dich chi co quyen doc (vd: `/root/` tren NEO) | Bam "Luu video" → chon thu muc → xac nhan | Hien loi "Khong du quyen luu tai thu muc nay" + nut "Thu lai" | P1 |
| TS-06 | Sao chep link happy path | `shareUrl` co gia tri hop le | Bam "Sao chep link" | Clipboard chua URL dung; toast "Da sao chep!" trong ≤500 ms | P1 |
| TS-07 | Nut "Sao chep link" an khi khong co link | Upload that bai → `shareUrl = ""` | Quan sat SuccessPage | Nut "Sao chep link" khong hien | P1 |
| TS-08 | UI khong block khi dang sao chep file lon | File MP4 > 50 MB | Bam "Luu video" → dang sao chep | Nut chuyen sang "Dang luu...", video preview van chay, khong dong ung dung | P1 |
| TS-09 | Dia day | Thu muc dich con < 10 MB trong khi MP4 > 10 MB | Bam "Luu video" → chon thu muc day dia → xac nhan | Hien loi "Khong du dung luong" + nut "Thu lai" | P1 |

---

## Yeu cau design (cho ux-designer)

`design_required: yes`. Ux-designer can thiet ke:

1. **Vi tri 2 nut moi tren SuccessPage**: "Luu video" (noi bat) va "Sao chep link" (phu).
   - Dat canh "Lam phim moi" hay rieng cot phai?
   - Nut "Luu video" can du to de bam duoc de dang tren man hinh cam ung NEO One.

2. **Trang thai nut**: normal / loading / disabled — bao gom icon va copy thich hop cho
   tre 6-14 (neu doi tuong chinh la hoc sinh sau khi PO xac nhan Q3).

3. **Toast / banner thong bao**: hien o dau, bao lau, kieu chu nao.

4. **Trang thai loi**: lay bao nhieu khong gian, mau sac, icon.

Design ref se duoc cap nhat vao `manifest.yml → design_ref` sau khi ux-designer hoan thanh.

---

## Phu thuoc

- `src/neo_stopmotion/ui/qml/pages/SuccessPage.qml` — them 2 nut moi va trang thai UI.
- `src/neo_stopmotion/services/export_service.py` — `export_completed` payload da co
  `mp4_path` (str), `gif_path` (str); khong can sua.
- Can them Python backend method (vd: `AppController.save_video_to(dest_dir)`) expose
  qua `QML_ELEMENT` / `@pyqtSlot` — dev tu quyet implementation detail.
- Clipboard copy: dung `QGuiApplication.clipboard()` (PyQt6 san co).
- File dialog: `QFileDialog.getExistingDirectory()` chay tren main thread hoac invoke
  tu QML `Qt.labs.platform.FolderDialog` — dev chon cach phu hop.

---

## Ghi chu trien khai

- Sao chep file PHAI chay tren background thread (khong block UI/video playback).
- Tren NEO One (Linux ARM64): `QFileDialog` chay duoc voi Qt6 / Linux — da xac nhan
  theo kien truc hien tai (PyQt6 Linux ARM64 build co san trong package).
- USB tren NEO One: khong nam trong pham vi dot nay. Neu nguoi dung muon luu vao USB,
  ho chi can chon dung thu muc USB mount (`/media/...`) trong dialog — van hoat dong
  ma khong can code them.
