# Hầm Ngục Tu Tiên Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not start implementation until the user requests execution and reviews the proposed gameplay differences.

**Goal:** Tạo mod Hầm Ngục riêng, giữ đấu trường/quái/boss Solo Leveling, dùng thưởng Tu Tiên và world mới.

**Architecture:** Tách chọn lọc nguồn local 2.2.7; namespace `hn_`; dùng arena trong Forest master shard. Điều phối lượt, combat, rewards và compatibility tách module; không cần Solo Leveling khi chạy.

**Tech Stack:** Lua, DST mod API, prefab/component/stategraph/brain, client-server actions/RPC, worldgen. Lua 5.4.5 có sẵn để chạy test mock; tương thích runtime Lua của DST phải kiểm tra trong game, không suy ra từ test Lua 5.4.

**Spec:** [Thiết kế và phân tích](../specs/2026-09-30-ham-nguc-tu-tien-design.md).

**Status:** Đã được người dùng duyệt và yêu cầu triển khai. Code Tasks 1–6 hiện có trong `HamNgucTuTien/`; đã đóng bản thử Task 7 với 32 test Lua, 18 shard mới, full-stack và restart headless. Nghiệm thu client/playtest còn mở. Các checkbox gộp cả kiểm thử người chơi chỉ đánh dấu khi hoàn thành toàn bộ điều kiện; xem `HamNgucTuTien/tests/manual-checklist.md` để biết bằng chứng và ca còn thiếu.

**Điều chỉnh triển khai:** dùng class `BufferedAction` toàn cục theo API DST; tách quái theo prefab nguồn thay vì tên file dự kiến; test dependency Python + dedicated engine thay nhóm Lua `boss_contract`. Thu hồi di chuyển entity gốc, dùng persistence container của DST thay vì dựng lại item từ save record; vật phẩm không thể đặt vào container nằm trên đất tại cổng. Checkpoint code gom sau lượt kiểm thử tích hợp; không sửa mod Nyx/Công Trình đang có.


## Global Constraints

- Tạo **mod Hầm Ngục riêng** trong bộ mod hiện tại.
- Giữ Hầm Ngục, quái và boss từ Solo Leveling; đổi phần thưởng sang Tu Tiên.
- Bản đầu có thể yêu cầu **tạo thế giới mới**.
- Không phụ thuộc Solo Leveling khi chạy; không nhập xu/shop/progression/quân đoàn Solo.
- Tên thư mục đề xuất: `HamNgucTuTien`; tiền tố `hn_`; `all_clients_require_mod=true`.
- Chỉ authoritative Forest master shard điều phối lượt; không resume trận đang đánh sau restart.
- Bảo toàn thay đổi đang có trong workspace và nguồn `3780347550/`; không đưa toàn bộ nguồn bị ignore vào commit.

## Review Focus

- Callback spawn/death cũ sau reset: không tạo quái, thưởng hoặc tiến wave mới — Task 2, 5.
- Người offline trong arena rồi reconnect sau restart: về điểm an toàn, không kẹt/nhận phạt nhầm — Task 2, 6.
- Boss nhắm người không có `hh_player`: đủ chiêu và gỡ buff đúng hạn — Task 4.
- Đồ chết, đồ nằm trong container/stack, đồ đã nhặt lúc cleanup: không xóa/nhân đồ — Task 5, 6.
- Skill teleport của Nyx/Tu Tiên bỏ qua action chuẩn: không vượt ranh giới arena — Task 6.

## Bản đồ file dự kiến

Mọi đường dẫn dưới đây nằm trong `HamNgucTuTien/` trừ khi ghi rõ. Đây là file sẽ tạo, không phải file đã tồn tại.

