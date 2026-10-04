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
local rates = {absolute_domain = 4, triflame_fan = 3.5, yellow_river = 4,
    eternal_night = 3.5, spirit_sword = 2.5}
for skill, levelmult in pairs(rates) do
    Damage.Begin(owner, skill)
    local before = calls
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, 80 * levelmult + 100, target), skill)
    assert(calls == before + 2, 'one native calculation per hit')
end
held.components.weapon.GetDamage = function(_, attacker, victim)
    assert(attacker == owner and victim == target, 'live weapon receives target')
    return 250
end
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 450, target), 'weapon changed during skill')
potion = 1
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 450, target), 'potion expired')
held = nil
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 200, target), 'unequipped')
held = {components = {weapon = {damage = 100, GetDamage = function() error('unavailable') end}}}
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 300, target), 'weapon fallback')
-- Luc Mach's held item is a command carrier; GetDamage intentionally returns
-- zero to avoid an extra basic hit, but its enhanced numeric damage is real.
held._ttk_attack_command = function() end
held.components.weapon.GetDamage = function() return 0 end
eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 300, target), 'command weapon contribution')
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
    eq(damage, native(owner, 80 * rates[skill] + 100, target, .8, 1.4), skill .. ' native')
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
    eq(nativeHit(caller, owner, target), native(owner, 80 * rates[skill] + 100, target),
        skill .. ' through calculator wrapper')
    held.components.weapon.damage = 250
    eq(nativeHit(caller, owner, target), native(owner, 80 * rates[skill] + 250, target),
        skill .. ' reads changed weapon through calculator wrapper')
    held.components.weapon.damage = 100
    potion, perk, upgrade = 1.25, 1.7, 1.4
    eq(nativeHit(caller, owner, target), native(owner, 80 * rates[skill] + 100, target),
        skill .. ' native live potion and Achievement buffs')
    potion, perk, upgrade = 1, 1, 1
    held = nil
    eq(nativeHit(caller, owner, target), native(owner, 80 * rates[skill], target),
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
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, 80 * levelmult + 100, target),
        skill .. ' emitted hit with live potion and Achievement buffs')
    potion, perk, upgrade = 1, 1, 1
    held = nil
    eq(Damage.Calculate(owner, skill, 80, target), native(owner, 80 * levelmult, target),
        skill .. ' emitted hit after weapon removal and buff expiry')
    held = {components = {weapon = {damage = 100}}}
    Damage.Begin(owner, skill)
end
eq(Damage.Calculate(owner, 'eternal_night', 80, target), native(owner, 380, target), 'owned path is not scaled twice by hook')
local other = {prefab = 'wilson', components = owner.components}
Damage.Begin(other, 'yellow_river')
local foreign = {}
Damage.MarkNative(foreign, other, 'yellow_river')
eq(nativeHit(foreign, other, target), native(other, 80, target), 'other character')
for _, level in ipairs({0, 9, 10, 79, 80, 90, 99, 100, 110}) do
    owner.components.levelsystem.level = level
    local steps = level >= 100 and 10 or math.min(8, math.floor(level / 10))
    eq(Damage.Calculate(owner, 'spirit_sword', 80, target), native(owner, 80 * (1 + .15 * steps) + 100, target), 'level ' .. level)
end
print('Nyx skill damage: five skills, live buffs/weapons, native attribution and blocking passed')
