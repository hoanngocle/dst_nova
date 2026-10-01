# Kế hoạch chuyển ba boss Solo còn lại vào Hầm Ngục Tu Tiên

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm Lợn Rừng Bọ Hung, Siêu Lợn Song Kiếm và Guardian tùy biến vào Hầm Ngục, giữ bộ chiêu đặc trưng và dùng cân bằng/thưởng Tu Tiên.

**Architecture:** Hai boss lợn dùng factory `hn_bosses`, brain chung và component hiệu ứng hiện có. Guardian dùng prefab/brain/stategraph riêng, hai pha trên cùng entity; FX có owner và run epoch để giới hạn sát thương/dọn dẹp. Mở rộng pool boss khó từ 3 lên 6, không thay thế boss DST ngoài hầm.

**Tech Stack:** DST Lua, Python kiểm tra asset/dependency, dedicated engine và client có renderer; nguồn Solo Leveling 2.2.7 trong `3780347550/`.

**Spec:** Yêu cầu ngày 2026-10-01: “Lập plan chuyển nốt 3 con còn lại sang”. Đã được duyệt triển khai qua “Bỏ qua, xử lý plan trước đó đã làm đi”. Tiến độ, thay đổi cách triển khai và bằng chứng trong [execution ledger](2026-10-01-extra-bosses-execution.md); các mục client/chơi thực chưa được xem là đạt chỉ bằng kiểm tra headless.

## Thiết kế đề xuất

### Nội dung và phân bố

| Nguồn | Prefab mới | Bộ chiêu cần giữ |
|---|---|---|
| `hh_beetle_pig` | `hn_beetle_pig` | Combo, nhảy đánh, tăng tốc/cường hóa, khống chế |
| `hh_dual_wield_pig` | `hn_dual_wield_pig` | Combo song kiếm, xoay đánh, vòng vây tường tạm |
| `minotau` | `hn_minotau` | Lao húc, đập đất, sóng xung kích, lửa, dịch chuyển, chuyển pha Nightmare |

- Hầm 2–5 làn: giữ pool 7 boss DST hiện có.
- Hầm 6–10 làn: chọn đều 1 trong 6 boss `hn_sharkboi`, `hn_igris`, `hn_beru`, `hn_beetle_pig`, `hn_dual_wield_pig`, `hn_minotau` (mỗi con 1/6). Mỗi lượt vẫn một boss cuối.
- Giữ hạng hầm, quái làn thường, phần thưởng Tu Tiên, 180 giây nhặt thưởng và cooldown 480 giây.
- Không thêm quân đoàn/đệ tử, nhiệm vụ, shop, world-rank Solo hoặc cơ chế giới hạn quái thoát cổng.
- Guardian gốc DST (`minotaur`) ngoài hầm và pool hầm thấp không bị thay thế.

### Chỉ số ban đầu

| Boss mới | Máu nền | Công thường nền | Planar nền | Máu sau hệ số hầm + Thần Khí tại ngày 200/cảnh giới 12 |
|---|---:|---:|---:|---:|
| Lợn Rừng Bọ Hung | 25.000 | 50 | 30 | 843.750 |
| Siêu Lợn Song Kiếm | 30.000 | 50 | 30 | 1.012.500 |
| Guardian tùy biến | 25.000 mỗi pha, 2 pha | 60 | 0 | 843.750 mỗi pha; tổng danh nghĩa 1.687.500 |

Hệ số boss khó hiện tại ×1,5 áp dụng đúng một lần. Thần Khí tự áp dụng hệ số ngày/cảnh giới: cuối thang máu ×7,5 ×3, công ×2 ×2. Công thường cuối thang tương ứng 300/300/360, chưa tính phòng thủ/hiệu ứng khác; planar không nhân theo hệ số công thường. Không sao chép hệ tăng của Solo. Tổng máu Guardian là hai thanh máu liên tiếp, không phải maxhealth 50.000 rồi hồi lại 50.000.

Chỉ số là điểm bắt đầu để thử với trang bị Tu Tiên hiện tại, không cam kết thời gian hạ boss từ phép tính lý thuyết.

## Bằng chứng ảnh hưởng thiết kế

