# Kế hoạch gộp phần thưởng Máy Quay Linh Thạch

> CẬP NHẬT 09/10/2026 — 1.6.4: Rút nhóm Quái xuống 15 gói theo yêu cầu; tổng 133 gói. Giữ các ID `quai_03, 06, 08, 09, 10, 13, 16, 19, 20, 24, 26, 27, 28, 30, 31`. Bỏ cả Slurper lẫn Slurtle/Snurtle cùng các nhóm chó, hải mã, ếch, xúc tu, ong. Bảng lịch sử 31 gói bên dưới được giữ để đối chiếu; bảng áp dụng nằm trong `docs/SLOT_REWARDS_FINAL.md`. Tỷ lệ nhóm vẫn 40%; mỗi gói còn lại 2,6667% khi đủ điều kiện.

> CẬP NHẬT CHỐT 08/10/2026: Người dùng đã duyệt toàn bộ và yêu cầu triển khai. Bảng cuối là `docs/SLOT_REWARDS_FINAL.md`; nội dung duyệt bên dưới lưu lịch sử và được thay thế bởi bảng cuối nếu khác nhau. Giữ chi phí và trọng số nhóm của bản đang cài. Sau rà soát, người dùng yêu cầu bỏ hai món thiếu bản tùy chỉnh cũ: `nhatvuphuonghoa` và `thanhiquangtruong`; giữ những món còn lại cùng gói. Tổng vẫn 149 gói.

> **For agentic workers:** Khi có yêu cầu triển khai runtime, dùng `superpowers:executing-plans` để thực hiện từng phần đã duyệt. Tài liệu hiện tại là kế hoạch nội dung đang duyệt; không phải lệnh triển khai vào game.

**Goal:** Gộp phần thưởng của bản Phàm Nhân Tu Tiên cũ và Tu Tiên 18.1.0 hiện tại thành một bảng mới, duyệt lần lượt Hiếm → Khá → Thường → Boss → Quái.

**Architecture:** Giữ hai bảng nguồn để đối chiếu và ghi riêng bảng hợp nhất. Chỉ thay bảng thưởng qua mod mở rộng sau khi chốt nội dung, tỷ lệ và phương án tích hợp; không sửa Tu Tiên gốc.

**Tech Stack:** Tài liệu Markdown cho giai đoạn duyệt; Lua/DST cho triển khai sau này; wiki Next.js cho trang đối chiếu.

**Spec:** Các quyết định của người dùng trong cuộc trao đổi ngày 08/10/2026, được ghi đầy đủ tại các mục bên dưới.

## Trạng thái và nguồn đối chiếu

- Nhóm Hiếm có 24 gói sau khi bỏ Ngọc quý theo yêu cầu mới nhất. Shadow Atrium và Hoa Hồng Ám Ảnh vẫn tạm ghi thành hai gói riêng, mỗi món ×1 vì người dùng chưa nêu số lượng.
- Đã chốt giữ gói sáu bùa của nhóm Khá hiện tại, mỗi loại một chiếc.
- Đã chốt bỏ năm gói khỏi nhóm Khá: Trung Phẩm Linh Thạch ×2, Kiếm bóng tối, Phòng tuyến, Kho báu và Thuyền. Còn 17 gói từ đề xuất hợp nhất; thêm bốn gói Solo đề xuất thành 21 gói để tiếp tục duyệt.
- Nhóm Thường: đã yêu cầu bỏ sáu gói Công cụ vàng, Làm ruộng, Soi hang, May vá, Muối, Nuôi ong và nấu ăn; thay bằng sáu gói Solo đề xuất. Bảng đang duyệt có 30 gói.
- Chưa chốt tỷ lệ mới và toàn bộ các nhóm còn lại. Không dùng tài liệu này để tự áp dụng các nhóm chưa duyệt.
- Chưa sửa runtime, chưa tăng version và chưa kiểm thử bảng hợp nhất trong game.
- Bản chỉnh cũ: repo `dst_wiki`, snapshot `7aa737ade55b1cb0a7e63915d100aa41a942624d`, `mods/PhamNhanTuTien/CHOUJIANGJI_REWARDS.md` và `scripts/ttk_slot_prizes.lua`; 104 gói.
- Bản hiện tại: Workshop `3721846643`, Tu Tiên **18.1.0**, `scripts/prefabs/xd_choujiangji.lua`; 131 gói, đọc từ bản đang cài ngày 08/10/2026. SHA-256 file nguồn: `ced8cb4fab45321b906ad166f001a976d3666444c4a589789c9882c3a71661a1`.
- Hai trang wiki đối chiếu: `/duyet/may-quay-linh-thach` (bản chỉnh cũ) và `/duyet/may-quay-linh-thach/hien-tai` (bản đang cài). Đây là các bản nguồn, chưa phải trang của bảng hợp nhất.

## Ràng buộc chung

- Mỗi hàng là một gói: trúng gói nào nhận toàn bộ vật phẩm và số lượng trong hàng đó.
- Các prefab từ bản Phàm Nhân cũ là mã tham chiếu; phải xác minh vật phẩm tương ứng thực sự tồn tại trong bộ mod hiện tại trước khi đưa vào runtime. Không tự đổi tiền tố `ttk_` thành `xd_`.
- Tỷ lệ vào nhóm Hiếm **4,7619%** hiện chỉ là mức tạm giữ để thảo luận. Tỷ lệ từng gói phải tính lại sau khi chốt trọng số; không sao chép tỷ lệ của bảng 16 gói sang bảng 24 gói.
- Khi triển khai runtime hoặc đổi thứ tự load, đọc `docs/MOD_LOAD_AND_STATS.md`, giữ quy tắc Tu Tiên là mod nền, tăng patch version của mod mở rộng được sửa và đồng bộ mô tả.
- Không sửa chỉ số, cảnh giới, tiến trình hoặc save nhân vật để phục vụ thay đổi bảng thưởng.

## 1. Nhóm Hiếm — 24 gói

Nền là 16 gói Hiếm của bản chỉnh cũ, thêm bảy gói riêng của bản hiện tại, loại bốn gói theo yêu cầu, thêm bốn gói Thần Khí thay thế và hai gói Shadow Atrium / Hoa Hồng Ám Ảnh; sau đó bỏ thêm gói Ngọc quý theo yêu cầu mới nhất.