| Nhóm | Files | Trách nhiệm |
|---|---|---|
| Bootstrap | `modinfo.lua`, `modmain.lua`, `modworldgenmain.lua` | Metadata, registration, config, module loading |
| Địa hình | `scripts/hn_dungeon/worldgen.lua`, `blueprints.lua`, `authority.lua`, `map_codec.lua` | Arena và quyền điều phối |
| Lượt | `scripts/components/hn_dungeon_manager.lua`, `hn_dungeon_cooldown.lua`; `scripts/hn_dungeon/waves.lua`, `spawner.lua`, `cleanup.lua` | Lifecycle, wave, entity ownership |
| Cổng | `scripts/prefabs/hn_dungeon_gate.lua`, `hn_dungeon_exit.lua`, `hn_dungeon_wall.lua`, `hn_arena_decor.lua` | Cổng, tường, trang trí |
| Người chơi/UI | `main/hn_actions.lua`, `hn_player_states.lua`, `hn_map.lua`, `hn_restrictions.lua`, `hn_strings.lua` | Vào/ra, xác nhận, minimap, client prediction |
| Combat | `scripts/hn_dungeon/combat.lua`, `boss_defs.lua`; `scripts/components/hn_combat_effects.lua`; `main/hn_mob_states.lua` | Chỉ số/buff/targeting và sửa stategraph có phạm vi |
| Quái/boss | `scripts/prefabs/hn_dungeon_mobs.lua`, `hn_igris.lua`, `hn_sharkboi.lua`, `hn_beru.lua`, `hn_combat_fx.lua`; `scripts/brains/hn_com_monster.lua`, `hn_sharkboi.lua`; `scripts/stategraphs/SGhn_igris.lua`, `SGhn_sharkboi.lua`, `SGhn_beru.lua` | Giữ cơ chế chiến đấu của nguồn |
| Thưởng | `scripts/hn_dungeon/rewards.lua`, `reward_defs.lua`; `scripts/prefabs/hn_treasure_rock.lua`, `hn_recovery_bag.lua` | Loot, rương, khoáng, bảo toàn đồ |
| Tích hợp | `main/hn_tutien_compat.lua` | Tu Tiên/Nyx/Thần Khí tùy khả năng đã đăng ký |
| Kiểm chứng | `tests/run.lua`, `tests/support/dst_mock.lua`, `tests/*_test.lua`, `tests/source_manifest.lua`, `tests/manual-checklist.md` | Test Lua, mapping nguồn/assets, checklist in-game |

Các prefab projectile/FX phụ sẽ được chốt trong manifest Task 1; không gom nội dung không liên quan từ factory `hh_boss` vào mod mới.

## Task 1: Khóa danh sách phụ thuộc và chứng minh arena hoạt động

**Files:** bootstrap, nhóm Địa hình/Cổng và `tests/source_manifest.lua`, `worldgen_test.lua`, `tests/run.lua`, `tests/support/dst_mock.lua`.

**Nguồn:** `3780347550/modworldgenmain.lua`, `scripts/dungeon_blueprints.lua`, `scripts/utils/hh_dungeon_authority.lua`, cổng/tường/decor; các entry prefab và đường `Asset/require/SpawnPrefab/SetStateGraph/SetBrain` liên quan.

**Interfaces:** `authority.IsAuthority(world) -> boolean`; `worldgen.Install(api) -> nil`; `blueprints` trả bảng layout; `map_codec.EncodeU16(values)` / `DecodeU16(text)`.

- [x] Lập mapping nguồn→đích, liệt kê asset/âm thanh/projectile/summon/helper và chiêu của từng boss. Kiểm tra lời gọi qua table/dynamic factory bằng đọc code, không chỉ tìm tên chứa dungeon. Ghi nguồn/tác giả/version và hash file dùng lại.
- [x] Viết test worldgen: encode/decode roundtrip; hàng blueprint bằng độ dài; đúng một exit; topology/entity/road dịch cùng offset; không tạo arena trên Caves; hook được khôi phục kể cả generation lỗi.
- [x] Chạy test trước implementation, xác nhận fail do module chưa có. Tạo bootstrap/registration và port worldgen có namespace; không dùng thư mục nguồn làm runtime dependency.
- [x] Run `lua HamNgucTuTien/tests/run.lua worldgen`: PASS tất cả ca trên. Runner nhận tên nhóm hoặc `all`, trả exit code khác 0 nếu có fail.
- [ ] Tạo world DST thử với Solo tắt: Forest-only và Forest+Caves, map nhỏ/lớn, ít nhất 3 seed mỗi tổ hợp. Kiểm tra nav/minimap/arena/exit; ghi kết quả vào checklist. Chưa qua bước này thì không mở rộng sang boss.
- [ ] Checkpoint commit chỉ file mod mới và tài liệu liên quan khi bước được nghiệm thu.

