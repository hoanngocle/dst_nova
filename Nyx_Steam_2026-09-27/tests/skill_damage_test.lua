package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
unpack = unpack or table.unpack
EQUIPSLOTS = {HANDS = 'hands'}
local Damage = require('util/nyx_skill_damage')
local function eq(actual, expected, label)
    assert(math.abs(actual - expected) < 1e-8,
        label .. ': expected ' .. expected .. ', got ' .. tostring(actual))
end
local held = {components = {weapon = {damage = 100}}}
local owner = {prefab = 'nyx', components = {
    levelsystem = {level = 100},
    inventory = {GetEquippedItem = function(_, slot) assert(slot == 'hands'); return held end},
    combat = {damagemultiplier = 1.2},
}}
local target = {mult = .5}
local potion, perk, upgrade = 1.15, 1.5, 1.3
local calls = 0
Xd_CalcDamage = function(attacker, base, victim, multiplier, basemultiplier)
    calls = calls + 1
    if victim.fail then error('native-calculator-error') end
    if victim.blocked then return 0 end
    return base * (basemultiplier or attacker.components.combat.damagemultiplier)
        * potion * perk * upgrade * victim.mult * (multiplier or 1), 'native-result'
end
local native = Xd_CalcDamage
local scales={triflame_fan=2,eternal_night=2,spirit_sword=3}
local rates = {absolute_domain = 4, triflame_fan = 3.5, yellow_river = 4,
    eternal_night = 3.5, spirit_sword = 2.5}
for skill, levelmult in pairs(rates) do
    Damage.Begin(owner, skill)
    local before = calls
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, (80 * levelmult + 100)*(scales[skill] or 1), target), skill)
    assert(calls == before + 2, 'one native calculation per hit')
end
held.components.weapon.GetDamage = function(_, attacker, victim)
    assert(attacker == owner and victim == target, 'live weapon receives target')
    return 250
end
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 1350, target), 'weapon changed during skill')
potion = 1
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 1350, target), 'potion expired')
held = nil
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 600, target), 'unequipped')
held = {components = {weapon = {damage = 100, GetDamage = function() error('unavailable') end}}}
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 900, target), 'weapon fallback')
-- Luc Mach's held item is a command carrier; GetDamage intentionally returns
-- zero to avoid an extra basic hit, but its enhanced numeric damage is real.
held._ttk_attack_command = function() end
held.components.weapon.GetDamage = function() return 0 end
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 900, target), 'command weapon contribution')
held._ttk_attack_command = nil
held.components.weapon.GetDamage = nil
target.blocked = true
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), 0, 'block also blocks weapon bonus')
target.blocked = nil

-- Installed 18.1 native callbacks pass the effect as local parameter inst.
-- Domain/river own the marker; native fan hitboxes refer to the marked parent.
local function nativeHit(inst, attacker, victim, multiplier, basemultiplier)
    local damage, extra = Xd_CalcDamage(attacker, 80, victim, multiplier, basemultiplier)
    return damage, extra
end
Damage.InstallNativeHook(_G)
local firstHook = Xd_CalcDamage
Damage.InstallNativeHook(_G)
assert(Xd_CalcDamage == firstHook, 'installation must be idempotent')
for _, skill in ipairs({'absolute_domain', 'triflame_fan', 'yellow_river'}) do
    local effect = {}
    Damage.MarkNative(effect, owner, skill)
    local caller = skill == 'triflame_fan' and {owner = effect} or effect
    local damage, extra = nativeHit(caller, owner, target, .8, 1.4)
    eq(damage, native(owner, (80 * rates[skill] + 100)*(scales[skill] or 1), target, .8, 1.4), skill .. ' native')
    assert(extra == 'native-result', 'preserve native return values')
    eq(nativeHit({}, owner, target), native(owner, 80, target), 'unrelated effect during active skill')
    Damage.End(owner, skill)
    eq(nativeHit(caller, owner, target), native(owner, 80, target), 'ended native skill')
end
-- Other mods may wrap the global calculator between the native effect and
-- Nyx's hook; the effect still has to contribute the equipped weapon.
local nyxHook = Xd_CalcDamage
local function intermediateCalculator(attacker, base, victim)
    local result, extra = nyxHook(attacker, base, victim)
    return result, extra
