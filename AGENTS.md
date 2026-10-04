# Quy tắc mod Tu Tiên

Tu Tiên là mod gốc và là nguồn quyết định chỉ số nền, cảnh giới và tiến trình tu luyện. Các mod trong repo chỉ mở rộng và cộng bonus riêng trên kết quả Tu Tiên đã tính.

- Đọc [quy tắc load và chỉ số](docs/MOD_LOAD_AND_STATS.md) trước khi sửa stat, hook component, save/load hoặc priority.
- Mọi mod phụ phải load sau Tu Tiên (bản hiện tại có `priority = -10`). DST load priority lớn trước. Giữ Thành Tựu trước Thần Khí và bảng Tiện Ích sau cả hai.
- Không thay nền Tu Tiên bằng chỉ số nhân vật ban đầu, cache cũ hoặc tổng đã lưu. Máu, độ no, tinh thần và sát thương phải giữ phần do Tu Tiên cung cấp khi cộng bonus.
- Mỗi mod chỉ thêm, cập nhật hoặc gỡ bonus thuộc sở hữu của nó. Sát thương và các hệ số dùng modifier có key riêng; không gán lại hệ số của Tu Tiên.
- Load không được tự hồi đầy hoặc đổi tiến trình. Giữ chỉ số hiện tại đã lưu, phạt hồi sinh và trạng thái hồn ma. Bonus tính lại phải không cộng lặp.
- Không dùng `xd_dtlevel:SetLevel(1)` để reset hoặc chẩn đoán nhân vật: lệnh này đã làm nhân vật của người dùng chết và không sửa được bonus bị mất.
- Kiểm tra cả tải save, lên cảnh giới, thay/tháo trang bị, thay điểm bonus và chết/hồi sinh. Phân biệt test mock với xác nhận bằng engine/game; không tuyên bố lỗi đã hết chỉ từ mock.
- Khi thay runtime hoặc thứ tự load của một mod, tăng patch version của mod đó và đồng bộ số version trong mô tả. Không sửa bản Tu Tiên gốc để ép nó theo mod phụ.
