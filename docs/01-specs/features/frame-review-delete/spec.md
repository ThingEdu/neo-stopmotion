# Spec: Xem lai va xoa frame khi chup stop-motion

> Feature key: `frame-review-delete` · scope: `app` · Owner: BA · Status: draft

---

## 1. User Story

**Vai**: Be (6-14 tuoi) dang chup phim stop-motion.

**Muc tieu**: Khi chup xong 1 tam hinh khong ung y (nham mat, nhich tay sai...), be
co the xem lai va xoa chinh xac tam do — khong phai chi xoa tam vua chup cuoi cung —
roi chup lai, ma khong bi mat cac frame truoc do.

**Ket qua mong doi**: Phim cuoi cung khong co khung anh loi; be tu tin lam lai ma
khong so hong ca du an.

---

## 2. Muc tieu ky thuat

- Xoa frame o bat ky vi tri nao (khong chi frame cuoi).
- Giu nguyen tinh nang UNDO frame cuoi (phim cung nhanh, nut cung).
- Sau khi xoa, ffmpeg tiep tuc ghep phim binh thuong (danh so frame lien tuc
  `frame_%04d.png`).
- Cap nhat bieu dem frame va thoi luong hien thi ngay.

---

## 3. Pham vi (Scope)

### Trong scope

| # | Tinh nang |
|---|-----------|
| 1 | Xoa frame bat ky theo vi tri (delete_frame(n)) |
| 2 | Re-sequence cac frame sau khi xoa (giu file lien tuc) |
| 3 | Cap nhat frame_count va duration trong project.json |
| 4 | Giu nguyen UNDO frame cuoi (undo_last_frame) bang nut Z / UART UNDO |
| 5 | Signal moi frame_deleted tren signal_bus de UI tu refresh |
| 6 | Hien thi thumbnail strip de be chon frame muon xoa (tuong thuoc design) |
| 7 | Xac nhan truoc khi xoa (popup "Con co muon xoa anh nay khong?") |

### Ngoai scope

| # | Ly do khong lam |
|---|-----------------|
| Them lenh UART moi cho xoa frame bat ky | Khong the chon so frame qua nut vat ly; UART UNDO giu nguyen |
| Undo-of-delete (khoi phuc frame da xoa) | Phuc tap, PO chua yeu cau — de nghi phase sau |
| Multi-select xoa nhieu frame mot luc | Phuc tap, phase sau |
| Trim dau/cuoi phim (batch delete) | Phase sau |

---

## 4. Yeu cau chuc nang

### 4.1 Xoa frame cuoi (UNDO nhanh — giu nguyen)

- Phim phap: nut Z tren ban phim HOAC nut vat ly ThingBot (UART UNDO).
- Hanh vi hien tai: `undo_last_frame()` → xoa file co so cao nhat → cap nhat
  frame_count → emit `frame_undone`.
- **Khong thay doi** logic nay. Chi dam bao test cover sau khi them delete_frame.

### 4.2 Xoa frame bat ky

**Kich hoat**: Be bam vao thumbnail (hoac phim tat keyboard) de chon frame, xac nhan
xoa.

**Hanh vi mong doi (step-by-step)**:

1. Be chon frame thu `n` (1-based) tu thumbnail strip.
2. UI hien popup xac nhan: "Con co muon xoa anh so [n] khong?" → be bam "Xoa" (hoac
   "Thoi" de huy).
3. App goi `frame_manager.delete_frame(n)`.
4. `delete_frame(n)` thuc hien:
   a. Xoa file `frame_000n.png` (theo index 1-based, do `%04d` bat dau 0001).
   b. Rename cac file `frame_000(n+1).png ... frame_000k.png` → `frame_000n.png ...
      frame_000(k-1).png` (re-sequence de giu lien tuc).
   c. Cap nhat `project.json`: giam `frame_count` di 1, tinh lai `duration`.
