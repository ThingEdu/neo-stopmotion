# Spec: Thu vien phim

> Feature key: `film-library` · scope: `app` · Owner: BA · Status: draft
> Design ref: `docs/03-codebase/design/brand/html-mockups/07-library.html` (PO da duyet 2026-06-16)

---

## 1. Muc tieu

**Van de dang giai quyet**: Sau khi lam xong nhieu buoi chup, be va Tho Ca khong co cach xem lai,
chia se, hoac quan ly cac phim da tao — phai vao thu muc tay. Man Thu vien phim cung cap giao dien
truc quan, dieu khien 100% bang ban phim, de mo lai phim cu, xem thong tin, luu ra USB, hoac xoa
phim khong can.

**User story chinh**:
- Tho Ca (nguoi huong dan): Sau buoi chup, muon chieu lai cho be xem tat ca phim da lam, khong
  mat thoi gian tim thu muc thu cong.
- Be (6-14 tuoi): Tu duyet phim da lam bang phim mu vu tren ban phim, chon phim yeu thich, bat phat
  lai khong can chuot.

---

## 2. Dinh nghia "phim hop le"

*De xuat, cho PO xac nhan (xem PO-Q1 cuoi spec)*

Mot session duoc hien trong Thu vien phim khi **dong thoi thoa man**:
1. `exported == true` trong `project.json`.
2. File `output.mp4` ton tai tren dia (kiem tra `Path(mp4_path).exists()`).

**Phim bi loai tru** (khong liet ke):
- Session chi co frames (chua export).
- Session co `project.json` nhung `exported == false`.

**Phim loi** (hien voi canh bao, xem §4.3):
- Thu muc session ton tai nhung `project.json` khong doc duoc (loi JSON / thieu file).
- `project.json` hop le nhung `mp4_path` la null hoac file khong ton tai.

---

## 3. Truong metadata hien thi

| Truong hien thi (UI) | Nguon SessionMeta | Ghi chu |
|----------------------|-------------------|---------|
| Ten phim | `title` | Neu rong: xem §5 |
| Ngay tao | `created_at` | Dinh dang: `dd/MM/yyyy · HH:mm` |
| So tam | `frame_count` | Hien thi: `N tam` |
| Thoi luong | `duration_seconds` | Dinh dang: `X.X giay`; tinh lai = `frame_count / fps_playback` neu khong khop |
| Toc do (fps) | `fps_playback` | Hien thi: `Cham · 5 fps` / `Vua · 8 fps` / `Nhanh · 12 fps` hoac `N fps` |
| Do phan giai | Khong co trong SessionMeta | Doc tu frame dau: `frames/frame_0001.png`; neu khong co → hien `--` |
| Dung luong | Khong co trong SessionMeta | Tinh tong `mp4_path.stat().st_size + gif_path.stat().st_size`; hien `X.X MB`; neu gif khong co → chi hien mp4 |
| Link chia se | `download_url` | Chi hien khi `download_url is not None`; hien duoi dang ngan (slug) |
| Luu tai | `mp4_path` (thu muc cha) | Hien duong dan thu muc session: font monospace, ellipsis dau |
| Thumbnail (luoi) | frame dau: `frames/frame_0001.png` | Neu khong co → hien placeholder emoji |

**Truong khong hien thi**:
- `session_id`: dung noi bo de xac dinh session khi xoa.
- `status`, `exported`: dung de loc, khong hien ra UI.
- `qr_path`, `gif_path`: dung trong hanh dong luu lai, khong hien thanh dong thong tin.
- `creator_name`: hien thi la tuy chon trong phase nay (`<!-- TODO: xac nhan PO co muon hien creator_name khong -->`).

---

## 4. Cac trang thai man hinh

### 4.1 Loading (khoi dong man)

Khi nguoi dung chuyen vao man Thu vien phim:
1. Hien thi skeleton loading tren luoi (2 cot x N hang, placeholder).
2. `LibraryService.scan_projects_dir()` quet `projects_dir`, doc tat ca `project.json`, loc phim
   hop le (§2), sap xep moi nhat truoc (§6).
3. Khi danh sach san: hien luoi phim, chon mac dinh phim dau tien (moi nhat).
4. Thoi gian cho phep: < 500 ms voi toi da 50 phim (ExportCfg.max_sessions).

### 4.2 Empty (chua co phim nao hop le)

Dieu kien: `projects_dir` trong, hoac tat ca session deu bi loai tru.

