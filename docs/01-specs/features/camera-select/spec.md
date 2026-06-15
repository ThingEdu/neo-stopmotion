# Spec: Chon camera input trong app (picker + preview)

> Feature key: `camera-select` · scope: `app` · Owner: BA
> Task: T-005 · Phase: phase-01-neo-device-polish · Wave: wave-3

---

## Muc tieu

Cho phep nguoi dung chu dong chon camera nao dung cho app thay vi app tu chon index 0
(tren macOS, Continuity Camera iPhone thuong bi macOS uu tien → app "tu" lay iPhone).

**Ai duoc huong loi:**
- Nguoi van hanh (Tho Ca) — thiet lap dung camera truoc buoi hoc.
- [BLOCKED — PO quyet] Tre 6-14 co the tu doi camera trong phien chup hay khong?

---

## Boi canh hien trang (doc tu code, xac nhan ngay 2026-06-15)

| Thanh phan | File | Hien trang |
|-----------|------|-----------|
| Mo webcam | `core/capture_engine.py:39` | `cv2.VideoCapture(index)`, mac dinh index 0 |
| Do webcam | `app.py:84` | Do index 0-5 neu fail; dung webcam dau tien mo duoc |
| Override | `config/settings.py:109` | Chi qua env `NEO_STOPMOTION_WEBCAM_INDEX` |
| Config luu | `config/defaults.toml:[capture]` | `webcam_index = 0` — ghi de duoc qua `~/.config/neostopmotion/config.toml` |
| UI | `ui/qml/pages/CapturePage.qml` | Khong co nut doi camera; khong enumerate device |

**Han che OpenCV tren macOS**: `cv2.VideoCapture` khong tra ve ten thiet bi —
chi co index so. Khong the hien "iPhone cua Anh" hay "FaceTime HD" o dot nay.
Nguoi dung xac dinh camera bang cach xem live preview truc tiep.

---

## Pham vi (chot voi PO)

### Trong pham vi — Option A (quick win)
- Nut "Doi camera" → mo picker → xoay vong index 0→5; nguoi dung xem live preview tung cam,
  bam "Chon" khi thay dung cam.
- Luu webcam_index vao `~/.config/neostopmotion/config.toml` de lan sau nho.
- Cross-platform: chay duoc tren macOS dev + NEO One (Linux ARM64).

### Ngoai pham vi (roadmap R-3)
- Hien ten thiet bi ("iPhone", "FaceTime HD") qua Qt `QMediaDevices`.
- Chuyen capture hoan toan sang Qt `QCamera`.
- Map index OpenCV ↔ Qt device ID.

---

## Cau hoi lam ro

> **Chu y**: Day la de xuat hop ly cua BA, KHONG phai quyet dinh cuoi. PO dien vao bang
> "Tra loi tu PO" de xac nhan. BA KHONG tu quyet thay PO vi anh huong den UX tre.

### Q1. Picker dat o dau?

**De xuat cua BA**: Dat tren CapturePage (nut nho, goc duoi phai hoac hang nut hien tai).

Ly do:
- SplashScreen la man hinh cho "tat ca da san sang" — them picker lam phuc tap luong khoi dong.
- CapturePage da co hang nut (Chup / Xoa frame / Tao phim). Them 1 nut nho "Doi camera" vao
  cuoi hang khong lam roi giao dien.
- Nguoi van hanh co the doi camera bat ky luc nao trong phien ma khong can thoat app.

Phuong an khac: Dat tren SplashScreen. Phu hop neu doi camera la viec lam 1 lan truoc buoi.
Nhuoc diem: phai thoat ve SplashScreen neu muon doi giua phien.

**PO da quyet (2026-06-15):**
| # | Cau hoi | Tra loi | Ngay |
|---|---------|---------|------|
| Q1 | Nut "Doi camera" dat o CapturePage hay SplashScreen? | CapturePage | 2026-06-15 |

### Q2. Ai duoc phep doi camera?

**De xuat cua BA**: Nguoi van hanh (Tho Ca) — doi truoc buoi, tre khong can tu doi.

Ly do:
- Tre 6-14 tuoi khong can hieu khai niem "camera index". Hien preview la du de Tho Ca chon.
- Neu tre tu doi se rui ro vo tinh chuyen sang camera sai giua phien chup.
- Neu chon: an nut sau menu "Cai dat" hoac can xac nhan PIN ngan hang o dot sau (ngoai pham vi hien tai).

Phuong an khac: Cho phep tre doi tu do. Don gian hon, it code hon, nhung rui ro UX cao.

**PO da quyet (2026-06-15):**
| # | Cau hoi | Tra loi | Ngay |
|---|---------|---------|------|
| Q2 | Tre co the tu doi camera hay chi Tho Ca? | Chi Tho Ca | 2026-06-15 |

### Q3. Co can nho camera giua cac phien?

**De xuat cua BA**: Co — ghi `webcam_index` vao `~/.config/neostopmotion/config.toml`.