## Task 2: Một lượt hoàn chỉnh với quái DST để kiểm tra lifecycle

**Files:** nhóm Lượt, `tests/lifecycle_test.lua`, `tests/cooldown_test.lua`.

**Interfaces:** manager `CanEnter(player) -> boolean, reason`; `Enter(player) -> boolean`; `Leave(player, reason) -> boolean`; `Fail(reason)`; `OnSave() -> table`; `OnLoad(data)`; `Track(entity, run_id)`; `IsActiveGate(gate) -> boolean`. `waves.Get(wave, total, rng) -> {prefabs, is_boss, multiplier}`. `spawner.Start(manager, wave_spec, run_id)` / `Cancel(manager)`; `cleanup.Run(manager, run_id)`.

- [ ] Viết test clock/entity mock: 5 giây tới wave đầu, 10 quái/wave thường, nghỉ 10 giây; boundary total=5/6/10; chặn nhập từ wave 2; cổng cooldown 480 giây; timeout bỏ cổng 480 giây.
- [ ] Thêm test fail/clear/last-player-left; death callback lặp; reset khi pending spawn; restart giữa READY/IN_PROGRESS/cleared/COOLDOWN; join lại sau arena reset. Chỉ một gate, callback cũ vô hiệu, không resume trận.
- [ ] Chạy đỏ, rồi port lifecycle có `run_id`, snapshot điểm về và registry entity; dùng quái DST tạm trong test nội bộ, không coi là bản phát hành đủ boss.
- [ ] Run `lua HamNgucTuTien/tests/run.lua lifecycle` và `lua HamNgucTuTien/tests/run.lua cooldown`: PASS; thử 2 client cùng lượt và disconnect hết tổ đội.
- [ ] Checkpoint commit sau khi lifecycle ổn định.

## Task 3: Cổng, xác nhận vào, minimap và client-server

**Files:** nhóm Người chơi/UI và Cổng; `tests/actions_test.lua`, `tests/network_test.lua`.

**Interfaces:** RPC namespace `modname`, handler `hn_enter_dungeon(player, gate)`; action `HN_ENTER_DUNGEON`, `HN_LEAVE_DUNGEON`; state `hn_dungeon_migrate`; event `hn_dungeon_state_changed` payload `{state,total_waves,run_id}`. Gọi manager Task 2, không cho client quyết định wave/thưởng.

- [ ] Test người chết, gate giả/cũ, double-click, đang transition, khoảng cách bình phương >36, state đổi trong lúc popup mở: đều từ chối; đúng gate và khoảng cách <=36 mới xét `CanEnter`.
- [ ] Test lối ra khóa ở wave boss, mở sau clear; client và server cùng định nghĩa action/netvar/state. Client không gọi server component.
- [ ] Chạy đỏ; port popup, action picker, transition, rank/icon/minimap và string cần thiết từ `hh_act`, `hh_rpc`, `hh_sg`, `dungeon_gate`, các hook map trong `modmain`.
- [ ] Run `lua HamNgucTuTien/tests/run.lua actions` và `lua HamNgucTuTien/tests/run.lua network`: PASS; thử dedicated server với client kết nối từ máy/tiến trình khác, không chỉ host.
- [ ] Checkpoint commit.

## Task 4: Port toàn bộ quái/boss trong phạm vi

