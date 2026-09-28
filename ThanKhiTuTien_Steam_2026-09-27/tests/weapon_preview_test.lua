package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

EQUIPSLOTS = {HEAD = "HEAD", BODY = "BODY", HANDS = "HANDS"}
local Effects = require("tbc_strengthen_effects")
local Detail = require("ttk_item_detail")

local early = Effects.Preview(3, 100)
assert(early.splash_damage == 3, "level 3 splash uses the actual 3% coefficient")
assert(early.bonus_damage == nil, "level 3 has no extra direct hit")

local full = Effects.Preview(16, 1024)
assert(full.splash_damage == 512, "level 16 splash is 50% of the attack")
assert(full.bonus_damage == 90, "level 16 extra hit is 90")
assert(full.stun_chance == 40 and full.shadow_chance == 40)
assert(full.shadow_damage == 9216, "level 16 shadow total uses the 9x coefficient")

local item = {
    components = {},
    _tbc_detail = {value = function() return "16;" end},
    _tbc_strengthen_stat = {value = function()
        return "Sát thương hiện tại: 1024 (+924 từ cường hóa)"
    end},
    HasTag = function(_, tag) return tag == "weapon" end,
    IsValid = function() return true end,
}
local detail = Detail.Read(item, {weapon_preview = Effects.Preview})
assert(detail.weapon_damage == 1024 and detail.preview.splash_damage == 512)
local rows = Detail.StrengthenRows(detail)
local all = {}
for _, row in ipairs(rows) do all[#all + 1] = row.text end
local description = table.concat(all, "\n")
assert(description:find("512", 1, true), "tooltip shows splash damage amount")
assert(description:find("90", 1, true), "tooltip shows extra hit amount")
assert(description:find("40%%"), "tooltip shows actual trigger chance")
assert(description:find("9216", 1, true), "tooltip shows shadow total")
local locked = Detail.StrengthenRows({kind = "weapon", level = 0})
for _, row in ipairs(locked) do
    assert(not row.text:find("?", 1, true), "locked milestones stay readable")
end
print("weapon_preview_test: ok")