- `scripts/enums/hh_boss.lua:189` và `:274`: hai boss lợn có định nghĩa prefab và SG riêng; cùng dùng `hh_com_monster`, `hh_monster`, `hh_buff` và loot Solo. SG Beetle chỉ yêu cầu buff tốc độ `hh_beetle_pig_speed` trong danh sách buff hiện tại.
- `SGhh_dual_wield_pig.lua`: chiêu vây tạo `wall_moonrock`, `persists=false`, xóa sau 4 giây; cần quản lý cùng lượt và không rơi vật liệu khi phá.
- `modmain.lua:71–80` nguồn: Guardian đặt `MINOTAU_DAMAGE=1000000`, `MINOTAU_HEALTH=1000000`, tốc độ 5/17, attack period 4, lửa 30 giây. Không đưa các global tuning này sang.
- `SGminotau.lua` hồi đầy máu và kích hoạt Nightmare trong state `death` của pha đầu. Dòng nguồn gọi `SetPercent(TUNING.MINOTAU_HEALTH)` còn dùng sai đơn vị phần trăm. Manager hiện xử lý event `death` như kết thúc boss ngay, nên không thể copy nguyên chuỗi hồi sinh.
- Guardian có chest spawner, liên kết Ruins respawner, phá workable, groundpound phá vật thể, lửa trừ thẳng health và death-shockwave trừ 999 sanity. Những đường này phải được chuyển sang luật arena hoặc loại bỏ tác dụng ngoài combat.
- Các hook chuyển động hiện có trong `main/hn_motion_guards.lua` còn tên `hh_beetle_pig`, `hh_dual_wield_pig`; phải đăng ký tên `hn_` mới khi đưa boss vào.

## Global Constraints

- Chỉ boss mới được thay đổi; không chỉnh cân bằng 3 boss đang có, thời gian cổng hoặc bản sửa build Igris.
- Mọi prefab, brain, SG, tuning/module custom mới dùng namespace `hn_`; tên bank/build vanilla giữ nguyên khi dùng tài sản vanilla.
- Không phụ thuộc runtime vào thư mục Solo hoặc mod Solo đang bật; không ghi đè `minotaur`/`minotau` của mod khác.
- Chỉ server áp dụng damage, chuyển pha, thưởng và spawn thực thể combat. Client nhận animation/FX qua network.
- Chỉ đánh người tham gia còn sống và đồng hành được phép theo `hn_dungeon/combat`; không đánh khách ngoài hầm, quái cùng hầm hay vật phẩm/kiến trúc.
- Đồ người chơi, arena, cổng/exit và rương thu hồi không được phá bởi boss mới.
- Boss mới chỉ dùng thưởng clear chung. Không tạo rương/atrium key/treasure Solo riêng; không copy `minotauchestspawner` vào runtime.
- Thắng một lần ở cái chết cuối; reset/restart vẫn hủy lượt theo quy tắc hiện có. Không hồi sinh boss sau reset.
- Chơi được trên world đã có arena, không cần worldgen mới. Dự kiến phát hành `1.1.0` nếu baseline vẫn là `1.0.0` lúc triển khai.

## Review Focus

1. Đòn chí mạng vượt toàn bộ máu pha 1 không làm manager cấp thưởng sớm — Task 3.
2. Reset/restart giữa chuyển pha hoặc trong lúc FX đang chờ không tạo boss/quái/FX muộn — Task 3–4.
3. Nhảy, lao và dịch chuyển sát góc tường không đưa boss ra ngoài arena — Task 2–4.
4. Damage từ FX nhận hệ số Thần Khí đúng một lần; nhiều vùng lửa chồng nhau không nhân damage mỗi frame — Task 4.
5. Client tham gia muộn, nhìn boss chuyển pha/chết và có mod Solo bật cùng không trùng prefab/build — Task 5.

## Task 1: Chốt dependency và khung kiểm tra boss mới

**Files:**
- Create `HamNgucTuTien/scripts/hn_dungeon/extra_boss_defs.lua`: định nghĩa hai boss lợn.
- Create `HamNgucTuTien/scripts/hn_dungeon/minotau_tuning.lua`: thông số riêng Guardian, không sửa global tuning.
- Create `HamNgucTuTien/tests/extra_bosses_test.lua`; thêm group `extra_bosses` trong `tests/run.lua`.
- Extend `tests/check_dependencies.py`, `SOURCE_MANIFEST.json`.

