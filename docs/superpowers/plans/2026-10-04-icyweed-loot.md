# Kế hoạch bổ sung đồ rơi — Gió lạnh vi vu

> Trạng thái: người dùng đã chốt; triển khai vào Achievement 1.3.3 ngày 04/10/2026. Bảng thưởng và bằng chứng QA: [ICYWEED_LOOT.md](../../ICYWEED_LOOT.md).
> Khi triển khai: dùng kỹ năng `superpowers:executing-plans`, làm và kiểm tra theo từng nhiệm vụ bên dưới.

**Mục tiêu:** Bụi cỏ lăn đóng băng luôn có Linh Thạch Tu Tiên, thường có vật liệu Tu Tiên/Solo hữu dụng, giảm đồ chiếm ô và bỏ trinket chỉ đổi vàng.

**Thiết kế:** Mỗi bụi có một phần thưởng bảo đảm và hai lượt thưởng ngẫu nhiên. Bảng vật phẩm, phép quay và kiểm tra khả năng sử dụng được tách khỏi prefab; kết quả do server tạo và lưu theo bụi.

**Công nghệ:** Lua, prefab/component DST, registry `Prefabs`, component `stackable`, OnSave/OnLoad.

**Yêu cầu gốc:** Người dùng yêu cầu lập plan chi tiết trước khi bổ sung. Yêu cầu trước đó: khi sửa phải tăng version.

## 1. Hiện trạng đã kiểm tra

- Perk `icyweed` thuộc nhóm Toàn cầu, giá **35 Sao**, hoạt động vào mùa đông.
- Bụi ở nơi sinh bụi cỏ lăn được đổi sang bụi đóng băng khi perk bật.
- **Mỗi lần đào một gốc cây trong mùa đông hiện tạo một bụi** khi perk bật. Đoạn này không có phép quay xác suất, dù mô tả tiếng Việt đang ghi “ngẫu nhiên từ cây hoặc gốc cây”.
- Mỗi bụi quay ba lượt độc lập, có thể lặp vật phẩm. Tổng trọng số hiện tại là 255.
- `ice`, `rocks`, `flint`, `saltrock`, `nitre` cộng 170/255 = **66,67% mỗi lượt**. Xác suất cả ba lượt đều là các vật liệu này khoảng **29,63%**.
- Trinket có trọng số 10/255, sau đó chọn ngẫu nhiên `trinket_1`–`trinket_46`. Xác suất một bụi có ít nhất một trinket khoảng **11,31%**.
- Bảng hiện không chứa prefab Tu Tiên, Solo hay Linh Thạch của hai mod.
- Đồ rơi hiện tạo trên mặt đất, không tự vào túi. `SpawnPrefab` chưa có kiểm tra kết quả `nil`.
- Kết quả quay được tạo lúc bụi spawn, nhưng prefab chưa lưu riêng kết quả này; cần lưu khi triển khai để tải lại thế giới không quay lại thưởng.

**Nguồn đối chiếu trong workspace:**

- `Achivement_Steam_2026-09-27/scripts/prefabs/icyweed.lua`: bảng trọng số, quay thưởng, thả đồ.
- `Achivement_Steam_2026-09-27/scripts/postInits/perk_global.lua`: điều kiện mùa đông và đào gốc cây.
- `Achivement_Steam_2026-09-27/scripts/constants/perks/global.lua`: giá perk.
- `Achivement_Steam_2026-09-27/main_strings_vi.lua`: mô tả perk.

## 2. Phương án đề xuất

### Một bụi cho ba nhóm thưởng

| Nhóm | Cách nhận | Số lượng |
|---|---|---|
| 1 — Bảo đảm | Linh Thạch hạ phẩm Tu Tiên `xd_lingshi1` | 2–4 viên |
| 2 — Ngẫu nhiên | Quay một lần theo bảng bên dưới | Theo hàng được chọn |
| 3 — Ngẫu nhiên | Quay độc lập lần nữa theo cùng bảng | Theo hàng được chọn |