end
Xd_CalcDamage = intermediateCalculator
for _, skill in ipairs({'absolute_domain', 'triflame_fan', 'yellow_river'}) do
    Damage.Begin(owner, skill)
    local wrappedEffect = {}
    Damage.MarkNative(wrappedEffect, owner, skill)
    local caller = skill == 'triflame_fan' and {owner = wrappedEffect} or wrappedEffect
    eq(nativeHit(caller, owner, target), native(owner, (80 * rates[skill] + 100)*(scales[skill] or 1), target),
        skill .. ' through calculator wrapper')
    held.components.weapon.damage = 250
    eq(nativeHit(caller, owner, target), native(owner, (80 * rates[skill] + 250)*(scales[skill] or 1), target),
        skill .. ' reads changed weapon through calculator wrapper')
    held.components.weapon.damage = 100
    potion, perk, upgrade = 1.25, 1.7, 1.4
    eq(nativeHit(caller, owner, target), native(owner, (80 * rates[skill] + 100)*(scales[skill] or 1), target),
        skill .. ' native live potion and Achievement buffs')
    potion, perk, upgrade = 1, 1, 1
    held = nil
    eq(nativeHit(caller, owner, target), native(owner, 80 * rates[skill]*(scales[skill] or 1), target),
        skill .. ' native weapon removal and buff expiry')
    held = {components = {weapon = {damage = 100}}}
    eq(nativeHit({}, owner, target), native(owner, 80, target),
        'unrelated hit through calculator wrapper')
    Damage.End(owner, skill)
end
Xd_CalcDamage = nyxHook
-- A callback can retain its effect in a closure instead of an inst parameter.
Damage.Begin(owner, 'absolute_domain')
local closureEffect = {}
Damage.MarkNative(closureEffect, owner, 'absolute_domain')
local function makeClosure(inst)
    return function()
        assert(inst ~= nil)
        local result = Xd_CalcDamage(owner, 80, target)
        return result
    end
end
eq(makeClosure(closureEffect)(), native(owner, 420, target), 'native effect captured by closure')
local function explicitHit(inst)
    local result = Damage.Calculate(owner, 'absolute_domain', 80, target)
    assert(inst == closureEffect)
    return result
end
eq(explicitHit(closureEffect), native(owner, 420, target), 'explicit calculation inside native callback is not scaled twice')
target.fail = true
local ok, err = pcall(Damage.Calculate, owner, 'absolute_domain', 80, target)
assert(not ok and tostring(err):find('native-calculator-error', 1, true), 'preserve calculator errors')
target.fail = nil
eq(nativeHit(closureEffect, owner, target), native(owner, 420, target), 'native calculation after calculator error')
-- A late integration can reinstall around another mod's wrapper. Both Nyx
-- layers must still send exactly one prepared base to the native calculator.
Xd_CalcDamage = intermediateCalculator
Damage.InstallNativeHook(_G)
local expected = native(owner, 420, target)
local before = calls
eq(nativeHit(closureEffect, owner, target), expected, 'nested hook layers do not scale twice')
assert(calls == before + 1, 'one native calculation through nested hooks')
Xd_CalcDamage = nyxHook
Damage.End(owner, 'absolute_domain')
for skill, levelmult in pairs(rates) do
    Damage.End(owner, skill)
    -- An emitted projectile may outlive the cast handle. Its explicit skill
    -- identity still includes the current weapon and buffs on every hit.
    potion, perk, upgrade = 1.25, 1.7, 1.4
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, (80 * levelmult + 100)*(scales[skill] or 1), target),
        skill .. ' emitted hit with live potion and Achievement buffs')
    potion, perk, upgrade = 1, 1, 1
    held = nil
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, 80 * levelmult*(scales[skill] or 1), target),
        skill .. ' emitted hit after weapon removal and buff expiry')
    held = {components = {weapon = {damage = 100}}}
    Damage.Begin(owner, skill)
end
eq(Damage.Calculate(owner, 'eternal_night', 80, target), native(owner, 760, target), 'owned path is not scaled twice by hook')
local other = {prefab = 'wilson', components = owner.components}
Damage.Begin(other, 'yellow_river')
local foreign = {}
Damage.MarkNative(foreign, other, 'yellow_river')
eq(nativeHit(foreign, other, target), native(other, 80, target), 'other character')
for _, level in ipairs({0, 9, 10, 79, 80, 90, 99, 100, 110}) do
    owner.components.levelsystem.level = level
    local steps = level >= 100 and 10 or math.min(8, math.floor(level / 10))
    eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, (80 * (1 + .15 * steps) + 100)*3, target), 'level ' .. level)
end
print('Nyx skill damage: five skills, live buffs/weapons, native attribution and blocking passed')

