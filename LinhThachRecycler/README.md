# Máy Tái Luyện Linh Thạch

Mod Don't Starve Together độc lập, dùng cùng **Tu Tiên** workshop `3721846643`.
Máy nhận tối đa 9 chồng vật phẩm, quy đổi chúng thành số dư và chỉ phát
`xd_lingshi1` khi người chơi bấm **Rút**.

## Cài đặt

1. Chép thư mục `LinhThachRecycler` vào thư mục `mods` của Don't Starve Together.
2. Bật mod Tu Tiên `3721846643` và Máy Tái Luyện Linh Thạch cho cùng thế giới.
3. Chế máy tại Máy Luyện Kim bằng 4 đá cắt, 4 ván, 2 vàng và 1 bánh răng.

## Sử dụng

- Đặt vật phẩm vào 9 ô để xem giá lô và số dư hiện tại.
- Bấm **Luyện hóa** để tiêu hủy các món hợp lệ. Món bị từ chối ở nguyên trong ô.
- Nếu một món trong lô đáng giá từ 5 Hạ Phẩm trở lên, bấm **Xác nhận** lần hai.
- Bấm **Rút** để lấy số Hạ Phẩm nguyên mà túi còn nhận được. Phần 0,5 và phần
  không vừa túi vẫn ở trong máy.

## Kiểm tra nhanh trong game

1. Cho **2 cỏ** vào máy, Luyện hóa và Rút: nhận đúng 1 `xd_lingshi1`.
2. Luyện một món có độ bền đầy và một món cùng loại đã hao: món hao cho ít hơn,
   nhưng không dưới 0,5.
3. Đưa Linh Thạch hoặc túi đang chứa đồ vào: máy báo lý do và không xóa món.
4. Khi túi đầy, bấm Rút: không có Linh Thạch rơi xuống đất và số dư còn nguyên.
5. Để lại vật phẩm cùng số dư 0,5, lưu rồi tải lại thế giới: cả đồ và số dư vẫn còn.
6. Thử đập máy khi còn đồ hoặc số dư: máy không nhận thao tác búa. Lấy hết đồ và
   rút hết số dư rồi mới đập được.

## Ghi chú kỹ thuật

Máy lưu số dư bằng đơn vị nguyên: `1` đơn vị bằng `0,5` Hạ Phẩm. Server tính lại
giá ngay trước khi xóa vật phẩm và chỉ trừ số dư sau khi túi thực sự nhận được
`xd_lingshi1`. Bảng giá nằm ở `scripts/nova_lingshi_pricing.lua` để dễ cân chỉnh.
