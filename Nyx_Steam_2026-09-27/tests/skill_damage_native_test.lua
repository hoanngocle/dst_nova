-- Optional integration with the locally extracted, unmodified Tu Tien 18.1
-- GLOBAL.Xd_CalcDamage definition. Do not redistribute upstream source.
local source = os.getenv('NYX_NATIVE_CALC')
if source == nil then
    print('Nyx native damage integration: skipped (NYX_NATIVE_CALC not set)')
    return
end
package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
GLOBAL = _G
EQUIPSLOTS = {HANDS = 'hands', NECK = 'neck'}
getelectricstimuli = function() return 1.6 end
XD_GetTaoZhuangDamageBonus = function() return .2 end
dofile(source)
local native = assert(Xd_CalcDamage)
local Damage = require('util/nyx_skill_damage')
local tags, mods = {}, {potion = 1.15, damagePerk = 1.5, damageUpgrade = 1.3}
local external = {Get = function()
    local result = 1
    for _, value in pairs(mods) do result = result * value end
    return result
end}
local weapon = {components = {
    weapon = {GetDamage = function() return 100 end},
    xd_fumo = {
        GetDamage = function() return 1.4 end,
        GetSkillDamageRate = function() return 1.2 end,
        GetByDamage = function() return .1 end,
    },
}}
local necklace = {components = {container = {slots = {{damagefn = function() return .3 end}}}}}
local armor = {components = {xd_armorfumo = {GetDamage = function() return .2 end}}}
local owner = {prefab = 'nyx', components = {
    levelsystem = {level = 100},
    combat = {damagemultiplier = 1.1, externaldamagemultipliers = external,
        pvp_damagemod = .5, playerdamagepercent = .8},
    inventory = {
        GetEquippedItem = function(_, slot) return slot == 'hands' and weapon or necklace end,
        EquipHasTag = function(_, tag) return tags[tag] end,
        equipslots = {armor},
    },
    xd_gem = {GetDamage = function() return .3 end},
}, HasTag = function(_, tag) return tag == 'player' end}
owner.components.combat.inst = owner
local targetTags = {}
local target = {components = {xd_guaiwu_skills = {by = 'test'}},
    HasTag = function(_, tag) return targetTags[tag] end}
local function eq(a, b, label) assert(math.abs(a-b) < 1e-8, label .. ': ' .. a .. ' ~= ' .. b) end
local rates = {absolute_domain = 4, triflame_fan = 3.5, yellow_river = 4,
    eternal_night = 3.5, spirit_sword = 2.5}
Damage.InstallNativeHook(_G)
for skill, rate in pairs(rates) do
    Damage.Begin(owner, skill)
    tags = {xd_fumo = true, xd_armorfumo = true, xd_diaozhui = true}
    local total = (80 * rate + 100) * 1.6 * 1.1 * external:Get() * 1.4 * 1.2 * 1.6
    eq(Damage.Calculate(owner, skill, 80, target), total, skill .. ' native fumo and armor')
    tags = {xd_armorfumo = true, xd_diaozhui = true}
    total = (80 * rate + 100) * 1.6 * 1.1 * external:Get() * 1.5 * 1.3 * 1.2
    eq(Damage.Calculate(owner, skill, 80, target), total, skill .. ' native necklace/set')
    targetTags.player = true
    eq(Damage.Calculate(owner, skill, 80, target), total * .8 * .5, skill .. ' native PvP')
    targetTags.alwaysblock = true
    eq(Damage.Calculate(owner, skill, 80, target), 0, skill .. ' native alwaysblock')
    targetTags = {}
end
mods.potion = nil
mods.damageUpgrade = 2
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 300, target), 'live native modifiers')
print('Nyx damage integration: actual Tu Tien calculator passed for all five skills and native modifiers')
