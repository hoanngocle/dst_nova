# Hầm Ngục Tu Tiên — phân tích và thiết kế đề xuất

Ngày: 2026-09-30. Trạng thái: người dùng đã duyệt toàn bộ baseline và yêu cầu triển khai; đang nghiệm thu bản thử 0.1.0-dev.

## 1. Phạm vi đã được người dùng chọn

- Tạo **mod Hầm Ngục riêng** trong bộ mod hiện tại.
- Giữ Hầm Ngục, quái và boss từ Solo Leveling; đổi phần thưởng sang Tu Tiên.
- Bản đầu có thể yêu cầu **tạo thế giới mới**.
- Người dùng đã yêu cầu bắt đầu triển khai sau khi duyệt thiết kế.

Tên thư mục đề xuất: `HamNgucTuTien`. Tiền tố riêng: `hn_` cho prefab/component/module/action/tag/event/RPC/tile mới. Đây là tên kỹ thuật đề xuất, chưa phải tên Workshop đã đăng ký.

## 2. Những gì đã xác minh trong nguồn local

Nguồn: `3780347550/`, Solo Leveling 2.2.7, tác giả Saikuno theo `modinfo.lua`. Thư mục này đang bị `.gitignore` bỏ qua. Không có `.codegraph/` ở root. Các đường dẫn dưới đây tính từ root repository.

| Phần | Nguồn và hành vi đã đọc |
|---|---|
| Sinh đấu trường | `3780347550/modworldgenmain.lua`: mở rộng bản đồ Forest, dịch tọa độ topology/entity/road, dựng vùng cách ly, tái tạo dữ liệu map/nav; không phải shard hoặc interior riêng. |
| Bản vẽ | `3780347550/scripts/dungeon_blueprints.lua`: bố trí nền, tường, cổng thoát, cột và trang trí. |
| Quyền điều khiển | `scripts/utils/hh_dungeon_authority.lua`: chỉ authoritative master shard có tag `forest`. |
| Điều phối | `scripts/components/dungeon_manager.lua`, khoảng 2.000 dòng: một cổng/lượt dùng chung, spawn, người chơi, hồi chiêu, lưu và dọn. |
| Cổng và tương tác | `scripts/prefabs/dungeon_gate.lua`, `dungeon_exit.lua`; `main/hh_act.lua`, `hh_rpc.lua`, `hh_sg.lua`; hook icon bản đồ trong `modmain.lua`. |
| Quái thường | `hh_dungeon_spider.lua`, `hh_dungeon_pig.lua`, `hh_dungeon_hounds.lua`; quái DST và `main/hh_dungeon_mobs_sg.lua`. |
| Boss | Igris/Sharkboi nằm trong `scripts/enums/hh_boss.lua` và prefab factory `scripts/prefabs/hh_boss.lua`; Beru có prefab riêng. Có brain, stategraph, projectile/FX và buff phụ thuộc. |
| Phần thưởng | `dungeon_manager.lua` sinh loot/rương, cấp vật phẩm ảo qua `hh_player`, và sinh `rock_treasure`; xu/shop nằm trong hệ riêng `main/hh_dungeon_shop.lua`. |
| Khả năng tích hợp | Nyx có Thuấn Ảnh; `nyx_blink_common.lua` dùng `IsTeleportingPermittedFromPointToPoint`. Công Trình chỉ nối Thiên Nghịch Châu vào prefab do Tu Tiên sở hữu. |

### Luật chơi gốc có thể giữ làm mốc

- Ngẫu nhiên 2–10 làn; mỗi làn thường 10 quái; làn cuối là boss.
- Lượt 2–5 làn dùng nhóm boss DST; lượt 6–10 dùng Igris, Sharkboi hoặc Beru.
- Làn đầu bắt đầu sau 5 giây; nghỉ giữa làn 10 giây.
- Đến từ làn 2 trở đi không được nhập cuộc. Đây không phải instance riêng cho từng người.
- Cổng mới xuất hiện sau hồi chiêu 480 giây; không ai vào trong 480 giây thì đóng lượt và sinh một quái thường tại vị trí cổng.
- Khi boss xuất hiện khóa lối ra; thắng được 180 giây nhặt thưởng; sinh 6 hoặc 12 mạch khoáng theo nhóm độ khó.
- Rời bằng lối ra đặt hồi chiêu cá nhân 480 giây; hook chết đặt 960 giây.
- Save/load không tiếp tục trận đang đánh: hủy lượt, dọn và hồi chiêu. Không được quảng bá tính năng resume giữa trận.
- Quái thường được nhân máu/sát thương x2 hoặc x3. Boss ở nhóm khó có hệ số x1,5 tại manager; các lớp chỉ số Solo khác còn tác động, nên không thể suy ra sức mạnh cuối chỉ từ hệ số này.

## 3. Ba cách chuyển và khuyến nghị