-- The bean skill delegates to the upstream projectile, including its summons
-- and owner-based stat calculation. It must not use Nyx's five-skill scaling.
local beanDef = assert(require('nyx/skilldefs').Get('bean_soldiers'), 'bean skill must be selectable')
assert(beanDef.cost == 0 and beanDef.cooldown == 45)
local beanOwner = {components = {health = {IsDead = function() return false end}},
    IsValid = function() return true end, HasTag = function() return false end}
local beanPosition, beanCaster, spawnCount
local beanProjectile = {valid = true, components = {complexprojectile = {
    Launch = function(_, pos, caster) beanPosition, beanCaster = pos, caster end,
}}, Transform = {SetPosition = function() end},
    ListenForEvent = function(self,event,fn) if event=='onremove' then self.onremove=fn end end,
    IsValid = function(self) return self.valid end,
    Remove = function(self) self.valid = false; if self.onremove then self.onremove() end end}
Prefabs = {xd_wmz_sdcb = true, xd_wmz_db = true}
SpawnPrefab = function(name)
    assert(name == 'xd_wmz_sdcb', 'must spawn the original projectile')
    spawnCount = (spawnCount or 0) + 1
    return beanProjectile
end
Vector3 = function(x,y,z) return {x=x,y=y,z=z} end
beanOwner.Transform = {GetWorldPosition = function() return 1,0,2 end}
local bean = assert(require('nyx/attack18').Prepare(beanOwner, 'bean_soldiers', {x=5,z=6}))
assert(bean:Start() and spawnCount == 1)
assert(beanCaster == beanOwner and beanPosition.x == 5 and beanPosition.z == 6)
assert(beanOwner._nyx_skill_damage_bonus.bean_explosion, 'enable attributed explosion calculation')
assert(not bean:IsDone())
beanProjectile:Remove()
assert(bean:IsDone(), 'finish once the native projectile explodes')
assert(not beanOwner._nyx_skill_damage_bonus,'clear explosion attribution on removal')
Prefabs.xd_wmz_db = nil
local missing = assert(require('nyx/attack18').Prepare(beanOwner, 'bean_soldiers', {x=5,z=6}))
assert(not missing:Start() and spawnCount == 1, 'missing upstream summon must fail before spawning')
print('Nyx bean soldiers: native delegation and missing-prefab guard passed (mock)')
local beanClock, beanStarts = 100, 0
local beanPort = {
    clock = function() return beanClock end,
    read = function() return {ready=true,level=1,realm_rank=0,current=0} end,
    alive = function() return true end, valid = function() return true end,
    spend = function(n) assert(n==0); return true end,
    refund = function(n) assert(n==0) end,
    prepare = function()
        return {Start=function() beanStarts=beanStarts+1; return true end,
            Cancel=function() end, IsDone=function() return true end}
    end,
}
local beanController = require('nyx/casting').New(beanPort)
assert(beanController:Request('bean_soldiers',{x=5,z=6},1), 'usable with zero Linh Luc')
assert(not beanController:Request('bean_soldiers',{x=5,z=6},2) and beanStarts==1)
beanClock=110
local savedBeans=beanController:Save()
local restoredBeans=require('nyx/casting').New(beanPort)
restoredBeans:Load(savedBeans)
assert(restoredBeans:Remaining('bean_soldiers')==35, 'preserve remaining cooldown after load')
beanClock=145
assert(restoredBeans:Request('bean_soldiers',{x=5,z=6},3) and beanStarts==2)
print('Nyx bean soldiers: zero resource, cooldown and reload passed (mock)')

-- Native CopyFromPlayer installs its own CalcDamage. The Nyx adapter must
-- run after that setup, read the current weapon/buffs on every hit, and
-- leave another character's summons on the original path.
local summonPostInit
TheWorld = {ismastersim=true}
Damage.InstallSummonHook({AddPrefabPostInit=function(name,fn)
    assert(name=='xd_wmz_db'); summonPostInit=fn
end})
owner.IsValid = function() return true end
local soldier = {components={combat={defaultdamage=20}}}
soldier.CopyFromPlayer = function(inst,master,load)
    inst.owner=master
    inst.components.combat.CalcDamage=function(self,victim)
        return native(inst.owner,self.defaultdamage,victim)
    end
    return 'copied',nil,load
