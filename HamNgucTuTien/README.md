# Hầm Ngục Tu Tiên

Bản thử `0.1.0-dev`: mod Hầm Ngục riêng cho Don't Starve Together, tách từ Solo Leveling 2.2.7 của Saikuno. Cần **tạo thế giới mới**, bật Tu Tiên (`3721846643`) trên server và cài mod này cho tất cả client. Solo Leveling không cần bật.

## Cài bản thử

Chép thư mục `HamNgucTuTien` vào thư mục `mods` của DST, bật trong **Server Mods**, bật Tu Tiên rồi tạo world mới. Dedicated server thêm `HamNgucTuTien={enabled=true}` vào `modoverrides.lua`; giữ cấu hình dependency Tu Tiên đang dùng. Bật mod này cho cả Forest và Caves khi cluster có hai shard. Arena và manager chỉ chạy ở Forest master.

Công Trình Tu Tiên, Nyx và Thần Khí là tùy chọn. Thiếu Linh Thạch bắt buộc hoặc dùng world chưa có arena sẽ không mở cổng. Không tạo arena vào save cũ.

## Luật chơi

- Một cổng và một lượt chung cho tổ đội, ngẫu nhiên 2–10 làn, 10 quái mỗi làn thường. Bắt đầu sau 5 giây, nghỉ giữa làn 10 giây.
- Làn cuối: boss DST ở hạng 2–5 làn; Igris, Sharkboi hoặc Beru ở hạng 6–10 làn. Giữ AI/chuỗi chiêu và assets nguồn, bỏ world-rank/progression Solo nên sức mạnh không bằng tuyệt đối mod gốc.
- Đến làn 2 đóng đăng ký. Khi boss xuất hiện khóa lối ra; thắng có 180 giây nhặt thưởng.
- Cổng hồi 480 giây. Cổng bị bỏ 480 giây sẽ đóng và thả một quái thường tại vị trí cổng.
- Rời hầm: hồi chiêu cá nhân 480 giây; chết: 960 giây. Vượt biên sẽ được đưa lại vào hầm, không bị giết.
- Đồ thực sự rơi khi chết được chuyển về vị trí cổng: vật phẩm thông thường vào rương thu hồi; ba lô/vật phẩm không thể nằm trong rương được đặt nguyên vẹn trên đất. Quyền mở rương là dùng chung tổ đội, không khóa theo userid. Đồ giữ lại khi chết vẫn thuộc người chơi.
- Không xóa quan hệ đồng hành. Đồng hành chưa hỗ trợ và vật phẩm gọi Chester/Hutch/Glommer khiến thao tác vào hầm bị từ chối. Abigail/Woby được giữ ngoại lệ của nguồn.
- Restart/rollback **hủy trận đang đánh**, dọn vật thể của lượt và hồi chiêu. Người reconnect ở arena được đưa về cổng. Đồ người chơi, rương thu hồi và thưởng đã nhặt được giữ.

## Thưởng dùng chung

| Nguồn | 2–5 làn | 6–10 làn |
|---|---|---|
| Quái thường | 50%: 1 Linh Thạch Hạ | 50%: 2 Linh Thạch Hạ |
| Rương thắng | 10 Linh Thạch Trung + 2 Huyền Tinh Hạ | 2 Linh Thạch Thượng + 2 Huyền Tinh Trung |
| Mỗi mạch khoáng | 2 Linh Thạch Hạ; 6 mạch | 4 Linh Thạch Hạ; 12 mạch |

Ngoài ra có loot vật lý gốc của quái (50%) và boss (100%). Thiếu Thần Khí: mỗi Huyền Tinh Hạ đổi thành 5 Linh Thạch Hạ, mỗi Huyền Tinh Trung thành 10. Không có xu/shop/kho ảo Solo. Giá trị cân bằng nằm trong `scripts/hn_dungeon/reward_defs.lua`.

## Kiểm chứng

Chạy từ root repository:

```powershell
lua HamNgucTuTien/tests/run.lua all
python HamNgucTuTien/tests/check_dependencies.py
```

[Checklist và bằng chứng QA](tests/manual-checklist.md) phân biệt test Lua, dedicated engine và ca chơi nhiều client chưa nghiệm thu. Các file `tests/engine_*.lua` chỉ được gọi bởi mod QA riêng trên cluster thử; bản mod không tự chạy chúng. Không bật prefab thưởng giả của QA trên server chơi.

## Nguồn

Tác giả nội dung gốc: **Saikuno**, Solo Leveling **2.2.7**, nguồn local `3780347550/`. [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json) ghi nguồn, SHA-256, phần trích và state boss. Tên bank/build animation giữ theo tài sản gốc. Lua dùng namespace `hn_`; mod không cần đọc thư mục nguồn lúc chạy. Chưa upload Workshop.
