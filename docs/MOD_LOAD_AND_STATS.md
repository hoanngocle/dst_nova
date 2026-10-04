# Tu Tiên là nguồn chỉ số nền

Quy tắc của người dùng: **Tu Tiên số 1; các mod khác chỉ được cộng vào, không được ghi đè phần chỉ số của Tu Tiên.** Áp dụng cho máu, độ no, tinh thần, sát thương và các chỉ số mở rộng của người chơi.

## Thứ tự load

DST sắp xếp `priority` từ lớn xuống nhỏ (mã game `scripts/mods.lua`, hàm `modPrioritySort`). `mod_dependencies` yêu cầu bật mod gốc; dependency không thay thế priority. Bản Tu Tiên đã cài dùng `priority = -10`.

| Thứ tự | Mod | Priority | Version trong repo |
|---|---|---:|---|
| 1 | Tu Tiên gốc, workshop-3721846643 | -10 | Giữ bản gốc |
| 2 | Nyx | -20 | 1.5.5 |
| 3 | Trang Phục Tu Tiên | -30 | 1.0.1 |
| 4 | Công Trình Tu Tiên | -40 | 1.6.2 |
| 5 | Hầm Ngục Tu Tiên | -50 | 1.1.2 |
| 6 | Thành Tựu Tu Tiên | -1000 | 1.3.5 |
| 7 | Thần Khí Tu Tiên | -1100 | 1.2.9 |
| 8 | Tiện Ích Tu Tiên | -1200 | 1.5.14 |
| 9 | Tiện Ích Client | -1300 | 1.0.6 |

Các thư viện và bản Việt Hóa ngoài repo dùng yêu cầu của mod gốc. Tiện Ích Client chỉ hoạt động phía client, không yêu cầu Tu Tiên để dùng độc lập và không sửa chỉ số server. Nyx vốn đã load sau Tu Tiên nên không tăng version trong thay đổi này.

Thành Tựu phải load trước Thần Khí để wrapper sát thương của Thần Khí tính trên đầu vào trước bạo kích. Tiện Ích đọc chỉ số cuối từ server sau các mod gameplay. Thứ tự này áp dụng cho đăng ký hook; callback load của từng component vẫn cần xử lý đúng vì engine không bảo đảm thứ tự component.

Hook phải giữ wrapper của Tu Tiên. Ví dụ `BufferedAction` có thể đã được Tu Tiên bọc thành hàm constructor; Hầm Ngục phải gọi tiếp constructor này rồi thêm kiểm tra của mình vào instance, thay vì giả định global luôn là class hoặc nạp lại class gốc.

## Cách cộng chỉ số

1. Tu Tiên tính nền từ nhân vật, cảnh giới, Luyện Thể và hiệu ứng của nó.
2. Thành Tựu chỉ cộng phần chênh lệch giữa bonus mới và bonus đã áp dụng. Không thay nền bằng máu/đói/tinh thần khởi đầu.
3. Thần Khí cộng linh dược và trang bị trên nền hiện có. Khi Tu Tiên thay `maxhealth` trực tiếp, phải ghi nhận thay đổi trước khi tính lại cache máu gốc.
4. Sát thương giữ `combat.damagemultiplier` của Tu Tiên; bonus mod phụ dùng modifier hoặc phép cộng trên sát thương game đã tính. Mỗi nguồn có key riêng, gỡ nguồn nào chỉ gỡ key của nguồn đó.
5. Tiện Ích đọc số liệu đã áp dụng, không tự đặt lại chỉ số khi mở bảng.

`SetMaxHealth`/`SetMax` chỉ được gọi với kết quả gồm nền Tu Tiên hiện tại và bonus mod đang quản lý. Không dùng một tổng cache cũ để thay kết quả mới của Tu Tiên. Không cộng bonus lần nữa khi thay trang bị hoặc gọi lại cùng cảnh giới.