- Số lượng trong khoảng dùng phân bố đều trên số nguyên, ví dụ 2–4 có thể ra 2, 3 hoặc 4.
- Hai lượt thưởng phụ có thể trùng nhau. Khi cùng prefab và có thể stack với nhau, gộp với cả nhóm bảo đảm trước khi thả.
- Vì vậy “ba nhóm thưởng” có thể tạo **1–3 stack**, không nhất thiết ba món khác nhau.
- Thưởng là vật phẩm thật rơi xuống đất, có thể cất, giao dịch và dùng theo cơ chế hiện có. Không tự cộng vào ví Solo.

### Phân bổ mỗi lượt thưởng phụ

| Nhóm vật phẩm | Tỷ lệ mỗi lượt |
|---|---:|
| Tu Tiên: hạt linh thảo và Linh Thạch | 25% |
| Solo/Thần Khí: Linh Thạch và vật liệu thuộc tính, cường hóa | 55% |
| DST: nguyên liệu chế tạo hữu dụng | 20% |
| **Tổng** | **100%** |

Khi tất cả mục được hỗ trợ, xác suất một bụi có ít nhất một vật phẩm Solo/Thần Khí ở hai lượt phụ là **79,75%**; có ít nhất một vật phẩm mod ở hai lượt phụ là **96%**. Ngoài ra mọi bụi đã có Linh Thạch Tu Tiên ở nhóm bảo đảm.

## 3. Bảng thưởng phụ cụ thể

**Tỷ lệ dưới đây áp dụng cho từng lượt, không phải cho toàn bộ bụi.** Dùng trọng số nguyên tổng 1.000 khi lập trình, ví dụ 0,5% = trọng số 5.

### A. Tu Tiên — tổng 25%

| Vật phẩm | Prefab | Tỷ lệ/lượt | Số lượng | Vai trò |
|---|---|---:|---:|---|
| Hạt linh thảo mùa đông | `xd_lc_hsc_seed` | 10% | 1–2 | Ưu tiên trồng linh thảo hợp mùa |
| Hạt linh thảo mùa thu | `xd_lc_qfx_seed` | 4% | 1 | Tích trữ cho trồng trọt |
| Hạt linh thảo mùa hè | `xd_lc_cyh_seed` | 4% | 1 | Tích trữ cho trồng trọt |
| Hạt linh thảo mùa xuân | `xd_lc_lmg_seed` | 4% | 1 | Tích trữ cho trồng trọt |
| Linh Thạch hạ phẩm, gói thêm | `xd_lingshi1` | 2,5% | 5–8 | Thưởng tiền tệ thêm |
| Linh Thạch trung phẩm | `xd_lingshi2` | 0,5% | 1 | Phần thưởng hiếm |

**Mức xác minh:** Các ID hạt đã được dùng trong bảng thưởng nhiệm vụ mùa của Achievement. Các ID Linh Thạch đã được dùng trong hệ thống thưởng, chế tạo và Hầm Ngục. Chưa xác nhận component stack của toàn bộ hạt và `xd_lingshi2` trên prefab thực tế của Tu Tiên 18.1.0 vì nguồn prefab được mã hóa; đây là bước kiểm tra bắt buộc khi triển khai, không phải khẳng định đã kiểm thử trong game.

Không tự gán tên cụ thể cho bốn loại cây khi chưa đọc được tên thực trong game; bảng dùng tên theo mùa đã được nguồn hiện có xác nhận.

### B. Solo/Thần Khí — tổng 55%

| Vật phẩm | Prefab | Tỷ lệ/lượt | Số lượng | Vai trò |
|---|---|---:|---:|---|
| Linh Thạch Solo | `hh_essence` | 20% | 1–2 | Tiền tệ/nguyên liệu của hệ Solo |
| Huyền Tinh hạ phẩm | `ttk_huyen_tinh_ha_pham` | 12% | 1–2 | Nguồn vật liệu cường hóa cấp thấp |
| Huyền Tinh trung phẩm | `ttk_huyen_tinh_trung_pham` | 3% | 1 | Thưởng cường hóa ít gặp |
| Giấy Thuộc Tính | `hh_effect_tally` | 9% | 1 | Nguyên liệu hệ thuộc tính |
| Lục Bảo Thạch | `hh_remove_stone` | 6% | 1 | Nguyên liệu hệ thuộc tính |
| Đá Đổi Thuộc Tính | `ac_refreshstone` | 3% | 1 | Đổi giá trị thuộc tính theo cơ chế Thần Khí |
| Đá Tẩy Thuộc Tính | `ad_cleanstone` | 2% | 1 | Tẩy thuộc tính theo cơ chế Thần Khí |