| # | Gói | Phần thưởng và số lượng | Prefab tham chiếu |
|---|---|---|---|
| 1 | Dreadstone | Mũ ×1 + giáp ×1 | `dreadstonehat`, `armordreadstone` |
| 2 | Nguyệt thực | Mũ ×1 + giáp ×1 | `lunarplanthat`, `armor_lunarplant` |
| 3 | Hư không | Mũ ×1 + giáp ×1 + lưỡi hái ×1 + ô ×1 | `voidclothhat`, `armor_voidcloth`, `voidcloth_scythe`, `voidcloth_umbrella` |
| 4 | Trượng dịch chuyển | Trượng cam ×1 + Lạc Thần Hoa Nhân ×3 | `orangestaff`, `ttk_luoshen_huayin` |
| 5 | Tử Xá Diện Giáp | Trang bị ×1 + Đuôi Linh Hồ ×3 | `ttk_zcmj`, `ttk_pog_tail` |
| 6 | Tà Sát Hộ Giáp | Giáp ×1 + Tà Sát Bộ Túc ×2 | `ttk_xshj`, `ttk_spider_leg` |
| 7 | Vương miện và Giáp Xương | Vương Miện Khai Sáng ×1 + Giáp Xương ×1 | `alterguardianhat`, `armorskeleton` |
| 8 | Trượng ngọc | Trượng vàng ×1 + trượng opal ×1 + trượng xanh lá ×1 | `yellowstaff`, `opalstaff`, `greenstaff` |
| 9 | Linh thực cay | Kẹo đậu tẩm ớt ×2 + súp hải sản tẩm ớt ×2 + salad hoa tẩm ớt ×2 | `jellybean_spice_chili`, `seafoodgumbo_spice_chili`, `flowersalad_spice_chili` |
| 10 | Thạch dê điện | Thạch dê điện **×7** + Lạc Hương Phanh Nhục ×2 | `voltgoatjelly`, `ttk_luoxiang_pengrou` |
| 11 | Lục Mạch Thần Kiếm | Kiếm ×1 + hạt Lôi Minh Quả ×3 | `lucmachthankiem`, `ttk_lc_lmg_seed` |
| 12 | Tinh La Kiếm | Kiếm ×1 + Lạc Thần Thanh Sơ ×2 | `ttk_tinhlakiem`, `ttk_luoshen_qingshu` |
| 13 | Phần Thiên Kiếm | Kiếm ×1 | `xd_ftj` |
| 14 | Tôn Hồn Phiên | Pháp bảo ×1 | `xd_zhf` |
| 15 | Tẩy Tủy Hoàn | Đan ×1 | `xd_danyao_xs` |
| 16 | Hóa Tinh Đan | Đan ×1 | `xd_danyao_hj` |
| 17 | Vân Trung Đan | Đan ×1 | `xd_danyao_yz` |
| 18 | Nguyên liệu quý | Phượng Tủy ×1 + Kỳ Lân Nhung ×1 | `xd_fs`, `xd_qlr` |
| 19 | Huyền Tinh quý | Huyền Tinh Cực Phẩm ×1 | `wb_enhancegem` |
| 20 | Bùa cường hóa | Bùa Giữ Cấp ×2 + Bùa Bảo Vệ ×1 | `nn_magicpaper`, `wb_strengthen_strengthen_protectpaper` |
| 21 | Chỉnh thuộc tính | Đá Đổi Thuộc Tính ×3 + Đá Tẩy Thuộc Tính ×2 | `ac_refreshstone`, `ad_cleanstone` |
| 22 | Cuộn cường hóa | Cuộn Cường Hóa +6 ×1 | `wb_strengthen_strengthen_6_levelpaper` |
| 23 | Shadow Atrium | Shadow Atrium ×1 | `shadowheart` |
| 24 | Hoa Hồng Ám Ảnh | Hoa Hồng Ám Ảnh ×1 | `xd_aymg` |

Hai gói 23–24 được bổ sung theo yêu cầu người dùng. Số lượng ×1 và cách tách thành hai gói là mặc định ghi nhận để duyệt, chưa phải số lượng do người dùng chỉ định. Mã vật phẩm đối chiếu với `dst_wiki/public/data/items.json`: Shadow Atrium là `shadowheart` (bản thường), Hoa Hồng Ám Ảnh là vật phẩm Tu Tiên `xd_aymg`.

Cuộn +6 dùng cho trang bị đang ở **+5**, nâng lên **+6**; không nâng thẳng từ +0. Hành vi này được xác nhận trong source Thần Khí hiện tại.

### Các gói đã loại khỏi nhóm Hiếm

1. Túi Krampus + Lạc Thần Thanh Sơ.
2. Túi gấu + hạt Xích Viêm Hoa.
3. Cửu Thiên Tinh Thần Phiên + hạt U Hồn Hoa.
4. Bộ đan tu luyện: Tụ Khí Hoàn + Đoán Thể Hoàn + Trúc Cơ Đan.
5. Ngọc quý: ngọc vàng ×7 + xanh lá ×7 + cam ×7 (`yellowgem`, `greengem`, `orangegem`).

Không đưa lại các gói này bằng cách đổi tên hoặc ghép vào gói khác. Ba gói đan riêng Tẩy Tủy Hoàn, Hóa Tinh Đan và Vân Trung Đan vẫn giữ.

### Điều chỉnh số lượng mới nhất của người dùng

- **Bỏ toàn bộ gói Ngọc quý** theo yêu cầu mới nhất; quyết định này thay thế lựa chọn giữ 7 viên mỗi màu trước đó.
- Thạch dê điện giữ **7**, bỏ đề xuất giảm còn 3. Phần Lạc Hương Phanh Nhục ×2 của gói hợp nhất vẫn giữ theo đề xuất trước đó.
- Các số lượng còn lại giữ theo bảng đã thảo luận; không suy ra yêu cầu phục hồi toàn bộ số lượng của bản hiện tại.

## 2. Nhóm Khá — 21 gói đề xuất đang duyệt

Giữ **một gói có cả sáu bùa**, theo nhóm Khá của Tu Tiên 18.1.0 hiện tại; không tách thành hai gói như bản chỉnh cũ và không chuyển lên Hiếm.

