# Xưởng Truyện AI — chạy local

Ứng dụng một người dùng, một truyện, giữ bố cục ba cột của bản Canvas. Không cần Firebase, PostgreSQL, npm install hay build. Cần Node.js 22.13+ (máy hiện tại đã có Node 26).

## Chạy

Trong thư mục chứa `story.html`, chạy PowerShell:

```powershell
Copy-Item .env.example .env
notepad .env
node story-server.mjs
```

Chỉ sao chép `.env.example` lần đầu; không ghi đè `.env` đã có key. Điền `GEMINI_API_KEY` trong `.env`. Có thể đổi `GEMINI_MODEL` sang model tài khoản của bạn hỗ trợ. Khởi động lại server sau khi sửa `.env`.

Mở http://127.0.0.1:8766/story.html. Có thể dùng `./start-story.ps1` thay lệnh Node (nếu chính sách PowerShell cho phép). Không mở trực tiếp bằng `file://` và không dùng Python HTTP server vì ứng dụng cần API local. Nhấn Ctrl+C tại terminal để dừng.

Không có key vẫn mở giao diện, chỉnh/lưu cấu hình và đọc các chương đã lưu. Tạo chương cần key hợp lệ, mạng và quota Gemini. Không dán key vào HTML hoặc chat.

## Dữ liệu và sao lưu

- Truyện, cấu hình, tốc độ và vị trí đọc nằm trong `.story-data/story.json`, không phụ thuộc cache trình duyệt.
- Ghi file tuần tự và thay thế bằng rename sau khi ghi xong; file hỏng khiến server từ chối khởi động, không tự xóa dữ liệu.
- Dùng nút **Sao lưu JSON** để tải bản sao. Khôi phục: dừng server, giữ bản sao file hiện tại, đặt bản sao lưu hợp lệ vào `.story-data/story.json`, rồi chạy lại.
- Chỉ chạy một server và chỉnh sửa trong một tab cho cùng thư mục dữ liệu. Khi chuyển sang tab khác, tải lại trang để lấy bản mới.
- Chưa chuyển dữ liệu cũ từ Firebase/Canvas vì file HTML không chứa dữ liệu truyện trên đó.
- `.env` và `.story-data` được bỏ qua bởi Git; server chỉ phục vụ các file giao diện đã chỉ định.

## Hoạt động

- Giao diện/CSS/JavaScript đều local, không dùng CDN hoặc Google Fonts.
- Mỗi lần tạo gửi bối cảnh, góp ý và tối đa ba chương gần nhất tới Gemini. Server yêu cầu JSON có `title` và `content`, chỉ lưu phản hồi hoàn chỉnh.
- Prompt yêu cầu khoảng 2.500 từ/chương. Chương dưới 1.500 từ được yêu cầu viết lại tối đa 2 lần (tổng 3 lượt gọi Gemini). Nếu vẫn thiếu, báo lỗi, chưa lưu chương và dừng tự động tạo. Từ 1.500 từ trở lên được lưu nếu phản hồi hoàn chỉnh, JSON hợp lệ và có tiêu đề/nội dung; không giới hạn số từ tối đa. Giao diện hiển thị số từ thực tế, đếm theo khoảng trắng và không tính tiêu đề.
- Prompt yêu cầu văn xuôi chia đoạn, ngăn bằng dòng trống và mỗi lượt thoại ở một đoạn riêng. Khung đọc tách các dòng thành đoạn; với khối văn bản dài hơn 600 ký tự, tự nhóm các câu hoàn chỉnh thành đoạn ngắn để dễ đọc, kể cả chương cũ thiếu xuống dòng. Không cắt giữa câu, không sửa câu chữ trong dữ liệu lưu; vị trí tô sáng/đọc vẫn dựa trên nội dung gốc.
- Tự động tạo đợi chương trước hoàn tất rồi nghỉ 10 giây. Dừng khi gặp lỗi; tắt công tắc ngăn chương tiếp theo, chương đang tạo vẫn được lưu nếu thành công.
- Đọc bằng Speech Synthesis của trình duyệt, chia đoạn ngắn, giữ vị trí khi tạm dừng/đổi tốc độ. Cần cài giọng tiếng Việt local để đọc offline; tùy giọng của trình duyệt, việc đọc có thể dùng dịch vụ mạng. Không dùng Gemini TTS.
- Server chỉ lắng nghe `127.0.0.1`. Đây là ứng dụng local một người dùng, chưa thiết kế để mở ra LAN/Internet.

## Kiểm tra

```powershell
node --test --test-isolation=none story-server.test.mjs story-audio.test.mjs story-text.test.mjs
```

Test dùng thư mục tạm và giả lập riêng phản hồi mạng Gemini; không gọi API tính phí và không đụng dữ liệu truyện thật.