Ly do:
- Thiet bi NEO One thuong co camera co dinh (webcam USB). Neu khong nho, moi lan khoi dong lai phai chon.
- Co che da co san: `load_settings()` doc `~/.config/neostopmotion/config.toml` va merge voi defaults.
  Chi can ghi de `[capture]\nwebcam_index = N` la xong.
- Khong anh huong den moi truong (env `NEO_STOPMOTION_WEBCAM_INDEX` van override config nhu cu).

**PO da quyet (2026-06-15):**
| # | Cau hoi | Tra loi | Ngay |
|---|---------|---------|------|
| Q3 | Luu webcam_index vao config file giua cac phien? | Co | 2026-06-15 |

---

## User Stories

### US-01 — Tho Ca chon dung camera truoc buoi
> Voi tu cach la nguoi van hanh, toi muon chon camera dung cho buoi chup
> de tre khong bi quay bang iPhone thay vi webcam lop.

**Acceptance Criteria:**
- AC1: Co nut "Doi camera" truy cap duoc ma khong can sua file config hay bien moi truong.
- AC2: Khi bam nut, xuat hien picker hien live preview truc tiep tu camera hien tai.
- AC3: Bam "Tiep theo" / "Camera truoc" / "Camera sau" → picker chuyen sang index ke tiep / truoc do
  (xoay vong 0→1→2→...→5→0), live preview cap nhat ngay.
- AC4: Bam "Chon camera nay" → picker dong, app dung camera vua chon, live preview tren CapturePage
  hien dung camera moi.
- AC5: Neu camera o index do khong mo duoc (isOpened() = False), picker bao "Camera nay khong hoat dong"
  va tu dong thu index ke tiep (khong de nguoi dung ket).
- AC6 [BLOCKED — phu thuoc Q3]: Lua chon duoc luu vao config; lan mo app tiep theo dung dung camera do.

### US-02 — Tre thay live preview dung camera ngay
> Voi tu cach la tre lam phim, toi muon thay hinh tu camera dung ngay khi
> vao trang chup, khong bi "quay nguoc" hay "quay xe".

**Acceptance Criteria:**
- AC7: Khi app khoi dong, webcam_index da duoc nho tu phien truoc (phu thuoc Q3) → live preview dung
  camera ngay tuc thi, khong phai chon lai.

---

## Trang thai man hinh / luong

### Trang thai 1 — CapturePage binh thuong (khong picker)
- Live preview hien dang chay voi camera hien tai (webcam_index tu config/env).
- Nut "Doi camera" hien o goc / hang nut (vi tri xac nhan sau design).
- [BLOCKED — design_required: yes] UX Designer quyet layout chinh xac.

### Trang thai 2 — Picker dang mo (Loading camera ke tiep)
- Modal/popup che phu CapturePage.
- Preview window nho (khoang 320x240 hoac ty le 4:3) hien live frame tu camera dang xem xet.
- Spinner / placeholder trong khi `cv2.VideoCapture(index).open()` dang chay (co the mat 0.5-2s).
- Hien so thu tu: "Camera 1 / 6", "Camera 2 / 6"... (index 0-5 = 6 vi tri).
- Nut "Camera truoc" / "Camera tiep" (xoay vong).
- Nut "Chon camera nay" (xac nhan).
- Nut "Huy" (dong picker, giu nguyen camera cu).
- [BLOCKED — design_required: yes] UX Designer thiet ke layout popup.

### Trang thai 3 — Camera o index nay khong hoat dong
- Preview window hien thong bao thay vi anh: "Camera nay khong hoat dong".
- Nut "Chon camera nay" bi disable.
- Nut "Camera tiep" van hoat dong de nguoi dung thu index khac.
- App khong crash; log canh bao.

### Trang thai 4 — Khong tim thay camera nao (0-5 deu fail)
- Picker hien canh bao: "Khong tim thay camera nao. Kiem tra day USB va thu lai."
- Nut "Chon camera nay" disable.
- Nut "Huy" dong picker; app ve CapturePage (co the dung synthetic hoac hien loi webcam cu).
- [BLOCKED — design_required: yes] Xem lai flow fallback sang synthetic capture.

### Trang thai 5 — Sau khi chon camera thanh cong
- Picker dong.
- CaptureEngine duoc khoi tao lai voi webcam_index moi.
- Live preview tren CapturePage cap nhat ngay voi camera moi.
- [Neu Q3 = co] Config duoc ghi: `~/.config/neostopmotion/config.toml` → `[capture] webcam_index = N`.
- Signal bus: `webcam_ready` emit de QML biet camera da san.

---

## Rang buoc ky thuat