**Phân biệt rõ:** `hh_essence` và `xd_lingshi1/2` là vật phẩm khác nhau. Không cộng chung, không đổi tên chung trong tài liệu và không tự quy đổi qua lại.

Các vật phẩm trên có định nghĩa stack trong bản port `ThanKhiTuTien_Steam_2026-09-27/scripts/prefabs/tbc_items.lua`. Solo gốc cũng có `hh_essence`, `hh_effect_tally`, `hh_remove_stone` stackable trong nguồn đã đọc. Huyền Tinh hạ/trung và hai prefab đá viết thường là phần của Thần Khí; chúng không được giả định là luôn tồn tại khi chỉ bật Solo.

Phải kiểm tra prefab cuối cùng đang được đăng ký khi bật cả Solo và Thần Khí, vì định nghĩa của một mod không chứng minh định nghĩa được game sử dụng cũng stack. ID ví Solo `ac_refreshStone`/`ad_cleanStone` có chữ hoa không được dùng thay ID vật phẩm vật lý khi chưa xác minh.

### C. Nguyên liệu DST — tổng 20%

| Vật phẩm | Prefab | Tỷ lệ/lượt | Số lượng |
|---|---|---:|---:|
| Vàng | `goldnugget` | 4% | 1–2 |
| Muối | `saltrock` | 2% | 1–2 |
| Đá mặt trăng | `moonrocknugget` | 2% | 1 |
| Kính trăng | `moonglass` | 2% | 1 |
| Thulecite | `thulecite` | 2% | 1 |
| Bánh răng | `gears` | 2% | 1 |
| Dreadstone | `dreadstone` | 1% | 1 |
| Mảnh Wagpunk | `wagpunk_bits` | 1% | 1 |
| Vỏ cây mặt trăng | `lunarplant_husk` | 1% | 1 |
| Pure Brilliance | `purebrilliance` | 1% | 1 |
| Horror Fuel | `horrorfuel` | 1% | 1 |
| Void Cloth | `voidcloth` | 1% | 1 |

Giữ vật liệu chế tạo cao cấp đã có trong pool nhưng ở tỷ lệ thấp. Đây không phải danh sách vật phẩm chỉ đổi cho Pig King.

## 4. Các món loại khỏi bảng

| Nhóm | Prefab | Lý do |
|---|---|---|
| Trinket | `trinket_1`–`trinket_46` | Bỏ toàn bộ nhánh quay trinket để giảm đồ chủ yếu đổi Pig King |
| Vật liệu quá phổ biến | `ice`, `rocks`, `flint`, `nitre` | Dành trọng số cho vật liệu mod; các món này có nguồn farm riêng dễ tiếp cận |
| Đồ chuyên cho nội dung đặc thù | `security_pulse_cage`, `moonstorm_static_item`, `moonglass_charged`, `gelblob_bottle` | Bỏ khỏi thưởng bụi để tránh nhận đồ không phù hợp tiến trình hoặc phải xử lý riêng |

Không coi mọi vật phẩm hàng cuối là vô dụng hoặc đều không stack. Ví dụ `moonstorm_static_item` có component stack trong nguồn game; lý do bỏ là vai trò đặc thù. `security_pulse_cage` không có component stack trong nguồn prefab đã đọc.

**Không thêm trong đợt này:**