| Vật phẩm | Số lượng |
|---|---:|
| `blueamulet` | 1 |
| `greenamulet` | 1 |
| `purpleamulet` | 1 |
| `orangeamulet` | 1 |
| `yellowamulet` | 1 |
| Life Giving Amulet — `amulet` | 1 |

Ngoài gói sáu bùa và các quyết định loại gói, nội dung nhóm Khá vẫn đang duyệt. Việc giữ gói sáu bùa không chốt tỷ lệ cũ 0,7519%/lượt cho bảng mới.

### Bảng hợp nhất sau yêu cầu thêm đồ Solo

Người dùng đã yêu cầu thêm vật phẩm Solo. Bốn gói Solo ở cuối bảng và số lượng của chúng là phương án cụ thể do trợ lý đề xuất để duyệt, chưa được chốt riêng. Các số lượng khác kế thừa bảng 22 gói đã trình bày, trừ các gói người dùng yêu cầu loại.

| # | Gói | Phần thưởng đề xuất |
|---|---|---|
| 1 | Nhất Vũ Phương Hoa | Vũ khí ×1 + hạt Hàn Sương Thảo ×3 |
| 2 | Thần Hi Quang Trượng | Trượng ×1 + Đá Sa Mạc ×3 |
| 3 | Ngư Long Đăng | Trang bị ×1 + Linh Thạch Hạ Phẩm ×20 |
| 4 | Chưởng Thiên Bình | Bình ×1 + hạt Lạc Thần Hoa ×2 |
| 5 | Di tích | Giáp Thulecite ×3 + mũ Thulecite ×3 + Thulecite ×3 |
| 6 | Mùa mưa | Mũ Eyebrella ×2 + Lạc Hương Phanh Nhục ×2 |
| 7 | Linh thực | Kẹo đậu `jellybean` ×10 + Lạc Thần Thanh Sơ ×3 |
| 8 | Chiến lợi phẩm | Mắt Deerclops ×1 + lông Bearger ×1 + Niết Bàn Huyết Tủy Trúc ×3 |
| 9 | Vảy và da | Vảy Dragonfly ×1 + da nấm ×1 |
| 10 | Làm vườn | Xẻng Brightshade ×1 + mầm cây quả đá ×5 + hạt Lạc Thần Hoa ×2 |
| 11 | Vân Mạc Thượng Trang | Trang bị ×1 + Xích Viêm Hoa ×3 |
| 12 | Sáu bùa — đã chốt | `blueamulet`, `greenamulet`, `purpleamulet`, `orangeamulet`, `yellowamulet`, `amulet`: mỗi loại ×1 |
| 13 | Linh thực đóng gói | Lạc Hương Phanh Nhục ×3 + Lạc Thần Thanh Sơ ×3 + `bundlewrap` ×7 |
| 14 | Công cụ mặt trăng | Cuốc Brightshade ×1 + rìu kính trăng ×4 |
| 15 | Chìa khóa và mỏ biển | Chìa khóa Klaus ×1 + mỏ Malbatross ×1 |
| 16 | Bữa ăn tiếp tế | `bonestew` ×2 + bánh thanh long ×5 + Pierogi ×5 |
| 17 | Kem | Kem ×10 |
| 18 | Linh Thạch Solo — mới, đề xuất | `hh_essence` ×10 |
| 19 | Vật liệu thuộc tính Solo — mới, đề xuất | Giấy Thuộc Tính `hh_effect_tally` ×3 + Lục Bảo Thạch `hh_remove_stone` ×2 |
| 20 | Đá Thuộc Tính Solo — mới, đề xuất | `hh_effect_stone` ×2 |
| 21 | Phúc Lạc Dược II — mới, đề xuất | `nn_liquidluck_2` ×1 |

**Nguồn xác minh đồ Solo:** source Solo Leveling 2.2.7 tại `3780347550/modinfo.lua`, `main/hh_string.lua`, `scripts/prefabs/hh_prefabs.lua` và `scripts/prefabs/wb_strengthen_food.lua`. Bốn gói mới dùng các prefab có trong Solo gốc, không suy ra nguồn gốc chỉ từ bản port Thần Khí. Đây là kiểm tra source, chưa xác nhận entity cuối cùng khi bật đồng thời Solo và Thần Khí.

`hh_essence` là Linh Thạch Solo, khác với `xd_lingshi*` của Tu Tiên; không quy đổi hoặc coi việc thêm gói này là khôi phục gói Trung Phẩm đã bỏ. Hai Đá Thuộc Tính phải giữ dữ liệu riêng theo prefab thực tế, không ép gộp stack. Chưa chốt tỷ lệ hoặc xác nhận cân bằng cho bốn gói mới.

### Gói đã loại khỏi nhóm Khá

- **Linh thạch hoàn thưởng: Trung Phẩm Linh Thạch ×2** (`xd_lingshi2`) — bỏ theo yêu cầu người dùng ngày 08/10/2026.
- Không dùng lại gói tương ứng từ bản cũ (`ttk_lingshi2` ×2) để thay thế.
- **Kiếm bóng tối:** Dark Sword `nightsword` ×4.
- **Phòng tuyến:** Trượng Lốc Xoáy `staff_tornado` ×2 + `deerclopseyeball_sentryward_kit` ×1.
- **Kho báu:** `chestupgrade_stacksize` ×1 + Linh Thạch Hạ Phẩm ×30.
- **Thuyền:** `boat_item` ×1 + `boatpatch` ×10 + `boat_rotator_kit` ×1.
- Bảng gộp ban đầu 22 gói, bỏ gói hoàn thưởng còn 21, bỏ thêm bốn gói trên còn **17**, thêm bốn gói Solo đề xuất thành **21**. Loại toàn bộ nội dung của các gói đã bỏ; không tự đưa lại các món đó vào gói khác. Các món thuộc gói khác vẫn giữ để duyệt, gồm Linh Thạch Hạ Phẩm ×20 đi kèm Ngư Long Đăng và mỏ Malbatross ở gói Chìa khóa và mỏ biển.
- Các gói còn lại chưa được chốt toàn bộ; không tự phân bổ lại tỷ lệ ở bước này.

