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
local scales={triflame_fan=2,eternal_night=2,spirit_sword=3}
Damage.InstallNativeHook(_G)
local explosion={}
Damage.Begin(owner,'bean_explosion')
Damage.MarkNative(explosion,owner,'bean_explosion')
local function nativeExplosion(inst,victim)
    local value=Xd_CalcDamage(owner,200,victim)
    return value
end
for _,case in ipairs({{1,200},{10,300},{99,1100},{100,1200},{1000,10200}}) do
    owner.components.levelsystem.level=case[1]
    eq(nativeExplosion(explosion,target),native(owner,case[2]+100,target),'explosion actual native level '..case[1])
end
Damage.End(owner,'bean_explosion')
owner.components.levelsystem.level=100
for skill, rate in pairs(rates) do
    Damage.Begin(owner, skill)
    tags = {xd_fumo = true, xd_armorfumo = true, xd_diaozhui = true}
    local total = (80 * rate + 100) * (scales[skill] or 1) * 1.6 * 1.1 * external:Get() * 1.4 * 1.2 * 1.6
    eq(Damage.Calculate(owner, skill, 80, target), total, skill .. ' native fumo and armor')
    tags = {xd_armorfumo = true, xd_diaozhui = true}
    total = (80 * rate + 100) * (scales[skill] or 1) * 1.6 * 1.1 * external:Get() * 1.5 * 1.3 * 1.2
    eq(Damage.Calculate(owner, skill, 80, target), total, skill .. ' native necklace/set')
    targetTags.player = true
    eq(Damage.Calculate(owner, skill, 80, target), total * .8 * .5, skill .. ' native PvP')
    targetTags.alwaysblock = true
    eq(Damage.Calculate(owner, skill, 80, target), 0, skill .. ' native alwaysblock')
    targetTags = {}
end
mods.potion = nil
mods.damageUpgrade = 2
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 900, target), 'live native modifiers')
print('Nyx damage integration: actual Tu Tien calculator passed for all five skills and native modifiers')
local summonPostInit
TheWorld={ismastersim=true}
owner.IsValid=function() return true end
Damage.InstallSummonHook({AddPrefabPostInit=function(_,fn) summonPostInit=fn end})
local soldier={components={combat={defaultdamage=20}}}
soldier.CopyFromPlayer=function(inst,master)
    inst.owner=master
    inst.components.combat.CalcDamage=function(self,victim) return native(master,20,victim) end
end
summonPostInit(soldier)
soldier:CopyFromPlayer(owner)
eq(soldier.components.combat:CalcDamage(target),native(owner,2100,target),'soldier actual native level/weapon/bonuses')
weapon.components.weapon.GetDamage=function() return 250 end
mods.damageUpgrade=1.25
eq(soldier.components.combat:CalcDamage(target),native(owner,2250,target),'soldier actual native live weapon/buff change')
targetTags.player=true
eq(soldier.components.combat:CalcDamage(target),native(owner,2250,target),'soldier actual native PvP')
targetTags.alwaysblock=true
eq(soldier.components.combat:CalcDamage(target),0,'soldier actual native alwaysblock')
print('Nyx soldier integration: actual Tu Tien calculator passed (mock entities; not engine)')
-- Exercise the actual target-side Than Khi wrapper as well as Xd_CalcDamage.
package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local ThanKhi=require('tbc_combat')
local defs=require('tbc_affix/defs')
local affixes={}
for code,row in pairs(defs.by_code) do
    if row.effect_key=='trueDamageNum' then
        affixes[#affixes+1]={id=code,value=10*row.scale}; break
    end
end
weapon.components.tbc_upgrade={level=16,affixes=affixes,
    IsWeaponMilestone=function() return true end,
    GetCombatStats=function() return {pierce=10} end}
local hitValues={addComDamage=20,addComDamagePercent=20,trueDamageNum=15}
owner.components.tbc_player_effects={Get=function(_,key) return hitValues[key] or 0 end,
    Has=function(_,key) return (hitValues[key] or 0)>0 end}
targetTags={}
local primaryDamage,primaryPierce,primaryAttacker,primaryWeapon
target.components.health={IsDead=function() return false end}
target.components.combat={inst=target,GetAttacked=function(_,attacker,damage,held,stimuli,packet)
    if stimuli==nil then
        primaryDamage,primaryPierce=damage,packet and packet.tbc_armor_pierce or 0
        primaryAttacker,primaryWeapon=attacker,held
    end
    return true
end}
ThanKhi.Install(target.components.combat,true,function() return 100 end)
soldier.components.combat.DoAttack=function(self,victim)
    return victim.components.combat:GetAttacked(soldier,self:CalcDamage(victim))
end
soldier:CopyFromPlayer(owner)
assert(soldier.components.combat:DoAttack(target))
local expectedPhysical=(native(owner,2250,target)+20)*1.2
eq(primaryDamage,expectedPhysical,'soldier actual hit-stage owner flat and percent bonuses')
eq(primaryPierce,expectedPhysical*.3+15+500,'soldier actual pierce, affix and strengthen true damage once')
assert(primaryAttacker==owner and primaryWeapon==weapon,'actual hit-stage receives Nyx and held weapon')
print('Nyx soldier integration: real Than Khi hit-stage flat/percent, armor pierce, affix and strengthen bonuses passed (mock entities)')