- Đá Thuộc Tính `hh_effect_stone`: mỗi viên có thuộc tính ngẫu nhiên riêng, không stack theo định nghĩa Thần Khí.
- Bùa Giữ Cấp `nn_magicpaper`, Bùa Bảo Vệ `wb_strengthen_strengthen_protectpaper`: bản Thần Khí stack nhưng nguồn Solo gốc đã đọc không thêm component stack. Tránh dùng chúng trong pool yêu cầu stack ở mọi cấu hình.
- Cuộn +6 đến +12, vũ khí, trang bị: phần thưởng lớn và thường không stack.
- Linh dược tăng chỉ số vĩnh viễn, đan đột phá và vật liệu boss Tu Tiên: tránh biến đào gốc cây thành nguồn vượt tiến trình. Chỉ bổ sung ở lượt cân bằng riêng nếu người dùng muốn.
- Linh Thạch thượng/cực phẩm, Huyền Tinh thượng/cực phẩm: giữ giá trị các nguồn boss, hầm ngục và ghép vật liệu.

## 5. Kiểm soát lượng thưởng

Nguồn bụi có thể tái tạo bằng trồng cây → chặt cây → đào gốc vào mùa đông. Phương án giữ giá perk và điều kiện sinh bụi hiện có, dùng tỷ lệ thấp cho thưởng cấp cao.

Ước lượng **100 bụi**, với đầy đủ prefab và stack hợp lệ:

| Món | Trung bình dự kiến |
|---|---:|
| Linh Thạch hạ phẩm bảo đảm | 300 viên |
| Linh Thạch hạ phẩm ở thưởng phụ | 32,5 viên |
| Linh Thạch trung phẩm | 1 viên |
| Linh Thạch Solo | 60 viên |
| Hạt linh thảo mùa đông | 30 hạt |
| Hạt của ba mùa khác | 8 hạt mỗi loại |
| Huyền Tinh hạ phẩm | 36 viên |
| Huyền Tinh trung phẩm | 6 viên |
| Giấy Thuộc Tính | 18 tờ |
| Lục Bảo Thạch | 12 viên |
| Đá Đổi / Đá Tẩy Thuộc Tính | 6 / 4 viên |
| Lượt thưởng vật liệu DST | 40 lượt |

Các con số là kỳ vọng toán học, không bảo đảm đúng cho một đợt 100 bụi. Ví dụ trung phẩm có thể không xuất hiện trong đợt nhỏ.

Huyền Tinh hiện có công thức 5 hạ → 1 trung, 4 trung → 1 thượng, 3 thượng → 1 cực trong Thần Khí. Riêng tỷ lệ quy đổi Linh Thạch Tu Tiên chưa được xác minh trong bước đọc nguồn này; phải kiểm tra trước khi đánh giá giá trị phần thưởng trung phẩm. Không gán tỷ lệ quy đổi dựa vào tên phẩm cấp.

Không thêm nhân hệ số theo level/cảnh giới/luck trong đợt đầu. Mô phỏng phải kiểm tra cả 1.000 bụi để thấy sản lượng khi farm lớn; đối chiếu với thưởng nhiệm vụ mùa, hầm ngục và giá tái chế trước khi chốt bản triển khai.

## 6. Tương thích và xử lý stack

1. **Lọc theo prefab thực tế:** dùng `Prefabs[id]`, không chỉ dựa vào tên workshop hay mod đang bật.
2. **Kiểm tra stack:** chạy kiểm tra trên server cho từng prefab mod trước khi đưa vào pool. Nếu vật phẩm có dữ liệu riêng không tương thích giữa các bản, coi là không đạt dù có component stack.
3. **Thiếu/không đạt một mục thưởng phụ:** thay chính mục đó bằng gói **2–4 `xd_lingshi1`**, giữ nguyên trọng số của mục. Không tăng tỷ lệ vật phẩm hiếm khác; không tự đẩy hết tỷ lệ của mod thiếu sang mod còn lại.
4. **Thiếu cả `xd_lingshi1`:** đây là cấu hình thiếu dependency Tu Tiên của Achievement. Dùng `goldnugget` 1–2 làm fallback cuối để tránh mất thưởng/crash, ghi cảnh báo một lần; không coi cấu hình này đạt nghiệm thu chính.
5. **Spawn thất bại khi nhặt:** thử fallback có giới hạn, kiểm tra `nil`, không lặp quay vô hạn. Nếu cả prefab chuẩn của game cũng không spawn được, ghi lỗi rõ ràng.
6. **Gộp stack:** gộp các phần thưởng cùng prefab khi `CanStackWith` cho phép; chia theo giới hạn stack đang có của game/mod. Không sửa giới hạn stack toàn cục.
7. **Lưu thưởng theo bụi:** lưu phiên bản dữ liệu và danh sách `{prefab, amount}`. Tải lại giữ kết quả và số lượng; kiểm tra khả dụng lại lúc phát thưởng nếu cấu hình mod thay đổi.
8. **Save cũ:** bụi không có dữ liệu thưởng mới tạo kết quả một lần khi load. Không yêu cầu tạo world mới; không xóa hay đổi vật phẩm đã nhặt trước bản cập nhật.
9. **Server phát thưởng một lần:** pick và haunt dùng cùng đường phát thưởng; chặn callback lặp khiến một bụi phát đồ nhiều lần. Haunt không cần đối tượng người chơi để phát đồ.