## 3. Nhóm Thường — 30 gói đề xuất đang duyệt

Giữ 24 gói từ bảng 30 gói đã trình bày; loại toàn bộ sáu gói người dùng chỉ định và thêm sáu gói Solo. Người dùng đã chọn năm gói Giấy Thuộc Tính, Lục Bảo Thạch, Phúc Lạc Dược I, Thuốc Tái Sinh Solo và Thuốc Ma Lực Solo, mỗi gói ×2. Linh Thạch Solo ×3 vẫn là đề xuất. Không xem việc chuyển sang nhóm Thường là chốt các đề xuất còn mở của nhóm Khá.

| # | Gói | Phần thưởng đề xuất |
|---|---|---|
| 1 | Linh thực Lạc Thần | Lạc Thần Thanh Sơ ×2 + Lạc Hương Phanh Nhục ×2 |
| 2 | Hạt dưỡng sinh | Hạt Hàn Sương Thảo ×4 + hạt Xích Viêm Hoa ×4 |
| 3 | Hạt dưỡng thần | Hạt Thanh Phong Tiên ×4 + hạt U Hồn Hoa ×4 |
| 4 | Hạt dưỡng khí | Hạt Địa Mạch Sâm ×4 + hạt Lôi Minh Quả ×4 |
| 5 | Linh thảo băng hỏa | Hàn Sương Thảo ×3 + Xích Viêm Hoa ×3 + hạt Địa Mạch Sâm ×3 |
| 6 | Địa Mạch Sâm | Linh thảo ×4 + hạt ×3 |
| 7 | Thanh Phong Tiên | Linh thảo ×3 + hạt ×4 |
| 8 | Lôi Minh Quả | Linh thảo ×3 + hạt ×4 |
| 9 | U Hồn Hoa | Linh thảo ×3 + hạt ×4 |
| 10 | Vườn Lạc Thần | Hạt Lạc Thần Hoa ×2 + Lạc Thần Hoa Nhân ×3 |
| 11 | Nguyên liệu Tu Tiên | Đuôi Linh Hồ ×3 + Tà Sát Bộ Túc ×2 + Niết Bàn Huyết Tủy Trúc ×3 |
| 12 | Linh khí dự trữ | Hạ Phẩm Linh Thạch ×30 + Lạc Thần Thanh Sơ ×2 |
| 13 | Ngọc sơ cấp | Ngọc đỏ ×1 + ngọc xanh dương ×1 + hạt Lôi Minh Quả ×3 |
| 14 | Hồi sinh | `amulet` ×1 + tim hồi sinh ×2 + hạt Địa Mạch Sâm ×3 |
| 15 | Mắt và sinh lực | Mặt nạ mắt ×1 + Booster Shot ×3 + Lạc Thần Thanh Sơ ×2 |
| 16 | Mandrake | Mandrake ×1 + súp Mandrake ×1 |
| 17 | Sừng cổ đại | Sừng Ancient Guardian ×1 + Tà Sát Bộ Túc ×2 |
| 18 | Khai khoáng | `multitool_axe_pickaxe` ×2 + kính trăng ×12 |
| 19 | Thuyền trưởng | `polly_rogershat` ×1 + hạt Hàn Sương Thảo ×3 |
| 20 | Nhện đồng hành | Trứng nhện ×2 + mũ nhện ×1 + Tà Sát Bộ Túc ×2 |
| 21 | Mũ hải mã | Tam o' Shanter ×1 + hạt Thanh Phong Tiên ×3 |
| 22 | Dịch chuyển | Đá Sa Mạc ×6 + hạt U Hồn Hoa ×3 |
| 23 | Nguyên liệu ma thuật | Gỗ sống ×6 + sậy ×20 |
| 24 | Hồi phục | Thuốc đắp mật ong ×3 + kẹo kéo ×6 |
| 25 | Linh Thạch Solo — mới, đề xuất | `hh_essence` ×3 |
| 26 | Giấy Thuộc Tính — mới, đã chọn ×2 | `hh_effect_tally` ×2 |
| 27 | Lục Bảo Thạch — mới, đã chọn ×2 | `hh_remove_stone` ×2 |
| 28 | Phúc Lạc Dược I — mới, đã chọn ×2 | `nn_liquidluck` ×2 |
| 29 | Thuốc Tái Sinh Solo — mới, đã chọn ×2 | `hh_thuoc_tai_sinh` ×2 |
| 30 | Thuốc Ma Lực Solo — mới, đã chọn ×2 | `hh_thuoc_ma_luc` ×2 |

### Sáu gói đã loại theo yêu cầu

- **Công cụ vàng:** chĩa, xẻng, cuốc chim và rìu vàng, mỗi loại ×2.
- **Làm ruộng:** cuốc vàng ×2 + bộ cày đất ×1.
- **Soi hang:** kính Molegles ×1 + sừng dê điện ×3.
- **May vá:** da heo ×5 + bộ kim chỉ ×4.
- **Muối:** muối ×20.
- **Nuôi ong và nấu ăn:** sáp tổ ong ×4 + bơ ×1.

Loại toàn bộ nội dung của sáu gói, không chuyển các món đã loại sang gói khác. Gói Khai khoáng dùng công cụ đa năng và gói Hồi phục có thuốc đắp mật ong vẫn nằm trong danh sách đề xuất, vì không thuộc sáu gói được chỉ định.

### Nguồn và những điểm chưa chốt

