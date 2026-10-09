# Tu Tiên là nguồn chỉ số nền

Quy tắc của người dùng: **Tu Tiên số 1; các mod khác chỉ được cộng vào, không được ghi đè phần chỉ số của Tu Tiên.** Áp dụng cho máu, độ no, tinh thần, sát thương và các chỉ số mở rộng của người chơi.

## Thứ tự load

DST sắp xếp `priority` từ lớn xuống nhỏ (mã game `scripts/mods.lua`, hàm `modPrioritySort`). `mod_dependencies` yêu cầu bật mod gốc; dependency không thay thế priority. Bản Tu Tiên đã cài dùng `priority = -10`.

| Thứ tự | Mod | Priority | Version trong repo |
|---|---|---:|---|
| 1 | Tu Tiên gốc, workshop-3721846643 | -10 | Giữ bản gốc |
| 2 | Nyx | -20 | 1.5.12 |
| 3 | Trang Phục Tu Tiên | -30 | 1.0.1 |
| 4 | Công Trình Tu Tiên | -40 | 1.6.4 |
| 5 | Hầm Ngục Tu Tiên | -50 | 1.1.2 |
| 6 | Thành Tựu Tu Tiên | -1000 | 1.3.8 |
| 7 | Thần Khí Tu Tiên | -1100 | 1.2.11 |
| 8 | Tiện Ích Tu Tiên | -1200 | 1.5.19 |
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

Công thức người dùng chốt ngày 2026-10-05: **tổng = chỉ số gốc nhân vật + bonus Perk Thành Tựu + bonus level Thành Tựu + bonus Tu Tiên/Luyện Thể + đan dược + trang bị**. Áp dụng việc giữ đủ nguồn cho máu, đói, tinh thần, tấn công, tốc chạy và phòng thủ. Chỉ số nền Tu Tiên trả về đã chứa gốc nhân vật, nên không cộng gốc lần thứ hai. Bonus phần trăm dùng đúng phép tính của nguồn đó; không coi phần trăm là điểm cộng thẳng. Phạt hồi sinh chỉ giảm trần máu sử dụng được sau khi tổng hợp nguồn, không xóa chỉ số gốc hay bonus.

Các số 288/386 từng được dùng trong trao đổi không phải hằng số bonus Luyện Thể độc lập. Phải đối chiếu với kết quả Tu Tiên trong cấu hình và tiến trình cụ thể.

Test mock của adapter kiểm tra cách giữ/capture bonus và chỉ số hiện tại; nó không chứng minh mã Tu Tiên đóng gói thật đã tính đúng bonus. Mọi báo cáo phải nêu riêng kết quả test Lua, khởi động engine và quan sát trong game. Sau phát hành, cập nhật server và client cùng version rồi tải lại thế giới.

## Kết quả kiểm tra ngày 2026-10-05

- Metadata Lua: version khớp mô tả, priority đúng bảng, dependency Tu Tiên có ở mọi mod server trong repo; Tiện Ích Client giữ chế độ độc lập.
- Ba regression chỉ số đã qua: `levelsystem_tutien_health_test.lua`, `tutien_health_reload_test.lua`, `elixir_progress_test.lua`. Bao gồm capture thay đổi máu từ Tu Tiên, load, bonus linh dược và trang bị không cộng lặp.
- Ba test restriction Hầm Ngục đã qua, gồm trường hợp Tu Tiên bọc `BufferedAction` thành hàm và giữ kiểm tra hợp lệ của constructor cũ.
- DST dedicated engine build 756039 khởi động offline với Tu Tiên 18.1.0 và toàn bộ mod gameplay trong bảng. Engine xác nhận đúng thứ tự Tu Tiên → Nyx → Trang Phục → Công Trình → Hầm Ngục → Thành Tựu → Thần Khí → Tiện Ích.
- Nhân vật Nyx tạo bằng console trong QA có 125 máu ban đầu; cấu hình QA cho 275 sau `SetLevel(46)`, rồi 625 khi cộng Achievement +350; sau 3 giây vẫn 625 và cache Thần Khí cũng là 625. Phép thử này xác nhận cộng bonus trên kết quả Tu Tiên đang cung cấp. Đây là số đo của cấu hình QA đó; không dùng 736 hoặc 386 làm giá trị nền cố định.
- QA dùng thư mục server và thế giới thử nghiệm riêng. Chưa xác nhận tải lại nhân vật trong save của người dùng, client render hay bản Workshop đã phát hành.
- Hotfix Tiện Ích 1.5.14: bỏ gọi `select` trong `modimport` tooltip vì sandbox mod không export hàm này. Regression chạy hook hover/container với `select=nil` đã qua; test tooltip Vạn Linh Phiên cũng đã qua.
- Hotfix Thần Khí 1.2.10: capture thay đổi máu trước/sau native health `OnLoad`, trước khi cập nhật mốc cache. Trace engine của 1.2.9 cho thấy body `OnLoad` tăng 125 → 275 nhưng cache vẫn 125; health `OnLoad` đổi mốc so sánh thành 275, khiến refresh và Achievement dùng nền 125 rồi tổng còn 475. Regression mới tái hiện lỗi này đã qua.
- Engine `engine_body_reload_test.lua` của 1.2.10 qua hai vòng `GetSaveRecord`/`SpawnSaveRecord`: maxhealth 625 → 625 → 625, currenthealth giữ 357, hunger max giữ 275 và sanity max giữ 200. Resource refresh không cộng lặp và Luyện Thể vẫn level 46. Đây là save/load entity thật trong thế giới QA; chưa chạy trực tiếp trên nhân vật trong save của người dùng.
- Hotfix Thành Tựu 1.3.6: lưu Perk toàn cầu vào component thế giới, ghi file cũ khi mua/bật/tắt và giữ bản sao dạng số trong save nhân vật. Thứ tự ưu tiên: save thế giới/thay đổi hiện tại → JSON cũ hợp lệ → dữ liệu nhân vật dự phòng. Không tạo lại file mặc định khi đọc lỗi; client không đọc/ghi dữ liệu toàn cầu. Bảy regression Lua qua; dedicated engine build 747465 qua save nhân vật, save thế giới và restart, kể cả khi JSON QA có trạng thái trái ngược. Chưa phát hành Workshop hoặc xác nhận trên save của người dùng.

