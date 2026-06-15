# Spec: Chon toc do / FPS cho video thanh pham

> Feature key: `video-speed` · scope: `app` · Owner: BA
> Task ref: T-006 · Phase: phase-01-neo-device-polish · Wave: 3

---

## Muc tieu

Cho nguoi dung (tre 6-14 + Tho Ca) chu dong chon toc do phim TRUOC KHI xuat, de video it frame
(~20 tam) khong bi chay qua nhanh tren catbox va khi xem lai trong app.

Van de goc: FPS xuat co dinh = 10, neu chup 20 tam thi phim chi dai 2 giay — "vut qua" trong
mat nguoi xem. Giai phap: bo chon toc do than thien ("Cham / Vua / Nhanh") anh huong FILE thuc
su duoc up len cloud.

---

## Phan biet quan trong (phai ro trong UI)

| # | Loai | Anh huong | Giai thich don gian |
|---|------|-----------|---------------------|
| A | **Toc do file xuat ra** (thay doi FPS luc export) | **Ca file MP4/GIF va ban len catbox** | Day la fix goc cua van de PO |
| B | **Toc do xem trong app** (MediaPlayer.playbackRate) | Chi anh huong luc xem trong app, KHONG doi file da up | Tuy chon phu, thuan tien kiem tra |

Spec nay tap trung vao (A). (B) toggle playbackRate da loai khoi pham vi dot nay theo PO (2026-06-15) — xem roadmap R-4.

---

## Cac trang thai man hinh / luong

### Trang thai 1 — CapturePage (truoc khi bam "Tao Phim")

**Chon toc do:**
- Hien thi bo chon "Toc do phim" kieu 3 nut (radio / segment control):
  - "Cham" = **5 fps** (CHOT: PO 2026-06-15)
  - "Vua" = **8 fps** (CHOT: PO 2026-06-15)
  - "Nhanh" = **12 fps** (CHOT: PO 2026-06-15)
- Mac dinh: "Vua" (8 fps). Auto goi y theo so frame co — xem muc "Goi y tu dong" (PO chot Q2b 2026-06-15).
- Nut "Tao Phim" (Enter / IO2): chi bat hoat khi co >= min_frames frame.
- **Giu nguyen lua chon qua cac session** trong cung phien lam viec (reset khi bat app lai).

**Goi y tu dong theo so frame (neu PO chot Q2b = co):**
- < 10 frame: uu tien goi y "Cham"; hien ghi chu "Phim it tam nen de cham de xem duoc nha!"
- 10-25 frame: goi y "Vua"
- > 25 frame: goi y "Nhanh"
- Nguoi dung van co quyen ghi de goi y.

**Trang thai Empty (0 frame):**
- Bo chon toc do hien thi nhung bi disable (grey out).
- CTA: "Bam nut xanh / phim Space de chup anh dau tien".
- Nut "Tao Phim" disabled.

**Trang thai Capturing (dang chup, co frame):**
- Bo chon toc do enable binh thuong; co the doi bat cu luc nao truoc khi bam "Tao Phim".
- Khi doi toc do: hien thi nhan thong bao nhe "Da chon: Cham / Vua / Nhanh" (1.5 giay tu bien).

**Loi camera:**
- Neu webcam bi ngat, hien loi nhu hien tai; bo chon toc do khong bi an huong (giu state).

### Trang thai 2 — ExportingPage / Spinner (dang xuat phim)

- Hien ten muc da chon: "Dang tao phim... (Toc do: Cham)".
- FPS truyen vao VideoExporter phai dung muc da chon.
- **Ca MP4 va GIF dung cung FPS** (GIF 2-pass palette phai su dung cung `-framerate` — xem
  `core/video_exporter.py:93-136`).
- Khong cho phep doi toc do trong luc xuat.

### Trang tai 3 — SuccessPage (xuat xong)

**Preview trong app:**
- MediaPlayer phat tu dong nhu hien tai (loop, khong am thanh).
- Toggle toc do xem (0.5x/1x/2x): **DA LOAI theo PO 2026-06-15** — SuccessPage giu nguyen, khong them nut.
- Thong tin hien thi: "Phim toc do Cham (5 fps) — 20 tam / 4 giay".
- URL cloud, QR: khong thay doi so voi hien tai.

**Khong co:**
- Nut "Xuat lai" / re-render doi toc do sau khi da up (ngoai pham vi; xem roadmap R-4).

**Loi khi xuat:**
- Neu ffmpeg that bai: hien thong bao "Oi, tao phim bi loi roi. Con thu lai nhe!" + nut "Thu lai"
  giu nguyen lua chon toc do da chon.
- Neu upload that bai: fallback catbox / 0x0.st nhu hien tai; **khong** anh huong file local.

---

## Thay doi ky thuat can de y (cho dev, khong phai spec UI)

