# Domain: Thu vien phim

> Feature key: `film-library` · scope: `app` · Owner: BA

---

## Luat nghiep vu

| # | Dieu kien | Ket qua |
|---|-----------|---------|
| BR-1 | Session co `exported == false` | Khong hien trong Thu vien (vi session chua hoan thanh) |
| BR-2 | Session co `exported == true` nhung `mp4_path` null hoac file khong ton tai | Hien voi trang thai loi (icon ⚠️), chi cho phep xoa |
| BR-3 | Session co `project.json` khong doc duoc (loi JSON, thieu truong bat buoc) | Hien voi trang thai loi (icon ⚠️), chi cho phep xoa |
| BR-4 | Thu muc nay sinh trong `projects_dir` khong co `project.json` | Bo qua (khong liet ke, khong hien loi) |
| BR-5 | `title` rong hoac null | Ten hien thi: "Phim dd/MM HH:mm" tu `created_at`, khong ghi lai vao JSON |
| BR-6 | `download_url is None` | Nut "Chep link" bi disabled; khong co tooltip URL |
| BR-7 | Xoa phim: nguoi dung phai xac nhan 2 lan | Hanh dong khong the undo — bao ve tre em |
| BR-8 | Xoa phim: xoa ca thu muc session (de xuat — cho PO xac nhan PO-Q2) | `shutil.rmtree(session_dir)` — bao gom frames/, output.mp4, output.gif, qr.png, project.json |
| BR-9 | Sap xep mac dinh: moi nhat truoc | Sort giam dan theo `created_at` |
| BR-10 | Scan chi lay toi da `StorageCfg.max_sessions` session (mac dinh 50) | Tranh qua tai khi projects_dir co nhieu thu muc |
| BR-11 | Do phan giai lay tu frame dau (`frames/frame_0001.png`) | Khong luu trong SessionMeta, tinh on-demand khi chon phim |
| BR-12 | Dung luong = mp4_path.size + gif_path.size (neu gif ton tai) | Khong luu trong SessionMeta, tinh on-demand khi chon phim |

---

## Validation

| Truong | Rang buoc | Hanh vi khi vi pham |
|--------|-----------|---------------------|
| `session_id` (khi xoa) | Phai la chuoi non-empty; thu muc tuong ung phai ton tai | Log loi + bao loi nhe, khong crash |
| `mp4_path` (khi phat) | Phai la Path hop le va file ton tai | Hien trang thai loi (§4.3 spec) |
| `download_url` (khi chep) | Phai non-None va non-empty | Nut disabled (BR-6) |
| `created_at` (khi hien ten) | Phai la datetime hop le | Fallback: "Phim khong ro ngay" |
| `projects_dir` (khi scan) | Thu muc phai ton tai va co quyen doc | Hien man loi (§4.5 spec) |

---

## State machine (LibraryPage)

```
[Vao man]
    |
    v
LOADING (scan projects_dir)
    |
    |--[0 phim hop le]--> EMPTY (hien CTA, nut disabled)
    |
    |--[≥1 phim hop le]--> NORMAL (luoi + panel chi tiet)
    |                           |
    |                           |--[Enter / nut Xem]--> PLAYING (mp4 loop)
    |                           |                           |
    |                           |                           |--[Enter/Space]--> PAUSED
    |                           |                           |--[◀▶▲▼]--> NORMAL (dung phat, doi phim)
    |                           |                           |--[Esc]--> [Thoat man]
    |                           |
    |                           |--[Del]--> CONFIRM_DELETE_1
    |                           |                   |--[Esc/"Thoi"]--> NORMAL
    |                           |                   |--["Xoa"]--> CONFIRM_DELETE_2
    |                           |                                   |--[Esc/"Huy"]--> NORMAL
    |                           |                                   |--["Xoa that"]--> DELETING
    |                           |                                                       |--[OK]--> NORMAL hoac EMPTY
    |                           |                                                       |--[loi]--> NORMAL + error toast
    |                           |
    |                           |--[S]--> SAVING (open_save_dialog)
    |                           |             |--[huy]--> NORMAL
    |                           |             |--[OK]--> NORMAL + success toast
    |                           |             |--[loi]--> NORMAL + error toast
    |                           |
    |                           |--[L]--> (copy clipboard) --> NORMAL + toast
    |
    |--[loi doc projects_dir]--> ERROR_DIR (hien thong bao loi + nut Thu lai)
    |                                   |--[Thu lai]--> LOADING
    |                                   |--[Esc]--> [Thoat man]

[Thoat man] (Esc hoac nut Quay lai chup) --> CapturePage
```

---

## Edge Case Matrix

| Tinh huong | Hanh vi mong doi | Ghi chu |
|-----------|------------------|---------|
| `projects_dir` khong ton tai (lan dau chay app) | Man loi ERROR_DIR + nut Thu lai | Khong tu dong tao thu muc |
| `projects_dir` = `~/projects` nhung khong co quyen doc | Man loi ERROR_DIR | Log warning |
| 51 session hop le (qua max_sessions=50) | Chi hien 50 phim moi nhat; hien chu nho "Hien 50/51 phim" | BR-10 |
| Session co `frames/frame_0001.png` khong ton tai | Thumbnail hien placeholder emoji; phan do phan giai = "--" | |
| Session co gif_path null (export truoc khi them GIF) | Dung luong chi tinh mp4; khong hien "-- MB GIF" | |
| Xoa phim trong khi phat: phim dang phat la phim bi xoa | Dung phat truoc khi mo dialog xac nhan | |
| Xoa phim, sau do projects_dir bi day (rmtree that bai) | Hien loi, phim van trong danh sach, khong xoa khoi UI | |
| Bam Del o empty state | Khong lam gi (nut disabled) | |
| Bam L khi download_url = "" (chuoi rong) | Xu ly nhu None (disabled) | |
| Chuyen phim trong khi dialog xoa dang mo | Dialog dong lai (Esc); chon phim moi | Tranh xoa nham phim |
| `fps_playback = 0` (du lieu loi) | duration hien "--"; khong chia 0 | |
| Ten phim co ky tu dac biet (emoji, Unicode) | Hien dung, ellipsis neu qua dai | |
| 2 session co cung `created_at` (microsecond khac) | Sap xep on dinh theo `session_id` de bo sung | Tranh nhap nhang thu tu |
| App mat ket noi disk khi dang copy (Luu lai) | Hien loi copy, de nghi thu lai | |
| `download_url` co gia tri nhung HTTP 4xx (het han) | De xuat: hien nut voi canh bao "Link co the het han" — cho PO xac nhan (PO-Q3) | |
