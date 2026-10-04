# Danh mục tượng quân cờ và perk Chiến lợi phẩm danh dự

Đối chiếu mã **Thành Tựu Tu Tiên** trong workspace và `scripts.zip` của **Don't Starve Together** đang cài trên máy, ngày 04/10/2026. Tài liệu này mô tả hành vi của **perk Toàn cầu “Chiến lợi phẩm danh dự” (`groundedscream`, 25 Sao)**, toàn bộ **46 mẫu tượng được mod đăng ký**, phác thảo/bản vẽ tương ứng và công thức tạc tượng. Tên prefab được giữ nguyên để tìm đúng món trong game hoặc mã nguồn.

## Đọc nhanh: perk và cách tạc tượng

- Khi đã mở perk, mod xét **tượng đang được đặt trong thế giới hiện tại**, theo **mẫu + chất liệu**. Không có phép đo khoảng cách đến nhân vật. Cùng một mẫu/chất liệu chỉ cần **ít nhất một tượng**; dựng thêm tượng giống hệt không nhân hiệu ứng. Mặt đất và hang là các thế giới riêng, nên tượng ở mặt đất không được kiểm tra như tượng trong hang.
- Ba chất liệu: **đá** = `stone` (dùng `cutstone` ở Bàn xoay gốm), **cẩm thạch** = `marble`, **kính trăng** = `moonglass`. Chúng là ba hiệu ứng khác nhau. Một mẫu không có tác dụng riêng ở một chất liệu sẽ được ghi `—`.
- Bàn xoay gốm (`sculptingtable`) cần **2 đá cắt + 2 ván + 4 cành** để dựng. Công thức mỗi tượng trong game là **2 đơn vị nguyên liệu điêu khắc tương ứng + 2 đá thường (`rocks`)**. Đưa chất liệu vào bàn, rồi chọn mẫu. Công thức `chesspiece_<mẫu>_builder` là **một công thức cho cả ba chất liệu**, không phải ba bản vẽ khác nhau.
- **44/46 mẫu** cần phác thảo `chesspiece_<mẫu>_sketch` để Bàn xoay gốm học mẫu. **Sừng sung túc (`hornucopia`) và ống tẩu (`pipe`)** có công thức điêu khắc sẵn, không có vật phẩm sketch riêng trong danh sách game. Đưa phác thảo vào **bàn cần dùng**; nó mở mẫu cho bàn đó qua `craftingstation:LearnItem`, không phải một perk Sao mới.
- Bảng bên dưới nêu **nguồn chính được xác nhận trong mã game**. Chữ “boss rơi” chỉ bảng rơi gắn với boss, không khẳng định người chơi luôn nhận được nếu mã có thêm điều kiện riêng. Nguồn sự kiện chỉ có trong sự kiện tương ứng.

### Quy tắc chung áp dụng thêm cho một số tượng

**Đá chung (chiến đấu).** Nếu mục tiêu khớp mẫu tượng đá đã đặt: đòn đánh thường của **người chơi lên mục tiêu** được nhân **1,5**; sát thương thường **mục tiêu gây lên người chơi** được nhân **0,5**. Mỗi chiều chỉ lấy một khóa tượng khớp, không nhân chồng theo số tượng. Mã dùng `groundedregistry:Exist` trực tiếp cho nhánh này.

**Cẩm thạch chung (EXP hạ gục).** Hạ mục tiêu khớp tượng cẩm thạch làm **EXP hạ gục cơ sở của mục tiêu ×2**, rồi mới qua các hệ số EXP khác. Nhánh này khớp **prefab mục tiêu**, không dùng danh sách tag mở rộng. Nó cũng chỉ kiểm tra tượng tồn tại trong registry.