**Interfaces:** `extra_boss_defs` trả bảng định nghĩa cùng schema với `boss_defs`; `minotau_tuning` trả table hằng chỉ dùng bởi prefab/SG/FX Guardian mới.

- [x] Ghi manifest nguồn của hai đoạn enum, hai SG lợn, prefab/brain/SG Guardian và toàn bộ FX dưới đây; ghi SHA-256 file nguồn và adaptation riêng.
- [x] Mở rộng dependency audit: tìm prefab trong `SpawnPrefab`, `SetStateGraph`, `SetBrain`/`require`, cả dạng có/không ngoặc và tên trong bảng; phân biệt prefab vanilla với custom. Xác nhận các tham chiếu động bằng bản kê từ nguồn, không coi regex là chứng minh đầy đủ.
- [x] Viết test contract cho ba prefab mới, chỉ số nền, đăng ký SG và dependency; chạy fail trước khi thêm implementation.
- [x] Chốt map đầy đủ FX dưới namespace mới trước triển khai Guardian. Không lấy cả mod/main source để thỏa dependency.

## Task 2: Chuyển hai boss lợn

**Files:**
- Modify `scripts/prefabs/hn_bosses.lua`: merge `extra_boss_defs` vào factory hiện tại, giữ ID cũ.
- Create `scripts/stategraphs/SGhn_beetle_pig.lua`, `SGhn_dual_wield_pig.lua`.
- Modify `main/hn_motion_guards.lua` để đăng ký SG mới.
- Create `scripts/prefabs/hn_boss_moonrock_wall.lua`; đăng ký trong `modmain.lua`.
- Test `tests/extra_bosses_test.lua`.

**Interfaces:** Hai boss dùng brain `brains/hn_com_monster`, helper `hn_dungeon/combat`, hiệu ứng `hn_combat_effects:Apply('speed', boss, 10, {multiplier=2})`. Tường tạm có owner/run epoch, không loot, không đào/đập để farm, tự xóa sau 4 giây hoặc khi reset.

- [x] Chuyển enum sang `hn_beetle_pig` (25.000/50/30), `hn_dual_wield_pig` (30.000/50/30); giữ timer chiêu từ nguồn: jump 7, strong 27, control 45, around 12 giây theo boss tương ứng.
- [x] Chuyển đủ 12 state đặt tên của Beetle và 11 state của Dual từ nguồn cùng CommonStates; thay `hh_utils` bằng combat helper, buff tốc độ bằng component hiện có. Không nhập `hh_monster`/`hh_buff`/treasure loot.
- [x] Thay phép kill trực tiếp mục tiêu không có locomotor trong AOE bằng đường combat có lọc mục tiêu; vật phẩm và cấu trúc không phải mục tiêu hợp lệ.
- [x] Thay chiêu vây `wall_moonrock` bằng tường tạm có quản lý; vị trí trong arena, không chặn exit bằng thực thể sống sót sau reset. Theo dõi tường qua manager `Track`, không thêm vào danh sách quái cần giết.
- [x] Test đánh người trong/ngoài hầm, speed refresh/death cleanup, vây 4 giây, phá/cleanup không sinh vật liệu, lặp reset. Chạy `lua HamNgucTuTien/tests/run.lua extra_bosses`.
- [ ] Chạy engine từng state, kiểm tra chuyển động sát tường và đủ animation vanilla Beetletaur/Boarrior. Commit riêng hai boss lợn khi xanh.

## Task 3: Guardian hai pha, không kết thúc lượt sớm

**Files:**
- Create `scripts/prefabs/hn_minotau.lua`, `scripts/brains/hn_minotaubrain.lua`, `scripts/stategraphs/SGhn_minotau.lua`.
- Create `scripts/components/hn_boss_phases.lua`.
- Modify `modmain.lua`, `main/hn_motion_guards.lua` để đăng ký.
- Extend `tests/extra_bosses_test.lua`, `tests/lifecycle_test.lua`.

