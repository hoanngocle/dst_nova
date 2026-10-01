# Sát thương 5 chiêu chiến đấu — Nyx 1.4.6

Mỗi lần trúng đích dùng công thức:

`Xd_CalcDamage(Nyx, sát thương gốc × hệ số cấp của chiêu + sát thương vũ khí hiện tại, mục tiêu)`

`Xd_CalcDamage` của Tu Tiên 18.1 đã áp dụng hệ số tấn công nhân vật, buff đan dược, perk sát thương và nâng sát thương Achievement (`damagePerk`, `damageUpgrade`). Các hệ số này được áp dụng một lần cho cả phần chiêu lẫn phần vũ khí. Buff hết hạn hoặc đổi vũ khí sẽ được cập nhật ở lần gây sát thương tiếp theo. Khi không cầm vũ khí, phần cộng vũ khí bằng 0.

| Chiêu | Hệ số cấp ở level 100 |
|---|---:|
| Tuyệt Đối Lĩnh Vực | ×4 |
| Tam Diễm Phiến | ×3,5 |
| Cửu Khúc Hoàng Hà Trận | ×4 |
| Tàn Dạ – Vĩnh Hằng Lĩnh Vực | ×3,5 |
| Huyền Thiên Trảm Linh Kiếm | ×2,5 |

Giữ nguyên các mốc tăng hệ số trước đây. Đây là công thức cho từng lần gây sát thương, không phải tổng sát thương toàn thời gian chiêu. Phần cộng vũ khí không nhân thêm hệ số cấp của chiêu. Quy tắc mục tiêu, PvP, chặn sát thương, phù ma và các hệ số riêng của Tu Tiên vẫn do hàm gốc xử lý; chí mạng và phòng thủ tiếp tục đi qua `GetAttacked`.

## Ghi chú tích hợp

Các hiệu ứng gốc của lĩnh vực, Hoàng Hà Trận và luồng lửa được đánh dấu theo thực thể. Hook cài ở `AddSimPostInit` nhận diện tham số local `inst` của callback Tu Tiên 18.1; hitbox lửa trỏ về emitter qua `inst.owner`. Cách này không phụ thuộc tên file hoặc thứ tự các wrapper `GetAttacked`, và không cộng buff cho những hiệu ứng không được đánh dấu dù chúng dùng chung file nguồn. Nếu bản Tu Tiên khác thay cấu trúc callback, hoặc mod khác bọc `Xd_CalcDamage` làm mất caller này, cần kiểm tra lại tích hợp.

## Kiểm thử

- `lua Nyx_Steam_2026-09-27/tests/skill_damage_test.lua`: năm chiêu, đổi/tháo vũ khí, buff hết hạn, các mốc level, hiệu ứng native, chiêu đồng thời, nhân vật khác và mục tiêu chặn sát thương.
- `tests/skill_damage_native_test.lua`: tùy chọn đặt `NYX_NATIVE_CALC` tới file chứa định nghĩa `GLOBAL.Xd_CalcDamage` trích từ bản Tu Tiên cài tại máy. Kiểm tra cả công thức gốc với phù ma, trang bị, PvP và chặn sát thương; không đưa mã nguồn mod gốc vào repository.
- Đã chạy hai bài trên bằng Lua 5.4 cùng các bài hiện có của Nyx, Tiện Ích và Thần Khí: 19 file kiểm thử thành công. Chưa kiểm thử trực tiếp trong game/DST Lua 5.1.