**Lưu ý về mã hiện tại:** hai quy tắc chung ở trên **không kiểm tra trạng thái đã mua perk** ở chính nơi tính sát thương/EXP. Vì thế có thể có hiệu ứng chỉ nhờ đặt tượng, ngay cả khi chưa mở perk. Các hiệu ứng riêng ở phần lớn bảng bên dưới thì gọi hàm kiểm tra perk. Đây là mô tả mã hiện tại, không phải lời khẳng định cơ chế được thiết kế như vậy. [Mã sát thương](../Achivement_Steam_2026-09-27/main_globalpostInits.lua) · [Mã EXP và ánh xạ mục tiêu](../Achivement_Steam_2026-09-27/scripts/functions/helperfunctions.lua).

## 21 mẫu có hiệu ứng riêng

Mỗi dòng là **một mẫu tượng**, với ba cột chất liệu. Nếu một chất liệu có “quy tắc chung” thì tác dụng đó **cộng với** hiệu ứng riêng ghi trong ô. Phác thảo đặt trong cột cuối là **mã vật phẩm**; tên đầy đủ luôn là `chesspiece_<mã mẫu>_sketch`.

| Mẫu / prefab `chesspiece_…` | Đá (`stone`) | Cẩm thạch (`marble`) | Kính trăng (`moonglass`) | Phác thảo và cách lấy |
|---|---|---|---|---|
| Quân tốt `pawn` | Người theo player nhận **gấp đôi thời gian trung thành được cộng**. | Khi nhận người theo, sát thương người theo **×1,5**. | Khi nhận người theo, sát thương họ chịu **×0,5**. | `pawn_sketch`: có trong bảng rơi bụi cỏ lăn hoặc tượng cẩm thạch Pawn có sẵn bị phá. |
| Xe `rook` | **Đá chung** với sinh vật có tag `rook`. | Đặt hoặc sửa tường đủ điều kiện: **+5 EXP** mỗi lần. | Quái không chọn tường làm mục tiêu và không thể tấn công tường qua hai hàm combat được sửa. | `rook_sketch`: đổi trinket **28/29** qua hệ thống `tradefor` của game. |
| Mã `knight` | **Đá chung** với sinh vật có tag `knight`. | Giáp của người chơi nhận sát thương: người sở hữu nhận EXP bằng **10% lượng sát thương giáp được báo**. | Giáp người chơi hao **50% lượng độ bền** trong `Armor:TakeDamage`. | `knight_sketch`: đổi trinket **30/31**. |
| Tượng `bishop` | **Đá chung** với sinh vật có tag `bishop`. | Thời gian người chơi bị điện giật **×0,5**. | **25%** chống một lần xét điện giật. | `bishop_sketch`: đổi trinket **15/16**. |
| Nữ hoàng `muse` | **80%** bỏ qua một lần tấn công của quái bóng tối `grue`. | Khi vào **trăng non**, xóa danh sách Touch Stone đã dùng của người chơi. | Khi vào trăng non, nấm mồ đã đào được thiết lập lại để có thể đào tiếp. | `muse_sketch`: bụi cỏ lăn hoặc tượng cẩm thạch Muse có sẵn bị phá. |
| Vua `formal` | **Đá chung** với sinh vật có tag `shadowcreature`. | Hạ quái bóng tối có `sanityreward > 0`: cộng thêm **2 lần** phần thưởng tinh thần gốc, tức tổng thường là **3 lần** nếu phần thưởng gốc vẫn được trao. | Quái bóng tối được hiển thị với alpha đầy đủ thay vì mờ theo tinh thần. | `formal_sketch`: bụi cỏ lăn hoặc phá tượng Maxwell. |
| Sừng sung túc `hornucopia` | EXP do ăn món có giá trị no dương và EXP thao tác nấu trong mã mod **×2**. | Vật phẩm rơi từ rau củ khổng lồ **3 lượt rơi** thay vì 1 khi `DropLoot` được gọi. | Thu hoạch nồi nấu nhận **thêm 1 thành phẩm** cùng loại, thành tổng 2; áp dụng cả stacksize của công thức. | **Không cần sketch**; công thức mở sẵn tại Bàn xoay gốm. |
| Ống tẩu `pipe` | Đổi trinket có giá trị vàng với Vua Lợn: nhận EXP bằng **giá trị vàng** của trinket. | Đào gốc cây: **20%** nhận 1 trinket ngẫu nhiên. | Khi tính điểm trinket đã trang bị, số lượng stack được tính **gấp đôi**, vẫn chịu mức trần của từng tác dụng trinket. | **Không cần sketch**; công thức mở sẵn tại Bàn xoay gốm. |
| Chó săn đất sét `clayhound` | **Đá chung** với sinh vật có tag `hound`. | Chó săn theo player được thêm **50% cơ hội né** và **50% cơ hội chí mạng**, đồng thời **+50% sát thương chí mạng** trong nhánh tính crit. | Trên **mặt đất**, thời gian cơ sở đến đợt chó săn tiếp theo **×5**; phần dao động được giữ nguyên. | `clayhound_sketch`: sự kiện dâng lễ chó sói, **8 `lucky_goldnugget`**. |
| Sói đất sét `claywarg` | Con mồi từ tuyến săn có tag `cz_spawnedforhunt` nhận **Đá chung**; mã gắn tag khi sinh nếu tượng đã tồn tại lúc prefab được khởi tạo. | Giới hạn số cuộc săn đồng thời trong `hunter`/`bosshunter` **×2**. | — | `claywarg_sketch`: sự kiện dâng lễ chó sói, **16 `lucky_goldnugget`**. |
| Bướm trăng `butterfly` | Bật hệ thống sinh **bướm trăng** của mod quanh người chơi đủ điều kiện. | Hồi máu từ **suối nước nóng** (`cause="hotspring"`) **×3**. | Khi rơi vật phẩm từ cây trăng cao: thử **3 lần**, mỗi lần **50%** thêm 1 `driftwood_log` (0–3 khúc). | `butterfly_sketch`: chế bằng **1 papyrus** ở công nghệ **Celestial cấp 3**. |
| Mỏ neo `anchor` | Khi người chơi đuối nước, hàm xác định sát thương đuối nước trả bảng rỗng; theo nhánh này người chơi **không chịu sát thương đuối nước**. | Với thân thuyền loại tương ứng, hệ số sát thương **va chạm bằng 0**; không chặn mọi loại sát thương lên thuyền. | Sát thương dương lên cầu cảng qua `dockmanager:DamageDockAtTile` bị đổi thành **0**. | `anchor_sketch`: chế bằng **1 papyrus** ở công nghệ **Seafaring cấp 2**. |
| Mặt trăng `moon` | Khi khối đá có tag `boulder` tạo loot: thử **3 lần**, mỗi lần **50%** thêm 1 `moonrocknugget` (0–3 mảnh). | Lúc **trăng tròn**, đòn người chơi thêm thành phần **30% cơ hội chí mạng** và **+30% sát thương chí mạng** trong hệ thống crit của mod. | Khi bắt đầu trăng tròn, mỗi đối tượng trồng/trồng lại đủ điều kiện có **20%** được kích hoạt một bước tăng trưởng tức thì. | `moon_sketch`: **1 papyrus**, **Celestial cấp 3**. |
| Carrat `carrat` | Mở công thức **cà rốt trồng** (`carrot_planted_perk`), tốn **1 Carrat**. | Khi bắt đầu nấu với **ít nhất 2 cà rốt** trong nguyên liệu: hoàn lại ngẫu nhiên **1 đến số cà rốt trừ 1**. | Bộ đếm tái mọc `carrot_planted` tăng với `timemult` **×5**, tức tái mọc nhanh hơn theo `regrowthmanager`. | `carrat_sketch`: lễ dâng Carrat, **8 `lucky_goldnugget`**. |
| Beefalo `beefalo` | **Đá chung** với sinh vật có tag `beefalo`. | Beefalo đang động dục không chọn người chơi có hiệu ứng làm mục tiêu qua hàm `retarget`. | Beefalo **đang được cưỡi** hồi máu `cause="regen"` **×5**. | `beefalo_sketch`: lễ dâng Beefalo, **8 `lucky_goldnugget`**. |
| Kitcoon `kitcoon` | Khi thú cưng ăn thức ăn do người chơi đưa, chủ của nó nhận **phần máu/no/tinh thần dương** mà món ăn sẽ cho chủ. Chỉ cộng giá trị >0. | Chế công thức nhận thú cưng `critter_*_builder`: hoàn **1 đơn vị** của một nguyên liệu hợp lệ được chọn theo trọng số lượng nguyên liệu. | — | `kitcoon_sketch`: lễ dâng Catcoon, **8 `lucky_goldnugget`**. |
| Catcoon `catcoon` | Sửa chu kỳ nhả hairball của Catcoon trong state `hairball`: thay đổi `hairball_friend_interval` và `hairball_neutral_interval` (lượt đầu đặt 1, lượt sau nhân 0,25); không phải cộng thẳng vật phẩm vào túi. | Sau khi đàn cá tự nhiên đã sinh thành công, **50%** tạo thêm một đàn cá loại `oceanfish_medium_6` hoặc `_7` (chọn đều), nếu tìm được chỗ dưới nước. | Khi chim bay đi, nếu trong bán kính **1** chưa có hạt giống: **50%** thử sinh thêm qua `periodicspawner`. | `catcoon_sketch`: lễ dâng Catcoon, **8 `lucky_goldnugget`**. |
| Người thỏ `manrabbit` | Người chơi được xem như có tag `hidesmeats` trong kiểm tra kho đồ, giúp che thịt khỏi cơ chế xét tag tương ứng. | Người thỏ theo player thêm **50% cơ hội né**, **50% cơ hội chí mạng** và **+50% sát thương chí mạng**. | Người chơi có thể ngủ trong **Rabbit House** qua hành động được mod mở. | `manrabbit_sketch`: lễ dâng Rabbit, **8 `lucky_goldnugget`**. |
| Tháp Rồng `yotd` | Khi người chơi đang cháy: tốc độ đi **×1,5**; bỏ hệ số khi lửa tắt. | Khi đang cháy: sát thương chiến đấu **×1,5**; bỏ hệ số khi lửa tắt. | Hệ số sát thương do cháy lên người chơi **×0,5**. | `yotd_sketch`: lễ dâng Dragon, **8 `lucky_goldnugget`**. |
| Sâu vực `yots` | Ăn `wormlight` hoặc `wormlight_lesser` không bị phần giảm tinh thần của món đó theo `GetSanityFn` đã sửa. | Mở công thức **1 `wormlight` từ 2 `wormlight_lesser`**. | Trong **hang**, thời gian cơ sở đến đợt tấn công hound **×5**; phần dao động giữ nguyên. | `yots_sketch`: lễ dâng Worm, **8 `lucky_goldnugget`**. |
| Kỵ sĩ mạ vàng `yoth` | Điểm may mắn (`GetEntityLuck`) của người chơi **−3**. Đây là **giảm**, theo đúng mã. | Điểm may mắn **+3**. Nếu đặt cả đá và cẩm thạch, hai phần cộng/trừ triệt tiêu nhau. | Giới hạn hệ số may mắn tối đa trong công thức cơ hội rơi vật phẩm của mod **×2**; không nhân đôi trực tiếp mọi món rơi. | `yoth_sketch`: lễ dâng Knight, **8 `lucky_goldnugget`**. |