1. **Tách chọn lọc — khuyến nghị:** tái sử dụng worldgen, bản vẽ, animation và chuỗi chiêu; viết lớp điều phối/tích hợp có namespace riêng; rút gọn phần buff/chỉ số thật sự được boss gọi; thay toàn bộ đường thưởng. Giữ trải nghiệm nhưng kiểm soát phụ thuộc.
2. **Copy gần nguyên mod rồi tắt phần thừa:** dễ dựng bản chạy thử ban đầu, nhưng `hh_monster` kéo effects/enchant/loot/config, shop kéo progression/reincarnation; rủi ro xung đột và mang gameplay ngoài phạm vi cao.
3. **Viết lại toàn bộ:** kiến trúc chủ động hơn nhưng khó giữ chiêu và cảm giác boss; công lớn hơn, không phù hợp mục tiêu copy tính năng hiện tại.

## 4. Kiến trúc đề xuất

- Mod server + client, `all_clients_require_mod=true`; dùng Lua/DST API, không phụ thuộc Solo Leveling khi chạy.
- Yêu cầu Tu Tiên để cấp Linh Thạch. Workshop ID `3721846643` hiện được Công Trình khai báo; xác minh lại bản Tu Tiên đang cài trước khi đóng gói.
- Thần Khí là tích hợp tùy chọn cho Huyền Tinh. Không buộc cài Công Trình/Nyx; bật chúng để kiểm tra tương thích.
- `modmain.lua` chỉ đăng ký assets/prefab và các module. `modworldgenmain.lua` chỉ đăng ký tile và gọi module worldgen.
- `hn_dungeon_manager`: trạng thái lượt, cổng, thành viên, lịch spawn, snapshot điểm về, `run_id` và save schema có version.
- `hn_dungeon/waves`: nhóm quái, boss và thông số gốc; `hn_dungeon/spawner`: spawn/cấu hình chiến đấu; `hn_dungeon/cleanup`: dọn đúng thực thể của lượt.
- `hn_dungeon/rewards`: duy nhất một nơi quyết định thưởng quái/rương/khoáng. Dùng prefab vật lý, không dùng kho ảo `hh_player`.
- `hn_dungeon/combat` và `hn_combat_effects`: chỉ những helper/buff cần cho chiêu đã port; áp dụng và gỡ modifier theo nguồn, tránh ghi đè vĩnh viễn chỉ số của mod khác.
- `main/hn_actions.lua`, `hn_player_states.lua`, `hn_map.lua`, `hn_restrictions.lua`: tương tác/network/map và luật vào/ra. Chỉ áp dụng hạn chế cho người/thực thể của hầm.
- `main/hn_tutien_compat.lua`: tích hợp dịch chuyển, vật phẩm và companion Tu Tiên/Nyx; đọc registration sau khi các mod đã nạp.

Luồng: tạo world → xác minh arena → mở cổng → xác thực tương tác trên server → vào lượt → các làn → boss → nhận thưởng → đưa người ra → dọn → hồi chiêu → cổng mới.

## 5. Phần giữ, phần thay, phần loại

**Giữ:** hình dạng/không khí đấu trường, hình cổng và icon độ khó, AI/chuỗi animation/chiêu quái-boss, làn sóng, khóa cổng boss, thời gian nhặt thưởng, mạch khoáng và quy trình hồi chiêu. Animation bank/build có thể giữ tên nội bộ khi asset cần; namespace Lua phải riêng.

**Thay:** điều kiện boss nhắm vào `hh_player` bằng điều kiện người chơi hợp lệ; hệ số chiến đấu và buff qua lớp hầm riêng; loot/rương/khoáng sang bảng thưởng Tu Tiên; hook chuyển cảnh để phù hợp Nyx/Tu Tiên. Giữ cơ chế từng chiêu, nhưng không hứa sức mạnh số học giống nguyên bản khi đã bỏ hệ chỉ số Solo.

**Loại:** xu/shop Hầm Ngục, progression nhân vật Solo, nhiệm vụ ngày/hiệp hội, quân đoàn bóng, kho vật phẩm ảo, world-rank Solo và luân hồi. Không copy toàn bộ `hh_utils`, `hh_monster`, `hh_buff` hoặc `modmain.lua`.

## 6. Phần thưởng — baseline đề xuất để thử cân bằng

Baseline này đã được người dùng duyệt; chưa được cân bằng bằng playtest đầy đủ. Giữ thưởng dùng chung của tổ đội, tránh nhân theo số người hoặc theo người đánh đòn cuối.

| Nguồn | 2–5 làn | 6–10 làn |
|---|---|---|
| Quái thường | 50% rơi 1 `xd_lingshi1` | 50% rơi 2 `xd_lingshi1` |
| Rương boss | 10 `xd_lingshi2` + 2 `ttk_huyen_tinh_ha_pham` | 2 `xd_lingshi3` + 2 `ttk_huyen_tinh_trung_pham` |
| Mỗi mạch khoáng | 2 `xd_lingshi1` | 4 `xd_lingshi1` |

