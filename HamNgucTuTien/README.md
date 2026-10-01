# Hầm Ngục Tu Tiên

Bản `1.1.0`: mod Hầm Ngục riêng cho Don't Starve Together, tách từ Solo Leveling 2.2.7 của Saikuno. Cần **tạo thế giới mới khi cài lần đầu**, bật Tu Tiên (`3721846643`) trên server và cài mod này cho tất cả client. Solo Leveling không cần bật. Nâng từ bản 0.1.x/1.0.0 trên world đã có arena chỉ cần cập nhật mod trên server và mọi client, rồi khởi động lại game.

## Cài đặt

Chép thư mục `HamNgucTuTien` vào thư mục `mods` của DST, bật trong **Server Mods**, bật Tu Tiên rồi tạo world mới. Dedicated server thêm `HamNgucTuTien={enabled=true}` vào `modoverrides.lua`; giữ cấu hình dependency Tu Tiên đang dùng. Bật mod này cho cả Forest và Caves khi cluster có hai shard. Arena và manager chỉ chạy ở Forest master.

Công Trình Tu Tiên, Nyx và Thần Khí là tùy chọn. Thiếu Linh Thạch bắt buộc hoặc dùng world chưa có arena sẽ không mở cổng. Không tạo arena vào save cũ.

## Luật chơi

Bản 1.0.0 giữ nguyên gameplay của 0.1.2-dev, gồm bản sửa build Igris. Cơ chế cổng hết giờ và quái thoát ra giữ nguyên.

Bản 0.1.2-dev sửa xung đột build Igris: texture custom dùng build riêng `hn_igris_build` cho cả boss và xác, bank vẫn là `boarrior`. Texture/animation và chỉ số chiến đấu giữ nguyên. Cập nhật mod trên server và client, khởi động lại game để nạp lại asset; world đã có arena không cần tạo lại. Kiểm tra asset và test Lua đã qua; chưa kiểm chứng hình ảnh trong client sau bản sửa. Các cảnh báo animation diện rộng và Storage Multi nằm ngoài bản sửa này.

- Một cổng và một lượt chung cho tổ đội, ngẫu nhiên 2–10 làn, 10 quái mỗi làn thường. Bắt đầu sau 5 giây, nghỉ giữa làn 10 giây.
- Làn cuối: boss DST ở hạng 2–5 làn; hạng 6–10 chọn đều một trong sáu boss: Igris, Sharkboi, Beru, Lợn Rừng Bọ Hung, Siêu Lợn Song Kiếm, Hộ Vệ Cổ Đại Ác Mộng. Giữ các nhóm chiêu và tài sản nguồn, bỏ world-rank/progression Solo nên sức mạnh không bằng tuyệt đối mod gốc.
- Đến làn 2 đóng đăng ký. Khi boss xuất hiện khóa lối ra; thắng có 180 giây nhặt thưởng.
- Cổng hồi 480 giây. Cổng bị bỏ 480 giây sẽ đóng và thả một quái thường tại vị trí cổng.
- Rời hầm: hồi chiêu cá nhân 480 giây; chết: 960 giây. Vượt biên sẽ được đưa lại vào hầm, không bị giết.
- Đồ thực sự rơi khi chết được chuyển về vị trí cổng: vật phẩm thông thường vào rương thu hồi; ba lô/vật phẩm không thể nằm trong rương được đặt nguyên vẹn trên đất. Quyền mở rương là dùng chung tổ đội, không khóa theo userid. Đồ giữ lại khi chết vẫn thuộc người chơi.
- Không xóa quan hệ đồng hành. Đồng hành chưa hỗ trợ và vật phẩm gọi Chester/Hutch/Glommer khiến thao tác vào hầm bị từ chối. Abigail/Woby được giữ ngoại lệ của nguồn.
- Restart/rollback **hủy trận đang đánh**, dọn vật thể của lượt và hồi chiêu. Người reconnect ở arena được đưa về cổng. Đồ người chơi, rương thu hồi và thưởng đã nhặt được giữ.

## Ba boss mới (1.1.0)

| Boss | Máu nền | Công thường / planar | Bộ chiêu |
|---|---:|---:|---|
| Lợn Rừng Bọ Hung | 25.000 | 50 / 30 | Combo, nhảy, tăng tốc, khống chế |
| Siêu Lợn Song Kiếm | 30.000 | 50 / 30 | Combo, xoay đánh, tường vây tồn tại 4 giây |
| Hộ Vệ Cổ Đại Ác Mộng | 25.000 mỗi pha | 60 / 0 | Lao húc, đập đất, sóng xung kích, lửa, dịch chuyển; hai pha |

