# Kế hoạch sửa cảnh báo animation và Storage Multi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sửa xung đột hình ảnh Igris; tái hiện và sửa đúng nguồn cảnh báo animation/Storage Multi, bảo toàn save, Scrapbook và gameplay.

**Architecture:** Tách thành ba nhánh kiểm chứng. Igris sửa trực tiếp trong Hầm Ngục vì đã xác nhận xung đột asset. Animation diện rộng và Storage Multi phải qua thử nghiệm đối chứng và trace trong mod QA trước khi quyết định file production cần sửa; không mặc định chúng là lỗi Hầm Ngục.

**Tech Stack:** DST build 747465, Lua, Python zipfile/struct, client có renderer, mod QA cục bộ trên bản sao world.

**Spec:** Yêu cầu người dùng ngày 2026-10-01: lập kế hoạch xử lý cảnh báo thiếu animation/trùng build Igris và sáu dòng `Unsupported Storage Multi key` trong lượt Hầm Ngục đã hoàn thành. Tài liệu này ghi cả bằng chứng và thiết kế sửa; chưa triển khai.

## Phạm vi và ràng buộc

- Không thay độ khó, máu, sát thương, loot, hồi chiêu hoặc luật chơi.
- Không ghi đè save đang chơi; QA dùng bản sao riêng, đồng thời sao lưu profile/Scrapbook trước thử nghiệm có đồng bộ tài khoản.
- Không xóa dữ liệu Scrapbook, không vô hiệu hóa đồng bộ và không chặn log để coi là đã sửa.
- Không sửa trực tiếp bản Workshop đang cài: nếu xác nhận lỗi mod bên ngoài, tạo bản vá nguồn riêng có phiên bản và cách khôi phục.
- Không tái chạy worldgen diện rộng cho sửa asset/client khi không có thay đổi worldgen.
- Các sửa Thành Tựu và di chuyển tài liệu NOVA đang có trong workspace thuộc công việc khác; không đưa vào commit sửa lỗi này.

## Bằng chứng đã kiểm tra

Nguồn: `C:/Users/NYX/Documents/Klei/DoNotStarveTogether/client_log.txt` và `client_chat_log.txt`, phiên kết thúc sáng 2026-10-01. Mốc thời gian bên dưới là thời gian tương đối trong log.

| Nhóm | Bằng chứng | Kết luận hiện tại |
|---|---|---|
| Igris | Dòng 2623, 00:16:22: build `lavaarena_boarrior_basic` trùng khi tải `HamNgucTuTien/anim/igris_dungeon.zip` | Xung đột đã xác nhận |
| Asset Igris | So sánh ZIP với `data/anim/lavaarena_boarrior_basic.zip`: `anim.bin` và `build.bin` bằng nhau từng byte, `atlas-0.tex` khác | Texture custom đang dùng lại định danh build gốc; không được bỏ custom ZIP và mất texture |
| Animation | 1.355 dòng `Could not find anim`, 248 cặp animation/bank khác nhau; có cây/cỏ/tường/vật phẩm, bắt đầu từ 00:17:36 trước làn đầu 00:18:23 | Chưa xác định nguồn; không phải chỉ xảy ra lúc đánh boss |
| Shadow Shade | Mod `3794362938` đang bật. `main/factory.lua:125` và `:565` sao chép build, bank hash, animation hash từ source sang bóng | Nghi phạm cho cảnh báo diện rộng; chưa có trace/A-B nên chưa kết luận |
| Storage | Dòng 6486–6491 lúc 00:23:34: `145B6D63`, `4A06BBE3`, `509152B3`, `724DBE03`, `ACCAC333`, `DAB0C283` | Engine phát lỗi, không có Lua stack trace kèm theo |
| Đường đồng bộ | `scripts/scrapbookpartitions.lua:445–470` đóng gói `SCRAPBOOK0..15` rồi gọi `TheInventory:SetStorageValueMulti(bigbucketdata)` | Đường gọi Scrapbook là ứng viên cụ thể; chưa chứng minh chính lời gọi này sinh sáu lỗi |
| Bucket | Scrapbook dùng `bit.band(hash, 0xF)`; cả sáu mã đều tận cùng `3` | Cùng bucket 3 nếu là hash entry Scrapbook; cần giải mã bằng `hash()` của engine, không đoán tên prefab |
| Kết thúc lượt | Chat: bốn làn thường, boss lúc 00:21:35; game serialize world/player trước khi thoát, không thấy Lua error/stack trace | Không chứng minh được mất save, cũng chưa đủ để xác nhận dữ liệu backend không bị ảnh hưởng |