Phan nay de BA noi lai bo tach cho dev biet dieu can chinh; khong thay the Architecture Decision.

- `config/defaults.toml` key `export.playback_fps = 10` → van la gia tri mac dinh "Vua".
- `VideoExporter.__init__(fps=...)` nhan fps tu gia tri nguoi dung chon, KHONG con co dinh.
- `app_controller._do_export()` can truyen fps duoc chon vao `export_service.start_export()`.
- GIF 2-pass: `_gif_palettegen_cmd` va `_gif_paletteuse_cmd` ca hai dung `self.fps` — khi
  VideoExporter nhan fps moi la ok, khong can sua rieng GIF.
- SuccessPage.qml: neu co Q3 toggle, them `player.playbackRate` property binding.

---

## Cac cau hoi lam ro — De xuat + Cho PO quyet

### Q1. Dat bo chon toc do o buoc nao?

```
(a) Tren CapturePage, ben canh / duoi nut "Tao Phim" — hien thi truoc khi bam export.
(b) Tren mot man hinh rieng TRUOC export, kieu "Chuan bi xuat phim — chon toc do".
(c) Vua tren CapturePage, vua co the doi tren SuccessPage (rebuild / re-render — NGOAI PHAM VI dot nay).

De xuat: (a) — don gian nhat, khong them man hinh, tre hieu ngay khi chua co nut "Tao Phim".
Ly do: man hinh CapturePage da co du cho (duoi FilmStrip, tren hang nut); them 3 nut nho khong
lam phuc tap UI; tre chon xong roi bam "Tao Phim" la mot hanh dong.

PO quyet: [x] (a) — tren CapturePage, phia tren nut "Tao phim" (2026-06-15)
```

### Q2. Gia tri fps cho 3 muc Cham / Vua / Nhanh la bao nhieu?

```
De xuat:
  Cham = 5 fps   (20 tam → 4 giay — xem thoai mai)
  Vua  = 8 fps   (20 tam → 2.5 giay — nhip nhanh vua)
  Nhanh = 12 fps (20 tam → ~1.7 giay — hieu ung muo ma)

Ly do: 5/8/12 phu hop dac diem stop-motion tre em (5-30 tam pho bien). 5 fps la nguong "xem
duoc" nhat; 12 fps la nguong "chay that"; 8 fps la trung gian.

(Luu y: FPS video thong thuong la 24/30; stop-motion thu cong thuong dung 8-15 fps;
12 fps la tieu chuan thap cua phim hoat hinh truyen thong.)

Q2b. Co can auto-goi-y theo so frame (xem "Goi y tu dong" trong spec) khong?

De xuat: Co — UI chi goi y (highlight nut Cham khi < 10 frame), khong ep buoc; don gian va
than thien. Tre van chon duoc theo y muon.

PO quyet Q2 fps: [x] Cham=5 / Vua=8 / Nhanh=12 — CHOT CUNG (2026-06-15)
PO quyet Q2b goi y tu dong: [x] Co — chi highlight, khong ep buoc (2026-06-15)
```

### Q3. Co can toggle toc do xem trong app (0.5x / 1x / 2x) tren SuccessPage khong?

```
(a) Co — them 3 nut nho "Xem 0.5x / 1x / 2x" tren SuccessPage; chi thay doi toc do xem trong
    app, KHONG anh huong file da up len catbox. Huu ich de tre kiem tra phim "o che do slow-mo".
(b) Khong — chi can fix file xuat ra la du. Toggle xem la phu, them code, them UI.

De xuat: (b) — "Dung don gian truoc, day du sau". Fix file xuat ra (Q1+Q2) da giai quyet van de
goc. Toggle playbackRate co the ship sau neu PO thay can.

PO quyet: [x] (b) KHONG them toggle — da loai theo PO 2026-06-15. SuccessPage giu nguyen.
Toggle 0.5x/2x playbackRate → roadmap (sau R-4 neu can).
```

**Bang tra loi tu PO:**
| # | Cau hoi | Tra loi | Ngay |
|---|---------|---------|------|
| Q1 | Dat bo chon toc do o buoc nao? | (a) Tren CapturePage, phia tren nut "Tao phim" | 2026-06-15 |
| Q2 | Fps cho Cham/Vua/Nhanh? | Cham=5 / Vua=8 / Nhanh=12 — CHOT CUNG | 2026-06-15 |
| Q2b | Auto-goi-y theo so frame? | Co — chi highlight, khong ep buoc | 2026-06-15 |
| Q3 | Co toggle 0.5x/1x/2x o SuccessPage? | KHONG — da loai khoi pham vi dot nay | 2026-06-15 |

---

## Test Scenarios