Do có fallback, cấu hình thiếu Thần Khí sẽ nhận nhiều Linh Thạch Tu Tiên hơn bảng kỳ vọng. Phải nêu điều này trong ghi chú bản phát hành.

## 7. Mô tả perk mới

Mô tả ngắn đề xuất:

> Mùa đông: bụi cỏ lăn đóng băng xuất hiện ở vùng bụi cỏ lăn và khi đào gốc cây. Mỗi bụi có 2–4 Linh Thạch hạ phẩm và 2 lượt thưởng vật liệu Tu Tiên, Solo/Thần Khí hoặc chế tạo.

Giá vẫn **35 Sao**, phạm vi vẫn **Toàn cầu**. Danh sách đầy đủ và tỷ lệ được đưa vào tài liệu đồ rơi; tooltip không liệt kê cả bảng dài. Nếu giao diện có giới hạn dòng, dùng mô tả ngắn hơn và đặt phần cách sinh bụi trong tài liệu, kiểm tra trực tiếp để không tràn ô perk.

## 8. File và trách nhiệm khi triển khai

Các đường dẫn bên dưới tính từ `C:/Users/hoanc/company/dst_nova`.

| File | Thao tác | Trách nhiệm |
|---|---|---|
| `Achivement_Steam_2026-09-27/scripts/constants/icyweedloot.lua` | Tạo | Bảng trọng số, số lượng, nhóm bảo đảm và danh sách fallback |
| `Achivement_Steam_2026-09-27/scripts/functions/icyweedloot.lua` | Tạo | Chuẩn bị pool, quay kết quả, chuẩn hóa dữ liệu lưu; hàm thuần có thể kiểm tra bằng RNG giả |
| `Achivement_Steam_2026-09-27/scripts/prefabs/icyweed.lua` | Sửa | Nối pool, kiểm tra spawn/stack, gộp đồ, lưu/load, phát thưởng một lần |
| `Achivement_Steam_2026-09-27/main_strings_vi.lua` | Sửa | Mô tả đúng cơ chế và thưởng mới |
| `Achivement_Steam_2026-09-27/modinfo.lua` | Sửa | Tăng version và đồng bộ version trong mô tả |
| `Achivement_Steam_2026-09-27/tests/icyweed_loot_test.lua` | Tạo | Kiểm tra bảng, biên RNG, fallback, phân bố và lượng thưởng |
| `Achivement_Steam_2026-09-27/tests/icyweed_runtime_test.lua` | Tạo | Kiểm tra spawn lỗi, stack, save/load và phát thưởng một lần |
| `docs/ICYWEED_LOOT.md` | Tạo | Bảng vật phẩm chính thức, cơ chế và các cấu hình tương thích đã kiểm tra |

Interface dự kiến:

- `PreparePool(prefab_exists, stack_supported) -> pool`: thay mục không được hỗ trợ bằng fallback, giữ tổng trọng số 1.000.
- `Roll(pool, random_int) -> rewards`: một nhóm bảo đảm + hai lượt thưởng phụ, trả các bản ghi `{prefab, amount}`.
- `NormalizeSaved(data) -> rewards_or_nil`: nhận dữ liệu save, kiểm tra ID/số nguyên dương/giới hạn, không gọi spawn.
- Prefab chịu trách nhiệm phát đồ thật, xử lý stack và fallback tại thời điểm nhặt.