Các cảnh báo `FROMNUM` (atlas/bank/sound) được gom vào trace animation nếu tái hiện cùng luồng; không tự coi đó là tên asset thật để tạo file bổ sung.

## Review Focus

1. Tải Igris trước hoặc sau Boarrior gốc phải ra đúng texture, không phụ thuộc thứ tự asset — kiểm tra ở Task 2.
2. Xác Igris và Igris sau save/load phải dùng build custom giống boss sống — Task 2.
3. Bóng của entity đổi bank/animation, ngủ/dậy, bị xóa hoặc spawn liên tục không dùng trạng thái của entity khác — Task 3.
4. Mod không bật hoặc API client thiếu phải hoạt động bình thường, dedicated server không chạy logic bóng — Task 3.
5. Scrapbook online/offline, giá trị unknown và load dữ liệu cũ không bị xóa hoặc gửi sai cấu trúc — Task 4.

## Task 1: Giữ bằng chứng và tái hiện có đối chứng

**Files dự kiến tạo:**
- `HamNgucTuTien/tests/qa/log_warning_probe/modinfo.lua`
- `HamNgucTuTien/tests/qa/log_warning_probe/modmain.lua`
- `HamNgucTuTien/tests/qa/log_warning_probe/scripts/hn_log_probe.lua`
- `HamNgucTuTien/tests/analyze_runtime_log.py`
- `docs/superpowers/reports/2026-10-01-dungeon-log-warnings.md`

**Interfaces:** Mod QA chỉ chạy khi bật riêng. `AnalyzeLog(path)` xuất số lượng theo cặp animation/bank, build collision và storage key, cùng mốc thời gian; không đưa chat cá nhân/token vào báo cáo. Trace có giới hạn theo cặp lỗi/đối tượng, không in mỗi frame.

- [ ] Chụp bản sao log và danh sách phiên bản/config mod trước khi log bị phiên mới ghi đè; ghi SHA-256, lưu log thô trong thư mục QA local bị ignore.
- [ ] Viết test parser bằng đoạn log có hai cảnh báo giống nhau, một build collision và sáu storage key; assert đếm đủ, phân nhóm riêng, không tính dòng đăng ký prefab là lỗi.
- [ ] Chạy test parser, triển khai parser tối thiểu, chạy lại đạt.
- [ ] Tạo bản sao world/profile QA, ghi rõ mod set và hành động mỗi lần chạy. Không thử trên world chính.
- [ ] Chạy cùng đường đi gần cây/cỏ/tường, mở/đóng UI vật phẩm, nhặt đồ, vào hầm, kết thúc, save/reload với full stack hiện tại để có baseline.
- [ ] Lặp lại trên bản sao cùng mốc save với Shadow Shade Pack tắt. Nếu cảnh báo vẫn còn, thử tiếp tắt riêng Too Many Items Rearranged; không đổi nhiều mod cùng lúc để suy kết luận.
- [ ] Storage thử trước tiên bằng trace trên full stack; chỉ thử đối chứng Don't Starve Alone nếu trace dẫn vào hệ lưu/shard. Dùng world QA tương thích cấu hình, không tùy tiện đổi kiểu host trên save gốc.
- [ ] Ghi bằng chứng đường gọi, sự khác biệt và giới hạn tái hiện. Commit công cụ QA và báo cáo, không đóng mod QA vào gói cài chơi.

## Task 2: Sửa xung đột build Igris

**Files:**
- Modify: `HamNgucTuTien/anim/igris_dungeon.zip`
- Modify: `HamNgucTuTien/scripts/hn_dungeon/boss_defs.lua`
- Modify: `HamNgucTuTien/scripts/prefabs/hn_corpses.lua`
- Extend: `HamNgucTuTien/tests/check_dependencies.py`
- Create: `HamNgucTuTien/tests/igris_assets_test.py`
- Update provenance: `HamNgucTuTien/SOURCE_MANIFEST.json` bằng metadata adaptation riêng; giữ hash nguồn gốc.

**Interfaces:** Build custom mới `hn_igris_build`; bank animation vẫn `boarrior`. Prefab `hn_igris` và `hn_corpse_igris` giữ nguyên ID; không chuyển đổi save schema.