- Vật phẩm Solo đối chiếu với `3780347550/main/hh_string.lua`, `scripts/prefabs/hh_prefabs.lua`, `scripts/prefabs/wb_strengthen_food.lua`, `scripts/dungeon_shop/hh_dungeon_shop_defs.lua` và `scripts/prefabs/hh_dungeon_potion.lua`.
- Dùng đúng `prefab_id` cho hai thuốc: `hh_thuoc_tai_sinh`, `hh_thuoc_ma_luc`; không dùng `prefab` minh họa trong bảng shop (`healingsalve`, `nightmarefuel`) làm phần thưởng thay thế.
- Theo yêu cầu ngày 08/10/2026, năm gói Solo ở dòng 26–30 tăng từ ×1 lên ×2. Linh Thạch Solo giữ đề xuất ×3. So với Khá, Thường có ít Linh Thạch và Giấy Thuộc Tính hơn, Lục Bảo Thạch bằng nhau (×2); Phúc Lạc Dược I ×2 so với cấp II ×1. Chưa xác nhận cân bằng kinh tế hoặc hiệu ứng khi bật cả Solo và Thần Khí.
- Thuốc Solo được xác minh trong source; phải kiểm tra khả dụng và tác dụng trên nhân vật thực tế trước triển khai, đặc biệt cơ chế mana Solo và mana Tu Tiên.
- Mức 33,3333% vào nhóm Thường mới là tỷ lệ nguồn để tham chiếu. Chưa chốt trọng số, tỷ lệ từng gói hoặc chính sách khi thiếu Solo.
- Gói Hạ Phẩm ×30 và gói có `amulet` vẫn là đề xuất đang duyệt. Quyết định bỏ gói Trung Phẩm ở Khá không tự loại chúng.
- Bảng đề xuất chưa đưa lại sáo Pan; việc bỏ sáo Pan khỏi bản hợp nhất vẫn cần người dùng chốt.

## 4. Nhóm Boss — chốt 43 gói cho máy quay trên đất liền

Ngày 08/10/2026, người dùng yêu cầu tự xử lý các Boss không phù hợp và hoàn thành phần Boss. Sau rà soát source DST build **756039** và Solo **2.2.7**, chốt **43 gói** từ danh sách 53 gói: **14 gói hiện tại + 9 gói DST mới + 13 gói Solo + 7 gói mini-boss/biến thể**. Mười gói bị loại được ghi riêng bên dưới, không tham gia quay.

Số lượng giữ như bảng: Boss mới ×1, Twins mỗi con ×1; giữ các gói cũ có nhiều con. Hoàn tất lựa chọn nội dung và phương án gọi cho nhóm Boss ở mức plan. **Chưa triển khai runtime, chưa xác nhận bằng engine/game.** Tỷ lệ nhóm/trọng số từng gói thuộc bước chốt tỷ lệ chung sau nhóm Quái.

### 4.1. Các gói giữ từ bản hiện tại — 14 gói

| # | Boss | Prefab và số lượng |
|---|---|---|
| 1 | Bee Queen | `beequeen` ×1 |
| 2 | Dragonfly | `dragonfly` ×1 |
| 3 | Bearger + Deerclops | `bearger` ×1 + `deerclops` ×1 |
| 4 | Spider Queen | `spiderqueen` ×2 |
| 5 | Armored Bearger | `mutatedbearger` ×1 |
| 6 | Crystal Deerclops | `mutateddeerclops` ×1 |
| 7 | Possessed Varg | `mutatedwarg` ×2 |
| 8 | Bộ ba cờ bóng tối | `shadow_knight` ×1 + `shadow_bishop` ×1 + `shadow_rook` ×1 |
| 9 | Klaus | `klaus` ×1 |
| 10 | Celestial Champion giai đoạn 3 | `alterguardian_phase3` ×1 |
| 11 | Ancient Guardian | `minotaur` ×1 |
| 12 | Brightshade | `lunarthrall_plant` ×3 |
| 13 | Kim Phượng Thần Niệm | `xd_jfsn` ×1 |
| 14 | Kỳ Lân Tàn Hồn | `xd_qlch` ×1 |

### 4.2. Boss DST bổ sung — 9 gói

| # | Boss | Prefab và số lượng |
|---|---|---|
| 15 | Moose/Goose | `moose` ×1 |
| 16 | Antlion | `antlion` ×1 |
| 17 | Toadstool | `toadstool` ×1 |
| 18 | Misery Toadstool | `toadstool_dark` ×1 |
| 19 | Eye of Terror | `eyeofterror` ×1 |
| 20 | Twins of Terror | `twinofterror1` ×1 + `twinofterror2` ×1 |
| 21 | Nightmare Werepig | `daywalker` ×1 |
| 22 | Scrappy Werepig | `daywalker2` ×1 |
| 23 | Great Depths Worm | `worm_boss` ×1 |

### 4.3. Boss Solo — 13 gói

| # | Boss | Prefab / cấu hình triệu hồi | Số lượng |
|---|---|---|---|
| 24 | Igris | `hh_igris_dungeon` | ×1 |
| 25 | Beru | `hh_beru_dungeon` | ×1 |
| 26 | Super Frostjaw | `hh_sharkboi` | ×1 |
| 27 | Lợn Rừng Bọ Hung | `hh_beetle_pig` | ×1 |
| 28 | Siêu Lợn Song Kiếm | `hh_dual_wield_pig` | ×1 |
| 29 | Multiverse Guardian | `minotau` — khác `minotaur` của DST | ×1 |
| 30 | Super MacTusk | `walrus` + treasure ID `walrus_adc` | ×1 |
| 31 | Super Crystal Deerclops | `mutateddeerclops` + treasure ID `mutateddeerclops_boss` | ×1 |
| 32 | Super Armored Bearger | `mutatedbearger` + treasure ID `mutatedbearger_boss` | ×1 |
| 33 | Super Mutated Warg | `mutatedwarg` + treasure ID `mutatedwarg_boss` | ×1 |
| 34 | Super Frostjaw — bản kho báu | `hh_sharkboi` + treasure ID `hh_sharkboi_boss` | ×1 |
| 35 | Super Krampus | `krampus` + treasure ID `treasure_kps` | ×1 |
| 36 | Super Catcoon | `catcoon` + treasure ID `treasure_cat_you` | ×1 |

### 4.4. Mini-boss và biến thể chiến đấu — 7 gói

| # | Boss / biến thể | Prefab và số lượng |
|---|---|---|
| 37 | Lord of the Fruit Flies | `lordfruitfly` ×1 |
| 38 | Treeguard | `leif` ×1 |
| 39 | Treeguard — cây thưa | `leif_sparse` ×1 |
| 40 | Varg | `warg` ×1 |
| 41 | Clay Varg | `claywarg` ×1 |
| 42 | Gingerbread Varg | `gingerbreadwarg` ×1 |
| 43 | Reanimated Skeleton — hang | `stalker` ×1 |

### 4.5. Mười gói loại khỏi bản quay trên đất