Gỡ bonus của mod phụ có thể giảm tổng tương ứng. Tiêu hao tài nguyên, sát thương nhận vào, thay cảnh giới hợp lệ và phạt hồi sinh vẫn do game/Tu Tiên quản lý; không đặt một mức sàn cố định làm vô hiệu các cơ chế đó. Nhân vật được khởi tạo chỉ số gốc khi tạo mới, không khởi tạo lại để sửa load.

## Save/load và kiểm tra

- Lưu tiến trình và bonus riêng của mod; không lấy tổng đã cộng bonus làm nền mới rồi cộng lại sau load.
- Sau callback load, khôi phục bonus qua cơ chế của Tu Tiên và ghi nhận nền mới trước các lần refresh của mod phụ.
- Giữ máu, đói và tinh thần hiện tại đã lưu; giới hạn theo max hợp lệ và phạt hiện có. Không hồi đầy hoặc hồi sinh khi tính bonus.
- Không reset Luyện Thể về cấp 1 để sửa stat. Thao tác này đã gây chết nhân vật và làm tiến trình hiển thị sai trong lần thử thực tế.
- So sánh trước/sau tải lại, lên cảnh giới, mua/gỡ điểm, thay/tháo trang bị và chết/hồi sinh. Kiểm tra cả có/không có Achievement, linh dược, bonus phần trăm và bonus cộng thẳng.

Mốc người dùng đã xác nhận: nhân vật gốc 125 máu, Nguyên Vũ tầng 1 (Luyện Thể level 46) cho 386 máu khi không có bonus khác. Với Achievement +350, tổng cần là **736**, trước các bonus/phạt khác. 475 chỉ gồm 125 + 350 và còn thiếu phần Luyện Thể.

Test mock của adapter kiểm tra cách giữ/capture bonus và chỉ số hiện tại; nó không chứng minh mã Tu Tiên đóng gói thật đã tính đúng bonus. Mọi báo cáo phải nêu riêng kết quả test Lua, khởi động engine và quan sát trong game. Sau phát hành, cập nhật server và client cùng version rồi tải lại thế giới.

## Kết quả kiểm tra ngày 2026-10-05

- Metadata Lua: version khớp mô tả, priority đúng bảng, dependency Tu Tiên có ở mọi mod server trong repo; Tiện Ích Client giữ chế độ độc lập.
- Ba regression chỉ số đã qua: `levelsystem_tutien_health_test.lua`, `tutien_health_reload_test.lua`, `elixir_progress_test.lua`. Bao gồm capture thay đổi máu từ Tu Tiên, load, bonus linh dược và trang bị không cộng lặp.
- Ba test restriction Hầm Ngục đã qua, gồm trường hợp Tu Tiên bọc `BufferedAction` thành hàm và giữ kiểm tra hợp lệ của constructor cũ.
- DST dedicated engine build 756039 khởi động offline với Tu Tiên 18.1.0 và toàn bộ mod gameplay trong bảng. Engine xác nhận đúng thứ tự Tu Tiên → Nyx → Trang Phục → Công Trình → Hầm Ngục → Thành Tựu → Thần Khí → Tiện Ích.
- Nhân vật Nyx tạo bằng console trong QA có 125 máu ban đầu; cấu hình QA cho 275 sau `SetLevel(46)`, rồi 625 khi cộng Achievement +350; sau 3 giây vẫn 625 và cache Thần Khí cũng là 625. Phép thử này xác nhận cộng bonus trên kết quả Tu Tiên đang cung cấp. Mốc 736 của người dùng phụ thuộc nền 386 đã quan sát trong cấu hình của họ.
- QA dùng thư mục server và thế giới thử nghiệm riêng. Chưa xác nhận tải lại nhân vật trong save của người dùng, client render hay bản Workshop đã phát hành.
- Hotfix Tiện Ích 1.5.14: bỏ gọi `select` trong `modimport` tooltip vì sandbox mod không export hàm này. Regression chạy hook hover/container với `select=nil` đã qua; test tooltip Vạn Linh Phiên cũng đã qua.