- [ ] Viết test asset contract: đọc trường tên trong BILD; build custom phải khác vanilla, texture custom giữ nguyên SHA-256, cấu trúc BILD còn đọc được. Assert cả boss và corpse tham chiếu build mới, có dependency asset cần thiết khi spawn độc lập.
- [ ] Chạy `python HamNgucTuTien/tests/igris_assets_test.py`: bản hiện tại phải fail vì build trùng.
- [ ] Đổi trường tên build trong `build.bin` bằng parser đúng cấu trúc/độ dài; không replace tùy tiện chuỗi trong binary. Giữ texture. Vì `anim.bin` custom bằng vanilla từng byte, dùng animation từ ZIP gốc và bỏ bản trùng trong gói custom nếu engine xác nhận ZIP chỉ chứa build/texture tải được.
- [ ] Cập nhật `SetBuild("hn_igris_build")` cho boss và corpse; khai báo asset cho corpse để không phụ thuộc boss đã từng spawn. Điều chỉnh checker namespace để xác minh build thực có trong ZIP thay vì báo lỗi mọi build `hn_`.
- [ ] Chạy test asset, dependency checker và `lua HamNgucTuTien/tests/run.lua all`.
- [ ] Trong client có renderer, spawn riêng corpse, spawn Igris/Boarrior theo cả hai thứ tự, xem chiêu và animation chết, save/reload. PASS khi đúng texture, không mất symbol và không còn dòng trùng build. Dedicated headless không thay thế bước nhìn hình.
- [ ] Commit riêng sửa Igris.

## Task 3: Sửa nguồn animation diện rộng sau khi trace xác nhận

**Reference ngoài repo:** `C:/Program Files (x86)/Steam/steamapps/workshop/content/322330/3794362938/main/factory.lua`, `SyncShadowAnimationFromSource(shadow, source)` và `CopySourceVisualToShadow(source, shadow)`.

**Files:** Tiếp tục probe ở Task 1. Nếu xác nhận Shadow Shade là nguồn, tạo bản nguồn local `ShadowShadePack_Local/` có ghi phiên bản upstream, sửa `main/factory.lua`, thêm `tests/animation_sync_test.lua`. Nếu không xác nhận, dừng nhánh sửa Shadow Shade và ghi đường gọi thực tế cùng file đích vào plan trước khi code production.

**Interfaces:** Giữ hai signature upstream. Chỉ bóng nhận cập nhật; tuyệt đối không sửa animation entity nguồn hoặc hook toàn cục để nuốt cảnh báo.

- [ ] Probe ghi prefab/GUID nguồn và bóng, bank hash, animation hash, trạng thái đổi bank tại hai hàm trên; đối chiếu với cặp cảnh báo engine. Kiểm tra tình huống lệch trạng thái trong cùng frame và việc API nhận hash số có đúng ở build hiện tại không.
- [ ] Dùng fixture tái hiện đúng lỗi đã quan sát: entity đổi bank, source mất hiệu lực, bóng được tái tạo và hai source cập nhật xen kẽ. Test phải bắt lỗi trước khi sửa; không coi A/B giảm log một mình là đủ để chọn dòng code.
- [ ] Sửa việc lấy và áp dụng trạng thái tại nguồn gây lỗi theo trace: snapshot nhất quán, cập nhật bank/build trước animation, bỏ qua trạng thái chưa hợp lệ. Chỉ dùng phép kiểm tra animation tồn tại nếu đã xác minh API đó không tự phát cảnh báo; không thử hàng loạt animation để dò.
- [ ] Assert entity nguồn không bị thay đổi; bóng tiếp tục cập nhật đúng sau khi source có trạng thái hợp lệ; config tắt và dedicated không kích hoạt code mới.
- [ ] Lặp đường đi và hành động baseline, kiểm tra hình bóng thật và đếm log. Nếu còn cảnh báo, phân nhóm nguồn riêng, không ép về 0 bằng lọc log.
- [ ] Commit riêng bản vá đã có bằng chứng; nếu lỗi chỉ tái hiện ở mod khác, báo nguồn và sửa đúng mod đó với cùng tiêu chí.

## Task 4: Xác định và sửa Storage Multi, giữ dữ liệu

**Reference:** `scripts/scrapbookpartitions.lua` trong `data/databundles/scripts.zip`; hàm `UpdateMultiStorageData()` và `UpdateStorageData(hashed, newdata)`.

**Files:** Probe và báo cáo ở Task 1. Chưa chỉ định file production vì chưa xác nhận caller lỗi. Chỉ tạo compatibility module ở mod sở hữu caller sau khi có trace; nếu là engine/backend, không patch Hầm Ngục hoặc binary game để che lỗi.

