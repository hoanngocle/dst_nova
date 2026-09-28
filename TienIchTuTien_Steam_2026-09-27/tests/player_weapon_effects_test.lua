package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

EQUIPSLOTS = {HEAD = "HEAD", BODY = "BODY", HANDS = "HANDS"}
local Effects = require("tbc_strengthen_effects")
local Detail = require("ttk_item_detail")
local Player = require("ttk_player_detail")
local source = {weapon_preview = Effects.Preview}
local weapon = {components = {
    weapon = {damage = 1024},
    tbc_upgrade = {level = 16, IsWeaponMilestone = function() return true end},
}}
local current_weapon = weapon
local combat = {GetWeapon = function() return current_weapon end,
    defaultdamage = 10, damagemultiplier = 1, damagebonus = 0}
local server = {components = {combat = combat,
    locomotor = {GetRunSpeed = function() return 6 end}}}

local stats = Player.Measure(server, source)
assert(stats.strengthen_level == 16 and stats.damage == 1024)
current_weapon = {components = {weapon = {damage = 1024}}, _tbc_source_item = weapon}
assert(Player.Measure(server, source).strengthen_level == 16,
    "weapon proxies use the upgraded source item")
current_weapon = weapon
local wire = Player.Encode(stats)
local client = {_ttk_player_detail = {value = function() return wire end},
    HasTag = function() return false end}
local decoded = Player.Read(client, source)
assert(decoded.strengthen_level == 16)
local data = {str = {{"Cảnh giới tu tiên", "Luyện Khí Tiên Kỳ"},
    {"伤害", 1024}, {"Sát thương xuyên giáp: 0"}}}
local augmented = Player.Augment(data, decoded, source, Detail)
local lines = {}
for _, row in ipairs(augmented.str) do lines[#lines + 1] = row[1] end
local output = table.concat(lines, "\n")
assert(output:find("Bộc Liệt", 1, true) and output:find("512", 1, true))
assert(output:find("Thiên Kiếp", 1, true), "equipped effects appear in player detail")
assert(output:find("Sát thương xuyên giáp: 500", 1, true),
    "the status stat includes the equipped weapon's true damage")

current_weapon = nil
local bare = Player.Measure(server, source)
local bare_client = {_ttk_player_detail = {value = function() return Player.Encode(bare) end},
    HasTag = function() return false end}
local bare_rows = Player.Augment(data, Player.Read(bare_client, source), source, Detail)
for _, row in ipairs(bare_rows.str) do
    assert(not row[1]:find("Bộc Liệt", 1, true), "unequipped effects disappear")
end
print("player_weapon_effects_test: ok")