- Giữ đường loot DST của quái thường như nguồn (roll 50%) và loot boss DST, tách khỏi phần thưởng Tu Tiên.
- Thiếu Huyền Tinh do không bật Thần Khí: mỗi đơn vị hạ phẩm đổi 5 Linh Thạch hạ; mỗi trung phẩm đổi 10 Linh Thạch hạ. Không sinh prefab chưa đăng ký.
- Thiếu prefab Linh Thạch bắt buộc: không mở lượt và báo rõ thiếu phụ thuộc; không âm thầm bỏ thưởng.
- Rương không bị giới hạn bởi số slot: chia stack hợp lệ; nếu đầy thì phần còn lại đặt sát rương và vẫn thuộc lượt.
- Event chết lặp, summons hoặc callback của lượt cũ không được tạo thêm rương/phần thưởng clear. Summon không tính vào số quái của wave và mặc định không nhận thưởng riêng.
- Đối chiếu sức mua/công thức Tu Tiên thực tế trước phát hành. Repo hiện có nơi tham chiếu Linh Thạch, chưa có đủ mã nguồn core Tu Tiên để kết luận giá trị kinh tế.

## 7. Các khác biệt an toàn đề xuất cần duyệt

- **Đồ khi chết:** nguồn gọi `DropEverything()` rồi cleanup có thể xóa đồ trên đất. Đề xuất chuyển đồ rơi của người chết về túi thu hồi tại cổng; đồ thưởng bỏ lại vẫn dọn. Phải phân biệt nguồn gốc vật phẩm ngay lúc rơi và lưu nguồn gốc qua restart. Không dùng quy tắc “mọi inventoryitem trong bán kính đều xóa”.
- **Thoát sai cách:** nguồn `PunishPlayer` có thể giết nhân vật nếu lệch khỏi vùng hầm. Đề xuất chặn chuyển cảnh không hợp lệ, đưa về điểm an toàn và kết thúc lượt nếu cần; không dùng kill làm xử lý lỗi vị trí. Đây là thay đổi có chủ ý so với bản gốc.
- **Companion:** nguồn tháo follower trừ Abigail/Woby. Đề xuất từ chối vào khi mang companion không được hỗ trợ và báo lý do, không tự xóa quan hệ chủ. Chi tiết companion Tu Tiên cần kiểm tra bằng core mod thực tế.
- Giữ cooldown chết 960 giây và luật hạn chế hồi sinh; kiểm tra cơ chế hồi sinh tự động của mod khác trước chốt hành vi cuối.

## 8. Rủi ro cần giải quyết bằng kiểm chứng

1. **Worldgen:** nguồn can thiệp sâu vào map/nav. Test nhiều seed, kích thước map và Forest+Caves; xác minh cổng đặt trên đất liền, không sinh duplicate ở Caves. Map cũ thiếu arena phải từ chối mở lượt rõ ràng.
2. **Boss:** Igris/Beru kiểm tra `hh_player` ở một số chiêu. Beru còn dùng `hh_monster`/`hh_buff`; chỉ bỏ component sẽ làm mất chiêu. Lập danh sách chiêu, projectile, summon, âm thanh, buff và helper trước port.
3. **Cân bằng:** Igris đặt base health 400.000 trong nguồn trước những lớp scaling khác. Cần thử với trang bị Tu Tiên; không lấy “x1,5” làm bằng chứng đã cân bằng.
4. **Dịch chuyển:** Thuấn Ảnh hợp lệ trong phòng; không cho qua tường/ra ngoài. Kiểm tra Thiên Nghịch Châu, Truyền Tống Trận, kỹ năng vũ khí và companion teleport.
5. **Save/reconnect:** không kẹt người khi reset, gate bị mất, disconnect hết tổ đội, callback spawn đến sau cleanup hoặc loot đang được nhặt lúc save.
6. **Hook mod khác:** boss/quái DST có thể bị buff và phát thưởng thêm bởi Tu Tiên/Thành Tựu/Thần Khí. Không mặc định tổng damage và loot chỉ do mod mới quyết định.

## 9. Tiêu chí hoàn thành

- Tắt Solo Leveling vẫn tạo world và hoàn thành đủ lượt 2–10 làn.
- Cả Igris, Sharkboi, Beru hoạt động đủ nhóm chiêu đã ghi trong manifest, đánh được Nyx và nhân vật DST.
- Client tham gia dedicated server nhìn thấy cổng, icon, animation và nhận trạng thái đúng; RPC giả/muộn/xa bị từ chối.
- Chết, thoát, reconnect, restart, reset và dọn không kẹt người/nhân thưởng/xóa nhầm đồ người chơi.
- Chỉ có một manager/cổng hoạt động đúng Forest master shard.
- Không xuất hiện xu/shop/nhân vật Solo ngoài phạm vi; thưởng mới đúng config và thiếu Thần Khí vẫn chạy.

Giới hạn phân tích: đã đọc các đường chính và một số dependency sâu; chưa hoàn tất asset closure, chưa chạy DST, chưa kiểm chứng đầy đủ core Tu Tiên. Plan phải dành bước kiểm chứng những phần này, không coi là đã giải quyết.
