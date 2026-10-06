package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path

local Reload = require('functions/tutienhealthreload')

local player = { components = {} }
local health = { maxhealth = 128, currenthealth = 100,
    _tbc_elixir_base = 128, _tbc_elixir_last_max = 128 }
function health:GetMaxWithPenalty() return self.maxhealth end
function health:SetCurrentHealth(value) self.currenthealth = value end
function health:_tbc_elixir_capture()
    self._tbc_elixir_base = self._tbc_elixir_base
        + self.maxhealth - self._tbc_elixir_last_max
    self._tbc_elixir_last_max = self.maxhealth
end
player.components.health = health
local hunger = { max = 120, current = 80 }
function hunger:SetCurrent(value) self.current = value end
player.components.hunger = hunger
local sanity = { max = 200, current = 60 }
function sanity:SetCurrent(value) self.current = value end
player.components.sanity = sanity
local body = { level = 46, calls = 0 }
function body:SetLevel(level)
    assert(level == 46)
    self.calls = self.calls + 1
    health.maxhealth = 389 -- 125 native + 261 body + 3 Achievement
    health.currenthealth = health.maxhealth
    hunger.max = 276
    hunger.current = hunger.max
end
player.components.xd_dtlevel = body

assert(Reload.Restore(player, 175, 90, 70))
assert(health.maxhealth == 389 and health.currenthealth == 175,
    'reload restores body maximum and saved current health')
assert(health._tbc_elixir_base == 389,
    'later elixir and equipment refreshes keep the restored body maximum')
assert(hunger.max == 276 and hunger.current == 90,
    'reload restores body hunger maximum without filling hunger')
assert(sanity.max == 200 and sanity.current == 70,
    'reload keeps Tu Tien sanity maximum and saved current sanity')
assert(Reload.Restore(player, 175, 90, 70))
assert(health.maxhealth == 389 and body.calls == 2,
    'same-level reapplication must not double the body bonus')

-- Existing save: 125 native + 70 Achievement levels * 5 = 475.
-- Tu Tien body level 46 must add its observed 261 health on top.
health.maxhealth = 475
health.currenthealth = 357
health._tbc_elixir_base = 475
health._tbc_elixir_last_max = 475
hunger.max = 325
sanity.max = 300
function body:SetLevel(level)
    assert(level == 46)
    health.maxhealth = 736
end
assert(Reload.Restore(player, 357, 262, 281))
assert(health.maxhealth == 736 and health.currenthealth == 357,
    'level 46 restores Tu Tien health above 350 Achievement health')
assert(hunger.max == 325 and hunger.current == 262
    and sanity.max == 300 and sanity.current == 281,
    'health repair does not overwrite existing hunger or sanity')
assert(health._tbc_elixir_base == 736,
    'later equipment refresh cannot revert health to 475')

local absent = { components = { health = health } }
assert(not Reload.Restore(absent, 100), 'players without Tu Tien are unaffected')

-- Missing optional save fields must preserve the current values, never refill
-- resources as a side effect of reapplying native cultivation.
health.currenthealth=37;hunger.current=44;sanity.current=42
function body:SetLevel(level)
    assert(level==46)
    self.calls=self.calls+1
    health.maxhealth=736;health.currenthealth=736
    hunger.current=hunger.max;sanity.current=sanity.max
end
assert(Reload.Restore(player))
assert(health.currenthealth==37 and hunger.current==44 and sanity.current==42,
    'missing save values preserve current resources rather than refilling them')

-- Native DST ghosts retain resurrect health despite being in ghost mode.
health.currenthealth=50
player.HasTag=function(_,tag) return tag=='playerghost' end
local before_calls=body.calls
assert(not Reload.Restore(player,50,44,42), 'ghost reload must not reapply a healing native level setter')
assert(body.calls==before_calls and health.currenthealth==50,
    'ghost restoration must not transiently heal or trigger another death')
player.HasTag=function() return false end
health.currenthealth=0
assert(not Reload.Restore(player,0,44,42), 'dead players awaiting ghost transition stay dead')
assert(body.calls==before_calls and health.currenthealth==0)
print('tutien_health_reload_test: ok')