| ID | Scenario | Precondition | Input/Action | Expected | Priority |
|----|----------|-------------|--------------|----------|----------|
| TS-01 | Happy path: xuat "Vua" (8 fps) | >= 5 frame, chon "Vua" | Bam "Tao Phim" (IO2) | MP4 va GIF co fps = 8; ffmpeg cmd co `-framerate 8` | P0 |
| TS-02 | Xuat "Cham" (5 fps) | >= 5 frame, chon "Cham" | Bam "Tao Phim" | MP4 va GIF co fps = 5; phim 20 frame dai ~4 giay | P0 |
| TS-03 | Xuat "Nhanh" (12 fps) | >= 5 frame, chon "Nhanh" | Bam "Tao Phim" | MP4 va GIF co fps = 12 | P0 |
| TS-04 | GIF phai khop FPS voi MP4 | >= 5 frame, chon "Cham" | Xuat | GIF palettegen va paletteuse deu dung `-framerate 5` | P0 |
| TS-05 | Mac dinh "Vua" khi mo app | App vua khoi dong | Khong chon gi | Bo chon hien "Vua" duoc active; fps export = 8 | P0 |
| TS-06 | Qua it frame | < 5 frame, bat ky toc do | Bam "Tao Phim" | Khong export, thong bao "Can them frame" | P0 |
| TS-07 | doi toc do giua chung | 10 frame, dang chon "Nhanh" | Doi sang "Cham" roi bam "Tao Phim" | File xuat ra dung fps "Cham" (5), khong phai "Nhanh" | P0 |
| TS-08 | Bo chon disable khi 0 frame | 0 frame | Khoi dong / nhap app | Bo chon grey out, khong the bam | P1 |
| TS-09 | Goi y tu dong (neu co Q2b) | 8 frame | Mo CapturePage | Nut "Cham" duoc highlight / goi y; nguoi dung van chon duoc muc khac | P1 |
| TS-10 | Toggle playbackRate (neu co Q3) | SuccessPage da hien, mp4Path co | Bam "0.5x" | `player.playbackRate` = 0.5; file tren catbox khong thay doi | P1 |
| TS-11 | Toc do duoc giu qua reset-va-cap-lai | Chon "Cham", reset session, chup lai | Bam "Tao Phim" | <!-- TODO: [BLOCKED] PO xac nhan — nen giu hay reset ve mac dinh? --> | P1 |
| TS-12 | ffmpeg loi giua xuat | Gia ffmpeg binary hong | Bat ky toc do + "Tao Phim" | Hien loi than thien, nut "Thu lai" giu nguyen lua chon | P1 |
| TS-13 | Upload loi, file local van dung fps | Tat mang, xuat "Nhanh" | "Tao Phim" | File local MP4/GIF fps = 12; thong bao upload loi; QR van co (local) | P1 |

> **Chu y cho python-dev:** TS-01 den TS-07 la P0 — bat buoc co pytest truoc khi mark DONE.
> TS-01 den TS-04 co the test bang `VideoExporter` truc tiep (unit test), khong can chay full UI.
> Smoke test: `NEO_STOPMOTION_AUTOSHOOT=8 NEO_STOPMOTION_AUTOEXPORT=1 python -m neo_stopmotion`
> voi env var moi `NEO_STOPMOTION_FPS=5` (hoac equivalent) de kiem TS-02 headless.

---

## Phu thuoc

- Spec lien quan: `docs/01-specs/features/frame-review-delete/` (T-004, da DONE — khong anh huong)
- Khong co giao thuc UART moi (scope: app only).
- `src/neo_stopmotion/core/video_exporter.py` — chinh sua fps parameter.
- `src/neo_stopmotion/services/app_controller.py` — truyen fps vao export.
- `src/neo_stopmotion/config/defaults.toml` — `export.playback_fps` la gia tri fallback.
- `src/neo_stopmotion/ui/qml/pages/CapturePage.qml` — them bo chon toc do.
- `src/neo_stopmotion/ui/qml/pages/SuccessPage.qml` — (neu Q3 = co) them toggle playbackRate.

---

## Phan thiet ke can ux-designer (design_required: yes)

Sau khi PO chot Q1/Q2/Q3, ux-designer can thiet ke:

1. **Bo chon toc do tren CapturePage**: vi tri, kich thuoc, style 3 nut (Cham/Vua/Nhanh);
   trang thai active / inactive / disabled; ghi chu fps hien thi ben duoi nut hay tooltip.
2. **Ghi chu goi y** (neu Q2b = co): style va vi tri hien thi goi y theo so frame.
3. **SuccessPage toggle** (neu Q3 = co): vi tri 3 nut "0.5x/1x/2x" so voi video preview; style.
4. **Thong bao 1.5 giay** khi doi toc do: vi tri (toast / inline), mau sac.
5. **Doan chat cua Tho Ca** khi hien bo chon: vi du "Con chon toc do cho phim nhe!
   Phim it tam thi chon Cham de xem roi nhe."
