# Máy Tái Luyện Linh Thạch

## Mục tiêu và phạm vi

Tạo một mod Don't Starve Together độc lập, dùng cùng mod Tu Tiên `3721846643`. Người chơi chế một máy để tiêu hủy vật liệu, trang bị và vật phẩm hiếm dư thừa, tích giá trị trong máy, rồi chủ động rút **Hạ Phẩm Linh Thạch** (`xd_lingshi1`) vào túi. Dọn kho là mục tiêu chính; thu gom vật liệu để kiếm thêm Linh Thạch là mục tiêu phụ. Người dùng chơi một mình, nên số dư thuộc về máy, không chia theo người chơi.

Mod không thay đổi Tu Tiên gốc hoặc bản Achievement local. Cấu trúc và tên prefab của máy nằm trong mod riêng, để sau này có thể chuyển phần tích hợp sang mod khác. Máy không ghép Linh Thạch lên các bậc cao vì trò chơi đã có cơ chế đó.

## Luồng chơi

1. Người chơi chế **Máy Tái Luyện** tại Máy Luyện Kim bằng 4 đá cắt, 4 ván, 2 vàng và 1 bánh răng, rồi đặt trong thế giới.
2. Máy có chín ô đầu vào. Người chơi đưa vật phẩm hoặc cả chồng vật phẩm vào các ô. Giao diện hiển thị giá trị dự kiến bằng đơn vị Hạ Phẩm và số dư hiện có. Vật phẩm chưa bị tiêu hủy khi chỉ đặt vào ô.
3. Bấm **Luyện hóa** để máy tiêu hủy các vật phẩm hợp lệ và cộng giá trị vào số dư. Món bị từ chối ở nguyên trong ô và được báo lý do. Nếu lô chứa món có giá trị từ 5 Hạ Phẩm trở lên, giao diện yêu cầu xác nhận thêm một lần trước khi tiêu hủy cả lô.
4. Bấm **Rút** để chuyển số viên Hạ Phẩm nguyên lớn nhất mà túi người chơi còn chứa được vào túi. Phần lẻ và phần chưa rút vẫn ở máy. Ví dụ: số dư 2,5 cho rút 2 viên và giữ lại 0,5.

Máy không cần nhiên liệu hay thời gian chờ sau khi đã chế. Nếu máy còn vật phẩm trong ô hoặc còn số dư, không thể đập dỡ máy; máy không cháy. Sau khi lấy hết đồ và rút hết số dư nguyên, số dư 0,5 vẫn ngăn đập dỡ để tránh mất giá trị. Người chơi có thể nạp thêm một món để rút hết.

## Định giá

Máy dùng **đơn vị nguyên nửa viên** trong mã và file lưu: `1` đơn vị bằng `0,5` Hạ Phẩm. Cách này tránh sai số số thực. Mỗi vật phẩm hợp lệ có giá trị tối thiểu `1` đơn vị. Chồng đồ nhân giá trị mỗi món với số lượng; máy không đánh giá cả chồng như một món.

Một bảng giá theo prefab xác định giá trị của những món phổ biến và món hiếm. Giá khởi điểm:

| Nhóm | Giá mỗi món |
| --- | ---: |
| Vật liệu tái tạo rất phổ biến, như cỏ, cành, đá | 0,5 Hạ Phẩm |
| Vật liệu và chiến lợi phẩm thông dụng, như gỗ, vàng | 1 Hạ Phẩm |
| Vật liệu khó kiếm, như bánh răng và đá quý thông thường | 2–3 Hạ Phẩm theo prefab |
| Vật phẩm hiếm và chiến lợi phẩm boss | 5–20 Hạ Phẩm theo prefab |

Vật phẩm hợp lệ chưa có trong bảng giá vẫn nhận giá mặc định `0,5`. Danh sách ngoại lệ cho vật phẩm hiếm của Tu Tiên được định giá tường minh; không đoán độ hiếm qua tên hoặc công thức. Trang bị có độ bền được nhân theo tỷ lệ độ bền còn lại, làm tròn xuống đơn vị nửa viên, nhưng không thấp hơn `0,5`. Với đồ chế tạo, so sánh tổng giá **toàn bộ sản phẩm của một lần chế** với tổng giá nguyên liệu. Nếu mức tối thiểu `0,5` cho mỗi sản phẩm làm đầu ra có giá cao hơn đầu vào, máy từ chối prefab đó. Bảng giá và danh sách từ chối nằm ở một mô-đun riêng để có thể chỉnh mà không sửa logic máy.

Máy từ chối mọi cấp Linh Thạch, chính máy này, túi hoặc vật phẩm chứa đồ khi còn đồ bên trong, các vật phẩm nhiệm vụ trong danh sách bảo vệ tường minh, và các sản phẩm chế tạo gây lãi theo quy tắc trên. Vật phẩm có giá trị đặc biệt chưa được định giá rõ vẫn có thể nhận theo giá mặc định, trừ khi thuộc nhóm bị từ chối trên. Giao diện hiển thị giá trước khi xác nhận để người chơi không vô tình đổi món quý lấy `0,5`.

## Cấu trúc mod và dữ liệu

- Prefab máy quản lý chín ô, số dư và thao tác tương tác. Máy xử lý tiêu hủy, cộng số dư và phát `xd_lingshi1` trên server để tránh nhân đôi vật phẩm.
- Mô-đun bảng giá nhận prefab, số lượng và trạng thái độ bền, rồi trả giá bằng đơn vị nửa viên hoặc lý do từ chối. Giao diện chỉ dùng kết quả này để xem trước; server luôn tính lại khi luyện hóa.
- Giao diện máy hiển thị giá trị lô, số dư, lý do từ chối và hai nút **Luyện hóa**/**Rút**. Tiêu hủy chỉ diễn ra khi người chơi bấm nút xác nhận cuối cùng.
- Dữ liệu lưu gồm số dư nguyên và vật phẩm còn trong ô. Sau khi tải lại thế giới, cả hai phải khôi phục nguyên vẹn.
- Mod khai báo phụ thuộc Tu Tiên. Nếu thiếu prefab `xd_lingshi1`, máy không tiêu hủy đầu vào và báo không thể rút; không tạo vật phẩm thay thế.

## Kiểm tra chấp nhận

- Hai cỏ giá `0,5` mỗi món tạo số dư `1`; rút được đúng một `xd_lingshi1`.
- Một chồng vật phẩm cộng đúng theo số lượng; nạp nhiều lô rồi rút không mất phần `0,5`.
- Trang bị đã hao độ bền cho ít hơn trang bị mới nhưng không dưới `0,5`.
- Vật phẩm hiếm hiển thị đúng giá và cần xác nhận thêm; Linh Thạch và túi còn đồ bị từ chối mà không mất vật phẩm.
- Túi đầy khiến số viên chưa nhận ở lại máy; lưu và tải thế giới giữ nguyên số dư và đồ trong ô.
- Chế đồ rồi tái luyện không tạo lợi nhuận Linh Thạch từ các công thức đã định giá; thao tác lặp và rút đồng thời không nhân đôi vật phẩm.

## Giới hạn bản đầu

Không tự ghép Linh Thạch bậc cao, không có tài khoản số dư riêng cho nhiều người chơi, không tự hút đồ gần máy và không tạo Linh Thạch khi người chơi chưa bấm **Rút**.
