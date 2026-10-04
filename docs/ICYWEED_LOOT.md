# Gió lạnh vi vu — đồ rơi từ Achievement 1.3.3

## Cách nhận

Perk Toàn cầu giá **35 Sao**. Trong mùa đông, bụi cỏ lăn ở vùng có spawner đổi sang bụi đóng băng; **đào mỗi gốc cây tạo một bụi** khi perk bật. Không cần tạo world mới.

Mỗi bụi cho:

1. **Bảo đảm 2–4 Linh Thạch hạ phẩm Tu Tiên** (`xd_lingshi1`).
2. **Hai lượt thưởng độc lập** theo bảng bên dưới. Có thể nhận cùng món hai lần.

Đồ rơi xuống đất, gộp khi stack tương thích, chia theo giới hạn stack đang dùng. Ba nhóm thưởng có thể thành một stack nếu cùng loại. Không tự cộng tiền vào ví Solo.

## Bảng thưởng phụ

Tỷ lệ áp dụng **cho mỗi lượt**, tổng 100%. Số lượng trong khoảng được quay đều trên số nguyên.

| Nhóm | Vật phẩm | Prefab | Tỷ lệ/lượt | Số lượng |
|---|---|---|---:|---:|
| Tu Tiên | Hạt Giống Phủ Băng (đông) | `xd_lc_hsc_seed` | 10% | 1–2 |
| Tu Tiên | Hạt Giống Thanh Nang (thu) | `xd_lc_qfx_seed` | 4% | 1 |
| Tu Tiên | Hạt Giống Sí Nhiệt (hè) | `xd_lc_cyh_seed` | 4% | 1 |
| Tu Tiên | Hạt Giống Điện Khuẩn (xuân) | `xd_lc_lmg_seed` | 4% | 1 |
| Tu Tiên | Gói Linh Thạch hạ phẩm thêm | `xd_lingshi1` | 2,5% | 5–8 |
| Tu Tiên | Linh Thạch trung phẩm | `xd_lingshi2` | 0,5% | 1 |
| Solo/Thần Khí | Linh Thạch Solo | `hh_essence` | 20% | 1–2 |
| Thần Khí | Huyền Tinh hạ phẩm | `ttk_huyen_tinh_ha_pham` | 12% | 1–2 |
| Thần Khí | Huyền Tinh trung phẩm | `ttk_huyen_tinh_trung_pham` | 3% | 1 |
| Solo/Thần Khí | Giấy Thuộc Tính | `hh_effect_tally` | 9% | 1 |
| Solo/Thần Khí | Lục Bảo Thạch | `hh_remove_stone` | 6% | 1 |
| Thần Khí | Đá Đổi Thuộc Tính | `ac_refreshstone` | 3% | 1 |
| Thần Khí | Đá Tẩy Thuộc Tính | `ad_cleanstone` | 2% | 1 |
| DST | Vàng | `goldnugget` | 4% | 1–2 |
| DST | Muối | `saltrock` | 2% | 1–2 |
| DST | Đá mặt trăng | `moonrocknugget` | 2% | 1 |
| DST | Kính trăng | `moonglass` | 2% | 1 |
| DST | Thulecite | `thulecite` | 2% | 1 |
| DST | Bánh răng | `gears` | 2% | 1 |
| DST | Dreadstone | `dreadstone` | 1% | 1 |
| DST | Mảnh Wagpunk | `wagpunk_bits` | 1% | 1 |
| DST | Vỏ cây mặt trăng | `lunarplant_husk` | 1% | 1 |
| DST | Pure Brilliance | `purebrilliance` | 1% | 1 |
| DST | Horror Fuel | `horrorfuel` | 1% | 1 |
| DST | Void Cloth | `voidcloth` | 1% | 1 |

**Linh Thạch Solo (`hh_essence`) và Linh Thạch Tu Tiên (`xd_lingshi1/2`) là hai vật phẩm riêng**, dùng theo cơ chế của từng mod.

## Những món đã bỏ

- Toàn bộ `trinket_1`–`trinket_46`.
- Băng, đá, đá lửa và nitre: dành trọng số cho vật liệu mod.
- `security_pulse_cage`, `moonstorm_static_item`, `moonglass_charged`, `gelblob_bottle`: đồ chuyên cho nội dung đặc thù.

Không thêm Đá Thuộc Tính ngẫu nhiên, bùa không stack của Solo gốc, cuộn cường hóa cấp cao, vũ khí, đan đột phá hoặc linh dược tăng chỉ số vĩnh viễn vào nguồn farm này.

## Thiếu mod, stack và save