### Cụ thể về “Đá chung” và “Cẩm thạch chung” của bảng trên

- `rook`, `knight`, `bishop`, `formal`, `clayhound`, `claywarg`, `beefalo` được ánh xạ qua **tag** ở nhánh sát thương, nên có “Đá chung” khi tag tương ứng khớp. `claywarg` dùng tag của sinh vật từ cuộc săn đặc biệt.
- Trong nhánh EXP hạ gục, các mẫu này **không tự động có “Cẩm thạch chung” nhờ tag**, vì hàm gọi không bật `include_tags`. Hiệu ứng cẩm thạch riêng trong từng ô vẫn áp dụng.

## 25 mẫu boss/quái có hiệu ứng theo quy tắc chung

Với **mọi mẫu trong bảng này**: tượng **đá** áp dụng “Đá chung” **lên đúng mục tiêu trong cột 2**; tượng **cẩm thạch** áp dụng “Cẩm thạch chung” khi hạ đúng mục tiêu đó; tượng **kính trăng chưa có hiệu ứng riêng** trong perk này. Phác thảo có mã `chesspiece_<mã mẫu>_sketch` và mở công thức tại Bàn xoay gốm như phần đầu. “Chưa có hiệu ứng riêng” không có nghĩa tượng không thể có chức năng khác ngoài perk của mod.

