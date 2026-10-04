package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local callbacks = {}
local Banner = require("tbc_soul_banner")
Banner.Install(function(name, callback) callbacks[name] = callback end)

assert(callbacks.vanhonphien ~= nil, "the item in the original prefab is supported")
assert(callbacks.vanhonphien_ground ~= nil, "the deployed banner is supported")
assert(callbacks.vanhonphien_soul ~= nil, "the actual summoned soul is supported")

TheWorld = {ismastersim = true}
TheWorld.ismastersim = false
for _, prefab in ipairs({"vanhonphien_soul", "xd_wmz_zhf_soul"}) do
    local client_soul = {prefab = prefab}
    callbacks[prefab](client_soul)
    assert(client_soul.displaynamefn ~= nil
        and client_soul.displaynamefn(client_soul) == "Hồn Linh",
        "the summoned soul has a short name on the client")
end
TheWorld.ismastersim = true
local banner = {_tbc_banner_level = 0}
local soul = {components = {}, tags = {}}
function soul:DoTaskInTime(_, fn) self.pending = fn end
function soul:AddTag(tag) self.tags[tag] = true end
function soul:IsValid() return true end
soul.components.entitytracker = {GetEntity = function(_, key)
    return key == "banner" and banner or nil
end}
soul.components.combat = {
    defaultdamage = 20,
    SetDefaultDamage = function(self, amount) self.defaultdamage = amount end,
    CalcDamage = function(self) return self.defaultdamage * 1.05 end,
}
-- The original mod replaces CalcDamage when it assigns the summoner.
soul.OnSpawnedBy = function(inst)
    inst.components.combat.CalcDamage = function(self)
        return self.defaultdamage * 1.05
    end
end

callbacks.vanhonphien_soul(soul)
soul:OnSpawnedBy({})
if soul.pending ~= nil then soul.pending() end
assert(soul.components.combat.defaultdamage == 50,
    "inspectable combat damage must show the strengthened base")
assert(math.abs(soul.components.combat:CalcDamage() - 52.5) < .000001,
    "the actual projectile hit preserves the owner's 5 percent bonus")

banner._tbc_banner_level = 3
local original_random = math.random
math.random = function() return .99 end
assert(math.abs(soul.components.combat:CalcDamage() - 90.72) < .000001,
    "strengthening affects the real combat path after spawning")
math.random = original_random
print("soul_banner_live_prefab_test: ok")