**Interfaces:** Payload chuẩn thấy trong Lua hiện tại là `{ SCRAPBOOK0 = { [hex_hash] = encoded_value }, ..., SCRAPBOOK15 = ... }`; bucket bằng `hash & 0xF`. Chưa có bằng chứng payload thực lúc lỗi tuân theo cấu trúc này.

- [ ] Probe tại `UpdateMultiStorageData`/ranh giới gọi `SetStorageValueMulti`: ghi call stack, tên key cấp ngoài, kiểu dữ liệu, số entry mỗi bucket; không ghi dữ liệu tài khoản đầy đủ. Dùng `hash(prefab)` thật của engine đối chiếu sáu mã với dataset đang nạp, đánh dấu mã không map được.
- [ ] Kiểm tra record trước/sau flush, `dirty_buckets`, copy local và sau restart. Chỉ tái hiện thao tác Scrapbook bình thường; không dùng lệnh unlock/reset toàn bộ.
- [ ] Nếu caller truyền sai cấu trúc hoặc thêm key ngoài schema: viết regression test với payload thực đã rút gọn; sửa caller đóng gói đúng cấp/bucket, giữ nguyên dữ liệu hợp lệ. Không tự xóa entry chưa biết để backend im lặng.
- [ ] Nếu payload đúng mà backend vẫn từ chối: tái hiện với game gốc trên profile QA, đối chiếu build/game update và lưu báo cáo. Khi chưa có fix đáng tin cậy, giữ nhánh này là chưa giải quyết; không gọi “fixed”.
- [ ] Test round-trip local, restart, online/offline và dữ liệu cũ/unknown bằng fixture; xác minh các mục Scrapbook hợp lệ vẫn được ghi nhận. Không kiểm chứng lỗi engine chỉ bằng mock Lua.
- [ ] Commit riêng khi có sửa đã xác nhận; ghi rõ lỗi thuộc code mod hay engine/backend.

## Task 5: Nghiệm thu và gói phát hành

- [ ] Chạy unit tests của các mod đã sửa, asset/dependency checks, kiểm tra cú pháp và diff. Không gộp sửa ngoài phạm vi.
- [ ] Trên client thật: hoàn thành lượt có Igris, nhặt thưởng, ra hầm, chờ cổng mới 480 giây simulation; save/reload. Chạy thêm lượt không có Igris để phân biệt cảnh báo diện rộng với boss.
- [ ] Tiêu chí: không còn build collision Igris; nhóm cảnh báo animation đã xác định không tái hiện với hành động baseline; Storage Multi chỉ được đánh dấu sửa khi thao tác gây lỗi cũ không còn lỗi và dữ liệu vẫn round-trip được.
- [ ] Nếu chỉ Igris hoàn tất thì có thể phát hành bản sửa asset riêng, ghi rõ animation/Storage còn điều tra. Dự kiến Hầm Ngục `0.1.2-dev` nếu chưa có bản mới hơn lúc triển khai; không tự tăng phiên bản mod không đổi.
- [ ] Cập nhật README, manifest adaptation, kết quả QA và đóng ZIP không kèm mod probe. Báo những gì đã kiểm chứng bằng client thật và phần chưa tái hiện.

## Thứ tự thực hiện

Task 1 lấy baseline trước; Task 2 có thể sửa ngay sau đó. Task 3 và Task 4 có cổng bằng chứng riêng trước sửa production. Task 5 nghiệm thu theo đúng phần đã hoàn tất. Lượt hiện tại chỉ tạo kế hoạch, chưa sửa mod hoặc cài bản vá vào game.

## Cập nhật thực thi theo phạm vi mới — 2026-10-01

Người dùng chỉ yêu cầu sửa trùng build Igris. Đã thực hiện phần asset/code của Task 2: đổi tên build BILD thành `hn_igris_build`, cập nhật boss/corpse và dependency của corpse, cập nhật checker/provenance. Giữ `anim.bin` vì không cần đổi hoặc bỏ animation để sửa định danh build; mọi byte texture, animation và phần BILD ngoài tên đều giữ nguyên. Làm trực tiếp trong checkout hiện tại, chỉ thay file Hầm Ngục và ghi chú plan; không đưa sửa Thành Tựu/NOVA vào phạm vi.

Hai test asset đã fail trước sửa và pass sau sửa; 32 test Lua, 73 kiểm tra cú pháp Lua và dependency checker đều pass. Bản gói `0.1.2-dev`. Chưa chạy lại engine/client renderer, nên bước kiểm tra hình ảnh thực tế còn chưa nghiệm thu. Không thực hiện Task 1/3/4 hoặc thay mã runtime của các nhóm lỗi khác.