5. Emit `signal_bus.frame_deleted(new_frame_count)`.
6. UI nhan signal: cap nhat FrameCounter + refresh thumbnail strip.

**Rang buoc**:
- Neu `frame_count == 0` hoac `n` ngoai khoang [1, frame_count]: raise
  `ValueError`, UI hien bao loi nhe.
- Qua trinh rename file phai atomic nhat co the (xem Rui ro §5.2).
- Neu xoa frame cuoi (n == frame_count): tuong duong undo_last_frame (khong can
  re-sequence, chi xoa 1 file + cap nhat metadata).

### 4.3 Cap nhat hien thi sau khi xoa

- FrameCounter: giam so frame hien thi ngay.
- Duration: tinh lai `frame_count / fps` (fps lay tu cau hinh hien tai).
- Thumbnail strip: load lai danh sach frame tu `get_all_frames()`.

---

## 5. Cach tiep can ky thuat de xuat

### 5.1 Core — FrameManager.delete_frame(n: int)

**Vi tri**: `src/neo_stopmotion/core/frame_manager.py`

**Logic**:

```
def delete_frame(n: int) -> None:
    # n: 1-based index
    validate n in [1, frame_count]
    path_to_delete = project_dir / f"frame_{n:04d}.png"
    xoa path_to_delete

    # Re-sequence: doi ten frame_(n+1)..frame_k thanh frame_n..frame_(k-1)
    for i in range(n+1, frame_count+1):
        rename frame_{i:04d}.png → frame_{i-1:04d}.png

    frame_count -= 1
    duration = frame_count / fps
    cap nhat project.json
```

**Diem can luu y**:
- Rename phai theo thu tu tang dan (i = n+1, n+2, ...) de tranh de tren file con
  ton tai.
- Chua co co che atomic thuc su tren file system (xem Rui ro).

### 5.2 Rui ro ky thuat

| Rui ro | Muc do | Giam thieu |
|--------|--------|-----------|
| Rename that bai giua chung (dien mat) → danh so lo hong | NGHIEM TRONG | Bat Exception, log loi, hien thong bao "Co loi xoa frame, kiem tra du an" |
| Hieu nang cham khi co nhieu frame (>100) | TRUNG BINH | Rename la O(n) file — chap nhan duoc voi du an nho; ghi chu de toi uu phase sau neu can |
| Mat mapping so frame neu UI giu cache index cu | TRUNG BINH | Luon reload danh sach tu get_all_frames() sau khi emit signal |
| Xung dot UNDO (undo_last_frame) goi dong thoi voi delete_frame | THAP | App dieu khien luon goi qua app_controller (1 thread) — khong dung thoi |
| Re-sequence lai lam moi thumbnail bi load sai cache | THAP | Image provider tra ve anh theo duong dan file moi sau rename |

### 5.3 Service — AppController

**Vi tri**: `src/neo_stopmotion/services/app_controller.py`

Them method `_do_delete_frame(n: int)`:
- Goi `frame_manager.delete_frame(n)`.
- Emit `signal_bus.frame_deleted(new_frame_count)`.
- Log hanh dong.

Khong them lenh UART moi. Xoa frame bat ky duoc goi tu UI (chuot/phim tat), khong
qua ThingBot.

### 5.4 Signal Bus

**Vi tri**: `src/neo_stopmotion/utils/signal_bus.py`

Them signal:
```python
frame_deleted = pyqtSignal(int)  # int = frame_count moi sau khi xoa
```

### 5.5 UI — Thumbnail va Image Provider

<!-- TODO: [BLOCKED] Chua ro UX Designer chon giai phap nao -->

Hai lua chon:

| Lua chon | Mo ta | Uu | Nhuoc |
|----------|-------|----|-------|
| A. file:// URL | QML Image { source: "file://" + path } | Don gian, khong can Python code them | Cache QML co the giu anh cu sau rename |
| B. QQuickImageProvider | Python cung cap anh qua load_frame(n) | Kiem soat cache chinh xac | Can viet them ImageProvider class |