Boss mới dùng hệ số hầm ×1,5 và hệ tăng ngày/cảnh giới hiện có của Thần Khí. Guardian chuyển pha trong 4,5 giây, hồi đầy thanh máu đã được scale; chỉ chết pha cuối mới tính thắng. Lửa từ cùng boss chỉ gây một tick/giây trên mỗi mục tiêu dù các vùng chồng nhau. Tường/FX dọn theo lượt và khi boss chết; không phá đồ/công trình hay sinh loot Solo riêng.

Phần điều khiển Guardian/FX được viết lại theo luật arena; nhịp hình ảnh có thể khác bản Solo. Đã có kiểm tra tự động và dedicated engine với bộ Tu Tiên; hình ảnh hai client và thời gian hạ boss bằng trang bị thật còn cần chơi thử. Không đưa nhóm quái Tầm Bảo ngoài map vào bản này.

## Cân bằng ba boss ban đầu (0.1.1-dev)

Giảm máu nền để dùng cùng hệ tăng theo ngày/cảnh giới của Thần Khí Tu Tiên. Giữ công nền, planar, AI/chiêu và hệ số làn. Quái thường vẫn nhân máu/công ×2 ở hạng 2–5 làn, ×3 ở hạng 6–10 làn; boss cuối tương ứng ×1 và ×1,5. Hệ số Thần Khí tiếp tục nhân lên các giá trị này, không được chép thêm vào Hầm Ngục.

| Boss | Máu nền cũ → mới | Trong hầm, chỉ hệ số hầm | Có Thần Khí: ngày 0/cấp 0 | Có Thần Khí: ngày 200/cấp 12 |
|---|---:|---:|---:|---:|
| Sharkboi | 50.000 → 20.000 | 30.000 | 105.000 | 675.000 |
| Igris | 400.000 → 30.000 | 45.000 | 157.500 | 1.012.500 |
| Beru | 600.000 → 40.000 | 60.000 | 210.000 | 1.350.000 |

Các cột Thần Khí tính theo code hiện tại trong repository: máu nền ×1,5 × hệ số boss theo ngày × hệ số cảnh giới thế giới. Ngày là `TheWorld.state.cycles` (0 khi vừa tạo); cảnh giới là mốc thế giới đã ghi nhận. Tổng trên chưa tính can thiệp riêng của mod khác. Công thường cuối thang vẫn ×6: Sharkboi/Beru 300, Igris 240 trước phòng thủ và hiệu ứng khác; planar và chiêu trừ thẳng máu không nhân theo công thường.

Mức máu mới đưa chênh lệch ba boss về 1:1,5:2, thay vì 1:8:12. Tham chiếu vũ khí Thần Khí có công nền 88–100 cùng hệ cường hóa/chí mạng/chiêu phụ; đây là mốc thử cho tổ đội, chưa phải kết quả đo thời gian hạ boss bằng nhân vật thực tế. Không yêu cầu cường hóa tối đa để mở hầm. Boss DST hạng 2–5 và phần thưởng giữ nguyên.

Nâng từ 0.1.0-dev trên world đã có arena: dừng server, thay mod trên server và client, rồi khởi động lại; boss của lượt mới nhận máu mới. Không cần tạo lại world chỉ để nhận chỉnh sửa chỉ số này. Yêu cầu world mới ở phần cài đặt áp dụng khi world chưa có arena.

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
python HamNgucTuTien/tests/igris_assets_test.py
```

[Checklist và bằng chứng QA](tests/manual-checklist.md) phân biệt test Lua, dedicated engine và ca chơi nhiều client chưa nghiệm thu. Các file `tests/engine_*.lua` chỉ được gọi bởi mod QA riêng trên cluster thử; bản mod không tự chạy chúng. Không bật prefab thưởng giả của QA trên server chơi.

## Nguồn

Tác giả nội dung gốc: **Saikuno**, Solo Leveling **2.2.7**, nguồn local `3780347550/`. [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json) ghi nguồn, SHA-256, phần trích và state boss. Tên bank/build animation giữ theo tài sản gốc, ngoại trừ build Igris được đổi thành `hn_igris_build` để tránh trùng Boarrior vanilla. Lua dùng namespace `hn_`; mod không cần đọc thư mục nguồn lúc chạy. Chưa upload Workshop.