| Mẫu / prefab `chesspiece_…` | Mục tiêu được ánh xạ trong mã | Nguồn phác thảo được xác nhận |
|---|---|---|
| `deerclops` | `deerclops` | Bảng rơi Deerclops. |
| `bearger` | `bearger` | Bảng rơi Bearger. |
| `moosegoose` | `moose` (Moose/Goose) | Bảng rơi Moose/Goose. |
| `dragonfly` | `dragonfly` | Bảng rơi Dragonfly. |
| `crabking` | `crabking`, **trừ** biến thể có tag `chasni_crabqueen` | Bảng rơi Crab King. |
| `malbatross` | `malbatross` | Bảng rơi Malbatross. |
| `toadstool` | `toadstool`, `toadstool_dark` | Bảng rơi Toadstool. |
| `stalker` | `stalker_atrium` | Bảng rơi Ancient Fuelweaver/Stalker Atrium. |
| `klaus` | `klaus` | Bảng loot Klaus. |
| `beequeen` | `beequeen` | Bảng rơi Bee Queen. |
| `antlion` | `antlion` | Bảng rơi Antlion. |
| `minotaur` | `minotaur` | Bảng rơi Ancient Guardian. |
| `guardianphase3` | `alterguardian_phase1`, `_phase2`, `_phase3` | Bảng rơi Celestial Champion giai đoạn 3. |
| `eyeofterror` | `eyeofterror` | Bảng rơi Eye of Terror. |
| `twinsofterror` | `twinofterror1`, `twinofterror2` | Phần thưởng Twins of Terror trong mã `eyeofterror.lua`. |
| `daywalker` | `daywalker` | Bảng rơi Daywalker. |
| `deerclops_mutated` | `mutateddeerclops` | Bảng rơi Mutated Deerclops. |
| `warg_mutated` | `mutatedwarg` | Bảng rơi Mutated Warg. |
| `bearger_mutated` | `mutatedbearger` | Bảng rơi Mutated Bearger. |
| `sharkboi` | `sharkboi` | Bảng rơi Sharkboi. |
| `wormboss` | `worm_boss` | Bảng rơi Worm Boss. |
| `daywalker2` | `daywalker2` | Bảng rơi Daywalker 2. |
| `wagboss_robot` | `wagboss_robot` | Bảng rơi Wagboss Robot. |
| `wagboss_lunar` | `alterguardian_phase4_lunarrift` | Bảng rơi Lunar Wagboss. |
| `vault_pillar_guard` | `vault_pillar_guard` | Phần thưởng của **guard cuối** trong phòng chìa khóa Vault. |