Kiểm tra stack thực tế dùng bộ nhớ đệm theo registry hiện tại, không spawn một bộ vật phẩm kiểm tra cho mỗi bụi. Entity kiểm tra phải được remove sau khi đọc component.

## 9. Các bước thực hiện và nghiệm thu

### Nhiệm vụ 1 — Xác minh vật phẩm và cân bằng

- [ ] Spawn từng ID mod trong world thử có Tu Tiên + Solo + Thần Khí; ghi tên hiển thị, component stack và khả năng dùng thực tế.
- [ ] Xác minh stack của hạt và Linh Thạch trung phẩm; mục nào không đạt dùng fallback đã nêu, cập nhật danh sách phát hành rõ ràng.
- [ ] Xác minh tỷ lệ quy đổi Linh Thạch và giá trị các vật liệu nhận được; đối chiếu nhiệm vụ mùa, hầm ngục, lò tái chế.
- [ ] Ghi lượng thưởng 100/1.000 bụi theo bảng; nếu cần thay tỷ lệ lớn hoặc thêm vật phẩm không stack, đưa bảng điều chỉnh cho người dùng duyệt trước.

### Nhiệm vụ 2 — Bảng và thuật toán thưởng

- [ ] Viết kiểm tra trước cho tổng 1.000, nhóm 250/550/200, ID trùng, trọng số dương và khoảng số lượng hợp lệ.
- [ ] Kiểm tra biên từng khoảng RNG: đầu/cuối đều chọn đúng mục; không có khoảng rỗng hay lệch một đơn vị.
- [ ] Kiểm tra nhóm bảo đảm luôn ra 2–4 hạ phẩm, rồi có đúng hai lượt phụ.
- [ ] Kiểm tra danh sách loại bỏ không thể được quay ra.
- [ ] Kiểm tra thiếu prefab và không stack giữ trọng số, có fallback hữu hạn.
- [ ] Tạo module dữ liệu/thuật toán tối thiểu và chạy lại các kiểm tra.
- [ ] Mô phỏng seed cố định, báo số liệu kỳ vọng và quan sát, không chỉ đưa một chuỗi drop đẹp để chứng minh.

### Nhiệm vụ 3 — Phát đồ và save

- [ ] Viết kiểm tra tích hợp prefab cho gộp cùng loại, giới hạn stack nhỏ và `SpawnPrefab` trả `nil`.
- [ ] Kiểm tra pick hai lần, pick/haunt nối tiếp không nhân đôi thưởng.
- [ ] Kiểm tra save/load giữ nguyên kết quả; save cũ không có dữ liệu mới vẫn load được.
- [ ] Kiểm tra bỏ mod sau khi lưu: vật phẩm thiếu được thay đúng lúc phát thưởng.
- [ ] Tích hợp vào prefab, bảo toàn component pickable, hiệu ứng và luồng gió hiện có.
- [ ] Kiểm tra client không tự quay hay spawn thưởng.

### Nhiệm vụ 4 — Kiểm tra trong game, mô tả và version

- [ ] Tu Tiên + Solo + Thần Khí: nhặt bụi, stack vào túi Solo/túi thường theo cơ chế sẵn có; dùng thử vật liệu nhận được.
- [ ] Tu Tiên + Thần Khí, Solo tắt: các prefab port được phát khi có thật.
- [ ] Tu Tiên + Solo, Thần Khí tắt: vật phẩm chỉ thuộc port chuyển fallback đúng.
- [ ] Chỉ Tu Tiên + Achievement: không lỗi vì thiếu Solo/Thần Khí, vẫn có thưởng hữu dụng.
- [ ] Kiểm tra mùa đông bật/tắt perk; đào gốc cây và bụi từ spawner; ngoài mùa đông không phát sinh thêm nguồn mới.
- [ ] Server nhiều người: hai người cùng nhặt không nhân đôi; ghost haunt không lỗi vì `picker == nil`.
- [ ] Restart server khi còn bụi chưa nhặt: thưởng không đổi; không yêu cầu world mới.
- [ ] Cập nhật mô tả, tài liệu và tăng Achievement **1.3.2 → 1.3.3**. Nếu version đã đổi trước lúc triển khai thì tăng từ version thực tế lúc đó.
- [ ] Xem diff đúng phạm vi, bảo toàn các sửa đang có của những nhiệm vụ trước. Chỉ báo hoàn thành khi ghi rõ kiểm tra nào đã chạy; tách phần chưa kiểm chứng trong game nếu môi trường không chạy được.