end
summonPostInit(soldier)
local copied,gap,load= soldier:CopyFromPlayer(owner,true)
assert(copied=='copied' and gap==nil and load==true, 'preserve upstream copy results')
held={components={weapon={damage=100}}}
potion,perk,upgrade=1.15,1.5,1.3
local beforeSoldier=calls
local result,extra=soldier.components.combat:CalcDamage(target)
eq(result,native(owner,2300,target),'soldier level, weapon and all owner bonuses')
assert(extra=='native-result' and calls==beforeSoldier+2,'one native calculation per soldier hit')
held.components.weapon.damage=250
potion,perk,upgrade=1.25,1.7,1.4
eq(soldier.components.combat:CalcDamage(target),native(owner,2450,target),'soldier live weapon and changed buffs')
held=nil
eq(soldier.components.combat:CalcDamage(target),native(owner,2200,target),'soldier weapon removed')
held={components={weapon={damage=100}}}
soldier:CopyFromPlayer(owner,false)
eq(soldier.components.combat:CalcDamage(target),native(owner,2300,target),'repeated copy does not double weapon')
for _,level in ipairs({1,2,3,4,5,6,7,10,29,80,99,100,110,1000}) do
    owner.components.levelsystem.level=level
    eq(soldier.components.combat:CalcDamage(target),native(owner,20*level+100,target),'uncapped soldier level '..level)
end
owner.components.levelsystem.level=110
local explosion={}
Damage.Begin(owner,'bean_explosion')
Damage.MarkNative(explosion,owner,'bean_explosion')
for _,case in ipairs({{1,200},{9,200},{10,300},{20,400},{30,500},{40,600},{80,1000},{99,1100},{100,1200},{110,1300},{1000,10200}}) do
    owner.components.levelsystem.level=case[1]
    eq(nativeHit(explosion,owner,target),native(owner,case[2]+100,target),'uncapped explosion at '..case[1])
end
eq(nativeHit({},owner,target),native(owner,80,target),'unmarked explosion remains native')
Damage.End(owner,'bean_explosion')
eq(nativeHit(explosion,owner,target),native(owner,80,target),'removed explosion remains native')
owner.components.levelsystem.level=110
target.blocked=true
eq(soldier.components.combat:CalcDamage(target),0,'soldier alwaysblock includes weapon')
target.blocked=nil
local foreignMaster={prefab='xd_wangmazi',components=owner.components,IsValid=owner.IsValid}
soldier:CopyFromPlayer(foreignMaster,false)
eq(soldier.components.combat:CalcDamage(target),native(foreignMaster,20,target),'original character unchanged')
TheWorld.ismastersim=false
local clientSoldier={}
summonPostInit(clientSoldier)
assert(clientSoldier.CopyFromPlayer==nil,'client has no combat adapter')
print('Nyx soldier damage: live weapon/bonuses, repeated setup, native blocking and foreign/client paths passed (mock)')
TheWorld.ismastersim=true
local landedAttacker,landedWeapon
local nativeGetAttacked=function(_,attacker,damage,weapon)
    landedAttacker,landedWeapon=attacker,weapon
    if target.hitfail then error('hit-stage-error') end
    return true,damage,'landed'
end
target.components={combat={GetAttacked=nativeGetAttacked}}
soldier.components.combat.DoAttack=function(self,victim)
    victim=victim or self.target
    return victim.components.combat:GetAttacked(soldier,self:CalcDamage(victim))
end
soldier:CopyFromPlayer(owner)
held={components={weapon={damage=100}}}
local hit,hitDamage,hitExtra=soldier.components.combat:DoAttack(target)
assert(hit and hitExtra=='landed' and landedAttacker==owner and landedWeapon==held,
    'hit-stage owner and current weapon must reach other mod wrappers')
eq(hitDamage,native(owner,2300,target),'hit-stage damage calculated once')
assert(target.components.combat.GetAttacked==nativeGetAttacked,'restore victim method after hit')
target.hitfail=true
local hitOK,hitError=pcall(soldier.components.combat.DoAttack,soldier.components.combat,target)
assert(not hitOK and tostring(hitError):find('hit-stage-error',1,true))
assert(target.components.combat.GetAttacked==nativeGetAttacked,'restore victim method after hit error')
target.hitfail=nil
held=nil
soldier.components.combat.target=target
soldier.components.combat:DoAttack()
assert(landedAttacker==owner and landedWeapon==nil,'implicit target and weapon removal')
soldier:CopyFromPlayer(foreignMaster)
soldier.components.combat:DoAttack(target)
assert(landedAttacker==soldier,'foreign summons retain native attacker')
print('Nyx soldier hit-stage: owner/weapon bonuses, return values, target fallback and error cleanup passed (mock)')