## Danh sách mã bản vẽ/phác thảo đầy đủ

Trong game, `sketch` là **bản phác thảo để bàn học mẫu**. Không phải `blueprint` học trực tiếp vào nhân vật. Bảng gộp sau cho phép kiểm tra nhanh **toàn bộ 46 mã** và nguồn. Công thức thành phẩm của mỗi mã luôn là `chesspiece_<mã>_builder`, dùng 2 nguyên liệu điêu khắc tương ứng + 2 `rocks`.

| Nhóm lấy phác thảo | Mã mẫu (mỗi mã thêm tiền tố `chesspiece_` và hậu tố `_sketch`) |
|---|---|
| **Không cần phác thảo** | `hornucopia`, `pipe` |
| **Bụi cỏ lăn / tượng có sẵn** | `pawn`, `muse`, `formal` |
| **Đổi trinket** | `rook` (28/29), `knight` (30/31), `bishop` (15/16) |
| **Papyrus tại công nghệ Celestial 3** | `butterfly`, `moon` |
| **Papyrus tại công nghệ Seafaring 2** | `anchor` |
| **Lễ dâng 8 `lucky_goldnugget`** | `carrat`, `beefalo`, `kitcoon`, `catcoon`, `manrabbit`, `yotd`, `yots`, `yoth`, `clayhound` |
| **Lễ dâng 16 `lucky_goldnugget`** | `claywarg` |
| **Boss/quái và phần thưởng đặc biệt** | `deerclops`, `bearger`, `moosegoose`, `dragonfly`, `crabking`, `malbatross`, `toadstool`, `stalker`, `klaus`, `beequeen`, `antlion`, `minotaur`, `guardianphase3`, `eyeofterror`, `twinsofterror`, `daywalker`, `deerclops_mutated`, `warg_mutated`, `bearger_mutated`, `sharkboi`, `wormboss`, `daywalker2`, `wagboss_robot`, `wagboss_lunar`, `vault_pillar_guard` |