## 10. Điểm cần tập trung khi review

- Prefab do Solo ghi đè có thể khác bản port: khả năng stack phải dựa vào entity thực tế.
- Hạt/tiền tệ Tu Tiên có nguồn mã hóa: không tuyên bố đã xác minh hành vi chỉ từ tên ID.
- Nguồn đào gốc cây liên tục có thể đẩy nhanh kinh tế: kiểm tra sản lượng lớn và giá tái chế.
- Save cũ và việc đổi bộ mod giữa hai lần mở world phải có đường fallback rõ ràng.
- RNG có tỷ lệ hiếm, hai người pick cùng lúc và haunt cần kiểm tra riêng để tránh đồ mất hoặc nhân đôi.

## 11. Chốt đề xuất để duyệt

- **Bảo đảm 2–4 Linh Thạch hạ phẩm/bụi.**
- **Hai lượt phụ: 25% Tu Tiên, 55% Solo/Thần Khí, 20% nguyên liệu DST mỗi lượt.**
- **Bỏ trinket, đồ đặc thù và bốn vật liệu phổ biến nhất; ưu tiên vật phẩm stack.**
- **Trung phẩm Tu Tiên chỉ 0,5%/lượt; chưa thêm đan đột phá, đồ boss hoặc đá thuộc tính ngẫu nhiên.**
- **Giữ nguồn sinh bụi, giá 35 Sao; sửa mô tả cho đúng và tăng version khi triển khai.**

Phương án đã được triển khai với đúng trọng số và số lượng ở trên. Test Lua, bốn cấu hình dedicated engine và restart đã đạt; các ca cần client thật còn được ghi rõ trong tài liệu QA.

## 12. Kết quả thực hiện

- [x] Xác minh 25 prefab thực tế: đủ mod đều spawn và stack; hạt hiển thị tên Phủ Băng, Thanh Nang, Sí Nhiệt, Điện Khuẩn.
- [x] Xác minh công thức Tu Tiên: 60 hạ → 1 trung, 20 trung → 1 thượng; tiền tệ trực tiếp kỳ vọng 392,5 hạ tương đương/100 bụi.
- [x] Bảng và phép quay, mọi biên RNG, fallback giữ trọng số, validation save; mô phỏng 100, 1.000, 100.000 bụi.
- [x] Prefab phát đồ: gộp/tách, spawn thất bại, thay registry, save/load cũ/mới, pick/haunt lặp và client guard.
- [x] Engine bốn cấu hình dependency và restart giữ nguyên thưởng. Dùng world/cluster thử riêng.
- [x] Version Achievement 1.3.3, mô tả perk ngắn, tài liệu bảng thưởng chính thức; kiểm tra tài liệu khớp cả 25 hàng code.
- [x] Review độc lập và sửa hai phát hiện; toàn bộ năm test Achievement đạt.
- [ ] Quan sát tooltip và thao tác dùng vật liệu tại lò rèn/túi Solo trong client thật.
- [ ] Hai client cùng nhặt một bụi; điều kiện mùa/perk trong phiên chơi thật. Luồng sinh bụi hiện có được giữ nguyên; phát thưởng một lần đã kiểm chứng bằng callback lặp trong unit/engine.

Fallback cho bụi đã lưu dùng số lượng chặn vào khoảng 2–4 hạ hoặc 1–2 vàng, không quay lại RNG khi đổi mod. Đây là quyết định giữ kết quả ổn định, đã ghi trong tài liệu phát hành.