**De xuat**: Chon A (file:// URL) truoc vi don gian; them `cache: false` hoac
timestamp suffix de force reload sau khi xoa.

**Ghi chep cho UX Designer**: Cac trang thai can design:
- Trang thai binh thuong: thumbnail strip hien tat ca frame.
- Frame dang duoc chon (hover/focus): border noi bat.
- Popup xac nhan xoa.
- Sau khi xoa: strip refresh, frame ke tiep duoc chon (hoac frame cuoi neu xoa frame
  cuoi cung).

---

## 6. Trang thai man hinh / luong

### Capturing (binh thuong)
- Live preview hien thi.
- Thumbnail strip hien tat ca frame da chup (cuon ngang neu nhieu).
- Nut Z / UART UNDO: xoa frame cuoi (hanh vi hien tai).
- Click vao thumbnail: chon frame → hien popup xac nhan xoa.

### Empty (0 frame)
- Thumbnail strip trong: hien thong bao "Chua co anh nao. Hay bam IO1 de chup!".
- Nut xoa bi vo hieu hoa (disabled).

### Error — xoa that bai
- Hien thong bao ngan: "Oi, xoa anh bi loi. Con thu lai nhe!" (1-2 giay, tu dong
  tat).
- Frame count KHONG thay doi.
- App tiep tuc hoat dong binh thuong.

### Error — index khong hop le
- Khong the xay ra neu UI chi cho phep chon frame ton tai.
- Neu xay ra (bug): log WARNING + hien bao loi nhe, khong crash.

### Success — sau khi xoa
- Thumbnail strip cap nhat (frame xoa bien mat, cac frame sau dich lai).
- FrameCounter giam 1.
- Live preview tiep tuc (khong bi gian doan).
- Be co the tiep tuc chup them hoac xoa frame khac.

---

## 7. Test Scenarios

| ID | Scenario | Precondition | Input/Action | Expected | Priority |
|----|----------|-------------|--------------|----------|----------|
| TS-01 | Xoa frame giua — re-sequence dung | Du an co 5 frame | delete_frame(3) | Frame 4→3, 5→4; frame_count=4; project.json cap nhat; ffmpeg chay duoc | P0 |
| TS-02 | Xoa frame cuoi | Du an co 3 frame | delete_frame(3) | frame_count=2; chi xoa 1 file, khong rename; ffmpeg chay duoc | P0 |
| TS-03 | Xoa frame dau | Du an co 4 frame | delete_frame(1) | Frame 2→1, 3→2, 4→3; frame_count=3; ffmpeg chay duoc | P0 |
| TS-04 | Xoa roi export thanh cong | 5 frame, xoa frame 2 | delete_frame(2) + export | MP4+GIF tao ra dung 4 frame, khong skip/loi | P0 |
| TS-05 | Frame count dung sau xoa | 7 frame | delete_frame(4) | frame_count==6; duration==6/fps | P0 |
| TS-06 | Xoa khi 0 frame | Du an trong | delete_frame(1) | ValueError; frame_count khong doi | P0 |
| TS-07 | Xoa index ngoai vung | 3 frame | delete_frame(5) | ValueError; frame_count khong doi | P0 |
| TS-08 | UNDO frame cuoi (hanh vi cu) khong bi anh huong | 4 frame | undo_last_frame() | Frame 4 xoa; frame_count=3; hanh vi giong truoc | P0 |
| TS-09 | Signal frame_deleted duoc emit | 3 frame | delete_frame(2) | frame_deleted(2) duoc emit voi gia tri dung | P0 |
| TS-10 | Xoa nhieu lan lien tiep | 5 frame | delete_frame(1) x3 | Sau 3 lan: frame_count=2; danh so lien tuc 0001-0002 | P1 |
| TS-11 | Xoa frame duy nhat | 1 frame | delete_frame(1) | frame_count=0; khong con file frame nao; project.json cap nhat | P1 |
| TS-12 | Hieu nang xoa frame 100 frame | 100 frame | delete_frame(1) | Hoan thanh trong < 3 giay | P1 |

---

## 8. Cau hoi lam ro cho PO

<!-- Ghi chep de Coordinator chuyen PO; khong tu y quyet -->

Q1. Ngoai xoa frame bat ky (tinh nang moi), PO co muon giu nguyen hanh vi UNDO
    frame cuoi qua nut Z va nut ThingBot (UART UNDO) khong?
    (a) Co — giu nguyen UNDO, them xoa bat ky qua UI   [De xuat]
    (b) Doi UNDO thanh mo man hinh xem lai — nut ThingBot se khong xoa nhanh nua
    De xuat cua em: (a) — don gian, khong lam hong quy trinh chup nhanh hien tai.

Q2. Khi xoa xong, neu be muon "lay lai" frame vua xoa, co can tinh nang
    Undo-of-delete (khoi phuc frame) khong?
    (a) Khong can — xoa la mat, be chup lai   [De xuat cho phase nay]
    (b) Can — them Undo-of-delete (phuc tap hon, phase sau)
    De xuat cua em: (a) cho phase nay; ghi nhan (b) cho roadmap.

Q3. Thumbnail strip cho phep be xem lai frame: can hien thi bao nhieu thumbnail
    cung luc?
    (a) Tat ca frame (cuon ngang neu nhieu — vd tren may tinh lon)
    (b) Chi hien 5-10 frame gan nhat
    De xuat cua em: (a) — de be biet toan bo du an; UX Designer co the gioi han
    kich thuoc thumbnail de vua man hinh.

---

## 8b. Quyết định PO (2026-06-14) — ĐÃ CHỐT

| # | Quyết định | Ảnh hưởng |
|---|-----------|-----------|
| 1 | **NEO One KHÔNG có màn cảm ứng** | Bé chọn frame bằng **chuột** (bấm thumbnail) + **bàn phím** (mũi tên/Delete/Escape). Không cần cỡ vùng chạm cảm ứng, nhưng vẫn để target to/rõ. |
| 2 | Sau khi xoá frame N, ảnh chụp tiếp **nối vào cuối** (không chèn lại vị trí N) | `delete_frame` chỉ re-sequence; `add_frame` append như cũ. Không cần logic chèn. |
| 3 | **KHÔNG** làm Undo-of-delete (lấy lại frame đã xoá) trong phase này | Hộp thoại xác nhận là đủ bảo vệ. Ghi roadmap nếu cần sau. |
| 4 | Giữ **xoá nhanh frame cuối** (Z / ThingBot UNDO) **VÀ** thêm **xoá frame bất kỳ** qua UI | Cả 2 cùng tồn tại. UNDO không đổi. |
| 5 | Filmstrip **cuộn ngang hiện tất cả frame** (tối đa ~100) | Chọn phương án A; giới hạn cỡ thumbnail cho vừa màn hình. |
| - | Thumbnail: **file:// + cache-busting** (đề xuất kỹ thuật, team tự chốt lúc code) | Tránh QML cache ảnh cũ sau rename. |

## 9. Phu thuoc

- `src/neo_stopmotion/core/frame_manager.py` — them `delete_frame(n)`.
- `src/neo_stopmotion/services/app_controller.py` — them `_do_delete_frame(n)`.
- `src/neo_stopmotion/utils/signal_bus.py` — them signal `frame_deleted`.
- `src/neo_stopmotion/ui/qml/CapturePage.qml` — them thumbnail strip + popup xac
  nhan (sau khi co design spec).
- Design spec: `docs/01-specs/features/frame-review-delete/design-spec.md`
  (UX Designer soang; can truoc khi dev code UI).
- Khong dong cham UART protocol: `src/neo_stopmotion/hardware/uart_protocol.py`
  khong thay doi.
