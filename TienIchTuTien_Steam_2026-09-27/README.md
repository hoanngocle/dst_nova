# Tiện Ích Tu Tiên 1.5.5 — Thông tin nhân vật

Nhấn **icon hồ sơ bạc–tím** ở góc dưới bên trái HUD, cạnh icon skin và hòm đồ của Nyx. Rê chuột lên icon sẽ hiện tên “Thông tin nhân vật”. Bảng sáng màu, kích thước 680×500, có bốn mục:

- **Tổng quan:** máu hiện tại/tối đa sau phạt hồi sinh, đói, tinh thần, linh lực,
  cấp độ, cảnh giới và tài nguyên riêng được nhân vật cung cấp.
- **Tấn công:** vũ khí đang dùng, sát thương nền sau hệ số, sát thương dự kiến,
  tốc chạy thực tế, khoảng cách đòn tối thiểu, bạo kích và xuyên giáp. Dòng
  **ST bạo kích cộng thêm** gộp các nguồn đang có: +100% gốc và +40% từ linh
  dược hiển thị thành +140%; dòng hệ số khi bạo kích tương ứng là 240%.
- **Phòng thủ:** giáp trang bị, hấp thụ của cơ thể, hệ số sát thương nhận vào,
  né tránh và hiệu ứng phòng thủ của các mod đang bật.
- **Nguồn buff:** từng hệ số đang áp dụng, trang bị/cường hóa/đá thuộc tính,
  kỹ năng đang bật và buff tạm thời. Có thời gian còn lại nếu buff cung cấp bộ đếm.

Mỗi trang có 10 dòng. Rê chuột lên dòng bị rút gọn để xem tooltip gọn, tối đa 5 dòng. Dùng **Trước / Sau** hoặc cuộn chuột để đổi
trang. Dùng **- / +** ở góc trên để thu nhỏ hoặc phóng to bảng; mức zoom được giữ khi mở lại trong phiên chơi. Nhấn **Esc**, nút **×** hoặc bấm ngoài bảng để đóng.

## Dữ liệu và cách đọc

Server gửi số liệu riêng cho người đang xem mỗi 0,5 giây khi bảng mở. Đóng bảng
sẽ ngừng yêu cầu. Dữ liệu quá 3 giây không được hiển thị như số liệu hiện tại.
Hồn ma không hiển thị các chỉ số chiến đấu của người sống.

Cập nhật cả **Thần Khí Tu Tiên 1.2.0** để có phép tính dự kiến cho hiệu ứng trúng
đòn của Thần Khí. Khi thiếu phần này, bảng ghi rõ “ST trước hiệu ứng trúng đòn”.
Bảng vẫn dùng được với nhân vật khác Nyx; chỉ những tài nguyên có component mới
được hiển thị. Client và server đều cần bản Tiện Ích mới; khởi động lại thế giới
sau khi cập nhật mod.

Sát thương dự kiến là sát thương vật lý trước phòng thủ mục tiêu, không phải
cam kết lượng máu mất trên mọi quái. Xuyên giáp hiển thị riêng. Giáp/kháng mục
tiêu, sát thương theo loại hoặc máu mục tiêu, proc ngẫu nhiên, đòn phụ, sát thương
đặc biệt và hiệu ứng Solo gốc không được gộp vào con số này. Hiệu ứng Solo gốc
được liệt kê riêng. Các lớp giảm sát thương có thứ tự và điều kiện khác nhau,
không cộng các tỷ lệ thành một tổng chung. Khoảng cách đòn tối thiểu không phải
DPS thực tế vì còn phụ thuộc hoạt ảnh và kỹ năng.

Nguồn không có tên dịch sẽ giữ mã gốc để vẫn nhận diện được. Các dòng nguồn
là phần giải thích chỉ số đã áp dụng, không phải phần cần cộng lại vào tổng.

## Kiểm tra

Chạy từ thư mục gốc repository:

```powershell
lua TienIchTuTien_Steam_2026-09-27/tests/character_stats_test.lua
lua ThanKhiTuTien_Steam_2026-09-27/tests/attack_preview_test.lua
```

Hai kiểm tra tích hợp RPC/giao diện dùng `json.lua` và `class.lua` từ
`data/databundles/scripts.zip` của bản DST đã cài. Giải nén hai file vào một thư
mục tạm, đặt `DST_TEST_SCRIPTS` tới thư mục chứa chúng rồi chạy:

```powershell
lua TienIchTuTien_Steam_2026-09-27/tests/character_info_rpc_test.lua
lua TienIchTuTien_Steam_2026-09-27/tests/character_info_screen_test.lua
```

Kiểm tra trong game: mở bảng ở host và client; thay/tháo vũ khí; bật/tắt kỹ năng;
chờ buff hết hạn; chuyển trang khi danh sách ngắn lại; chết/hồi sinh; đóng/mở lại
bảng; kiểm tra HUD ở độ phân giải và mức UI scale đang dùng. Kiểm tra tự động
không thay thế bước quan sát bố cục và kết nối thật trong game.