**Interfaces:** `hn_boss_phases` chỉ gắn lên `hn_minotau`; phase 1 → transitioning → phase 2 → final death, chuyển một lần. Dùng `health:SetMinHealth(1)` và event `minhealth` (kiểm chứng với engine API thực), giữ boss trong `manager.monsters` suốt chuyển pha. Timer chuyển pha 4,5 giây tương ứng chuỗi nguồn; callback chỉ chạy nếu entity/manager/run epoch còn hợp lệ.

- [x] Viết test: đánh quá máu pha 1 không phát final death, không tạo thưởng/khai thông exit; event minhealth lặp không lên nhiều pha. Reset ở giây 4 không làm boss hồi sinh ở 4,5.
- [x] Chuyển prefab/brain/SG Guardian; bỏ nhánh tìm Ruins respawner/home cũ, gắn home tại arena. Các lựa chọn chiêu/di chuyển giữ theo hai pha nguồn.
- [x] Pha đầu giữ minhealth 1; vào state chuyển pha riêng, không đi qua state `death` của game. Tạm ngừng tấn công/nhận damage khi đổi hình. Kết thúc: `SetPercent(1)` trên **maxhealth đã được scale**, mở minhealth về 0, khôi phục khả năng nhận damage/AI và bật Nightmare. Không gọi `ApplyStats` lần hai.
- [x] Mỗi pha 25.000 HP nền, công 60, tốc độ 5/17 và attack period 4. Không thêm hồi máu tự động KLAUS; tránh tăng tổng độ bền ngoài hai thanh máu đã định.
- [x] Chỉ pha 2 mới chết thật và phát `death` cho manager. Bỏ chest spawner/loot hardcode; FX lúc chết cuối chỉ còn hình ảnh, không nổ gây sát thương trong thời gian nhặt thưởng.
- [x] Test với Thần Khí: pha 2 có maxhealth bằng pha 1 ở cùng level; cập nhật realm giữa chuyển pha không nhân hệ số lần hai; final death gọi clear đúng một lần. Engine kiểm chứng minhealth/event order bằng entity QA tối thiểu gắn component phase để không phụ thuộc FX chưa port; chạy boss đầy đủ ở Task 4–5.
- [ ] Commit component phase và prefab/brain/SG Guardian khi test vòng đời pass; ghi rõ dependency FX còn ở Task 4, chưa đăng ký boss vào pool chơi.

## Task 4: FX, damage và giới hạn arena của Guardian

**Files:**
- Create `scripts/hn_dungeon/boss_hazards.lua` và `scripts/prefabs/hn_minotau_fx.lua`.
- Port SG phụ thành `SGhn_minotau_shockwave.lua`, `SGhn_minotau_teleport.lua`, `SGhn_minotau_teleportpost.lua`; nếu giữ death wave visual, dùng tên SG riêng tương ứng.
- Extend motion guards, dependency audit, extra boss tests.

**Map nguồn:** `minotaur_deadlyshockwave`, `minotaur_deathshockwave`, `minotaur_shadowblaze` (gồm `_high`, `_rigidbody`), `minotaurattachedfire_fx`, `minotaurfirecharge_fx`, `minotaurfirering_fx`, `minotaurfiresplash_fx`, `minotaurtarget_fx`, `minotaurteleport_fx`, `minotaurteleportpost_fx`, `minotaurtransform_fx`, `minotaur_weakeningfx`, `shadowpoundring_fx` → tên tương ứng bắt đầu `hn_minotau_`. Chỉ vanilla FX thực sự không tùy biến mới dùng ID vanilla trực tiếp.

**Interfaces:** `boss_hazards.Spawn(owner, prefab, position)` gắn owner/run epoch và gọi `manager:Track`; hazard không vào `manager.monsters`. `boss_hazards.Hit(owner, target, multiplier)` lấy damage từ combat của owner sau scaling, áp dụng combat mục tiêu, không tự scale HP/công của FX.