**Files:** nhóm Combat/Quái-boss, asset closure đã khóa ở Task 1; `tests/combat_test.lua`, `tests/boss_contract_test.lua`.

**Interfaces:** `combat.IsValidPlayerTarget(inst,target) -> boolean`; `combat.ApplyStats(inst, difficulty, is_boss) -> nil`; effect component `Apply(id, source, duration, params)` / `RemoveSource(source)`; defs chứa base stats, skill timers và effect parameters trích từ manifest.

- [ ] Test Nyx/Wilson không có `hh_player` vẫn là mục tiêu hợp lệ; ghost/invalid/player ngoài lượt không bị chiêu riêng của hầm chọn. Test gỡ buff hết hạn/chết/reset và không cộng scaling hai lần.
- [ ] Test đủ nhóm quái; Igris/Sharkboi/Beru có đúng brain, state, asset, projectile/summon/effect theo manifest; summon không làm treo counter wave.
- [ ] Chạy đỏ; port lần lượt nhện/heo/sói → Sharkboi → Igris → Beru. Trích helper/buff thực dùng, giữ chuỗi chiêu; không tạo dummy `hh_player` để vượt điều kiện.
- [ ] Thay các `hh_player` guard và dependencies `hh_monster`/`hh_buff` bằng contract riêng; rà cả truy cập ngoặc vuông trong code obfuscated. Không âm thầm bỏ chiêu nếu chưa map effect được.
- [ ] Run `lua HamNgucTuTien/tests/run.lua combat` và `lua HamNgucTuTien/tests/run.lua boss_contract`: PASS. Trong DST kích hoạt từng nhóm chiêu, ghi quan sát animation, damage, CC, hồi phục, summon và hành vi khi sát tường.
- [ ] Đối chiếu gameplay với nguồn có Solo trên một world thử riêng; chốt baseline health/damage sau khi thấy tương tác các mod Tu Tiên. Checkpoint commit.

## Task 5: Thưởng Tu Tiên, khoáng và bảo toàn đồ

**Files:** nhóm Thưởng, cleanup; `tests/rewards_test.lua`, `tests/recovery_test.lua`.

**Interfaces:** `rewards.Roll(kind, tier, rng, prefab_exists) -> {{prefab,count}}`; `rewards.GrantClear(manager, run_id, pos) -> boolean`; `rewards.SpawnLoot(manager, entries, pos)`; túi thu hồi lưu item save records, owner userid và recovery id.

- [ ] Sau khi bảng thưởng được duyệt, viết assertion theo số cụ thể ở spec: tier dễ/khó, roll 0.49 được và 0.50 không được quà quái; thiếu Huyền Tinh có fallback; thiếu Linh Thạch khóa mở lượt; stack/rương đầy không mất phần dư.
- [ ] Test gọi clear hai lần hoặc event của `run_id` cũ chỉ sinh một rương; summon không phát thưởng riêng; không còn gọi kho ảo/xu/shop của Solo.
- [ ] Với đề xuất túi thu hồi được duyệt: test đồ chết trong nhiều slot/container, đồ stack, đồ đã nhặt, offline owner và save/load trong khi chuyển đồ. Mỗi item chỉ tồn tại ở một nơi; cleanup không xóa túi/đồ người chơi.
- [ ] Chạy đỏ; đổi các đường loot quái, rương, phần thưởng ảo và `rock_treasure`, không chỉ đổi loot boss. Áp dụng tagging/persistence để cleanup giới hạn đúng vật thể của lượt.
- [ ] Run `lua HamNgucTuTien/tests/run.lua rewards` và `lua HamNgucTuTien/tests/run.lua recovery`: PASS; thử túi thu hồi qua restart trong DST và kiểm tra tương tác hệ loot tự động hiện có.
- [ ] Checkpoint commit.

## Task 6: Chống vượt biên và tương thích Tu Tiên/Nyx