Hien thi:
- Vung luoi: emoji 📽️, dong chu `"Chua co phim nao. Hay lam phim dau tien nhe!"`.
- Panel phai: an (hoac hien thong bao dang giong).
- Nut hanh dong (Xem/Luu lai/Chep link/Xoa): tat ca disabled.
- Thanh phim tat footer: van hien (Esc van hoat dong de quay lai chup).

### 4.3 Phim loi (project.json hong / thieu mp4)

*De xuat: hien canh bao nhe, cho PO xac nhan*

- Phim loi van hien trong luoi nhung co icon canh bao ⚠️ thay cho thumbnail.
- Ten hien thi: `"Phim bi loi"` + session_id (8 ky tu dau).
- Chi cac nut: **Xoa phim** — nut con lai disabled.
- Click chon: panel phai hien thong bao `"Phim nay bi loi (khong doc duoc thong tin). Hay xoa di de don dep."`.

### 4.4 Normal (co ≥1 phim hop le)

**Luoi trai** (2 cot):
- Moi o: thumbnail 104×78 px (frame_0001.png) + thoi luong phia duoi-phai, ten phim, ngay tao,
  badge so tam, badge trang thai (da chia se / tren may).
- O dang chon: vien mau primary (#FF7043), do bong noi bat.
- Badge "Da chia se" (mau xanh la): khi `download_url is not None`.
- Badge "Tren may" (mau xam): khi `download_url is None`.

**Panel chi tiet phai** (width: 470 px):
- Player (ty le 4:3): hien frame_0001.png lam poster; icon play o giua.
- Ten phim (font 24 px, bold).
- Bang thong tin (cac truong §3).
- 4 nut hanh dong: Xem / Luu lai / Chep link / Xoa phim (xem §7).

**Footer phim tat**: hien thuong xuyen (§8).

### 4.5 Error — khong doc duoc projects_dir

Dieu kien: `projects_dir` khong ton tai hoac khong co quyen doc.

Hien thi:
- Thong bao loi: `"Khong the mo thu muc du an: [duong dan]. Kiem tra lai cai dat."`.
- Nut "Thu lai" de scan lai.
- Nut "Quay lai chup" (Esc).
- Luoi va panel phai an.

### 4.6 Playback (dang phat phim)

Khi bam **Xem** (Enter hoac nut Xem):
- Mp4 phat trong player panel phai, loop (khong am thanh).
- Icon play doi thanh pause.
- Bam Enter hoac Space: toggle play/pause.
- Phim tat ◀▶▲▼: van dieu huong luoi (dung phat phim dang chon, chuyen sang phim khac).
- Bam Esc: quay lai chup (thoat man, khong chi dung phat).

---

## 5. Ten hien thi khi title rong

*De xuat, cho PO xac nhan*

Neu `SessionMeta.title == ""` hoac `title is None`:
- Ten hien thi: `"Phim <dd/MM HH:mm>"`, vi du `"Phim 16/06 14:20"`.
- Lay gia tri `created_at` de dinh dang.
- Ten nay chi dung de hien thi, khong ghi lai vao `project.json`.

---

## 6. Sap xep

- Mac dinh: **moi nhat truoc** — sap xep giam dan theo `created_at`.
- Khong co tuy chon sap xep trong phase nay (ghi nhan cho roadmap).
- Sau khi xoa 1 phim: danh sach re-render, chon tu dong phim ke tiep (hoac phim cuoi cung neu xoa phim cuoi).

---

## 7. Hanh dong tren 1 phim

### 7.1 Xem phim (Enter / nut Xem)

1. Lay `mp4_path` tu `SessionMeta`.
2. Kiem tra file ton tai; neu khong → hien thong bao loi (xem §4.3).
3. Phat mp4 trong player: loop, khong am thanh, khong co thanh tua.
4. Player hien `"Enter / Space — phat/dung"`.
5. Phim dang phat khong anh huong den dieu huong luoi (◀▶▲▼ van chon phim khac → dung phat phim cu, bat dau poster phim moi).

### 7.2 Luu lai (S / nut Luu lai)

1. Mo `open_save_dialog` (tai su dung logic tu `save-video` feature).
2. Nguoi dung chon thu muc dich.
3. Copy `output.mp4` + `output.gif` (neu co) + `qr.png` (neu co) vao thu muc dich.
4. Hien thong bao thanh cong: `"Da luu phim ra [duong dan dich]!"`.
5. Neu huy dialog: khong lam gi.
6. Loi khi copy (quyen, dia day): hien thong bao loi + nut "Thu lai".

### 7.3 Chep link (L / nut Chep link)

Dieu kien: chi hien / cho phep khi `download_url is not None`.

1. Copy `download_url` vao clipboard.
2. Hien thong bao ngan (toast 2 giay): `"Da chep link! Gan vao bat ky dau de chia se."`.
3. Neu `download_url is None`: nut disabled, tooltip `"Phim nay chua duoc chia se len cloud."`.

*De xuat: Neu download_url het han (response 4xx khi kiem tra), giu nut nhung hien canh bao — cho PO xac nhan (PO-Q3).*

### 7.4 Xoa phim (Del / nut Xoa phim)

Xac nhan 2 buoc bat buoc (tuong tu xoa frame):

**Buoc 1 — Xac nhan lan 1**:
- Hien dialog: `"Con co muon xoa phim '[ten phim]' khong?"`.
- Nut: `"Xoa"` (mau do) va `"Thoi"`.
- Phim tat: Enter = Xoa, Esc = Thoi.

**Buoc 2 — Xac nhan lan 2** (bao ve extra cho tre em):
- Hien: `"Xoa phim nay se mat vinh vien, khong lay lai duoc. Xoa that khong?"`.
- Nut: `"Xoa that"` (mau do dam) va `"Huy"`.
- Phim tat: Enter = Xoa that, Esc = Huy.

**Neu xac nhan**:
1. `LibraryService.delete_session(session_id)`:
   a. Xoa toan bo thu muc session (`shutil.rmtree`).
   b. Khong co undo.
2. Xoa khoi danh sach hien thi, chon tu dong phim ke tiep.
3. Neu xoa phim cuoi cung: chuyen sang empty state (§4.2).
4. Log hanh dong voi `session_id` + `session_dir`.

**Neu that bai** (quyen, dia):
- Thong bao loi: `"Khong the xoa phim. Kiem tra lai quyen thu muc."`.
- Phim van con trong danh sach.

*De xuat: Xoa toan bo thu muc session (bao gom frames/, output.mp4, output.gif, qr.png, project.json). Cho PO xac nhan (PO-Q2).*

---

## 8. Ban do phim tat man Thu vien

| Phim tat | Hanh dong | Ghi chu |
|----------|-----------|---------|
| `◀` `▶` `▲` `▼` | Di chuyen chon phim trong luoi | Grid 2 cot: ◀▶ ngang, ▲▼ doc |
| `Enter` | Xem phim dang chon / Toggle play-pause khi dang phat | |
| `Space` | Toggle play-pause khi dang phat | |
| `S` | Luu lai phim dang chon | |
| `L` | Chep link phim dang chon (neu co download_url) | |
| `Del` | Bat dau luong xoa phim dang chon (2 buoc xac nhan) | |
| `Esc` | Quay lai CapturePage | Thoat man, dung phat neu dang phat |
| `?` | Mo/tat bang phim tat (help overlay) | |
| `G` | (tu CapturePage) Vao man Thu vien phim | Xem T-011 |

**Quy tac tro nguon phim tat**:
- Tab / Shift+Tab: khong dung (giu don gian cho tre em).
- Chuot: ho tro click chon phim, click nut — khong bat buoc.

---

## 9. Dieu huong

**Vao man Thu vien tu**:
- CapturePage: nut "Phim da lam" hoac phim `G`.
- SuccessPage: nut "Xem thu vien" (neu co — ghi nhan cho T-012).

**Thoat man Thu vien**:
- Phim `Esc` → CapturePage.
- Nut "Quay lai chup" (header phai).

**Khong co dieu huong ngang** giua Thu vien va Success/Export page.

---

## 10. Test Scenarios

| ID | Scenario | Precondition | Input/Action | Expected | Priority |
|----|----------|-------------|--------------|----------|----------|
| TS-LIB-01 | Liet ke phim hop le | 3 session: 2 exported+mp4, 1 chi frames | Mo man Thu vien | Hien dung 2 phim, khong hien session chua export | P0 |
| TS-LIB-02 | Sap xep moi nhat truoc | 3 phim voi created_at khac nhau | Mo man Thu vien | Phim moi nhat hien o vi tri dau tien | P0 |
| TS-LIB-03 | Empty state | projects_dir trong / khong co phim hop le | Mo man Thu vien | Hien icon 📽️ + CTA text, tat ca nut hanh dong disabled | P0 |
| TS-LIB-04 | Phat mp4 happy path | ≥1 phim hop le duoc chon | Bam Enter | Player hien mp4 phat loop, icon chuyen pause | P0 |
| TS-LIB-05 | Xoa phim — 2 buoc xac nhan | 2 phim trong danh sach | Bam Del → "Xoa" → "Xoa that" | Thu muc session bi xoa khoi dia; danh sach con 1 phim; chon tu dong phim ke tiep | P0 |
| TS-LIB-06 | Xoa phim duy nhat | 1 phim | Bam Del → xac nhan 2 buoc | Thu muc xoa; chuyen sang empty state | P0 |
| TS-LIB-07 | Huy xoa o buoc 1 | 1 phim | Bam Del → "Thoi" | Phim khong bi xoa; man hien lai binh thuong | P0 |
| TS-LIB-08 | Huy xoa o buoc 2 | 1 phim | Bam Del → "Xoa" → "Huy" | Phim khong bi xoa; man hien lai binh thuong | P0 |
| TS-LIB-09 | Chep link khi co download_url | Phim co download_url != None | Bam L | download_url vao clipboard; hien toast "Da chep link!" | P0 |
| TS-LIB-10 | Chep link khi khong co download_url | Phim co download_url == None | Bam L | Nut disabled; tooltip hien | P0 |
| TS-LIB-11 | Ten phim hien khi title rong | Phim co title="" | Mo man | Ten hien "Phim dd/MM HH:mm" lay tu created_at | P0 |
| TS-LIB-12 | Phim loi — project.json hong | Thu muc session co file JSON khong hop le | Mo man | Phim hien voi icon ⚠️; chi nut Xoa active | P1 |
| TS-LIB-13 | Phim loi — mp4 khong ton tai | project.json exported=true nhung mp4_path file mat | Bam Enter | Thong bao loi, khong crash | P1 |
| TS-LIB-14 | projects_dir khong doc duoc | projects_dir thieu / khong co quyen | Mo man | Man hien loi + nut "Thu lai" + "Quay lai chup" | P1 |
| TS-LIB-15 | Luu lai happy path | 1 phim chon, save dialog xac nhan | Bam S, chon thu muc | mp4+gif+qr duoc copy; hien toast thanh cong | P1 |
| TS-LIB-16 | Luu lai — huy dialog | 1 phim chon | Bam S, huy dialog | Khong co gi thay doi | P1 |
| TS-LIB-17 | Dieu huong bang phim tat luoi | ≥4 phim (2 hang x 2 cot) | ▼, ▶, ▲, ◀ | O chon di chuyen dung theo grid 2 cot | P1 |
| TS-LIB-18 | Esc quay lai chup | Dang o man Thu vien | Bam Esc | CapturePage duoc hien, Thu vien dong | P1 |
| TS-LIB-19 | Hien thi do phan giai tu frame dau | Phim hop le co frames/frame_0001.png | Chon phim | Do phan giai hien dung (vi du 1280×960) | P1 |
| TS-LIB-20 | Tinh dung luong mp4 + gif | Phim co ca mp4 va gif | Chon phim | Dung luong = tong size 2 file, hien X.X MB | P1 |
| TS-LIB-21 | Scan hieu nang 50 phim | 50 session hop le trong projects_dir | Mo man | Danh sach hien trong < 500 ms | P1 |

---

## 11. Cau hoi cho PO (cho Coordinator chuyen)

| # | Cau hoi | De xuat BA | Anh huong |
|---|---------|-----------|-----------|
| PO-Q1 | "Phim da lam" = chi `exported=true & mp4 ton tai`, hay ca session dang do? | Chi phim export thanh cong | Loc LibraryService |
| PO-Q2 | Xoa phim: xoa ca thu muc session (frames/, mp4, gif, qr, json), hay chi cac file output? | Xoa ca thu muc (gon sach) | Logic delete_session |
| PO-Q3 | Neu `download_url` het han (HTTP 4xx khi chia se), nut "Chep link" tat hay van hien voi canh bao? | Van hien nhung co canh bao | Nut Chep link |

---

## 12. Phu thuoc

- `src/neo_stopmotion/core/models.py` — `SessionMeta` (da co).
- `src/neo_stopmotion/config/settings.py` — `StorageCfg.projects_dir`, `StorageCfg.max_sessions` (da co).
- `LibraryService` (can tao moi) — `src/neo_stopmotion/services/library_service.py`:
  `scan_projects_dir()`, `delete_session(session_id)`.
- `open_save_dialog` (tai su dung) — tu feature `save-video` (da co).
- QML: `LibraryPage.qml` + `LibraryFilmCard.qml` + `LibraryDetailPanel.qml` (can tao moi).
- Design token: `NeoConstants.qml` (da co, primary #FF7043, secondary #1565C0...).
- T-011 (keyboard map toan man): xac minh khop phim tat §8.
- T-012 (implementation LibraryPage): phai doi spec nay duoc PO duyet truoc khi bat dau code.