## Giới hạn và các chỗ dễ hiểu nhầm

1. **Không phải cứ đặt tượng boss kính trăng là có buff.** Với 25 mẫu trong bảng boss, mã perk chỉ dùng bản **đá/cẩm thạch** theo quy tắc chung. Chưa có nhánh perk dành riêng cho bản kính trăng của các mẫu đó.
2. **Không phải mọi nguồn gọi là “bản vẽ” đều là vật phẩm blueprint.** Các tượng dùng `*_sketch`, còn hai tượng `hornucopia`/`pipe` đã có công thức điêu khắc sẵn.
3. **Một số hiệu ứng lấy trạng thái khi sự kiện xảy ra.** Ví dụ buff người theo được gắn khi nhận leader; tượng Clay Warg gắn tag lúc sinh con mồi. Nếu vừa đặt/đập tượng giữa chừng, hiệu ứng đã gắn có thể không đổi ngay đến khi sự kiện đó chạy lại.
4. **Đừng hiểu chú thích mã là công thức thực tế.** Chẳng hạn chú thích Carrat kính trăng nói “4×”, nhưng phép tính trong mã là `timemult ×5`; tài liệu này dùng phép tính. Chú thích giảm tần suất chó săn nói “3×”, nhưng mã nhân thời gian cơ sở **5**.

## Nguồn mã đã đối chiếu

- [Đăng ký tượng và toàn bộ hiệu ứng riêng](../Achivement_Steam_2026-09-27/scripts/postInits/chasni_grounded_postinit.lua)
- [Registry kiểm tra tượng tồn tại](../Achivement_Steam_2026-09-27/scripts/components/groundedregistry.lua)
- [Ánh xạ mục tiêu và EXP hạ gục](../Achivement_Steam_2026-09-27/scripts/functions/helperfunctions.lua)
- [Hệ số sát thương chung và các hiệu ứng crit/né](../Achivement_Steam_2026-09-27/main_globalpostInits.lua)
- [Công thức bổ sung do tượng mở](../Achivement_Steam_2026-09-27/main_recipes.lua)
- Mã game DST cài trên máy: `C:/Program Files (x86)/Steam/steamapps/common/Don't Starve Together/data/databundles/scripts.zip`, các file `scripts/recipes.lua` (dòng 389, 879–925, 1093–1171), `scripts/prefabs/sketch.lua`, `scripts/prefabs/sculptingtable.lua` và các prefab boss tương ứng.
