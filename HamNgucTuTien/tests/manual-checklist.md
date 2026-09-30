# QA — Hầm Ngục Tu Tiên 0.1.0-dev

Ngày 2026-09-30; dedicated server Windows x64 **747465**, Tu Tiên **18.1.0**. Đây là bản thử, chưa nghiệm thu phát hành ổn định. Không sửa save hoặc thư mục game đang chơi; mọi engine test dùng cluster riêng dưới `.superpowers/sdd/2026-09-30-ham-nguc-tu-tien/runtime`.

## Đã kiểm chứng

- [x] 30 test Lua 5.4.5: worldgen codec/offset/hook restoration, lifecycle/epoch/cooldown, RPC, target/buff, thưởng, cleanup, recovery, companion và chặn teleport trước khi dùng tài nguyên.
- [x] `python HamNgucTuTien/tests/check_dependencies.py`: custom stategraph closure và tên animation.
- [x] DST tạo world nhỏ, nạp arena mới và nạp lại save; Solo tắt (`server-out.log`, `server-stage6.log`).
- [x] 19 prefab tự tạo spawn được trong engine: cổng, recovery, khoáng, quái/boss/FX/corpse; thiếu hai SG sói đã được phát hiện và sửa.
- [x] 13 ca kích hoạt state boss trong engine tới `HN_QA_DONE`: Igris attack/dash/rotate/around/blink, Beru attack/jump/strong/control, Sharkboi attack1/2/3/ice_summon (`server-stage6.log`). Đây là thử thực thi state, chưa thay thế quan sát hình ảnh/đủ sát thương trên client.
- [x] Tu Tiên thật đăng ký đủ Linh Thạch; callback `xd_use_inventory:OnUse` gọi `onusefn(inst,doer)` đã đo bằng QA instrumentation (`server-stage11.log`). Không giải mã hoặc sửa core.
- [x] Wilson thật vào hầm, `DropEverything(true)` thu hồi axe và ba lô chứa redgem, cấp một rương thưởng thật, reset giữ đồ cá nhân đã đặt vào rương (`server-stage11.log`). Lượt dùng fixture ở stage9 được ghi riêng; không dùng làm bằng chứng tích hợp Tu Tiên.

## Cần nghiệm thu thêm

- [ ] Ma trận Forest-only và Forest+Caves, nhỏ/lớn, mỗi tổ hợp ít nhất 3 seed; nhìn nav/minimap bằng client.
- [ ] Hai client thật: popup, rank/icon, prediction/transition, khóa boss, spam/đồng thời vào cổng, mất kết nối cả tổ đội.
- [ ] Thử cả Nyx và nhân vật DST qua đầy đủ chuỗi chiêu, sát tường; đối chiếu animation/damage/CC với Solo gốc.
- [ ] Chơi đủ độ khó 2–10, cân bằng lượng máu, số người, thời gian clear và loot/giờ.
- [ ] Restart thực tế giữa trận và sau clear; reconnect người offline; rương thu hồi/ba lô/đồ stack qua save/load; auto-loot của đầy đủ bộ mod.
- [ ] Bộ Tu Tiên/Nyx/Thần Khí/Công Trình/Thành Tựu; Thiên Nghịch Châu, Truyền Tống Trận, Thuấn Ảnh, hồi sinh/companion trong client.

## Chạy lại

Từ root repository: `lua HamNgucTuTien/tests/run.lua all` và `python HamNgucTuTien/tests/check_dependencies.py`. Có thể chọn nhóm `worldgen`, `lifecycle`, `cooldown`, `actions`, `network`, `combat`, `rewards`, `recovery`, `compat`, `restrictions`.

Các `engine_smoke.lua`, `engine_lifecycle.lua`, `engine_worldgen.lua` phải được import từ `AddSimPostInit` của một mod QA riêng, trên **cluster dùng để thử**. Chúng tạo/xóa entity và thay trạng thái lượt. `engine_lifecycle.lua` yêu cầu Tu Tiên thật hoặc prefab thưởng fixture được ghi rõ trong log. Không dùng QA mod trên server chơi. Cổng nằm ở Forest master; cần cả mod trên Caves nhưng không có arena/manager thứ hai.

Logs có `HN_QA_PASS`, `HN_QA_DONE`; chỉ xem kết quả pass khi không có lỗi Lua trong cả khoảng chạy, không chỉ khi một dòng pass xuất hiện.
