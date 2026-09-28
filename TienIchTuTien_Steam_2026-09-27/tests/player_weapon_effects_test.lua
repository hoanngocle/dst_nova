package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

EQUIPSLOTS = {HEAD = "HEAD", BODY = "BODY", HANDS = "HANDS"}
local Player = require("ttk_player_detail")
local source = {
    combat_stats = function(_, weapon)
        return {crit_rate = weapon ~= nil and 17 or 10,
            crit_effect = weapon ~= nil and 50 or 0,
            pierce = weapon ~= nil and 12 or 10}
    end,
    flat_pierce = function(_, weapon)
        return weapon ~= nil and 500 or 0
    end,
}
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
assert(stats.crit_rate == 17 and stats.crit_damage == 250)
assert(stats.pierce_percent == 12 and stats.flat_pierce == 500)
current_weapon = {components = {weapon = {damage = 1024}}, _tbc_source_item = weapon}
assert(Player.Measure(server, source).strengthen_level == 16,
    "weapon proxies use the upgraded source item")
current_weapon = weapon
local wire = Player.Encode(stats)
local client = {_ttk_player_detail = {value = function() return wire end},
    HasTag = function() return false end}
local decoded = Player.Read(client, source)
assert(decoded.crit_rate == 17 and decoded.crit_damage == 250)
assert(decoded.pierce_percent == 12 and decoded.flat_pierce == 500)
local data = {str = {{"Cảnh giới tu tiên", "Luyện Khí Tiên Kỳ"},
    {"伤害", 1024}, {"Sát thương xuyên giáp: 0"}}}
local augmented = Player.Augment(data, decoded)
local lines = {}
for _, row in ipairs(augmented.str) do lines[#lines + 1] = row[1] end
local output = table.concat(lines, "\n")
assert(output:find("Tỷ lệ bạo kích: 17%", 1, true))
assert(output:find("Sát thương bạo kích: 250%", 1, true))
assert(output:find("Tỷ lệ xuyên giáp: 12%", 1, true))
assert(output:find("Sát thương xuyên giáp: 500", 1, true),
    "the status stat includes the equipped weapon's true damage")
assert(not output:find("CƯỜNG HÓA", 1, true)
    and not output:find("Bộc Liệt", 1, true),
    "player detail contains numbers, not weapon skill descriptions")

current_weapon = nil
local bare = Player.Measure(server, source)
local bare_client = {_ttk_player_detail = {value = function() return Player.Encode(bare) end},
    HasTag = function() return false end}
local bare_rows = Player.Augment(data, Player.Read(bare_client, source))
for _, row in ipairs(bare_rows.str) do
    assert(not row[1]:find("CƯỜNG HÓA", 1, true), "unequipped effects disappear")
end
print("player_weapon_effects_test: ok")
