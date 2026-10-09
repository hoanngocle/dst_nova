# Kiểm chứng Máy Quay Linh Thạch 1.6.4

Ngày 09/10/2026: chỉ rút nhóm Quái từ 31 xuống 15 gói, tổng từ 149 xuống 133; giữ trọng số nhóm 4,2 (40%).

- Đối chiếu danh mục Lua với bản 1.6.3 trong Git: bốn nhóm khác giống hệt; 15 gói còn lại giữ đúng ID, nội dung, số lượng và trọng số cũ.
- Không còn chó thường/nguyên tố, hải mã, ếch thường/mặt trăng, xúc tu, ong sát thủ, Slurper, Slurtle hoặc Snurtle trong nhóm Quái.
- Test danh mục và giao dịch qua trên Lua 5.1. JSON wiki khớp 133 gói, 15 gói Quái với tỷ lệ 2,6667%/gói/lượt.
- Không chạy lại engine cho thay đổi chỉ loại dữ liệu này; các gói giữ lại thuộc tập đã kiểm tra khởi tạo ở bản 1.6.3 bên dưới.

## Lịch sử kiểm chứng 1.6.3

Ngày 08/10/2026. Bảng chốt: `SLOT_REWARDS_FINAL.md`.

## Source và kiểm thử Lua

- Danh mục 149 gói: Hiếm 24, Khá 21, Thường 30, Boss 43, Quái 31.
- Đã bỏ hai prefab tùy chỉnh cũ `nhatvuphuonghoa`, `thanhiquangtruong`; không thay bằng pháp bảo gốc. Giữ vật phẩm còn lại của hai gói.
- Lua 5.1: kiểm tra cú pháp các file runtime thay đổi; kiểm thử chọn gói, lọc prefab thiếu, số lượng, rollback toàn gói.
- Kiểm thử biên nhận: thiếu tiền, máy bận, hoàn tiền đúng một lần, lỗi tạo thưởng, callback lặp, callback ngoài bị lỗi và rollback tuần lộc Klaus.
- Test hiện hữu: `thien_nghich_chau_test.lua` dùng Lua 5.4+ theo yêu cầu của test; `test_fsct.py` dùng thành phần Hauntable từ source DST.
- Review độc lập: hai lỗi callback lặp và tuần lộc Klaus đã sửa, bổ sung regression test; lượt review lại không còn phát hiện đáng kể.

## Engine DST thực

Engine bản 756039, Tu Tiên 18.1.0, Solo 2.2.7, Nyx và Thần Khí từ bộ mod hiện có; Công Trình dùng source 1.6.3 trong worktree. Chạy server offline trong cluster QA riêng, không dùng save người chơi.

- `SLOT_REGISTRY 0`: không còn prefab thiếu trong bảng chốt khi bật đủ mod.
- `SLOT_SPAWN_DONE 149`: cả 149 gói được tạo và cấu hình trong engine trên đất; mỗi gói được dọn sau lượt kiểm tra ngắn. Bao gồm Twins, Klaus, Antlion và các biến thể treasure Solo.
- Trader thật: 59 Hạ Phẩm bị từ chối; đưa 61 thì thu đúng 60 và giữ lại 1; máy bận từ chối thêm giao dịch.
- Stategraph gốc: hoạt ảnh kết thúc gọi trả thưởng đúng một lần; callback lặp không trả lại. Entity QA tắt ngủ vì không có client đăng nhập đứng cạnh.
- `GetSaveRecord` khi đang quay rồi `SpawnSaveRecord`: component được khôi phục, hoàn đúng 60 Hạ Phẩm cạnh máy, xóa biên nhận. `SLOT_LOAD_REFUND true`.
- Kết quả lượt cuối: `SLOT_QA_DONE PASS`. Probe có thể chạy lại từ `CongTrinhTuTien_Steam_2026-09-27/tests/engine_slot_rewards_test.lua` trong mod QA cuối thứ tự load.

## Wiki

- `npm run build`: thành công, gồm route `/duyet/may-quay-linh-thach/ban-cuoi`.
- HTTP 200 tại preview 3001: 5 bảng, đúng 149 hàng thưởng. Có bản Markdown tải xuống.

## Phạm vi chưa xác nhận

Chưa chơi trọn trận chiến của từng Boss với client, chưa kiểm tra mọi địa hình/cấu hình mod, và chưa khởi động lại toàn server từ save ghi xuống đĩa. Round-trip bản ghi entity và kiểm tra khởi tạo engine ở trên không được coi là đã kiểm chứng các trường hợp này.
