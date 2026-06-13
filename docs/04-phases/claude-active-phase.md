# Active Phase Pointer

> File này cho Coordinator biết phase/wave nào đang hoạt động. SESSION START đọc file
> này ĐẦU TIÊN. Cập nhật mỗi khi đổi phase/wave.

```yaml
active_phase_path: ""      # vd: docs/04-phases/feat-fps-selector
active_wave: ""            # vd: wave-1
branch: ""                 # vd: feat-fps-selector
updated: ""                # YYYY-MM-DD
```

Chưa có phase nào hoạt động. Khi bắt đầu phase mới, Coordinator (hoặc PO) cập nhật
các trường trên và tạo `docs/04-phases/<phase>/` từ template.