| Boss / prefab | Lý do và quyết định |
|---|---|
| Malbatross — `malbatross` | AI `ShouldLeaveLand` phát `depart` khi ở trên đất hơn 5 giây. Bỏ gói, không sửa AI để ép ở lại. |
| Crab King — `crabking` | Cần khảm ngọc/kích hoạt và cơ chế biển, băng biển, thuyền. Bỏ khỏi máy quay trên đất. |
| Frostjaw DST — `sharkboi` | Có khả năng đánh trên đất nhưng vòng đời, dịch chuyển và đấu trường gắn với `sharkboimanager`. Bỏ bản DST trong bản này; giữ hai gói Super Frostjaw Solo đã có, không thêm gói trùng để bù. |
| Sharkboi dưới nước — `sharkboi_water` | Locomotor có `allowocean = true, ignoreLand = true`; không dùng trên đất. |
| Ancient Fuelweaver — `stalker_atrium` | `brains/stalkerbrain.lua` gọi `OnLostAtrium` khi không ở gần Atrium; hàm này giết Boss. Bỏ gói, không dựng Atrium hoặc tắt kiểm tra toàn cục. |
| W.A.R.B.O.T. — `wagboss_robot` | Có trạng thái tắt/thân thiện/thù địch và chuỗi chuyển sang Boss tiếp theo; ngoài phạm vi gói gọi độc lập. Bỏ gói trong bản này. |
| Celestial Revenant — `alterguardian_phase1_lunarrift` | Kết thúc bằng dạng Gestalt để bắt, thuộc chuỗi W.A.R.B.O.T.; không dùng làm gói Boss độc lập. |
| Celestial Scion — `alterguardian_phase4_lunarrift` | Kết thúc phát sự kiện thế giới `ms_wagboss_alter_defeated`, liên quan tiến trình Wagstaff. Bỏ để không kéo chuỗi thế giới vào lượt quay. |
| Ancient Guard Tower — `vault_pillar_guard` | Nhắm mục tiêu phân nhánh theo `trial` trong Vault hoặc chế độ bảo vệ người chơi khi không có trial. Không dùng như Boss thù địch độc lập nếu chưa sửa hành vi; bỏ gói trong bản này. |
| Reanimated Skeleton rừng — `stalker_forest` | Biến thể này không bật `canfight` như bản hang; có vòng đời phụ thuộc ban đêm. Bỏ; giữ `stalker` là biến thể chiến đấu. |

“Bỏ” ở đây là quyết định phạm vi của bảng thưởng trên đất. Không khẳng định các prefab này tuyệt đối không thể dùng nếu viết một hệ thống triệu hồi riêng.

### 4.6. Quy cách triệu hồi đã chốt cho bản triển khai sau

| Trường hợp | Cách xử lý bắt buộc |
|---|---|
| Mọi gói | Chạy phía server, đặt tại điểm đất hợp lệ quanh máy, không trên biển/thuyền/điểm bị chặn; kiểm tra đủ chỗ cho cả gói trước khi phát. Chỉ khởi tạo các entity của lượt này. Không đổi mùa, ngày đêm, rift hay tiến trình thế giới để ép Boss chạy. |
| Antlion | Gọi `StartCombat(người_quay)` ngay sau spawn/đặt vị trí, trước task `OnInit` ở tick 0. Hàm gốc hủy task kiểm tra bão cát và tạo combat/health. Không chỉ gọi `SpawnPrefab` rồi chờ vì Boss có thể tự rời khi không có bão cát. |
| Klaus | Đặt vị trí/home trước khi brain chạy; dùng `SpawnDeer()` đúng một lần để có cặp hươu phụ trợ, tránh Klaus thiếu helpers rồi tự cuồng nộ. Hai hươu là bộ phận của trận Klaus, không là gói quay mới; kiểm tra không tạo lặp khi tải save. |
| Nightmare Werepig | Dùng bản tự do, không gọi `MakeChained`; gọi `MakeHostile()` và đặt mục tiêu hợp lệ. Giữ cơ chế bị đánh bại ở ngưỡng máu tối thiểu của game, không ép chết để phát loot lần hai. |
| Scrappy Werepig | Prefab trực tiếp đã có combat và listener `minhealth`; không gọi `MakeBuried` hoặc tạo bãi phế liệu. Đặt mục tiêu; chỉ gọi `MakeFreed()` nếu entity thực sự có `buried`. Giữ vòng đời thất bại/loot của game. |
| Eye of Terror | Dùng entity độc lập, trạng thái đến trận của stategraph và mục tiêu hợp lệ; không gắn vào Terrarium thật hoặc bộ điều khiển sự kiện của thế giới. |
| Twins of Terror | Một `twinmanager` riêng cho lượt; gửi `arrive` với entity người quay để tạo đúng hai con, rồi `set_spawn_target`. Không vừa dùng manager vừa spawn thêm hai prefab con. Giữ entitytracker và save/load của manager để loot phối hợp không bị thiếu/lặp. |
| Toadstool, Misery Toadstool, Ancient Guardian, Great Depths Worm | Dùng prefab combat trực tiếp trên đất đủ rộng. Đặt vị trí trước khi brain/update khởi tạo, giữ các điểm home/spawnpoint và các entity con do Boss tạo. Với Worm dùng `worm_boss` làm controller, không dùng `worm_boss_dirt` thay Boss. |
| Brightshade | Prefab trực tiếp có `targetsize = "med"`, health/combat và stategraph; giữ ×3. Không gọi `infest` lên cây trồng của người chơi để bổ sung vật chủ. Kiểm tra animation, dây leo và thu hồi entity con khi thử game. |
| Kim Phượng Thần Niệm, Kỳ Lân Tàn Hồn | Giữ hai prefab đang có trong bảng Tu Tiên hiện tại. Xác minh đăng ký từ Tu Tiên đang bật, đặt vị trí trước brain và giữ home/spawnpoint theo prefab; không tự đổi sang bản pet, pháp bảo hoặc biến thể tên gần giống. |
| Bảy bản kho báu Solo | Spawn prefab ở bảng, rồi gọi `components.hh_monster:SetTreasureId(id)` đúng một lần theo cơ chế Solo. Treasure ID không phải prefab. Không spawn lại bản thường nếu thiếu component/cấu hình. |
| Igris, Beru, Super Frostjaw, hai Boss lợn Solo | Dùng prefab/brain/stategraph combat của Solo. Không dùng bản shadow/follower hoặc tự dựng hầm ngục; giữ cơ chế dọn entity khi vùng không còn được tải. Hai Boss lợn có prefab đăng ký dù lượt xuất hiện trong bảng kho báu Solo đang comment; không bật lại bảng kho báu đó. |
| Multiverse Guardian | Dùng `minotau` của Solo, khác `minotaur` DST. Giữ các phase/loot do prefab Solo quản lý; không phát loot riêng lần hai. |
| Super Krampus | Chỉ Boss ×1 có treasure ID; không tự thêm hai pigman từ sự kiện kho báu nguồn. |
| Thiếu mod/prefab hoặc không tìm được vị trí | Loại gói khỏi tập đủ điều kiện trước khi chọn/phát. Không trừ lượt mà phát thiếu một phần gói; lỗi phát giữa chừng phải thu hồi entity của lượt và hoàn chi phí. Trọng số chỉ chuẩn hóa trong tập đủ điều kiện theo chính sách chung sẽ chốt. |