- [x] Viết test FX không còn owner, owner chết, epoch cũ và target ngoài hầm đều không gây damage; reset dọn sạch, callback trễ không respawn.
- [x] Port asset/animation/âm thanh và trajectory FX nguồn; không trích global tuning hoặc hook thay boss vanilla.
- [x] Damage: đòn trực tiếp/charge/shockwave = ×1 công boss, slam/groundpound = ×1,5; vùng lửa = ×0,15 mỗi giây, tối đa một tick/giây trên mỗi mục tiêu từ cùng boss dù nhiều vùng chồng nhau. Mốc tick thuộc boss, được dọn theo lượt. FX lửa tồn tại tối đa 30 giây hoặc tới lúc boss chết/reset. Guardian không thêm planar.
- [x] Loại bỏ trừ health theo phần trăm, trừ thẳng sanity -999, đốt inventory/công trình và `workable:Destroy` từ các đường source; hình ảnh lửa vẫn giữ, sát thương đi qua helper. Groundpound không phá arena/cổng/đồ.
- [x] Charge/jump/teleport chỉ chấp nhận đường/điểm đáp hợp lệ trong arena; khi không có điểm hợp lệ, ở lại vị trí an toàn và thoát state. Không teleport về Ruins/spawnpoint ngoài hầm.
- [x] Test hit count với 3 vùng lửa chồng nhau; một giây chỉ nhận một tick. Test damage với/không Thần Khí và realm thay đổi; FX không nhận hệ số thứ hai.
- [ ] Engine/client: thử sát mọi cạnh/góc, target dịch chuyển/chết/rời hầm, reset giữa sóng và lửa; vật phẩm trên đất/tường/cổng còn nguyên. Commit FX/arena compatibility khi pass.

## Task 5: Đưa vào pool, kiểm chứng cả lượt và phát hành

**Files:** Modify `scripts/hn_dungeon/waves.lua`, `modinfo.lua`, `README.md`, `SOURCE_MANIFEST.json`, `tests/qa-results.json`, `tests/manual-checklist.md`; create `tests/engine_extra_bosses.lua` chỉ dùng trong mod QA.

- [x] Viết test chọn deterministic RNG: hạng 6 và 10 đều chọn được đủ 6 boss, hạng 5 vẫn 7 boss DST, multiplier boss khó vẫn 1,5. Chạy fail trước khi sửa pool.
- [x] Thêm 3 ID mới vào pool khó; không thêm vào pool quái thường hoặc quái thoát cổng. Hiển thị tên tiếng Việt tương ứng; Guardian dùng “Hộ Vệ Cổ Đại Ác Mộng”.
- [x] Test boss bất kỳ chỉ tạo một rương thắng; Guardian pha 1 không ra rương, pha 2 một rương; không rơi atrium key/dreadhammer/rương riêng. FX/tường không chặn hoàn thành làn.
- [x] Chạy toàn bộ Lua tests, asset Igris test, dependency checker và cú pháp tất cả Lua. Manifest có mapping nguồn→đích và hash nguồn, không khẳng định behavior giữ nguyên tuyệt đối.
- [x] Chạy engine/full stack Tu Tiên + Thần Khí + Nyx + Công Trình + Thành Tựu; kiểm tra các state của 3 boss mới, phase reset, reward và cleanup. QA không được import tự động bởi mod chơi.
- [ ] Client thực với 2 người: đánh cả 3 boss, quan sát animation/FX và chuyển pha, client vào muộn/reconnect, chết/rời trận, thắng/nhặt thưởng, chờ cổng tiếp theo. Kiểm tra không trùng build/prefab, không Lua error, không FX còn gây damage sau clear.
- [ ] Chơi thử đánh giá thời gian và damage thực trước khi chốt chỉ số; mọi điều chỉnh phải được ghi lại, không tự nâng hệ số của toàn bộ quái thế giới.
- [x] Cập nhật version dự kiến `1.1.0`, hướng dẫn cập nhật trên world đã có arena, gói ZIP không kèm QA runner. Chỉ báo các bước đã thực sự kiểm chứng; commit riêng phát hành, không tự upload Workshop.

## Thứ tự và tiêu chí hoàn tất

Task 1 → hai boss lợn (Task 2) → Guardian hai pha (Task 3) → FX/arena (Task 4) → tích hợp/QA (Task 5). Chưa thêm boss vào pool chơi cho tới khi cả state, damage và cleanup đạt.

Hoàn tất khi cả ba boss spawn/đánh/chết được, Guardian chỉ clear sau pha 2, có đúng một lần thưởng, không damage ngoài arena, không phụ thuộc Solo đang bật, và bản cập nhật dùng được trên world có arena sẵn. Luồng cổng hết giờ/quái thoát ra giữ nguyên theo quyết định trước của người dùng.