**Files:** nhóm Tích hợp, `hn_restrictions.lua`, `hn_player_states.lua`; `tests/compat_test.lua`, `tests/restrictions_test.lua`.

**Interfaces:** `compat.Install(api)`; `restrictions.CanTeleport(player, from_x, from_z, to_x, to_z) -> boolean, reason`; gọi tại validation trước khi dùng resource/cooldown. `restrictions.CanEnterWithFollowers(player) -> boolean, reason`.

- [ ] Đọc core Tu Tiên đã cài để xác minh đường use/teleport/revive/companion và đăng ký prefab Linh Thạch. Ghi hook đúng vào manifest; không suy đoán API từ tên item.
- [ ] Test Thuấn Ảnh trong phần sàn hợp lệ được dùng; qua tường/ngoài arena bị từ chối; người ngoài hầm không bị ảnh hưởng. Test Thiên Nghịch Châu/Truyền Tống Trận/weapon teleport không vượt restriction.
- [ ] Test companion không hỗ trợ bị từ chối trước entry, vẫn giữ owner; hồi sinh và lỗi vị trí theo chính sách được duyệt; chết cooldown 960 giây, exit cooldown 480 giây.
- [ ] Chạy đỏ; nối bằng hook trong mod mới trước. Chỉ sửa mod Nyx/Công Trình nếu thực sự không có điểm hook thích hợp, với thay đổi nhỏ và ghi rõ phạm vi.
- [ ] Run `lua HamNgucTuTien/tests/run.lua compat` và `lua HamNgucTuTien/tests/run.lua restrictions`: PASS; thử bộ Tu Tiên/Nyx/Thần Khí/Công Trình/Thành Tựu thực tế, có và không có Thần Khí.
- [ ] Checkpoint commit.

## Task 7: Nghiệm thu và đóng gói bản thử

**Files:** `tests/manual-checklist.md`, `README.md`, `modinfo.lua`, manifest/assets nếu có lỗi thiếu.

- [x] Run `lua HamNgucTuTien/tests/run.lua all`: toàn bộ test PASS. Kiểm tra syntax từng file; test Lua 5.4 không thay thế nạp mod trong DST.
- [x] Kiểm tra artifact không còn require/SpawnPrefab/component bắt buộc từ Solo; xác minh từng asset được tham chiếu có trong mod hoặc base game. Không cấm chuỗi `hh_` trong tên bank/build nếu animation gốc yêu cầu.
- [ ] Chạy hết checklist: Solo tắt; Tu Tiên bật; hai độ khó; cả ba boss; Forest+Caves; host/client/dedicated; chết, quit, reconnect, restart, gate mất, cleanup và thưởng.
- [ ] Chơi thử một người và tổ đội, ghi thời gian clear, số lần chết, loot/giờ và tương tác damage của Tu Tiên; chỉnh bảng config, rerun test liên quan.
- [x] README nêu world mới, dependency, luật chết/đồ/restart và attribution nguồn; đóng gói bản thử. Upload Workshop là công việc riêng khi được yêu cầu.

## Thứ tự và điểm dừng đánh giá

`Arena → Lifecycle → Cổng/network → Quái/boss → Thưởng → Compatibility → Playtest`.

Ưu tiên kiểm chứng worldgen và boss dependencies sớm vì đây là hai nguồn rủi ro lớn nhất. Bản chơi thử chỉ đủ phạm vi sau Task 6; bản lifecycle với quái DST ở Task 2 là bước kiểm tra nội bộ.

Không chốt lịch hoàn thành trước Task 1/4: lượng dependency động và khả năng tích hợp core Tu Tiên chưa được xác minh đủ. Đây là một tính năng nhiều giai đoạn, không phải thao tác copy vài file.

## Duyệt trước khi bắt đầu

Người dùng đã trả lời OK cho baseline và sau đó yêu cầu “Bắt đầu đi”. Triển khai inline trên nhánh `codex/ham-nguc-tu-tien`, giữ nguyên các thay đổi không thuộc Hầm Ngục.