### 4.7. Bằng chứng và nghiệm thu

- Nguồn game: `C:/Program Files (x86)/Steam/steamapps/common/Don't Starve Together/data/databundles/scripts.zip`, build `756039`. Các nhánh quyết định: `brains/malbatrossbrain.lua:236`, `prefabs/crabking.lua` (socket/kích hoạt/biển), `prefabs/sharkboi_water.lua` (pathcaps), `brains/stalkerbrain.lua:218`, `prefabs/stalker.lua:998`, `prefabs/antlion.lua:284`, `prefabs/klaus.lua:293`, `prefabs/daywalker.lua:939`, `prefabs/daywalker2.lua:1233`, `prefabs/eyeofterror.lua:791`, `prefabs/vault_pillar_guard.lua:247`, `prefabs/alterguardian_phase4_lunarrift.lua:807`.
- Solo: `3780347550/main/hh_assets.lua`, `main/hh_tunning.lua`, `scripts/enums/hh_boss.lua`, `scripts/prefabs/hh_boss.lua`, `scripts/prefabs/hh_beru_dungeon.lua`, `scripts/prefabs/minotau.lua`, `scripts/enums/hh_treasure_monster.lua` và `scripts/components/hh_monster.lua:616`. Bảy treasure ID đã đối chiếu với bảng cấu hình thực; hai gói `hh_sharkboi` khác nhau bởi treasure ID.
- Phân loại hoàn tất ở mức source/plan; không gọi đây là kết quả test game. Trước phát hành runtime, phải chạy từng gói: spawn → nhận mục tiêu → đánh đủ phase → kết thúc/loot → dọn entity; kiểm tra tải save và lúc người chơi rời vùng, đặc biệt các adapter trong bảng trên. Nếu gói chưa đạt nghiệm thu, không bật gói đó trong bản phát hành.
- Không thay đổi tỷ lệ vào nhóm ở bước này. Mức **7,6190%** chỉ là tỷ lệ nguồn tham chiếu; chưa chia đều 43 gói.
- Nhóm Quái loại các Boss/mini-boss trùng cấu hình; so sánh cả prefab và biến thể/treasure ID. Bản thường và Super Solo không phải cùng gói. Xem bảng hợp nhất ở mục 5; các bảng nguồn giữ nguyên để đối chiếu.

## 5. Nhóm Quái — 31 gói đề xuất đang duyệt

Đối chiếu 32 gói bản cũ với 33 gói hiện tại. Lấy số lượng bản hiện tại làm đề xuất mặc định; giữ các thành phần riêng của bản cũ như chó săn và nhện phun. Đây là bảng để người dùng duyệt, chưa chốt cả nhóm hoặc tỷ lệ.

| # | Gói | Sinh vật và số lượng đề xuất |
|---|---|---|
| 1 | Chó nguyên tố | `firehound` ×5 + `icehound` ×5 |
| 2 | Khỉ hang | `monkey` ×7 |
| 3 | Lính heo | `pigguard` ×5 |
| 4 | Sâu hang và Slurper | `worm` ×5 + `slurper` ×4 |
| 5 | Chó săn — từ bản cũ | `hound` ×3 |
| 6 | Ewecus | `spat` ×2 |
| 7 | Thợ săn hải mã | `walrus` ×3 |
| 8 | Chim cao cổ | `tallbird` ×3 |
| 9 | Quân cờ máy | `bishop` ×1 + `rook` ×1 + `knight` ×1 |
| 10 | Khỉ cướp biển | `powder_monkey` ×5 |
| 11 | Ếch | `frog` ×4 + `lunarfrog` ×2 |
| 12 | Xúc tu | `tentacle` ×8 |
| 13 | Dơi | `bat` ×10 |
| 14 | Người thỏ | `bunnyman` ×4 |
| 15 | Ong sát thủ | `killerbee` ×12 |
| 16 | Ác mộng | `crawlingnightmare` ×3 + `nightmarebeak` ×2 |
| 17 | Ruồi trái cây | `fruitfly` ×4 |
| 18 | Mèo gấu | `catcoon` ×5 |
| 19 | Nhện y tá | `spider_healer` ×5 |
| 20 | Bộ ba Ink Blight | `shadowthrall_horns` ×1 + `shadowthrall_hands` ×1 + `shadowthrall_wings` ×1 |
| 21 | Sên hang | `slurtle` ×4 + `snurtle` ×1 |
| 22 | Người nấm | `mushgnome` ×3 |
| 23 | Voi Koala | `koalefant_summer` ×1 + `koalefant_winter` ×1 |
| 24 | Mắt bay nhỏ | `eyeofterror_mini` ×6 |
| 25 | Kền kền | `buzzard` ×4 |
| 26 | Nhện hang | `spider_hider` ×4 + `spider_spitter` ×2 |
| 27 | Krampus thường | `krampus` ×2 |
| 28 | Rồng trái cây | `fruitdragon` ×5 |
| 29 | Dê điện | `lightninggoat` ×3 |
| 30 | Bầy nhện | `spider` ×5 + `spider_warrior` ×2 + `moonspider_spike` ×2 |
| 31 | Lính người cá | `mermguard` ×5 |

