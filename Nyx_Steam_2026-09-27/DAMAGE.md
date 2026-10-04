# Sát thương 5 chiêu chiến đấu — Nyx 1.5.2

Bản 1.5.2 (2026-10-02): sửa phần cộng sát thương vũ khí Lục Mạch, nhận diện callback native qua wrapper/closure và chống tính hệ số chiêu hoặc vũ khí hai lần. Cả năm chiêu cập nhật vũ khí và buff đang có ở mỗi hit.

Mỗi lần trúng đích dùng công thức:

`Xd_CalcDamage(Nyx, sát thương gốc × hệ số cấp của chiêu + sát thương vũ khí hiện tại, mục tiêu)`

`Xd_CalcDamage` của Tu Tiên 18.1 đã áp dụng hệ số tấn công nhân vật, buff đan dược, perk sát thương và nâng sát thương Achievement (`damagePerk`, `damageUpgrade`). Các hệ số này được áp dụng một lần cho cả phần chiêu lẫn phần vũ khí. Buff hết hạn hoặc đổi vũ khí sẽ được cập nhật ở lần gây sát thương tiếp theo. Khi không cầm vũ khí, phần cộng vũ khí bằng 0.

Quy tắc này áp dụng cho mọi hit của năm chiêu: hiệu ứng gốc của Lĩnh Vực và Hoàng Hà, luồng lửa và hỏa ảnh Tam Diễm, hỏa ảnh và tia Tàn Dạ, kiếm lớn, tia và nổ kiếm nhỏ Trảm Linh. Những hiệu ứng do Nyx tính trực tiếp luôn cộng vũ khí, kể cả khi hit xảy ra sau khi handle của lần cast đã kết thúc.

Lục Mạch dùng món cầm tay để ra lệnh cho kiếm bay: `GetDamage()` của món cầm tay cố ý trả 0 để tránh thêm đòn đánh thường. Với món có `_ttk_attack_command`, các chiêu đọc chỉ số `weapon.damage` hiện tại, bao gồm cường hóa và thay đổi ngọc, thay vì lấy số 0 đó.

| Chiêu | Hệ số cấp ở level 100 |
|---|---:|
| Tuyệt Đối Lĩnh Vực | ×4 |
| Tam Diễm Phiến | ×3,5 |
| Cửu Khúc Hoàng Hà Trận | ×4 |
| Tàn Dạ – Vĩnh Hằng Lĩnh Vực | ×3,5 |
| Huyền Thiên Trảm Linh Kiếm | ×2,5 |

Giữ nguyên các mốc tăng hệ số trước đây. Đây là công thức cho từng lần gây sát thương, không phải tổng sát thương toàn thời gian chiêu. Phần cộng vũ khí không nhân thêm hệ số cấp của chiêu. Quy tắc mục tiêu, PvP, chặn sát thương, phù ma và các hệ số riêng của Tu Tiên vẫn do hàm gốc xử lý; chí mạng và phòng thủ tiếp tục đi qua `GetAttacked`.

## Ghi chú tích hợp

Các hiệu ứng gốc của lĩnh vực, Hoàng Hà Trận và luồng lửa được đánh dấu theo thực thể. Hook cài ở `AddSimPostInit` tìm `inst` dưới dạng tham số local hoặc upvalue của callback Tu Tiên 18.1, qua tối đa 9 tầng caller; hitbox lửa trỏ về emitter qua `inst.owner`. Hook dừng ở callback của hit để không lấy nhầm hiệu ứng đang nằm trong caller bên ngoài. Một guard giữ phần chiêu và vũ khí chỉ được chuẩn bị một lần nếu đường tính trực tiếp và hook lồng nhau; guard được khôi phục cả khi calculator báo lỗi.

Cách này không phụ thuộc tên file hoặc thứ tự các wrapper `GetAttacked`, và không tăng sát thương cho hiệu ứng không được đánh dấu dù chúng dùng chung file nguồn. Nếu bản Tu Tiên khác đổi tên `inst`, callback bị loại khỏi stack bởi tail call hoặc số wrapper vượt phạm vi dò, cần kiểm tra lại tích hợp.

## Kiểm thử

- `lua Nyx_Steam_2026-09-27/tests/skill_damage_test.lua`: năm chiêu, đổi/tháo vũ khí, Lục Mạch, buff đan dược/Achievement thay đổi và hết hạn, các mốc level, hiệu ứng native, callback đóng, wrapper calculator, chống tính hai lần, khôi phục sau lỗi, chiêu đồng thời, nhân vật khác và mục tiêu chặn sát thương.
- `tests/skill_damage_native_test.lua`: tùy chọn đặt `NYX_NATIVE_CALC` tới file chứa định nghĩa `GLOBAL.Xd_CalcDamage` trích từ bản Tu Tiên cài tại máy. Kiểm tra cả công thức gốc với phù ma, trang bị, PvP và chặn sát thương; không đưa mã nguồn mod gốc vào repository.
- Kiểm tra ngày 2026-10-02: 10 bài Nyx chạy qua bằng Lua 5.1; bài sát thương chạy qua thêm bằng LuaJIT 2.1; hai file Lua thay đổi biên dịch cú pháp được bằng Lua 5.1. Fixture cũ dùng alias `table.unpack = unpack` khi chạy trên Lua 5.1. Bài tích hợp calculator gốc được bỏ qua ở lần này vì không có file Tu Tiên gốc tại máy. Chưa kiểm thử trực tiếp trong game.