| Rang buoc | Chi tiet |
|-----------|---------|
| Platform | Cross-platform: macOS (dev) + Linux ARM64 (NEO One). Khong dung API Mac-only. |
| OpenCV | `cv2.VideoCapture(index)` — khong lay duoc ten thiet bi. Preview = xac nhan duy nhat. |
| Index range | 0–5 (6 vi tri). Tren macOS co the co Continuity Camera o index 0 hoac 1. NEO One thuong chi co 1 USB cam. |
| Config write | Ghi `~/.config/neostopmotion/config.toml`. Format TOML, section `[capture]`, key `webcam_index`. |
| Env override | `NEO_STOPMOTION_WEBCAM_INDEX` van co uu tien cao nhat (khong bi ghi de boi config write). |
| Thread safety | CaptureEngine.open() va release() goi tu thread chinh (Qt main thread). Picker phai dong engine cu truoc khi mo engine moi. |
| Live preview trong picker | Doc frame tu OpenCV trong picker loop; khong dung PreviewImageProvider hien tai (chi phuc vu main preview). Can giai phap rieng hoac mo rong provider. [BLOCKED — ky thuat: UX Designer + architect quyet] |

---

## Phu thuoc thiet ke (design_required: yes)

Nhung gi BA KHONG tu quyet — can UX Designer sau khi PO duyet spec:

1. **Vi tri nut "Doi camera"** tren CapturePage (goc / hang nut / icon-only).
2. **Layout popup picker**: kich thuoc, vi tri preview nho, nut dieu huong.
3. **Trang thai loading** trong picker khi dang mo camera ke tiep.
4. **Trang thai loi** (camera fail) trong picker — hien gi, o dau.
5. **Animation** khi picker mo/dong.
6. **Icon** cho nut "Doi camera" (phu hop nhan dan tre Viet Nam, khong chi dung emoji Mac).

---

## Test Scenarios

| ID | Scenario | Precondition | Input/Action | Expected | Priority |
|----|----------|-------------|--------------|----------|----------|
| TS-01 | Happy path chon camera thanh cong | Mac co 2 camera (built-in + Continuity/USB), app dang o CapturePage, webcam_index=0 dang dung | Bam "Doi camera" → bam "Camera tiep" → bam "Chon camera nay" | Picker dong; live preview doi sang camera index 1; khong crash; `webcam_ready` emit | P0 |
| TS-02 | Luu config sau khi chon | Phu thuoc Q3=co; da chon camera index 1 | Tat app, mo lai app | App khoi dong voi webcam_index=1; `~/.config/neostopmotion/config.toml` co `webcam_index = 1` | P0 |
| TS-03 | Camera ke tiep khong hoat dong | Chi co 1 camera o index 0; index 1-5 deu fail | Bam "Doi camera" → bam "Camera tiep" (chuyen sang index 1) | Preview hien "Camera nay khong hoat dong"; nut "Chon" disable; nut "Camera tiep" con hoat dong | P0 |
| TS-04 | Huy picker giu nguyen camera cu | App dang dung index 0; picker dang mo o index 2 | Bam "Huy" | Picker dong; app tiep tuc dung index 0; live preview khong thay doi | P0 |
| TS-05 | Khong co camera nao (0-5 deu fail) | Moi camera deu ro/fail (sim bang mock) | Mo picker → xoay het 6 index | Picker hien canh bao "Khong tim thay camera nao"; nut "Chon" disable | P0 |
| TS-06 | Env override khong bi ghi de boi config | `NEO_STOPMOTION_WEBCAM_INDEX=2` trong env; nguoi dung chon camera index 1 qua picker | Chon index 1, ghi config, restart app voi env var | App dung index 2 (env thang); config co index 1 nhung bi env override | P0 |
| TS-07 | Picker xoay vong index | App o index 0, co 6 index (0-5) | Bam "Camera tiep" 6 lan | Index lan luot: 0→1→2→3→4→5→0 (quay vong) | P1 |
| TS-08 | Mo picker trong khi dang co frame | Da chup 3 frame, webcam_index=0 | Mo picker, chuyen sang index 1, chon | Frame hien co khong bi xoa; camera doi; session tiep tuc | P1 |
| TS-09 | NEO One Linux: chi co 1 USB cam o index 0 | NEO One, 1 USB webcam, khong co Continuity Camera | Mo picker → thu cac index 1-5 | Index 1-5 hien "khong hoat dong"; nguoi dung co the chon lai index 0 | P1 |
| TS-10 | Config ghi duoc khi thu muc ton tai | `~/.config/neostopmotion/` ton tai; quyen ghi OK | Chon camera moi | Config duoc ghi thanh cong; khong co exception | P1 |
| TS-11 | Config ghi that bai (quyen han) | `~/.config/neostopmotion/` khong co quyen ghi | Chon camera moi | App van doi camera trong phien; log warning; khong crash; hien thong bao "Khong luu duoc tuy chon" | P1 |
| TS-12 | Preview trong picker khong anh huong onion skin | Dang co lastFrame tu lan chup truoc | Mo picker, xem preview camera index 1 | Onion skin tren CapturePage khong bi xoa/hong; khi dong picker preview chinh hoat dong binh thuong | P1 |

---

## Phu thuoc

- Spec lien quan: `docs/01-specs/features/frame-review-delete/spec.md` (CapturePage layout)
- Config system: `src/neo_stopmotion/config/settings.py` (load_settings, CaptureCfg)
- Signal bus: `src/neo_stopmotion/utils/signal_bus.py` (webcam_ready, webcam_error)
- Design: `design_required: yes` — ux-designer can tao design spec truoc khi dev code UI
