package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local callbacks = {}
local M = require("tbc_soul_banner")
M.Install(function(name, callback) callbacks[name] = callback end)

assert(M.Damage(0) == 50, "new soul base damage is 50")
assert(math.abs(M.Damage(1) - 60) < .000001, "each level increases the previous level by 20%")
assert(math.abs(M.Damage(16) - 924.4212944751815) < .000001,
    "level 16 compounds sixteen times")
for _, row in ipairs({
    {0, 0, 0}, {2, 0, 0}, {3, 10, 20}, {4, 10, 20},
    {5, 20, 40}, {7, 30, 60}, {9, 40, 80}, {10, 40, 80},
    {11, 50, 100}, {12, 50, 100}, {13, 60, 120},
    {15, 60, 120}, {16, 70, 140},
}) do
    local rate, effect = M.CritBonus(row[1])
    assert(rate == row[2] and effect == row[3],
        "critical bonuses accumulate at all seven milestone levels")
end

local function Entity(prefab)
    local inst = {prefab = prefab, components = {}, tags = {}, valid = true}
    function inst:AddTag(tag) self.tags[tag] = true end
    function inst:HasTag(tag) return self.tags[tag] == true end
    function inst:IsValid() return self.valid end
    function inst:DoTaskInTime(_, fn) self.pending = fn end
    function inst:AddComponent(name)
        if name == "tbc_upgrade" then
            self.components[name] = {
                level = 0,
                SetLevel = function(component, level) component.level = level; return true end,
                UpdateDisplay = function() end,
            }
        end
    end
    return inst
end

TheWorld = {ismastersim = true}
local item = Entity("xd_wmz_zhf")
item.components.inventoryitem = {}
item.components.deployable = {ondeploy = function()
    local ground = Entity("xd_wmz_zhf_ground")
    ground.components.portablestructure = {ondismantlefn = function()
        local recovered = Entity("xd_wmz_zhf")
        recovered.components.inventoryitem = {}
        recovered.components.deployable = {ondeploy = function() end}
        callbacks.xd_wmz_zhf(recovered)
        ground.recovered_item = recovered
    end}
    callbacks.xd_wmz_zhf_ground(ground)
    item.spawned_ground = ground
end}
callbacks.xd_wmz_zhf(item)
item.components.tbc_upgrade:SetLevel(3)
item.components.deployable.ondeploy(item, {}, {})
local ground = item.spawned_ground
assert(ground._tbc_banner_level == 3, "deploy carries the strengthened level")
local saved = {}
ground:OnSave(saved)
ground._tbc_banner_level = 0
ground:OnLoad(saved)
assert(ground._tbc_banner_level == 3, "world save restores the deployed banner level")

ground.components.portablestructure.ondismantlefn(ground, {})
local recovered = ground.recovered_item
assert(recovered.components.tbc_upgrade.level == 3, "dismantle preserves the level")

local soul = Entity("xd_wmz_zhf_soul")
soul.components.entitytracker = {GetEntity = function() return ground end}
soul.components.combat = {
    defaultdamage = 20,
    SetDefaultDamage = function(self, amount) self.defaultdamage = amount end,
    CalcDamage = function(self) return self.defaultdamage end,
}
callbacks.xd_wmz_zhf_soul(soul)
local original_random = math.random
math.random = function() return .99 end
assert(math.abs(soul.components.combat:CalcDamage() - 86.4) < .000001,
    "a soul attacking for the strengthened banner uses 50 times 1.2 cubed")
math.random = function() return .05 end
assert(math.abs(soul.components.combat:CalcDamage() - 190.08) < .000001,
    "a +3 soul crits for 2.2 times its strengthened damage")
ground._tbc_banner_level = 5
assert(math.abs(soul.components.combat:CalcDamage() - 298.5984) < .000001,
    "a +5 soul gets a 2.4 times critical multiplier")
ground._tbc_banner_level = 16
assert(math.abs(soul.components.combat:CalcDamage() - 3143.032401215617) < .000001,
    "a +16 soul gets all seven critical damage bonuses")
ground._tbc_banner_level = 0
assert(soul.components.combat:CalcDamage() == 50, "soul reads the current banner level")
math.random = original_random

Class = function(constructor)
    local prototype = {}
    return setmetatable(prototype, {__call = function(_, inst)
        local instance = setmetatable({}, {__index = prototype})
        constructor(instance, inst)
        return instance
    end})
end
local Upgrade = require("components/tbc_upgrade")
local actual = Upgrade(item)
actual.level = 3
assert(actual:GetKind() == "soul_banner", "banner enters the strengthening system")
local kind, current, next_damage = actual:GetStrengthenPreview()
assert(kind == "soul_banner" and math.abs(current - 86.4) < .000001)
assert(math.abs(next_damage - 103.68) < .000001,
    "forge preview shows the next compounded soul damage")
item.tags.weapon = true
item._tbc_detail = {value = function() return "3;" end}
item._tbc_strengthen_stat = {value = function() return "Sát thương Hồn Linh: 86.40" end}
local detail = require("ttk_item_detail").Read(item, {max_affixes = 5})
assert(detail.kind == "soul_banner", "detail panel recognizes the banner")
assert(#require("ttk_item_detail").StrengthenRows(detail) == 0,
    "banner does not inherit unrelated weapon milestones")
local section = require("tbc_display").SectionsFromState("3;", item)[1]
assert(section.desc:find("86.40", 1, true), "hover shows soul damage")
assert(section.desc:find("10%", 1, true) and section.desc:find("20%", 1, true),
    "hover shows the +3 critical bonuses")
local final_section = require("tbc_display").SectionsFromState("16;", item)[1]
assert(final_section.desc:find("70%", 1, true)
    and final_section.desc:find("140%", 1, true),
    "hover shows the +16 cumulative critical bonuses")
assert(not section.desc:find("Bộc Liệt", 1, true), "hover excludes weapon milestones")
print("soul_banner_strengthen_test: ok")