- Server kiểm tra prefab thực tế và component stack; không đoán từ tên mod. Kết quả kiểm tra được cache theo định nghĩa prefab để không spawn probe cho mỗi bụi.
- Mục thiếu/không stack được thay bằng **2–4 hạ phẩm**, giữ đúng trọng số của mục. Nếu thiếu cả hạ phẩm, fallback cuối là **1–2 vàng** và log cảnh báo một lần.
- Thần Khí tắt thì các vật phẩm chỉ thuộc Thần Khí chuyển fallback; bật Solo không tự tạo các prefab vật lý còn thiếu.
- Thưởng được lưu theo từng bụi; restart giữ kết quả. Bụi từ save cũ chưa có dữ liệu mới quay một lần. Đồ đã nhặt trước cập nhật không bị sửa.
- Nếu mod thay đổi sau khi bụi đã có thưởng, lượng fallback lúc nhận được chặn vào khoảng 2–4 hạ phẩm hoặc 1–2 vàng, **không quay RNG lại**. Vì vậy cấu hình thiếu mod nhận nhiều hạ phẩm hơn bảng kỳ vọng.
- Pick và haunt phát thưởng một lần; client không tự quay hay spawn thưởng.

## Cân bằng và kiểm tra

Với đủ vật phẩm hợp lệ, trung bình 100 bụi nhận **332,5 hạ phẩm, 1 trung phẩm, 60 Linh Thạch Solo, 36 Huyền Tinh hạ phẩm và 6 Huyền Tinh trung phẩm**. Có thể nhận nhiều hoặc ít hơn kỳ vọng ở đợt nhỏ.

Đã đọc công thức thực trong engine Tu Tiên 18.1.0: **60 hạ phẩm → 1 trung phẩm**, **20 trung phẩm → 1 thượng phẩm**. Do đó tiền tệ Tu Tiên trực tiếp từ 100 bụi có kỳ vọng tương đương **392,5 hạ phẩm**; chưa tính vật liệu đem tái chế. Pure Brilliance/Horror Fuel trong bảng tái chế hiện có giá cao, nên giữ tỷ lệ 1% mỗi món/lượt, thấp hơn pool cũ.

Mô phỏng Lua 5.1, seed `4102026`:

| Số bụi | Hạ phẩm Tu Tiên | Trung phẩm Tu Tiên | Linh Thạch Solo | Huyền Tinh hạ phẩm |
|---:|---:|---:|---:|---:|
| 100 | 352 | 0 | 61 | 23 |
| 1.000 | 3.406 | 8 | 605 | 383 |
| 100.000 | 332.970 | 998 | 60.156 | 35.770 |

Test Lua kiểm tra toàn bộ biên trọng số, khoảng số lượng, fallback, validation dữ liệu save, gộp/tách stack, pick/haunt lặp và client. Test engine dùng dedicated server offline trên cluster riêng; `tests/engine_icyweed_test.lua` không được nạp trong mod khi chơi.

### QA ngày 04/10/2026

| Cấu hình dedicated offline | Kết quả |
|---|---|
| Tu Tiên + Solo + Thần Khí + Achievement | 25 ID có stack, phát đúng vật phẩm và số lượng |
| Tu Tiên + Thần Khí + Achievement | Đạt; vật liệu port hoạt động khi Solo tắt |
| Tu Tiên + Solo + Achievement | Đạt; Huyền Tinh và đá đổi/tẩy thuộc port thiếu được thay bằng hạ phẩm |
| Tu Tiên + Achievement | Đạt; toàn bộ mục Solo/Thần Khí dùng fallback hạ phẩm |
| Restart cấu hình đầy đủ | Giữ đúng `xd_lingshi1:4`, `xd_lingshi2:1`, `goldnugget:2` đã lưu |

- Đã kiểm tra gộp/tách 20 hạ phẩm thành hai stack ở giới hạn engine 10; không mất hoặc nhân đơn vị.
- Cả bốn cấu hình có marker `ICYWEED_QA_PASS`, ca restart có `ICYWEED_RESTART_OK`; các lượt cuối không có lỗi Lua.
- Năm script test Achievement đều đạt: hai test icyweed mới và ba regression giá thuộc tính, thành tựu linh dược, máu Tu Tiên.
- Review độc lập đã sửa lỗi trong harness API stack và bổ sung regression cảnh báo thiếu dependency Tu Tiên.
- Chưa kiểm tra giao diện tooltip bằng client, hai client cùng nhặt hoặc thao tác dùng vật liệu trực tiếp tại lò rèn/túi Solo. Guard callback lặp đã qua unit test và engine; các cơ chế dùng vật liệu hiện có không được thay đổi bởi cập nhật này.

Chạy test Lua từ root repository bằng Lua 5.1:

```powershell
lua Achivement_Steam_2026-09-27/tests/icyweed_loot_test.lua
lua Achivement_Steam_2026-09-27/tests/icyweed_runtime_test.lua
```

### Quyết định khi triển khai

- Làm trên nhánh `codex/icyweed-loot` trong checkout hiện tại vì các sửa được duyệt trước đó còn chưa commit và là nền của bản cập nhật. Giới hạn: các sửa cùng nằm trong một checkout; danh sách file của đợt này được review riêng.
- Thử engine trên bản copy mod và cluster riêng. Không dùng kết quả headless để khẳng định giao diện hay chơi nhiều client đã được nghiệm thu.
- Khi đổi bộ mod sau lúc lưu bụi, fallback chặn số lượng vào khoảng được duyệt thay vì quay lại. Đổi lại, phân bố lượng thay thế không giống bụi mới sinh; kết quả thay thế không phụ thuộc restart.