## Tổng hợp nguồn chỉ số — bản sửa tiếp theo ngày 2026-10-05

- Thành Tựu 1.3.7: sửa bonus tốc chạy/tấn công Perk thành hệ số `1 + bonus`; cập nhật về 0 gỡ đúng hiệu ứng Perk/level, giữ hệ số Tu Tiên và item. Khi phục hồi sau load, giữ giá trị hiện tại nếu save thiếu trường; bỏ qua nhân vật chết/hồn ma.
- Thần Khí 1.2.11: khi Tu Tiên thay đổi máu nền trực tiếp, tính lại bonus % của trang bị đang đeo ngay trên nền mới, không phải đợi tháo/đeo lại.
- Tiện Ích 1.5.16: dùng lại kết quả tính tấn công từ provider; không đưa tổng đã có bonus đan dược/item qua provider lần thứ hai.
- 26 test Lua liên quan đã qua, gồm composition nguồn, gỡ nguồn về 0, save/load, điểm thuộc tính, elixir, combat preview và bảng chỉ số. Test widget dùng mã `SetHoverText` thật từ DST; test item hook chạy Lua 5.1.
- Engine DST với Tu Tiên gốc đã qua `engine_stat_composition_test.lua` đến `STAT_COMPOSITION_QA_DONE`: đủ các nguồn máu/đói/tinh thần, modifier Perk + level cho tấn công/tốc chạy/def, đan dược, đồ cường hóa và affix; đổi Luyện Thể 46 → 47, đổi điểm, tháo/đeo lại, refresh lặp, hai vòng `GetSaveRecord`/`SpawnSaveRecord`, chết, tải hồn ma và hồi sinh.
- Trong fixture này, tổng HP 1407.675 → 1412.2125 khi tăng Luyện Thể; tháo đồ còn 771.25, đeo lại 1412.2125. Hai lần tải giữ 1412.2125, HP hiện tại 357, đói 91, tinh thần 83 và penalty 0.25. Sau hồi sinh không đeo đồ còn đúng 771.25. Đây là số đo QA, không phải chỉ số mặc định để gán cho nhân vật người dùng.
- Ca chết/hồi sinh dùng `health:Kill()`, sự kiện native `makeplayerghost` và `respawnfromghost` trên entity thật, không chờ animation của client. DST giữ sẵn resurrect health (50 trong QA) khi ở dạng hồn ma; test giữ trạng thái ghost và giá trị native này, không ép health về 0. Hao đói/tinh thần theo thời gian được tắt trong fixture để đối chiếu save chính xác.
- Rà soát độc lập không phát hiện lỗi trong phạm vi sửa; syntax Lua 5.1 và `git diff --check` qua. Chưa phát hành Workshop và chưa xác nhận phiên chơi/client thực tế của người dùng.

## Hotfix host trong game — Thành Tựu 1.3.8

`main_initialize.lua` đã tạo `ShardIndex()` mới nên `GetSlot()` trả nil; nhánh host trong game truyền nil vào `GetPersistentStringInClusterSlot` và crash khi tạo world. Dùng `ShardGameIndex` đang hoạt động và chỉ gọi API cluster khi slot là số nguyên dương. Dedicated, đường legacy hoặc thiếu slot dùng đường persistence hiện tại. Giữ nguyên ưu tiên dữ liệu world/player, không ghi file mặc định khi đọc thiếu/lỗi.

Regression đã tái hiện lỗi trước sửa và qua sau sửa: host cluster, legacy, dedicated, client, thiếu active index, slot nil/sai kiểu/ngoài miền, đồng thời giữ các kiểm tra mua/bật/tắt và phục hồi Perk. Test dedicated trước đây không bao phủ nhánh host trong game gây crash này.

Kiểm tra hotfix: 26 test Lua qua, regression Perk chạy cả Lua 5.1; constructor `ShardIndex` thật từ DST xác nhận slot khởi tạo là nil. Dedicated engine nạp Thành Tựu 1.3.8 và chạy trọn matrix chỉ số đến `STAT_COMPOSITION_QA_DONE`, không có Lua error. Nhánh host trong game được kiểm tra bằng mock API; chưa xác nhận trực tiếp bằng phiên host/client của người dùng, chưa phát hành Workshop.