### Cách gộp và các thay đổi đề xuất

- Bỏ gói Brightshade ×1 khỏi Quái vì Boss đã giữ Brightshade ×3.
- Warg đã ở Boss: thay gói Warg ×2 hiện tại bằng chó săn thường ×3 vốn đi kèm Warg trong bản cũ. Không tăng thêm số gói.
- Ruồi Chúa đã ở Boss: bỏ riêng Ruồi Chúa khỏi gói, giữ ruồi trái cây thường ×4.
- Nhện hang: lấy Cave Spider ×4 hiện tại, thêm Spitter ×2 từ bản cũ vào cùng gói.
- Tạm loại gói bom bóng tối `fused_shadeling_bomb` ×6 (bản cũ ×3). Source `prefabs/fused_shadeling_bomb.lua` có tag explosive, timer nổ và sát thương vùng; đây là gói bẫy nổ. Việc loại là đề xuất để duyệt, không phải người dùng đã yêu cầu bỏ.
- Kết quả: 33 gói hiện tại − Brightshade − bom = **31 gói**. Hai gói Warg/Ruồi Chúa được sửa nội dung, không xóa thêm gói; nhện phun nhập vào gói nhện hang.
- Krampus ×2, hải mã ×3 và mèo gấu ×5 vẫn là **bản thường**. Chúng khác các gói Super Solo có treasure ID, nên không loại chỉ vì trùng prefab nền. Không gắn treasure ID lên các gói Quái này.
- Chưa tự bổ sung quái riêng Solo vào nhóm Quái; bảng này là hợp nhất hai nguồn. Người dùng có thể yêu cầu thêm/thay ở bước duyệt.
- Nhóm bao gồm sinh vật trung lập và thù địch theo hai nguồn, không mặc định tất cả sẽ tấn công người quay. Chưa kiểm thử từng gói trên đất hoặc khi bật đủ mod; bước triển khai phải kiểm tra AI, thành phần bầy đàn, save/load và entity phụ trước khi mở gói.
- **40%** là tỷ lệ vào nhóm trong cả hai bảng nguồn; chưa chốt giữ tỷ lệ này hoặc chia đều 31 gói. Không dùng lại tỷ lệ từng gói của bảng 32/33 gói cho bản hợp nhất.

Nguồn: `dst_wiki/app/duyet/may-quay-linh-thach/rewards.json` và `dst_wiki/app/duyet/may-quay-linh-thach/hien-tai/rewards.json`, nhóm `quai`; đối chiếu danh sách Boss đã chốt ở mục 4. Hai bảng wiki nguồn giữ nguyên.

## 6. Những phần tiếp tục duyệt

- [x] Gộp danh sách nhóm Hiếm, loại bốn gói và bổ sung bốn gói Thần Khí.
- [x] Bỏ gói Ngọc quý khỏi Hiếm theo yêu cầu mới nhất; giữ thạch dê điện ×7.
- [x] Thêm Shadow Atrium và Hoa Hồng Ám Ảnh vào nhóm Hiếm, tạm mỗi món ×1 trong hai gói riêng.
- [x] Giữ một gói sáu bùa, mỗi loại ×1 ở nhóm Khá.
- [x] Bỏ gói Trung Phẩm Linh Thạch ×2 khỏi nhóm Khá.
- [x] Bỏ Kiếm bóng tối, Phòng tuyến, Kho báu và Thuyền khỏi nhóm Khá.
- [x] Xác minh source Solo và bổ sung bốn gói Solo vào bảng đề xuất nhóm Khá.
- [ ] Duyệt loại vật phẩm và số lượng của bốn gói Solo mới.
- [ ] Duyệt các gói còn lại của nhóm Khá.
- [x] Loại sáu gói được chỉ định khỏi Thường và thêm sáu gói Solo vào bảng đề xuất.
- [x] Chọn năm gói Solo ở dòng 26–30 của nhóm Thường, mỗi gói ×2.
- [ ] Duyệt Linh Thạch Solo ×3 và các gói còn lại của nhóm Thường.
- [x] Bổ sung danh sách Boss DST và Solo còn thiếu theo yêu cầu; ghi rõ prefab và cấu hình các bản kho báu.
- [x] Hoàn tất nhóm Boss: 43 gói trên đất, loại 10 gói và chốt cách khởi tạo đặc biệt theo yêu cầu.
- [x] Đối chiếu nhóm Quái và ghi bảng gộp 31 gói, xử lý các Boss trùng trong bảng đề xuất.
- [ ] Duyệt nội dung, số lượng nhóm Quái và đề xuất bỏ gói bom bóng tối.
- [ ] Chốt tỷ lệ vào từng nhóm và trọng số mỗi gói; tính xác suất từng gói/lượt.
- [ ] Xác minh prefab của mọi vật phẩm bản cũ trong bộ mod đang dùng; thống nhất vật phẩm thay thế nếu thiếu.
- [ ] Chốt chi phí lượt quay và cách xử lý thiếu mod/prefab, save/load giữa lượt quay trước khi viết kế hoạch tích hợp runtime.

## Review Focus — các điểm cần kiểm tra trước triển khai

- Boss có đúng 43 gói; 10 gói loại không xuất hiện trong pool. Antlion/Twins/Klaus/Werepig/Solo treasure phải đi qua cách khởi tạo riêng đã ghi, không phát như vật phẩm đơn thuần.

- Đúng 24 gói Hiếm, gồm `shadowheart` và `xd_aymg`; không tái xuất hiện năm gói đã loại.
- Không còn gói Ngọc quý trong bảng Hiếm; gói thạch vẫn có `voltgoatjelly` ×7.
- Gói bùa nằm ở Khá và phát đủ sáu prefab khác nhau, mỗi loại ×1.
- Tên vật phẩm giống nhau giữa hai mod không chứng minh prefab hoặc tác dụng tương đương; kiểm tra registry và entity thực tế.
- Tỷ lệ đã chuẩn hóa phải khớp bảng được duyệt; tách rõ xác suất vào nhóm và xác suất gói trong một lượt. Kiểm tra bằng source/mock không được báo là xác nhận bằng game.
