package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path

package.loaded['functions/helperfunctions'] = true
level_lists = {}
allachiv_coindata = { healthup = 10 }
healthGain = 5

function Class(ctor)
    local class = {}
    return setmetatable(class, { __call = function(_, inst)
        local object = setmetatable({}, { __index = class })
        ctor(object, inst)
        return object
    end })
end

function chasni_setMaxHealth(health, value)
    local percent = health:GetPercent()
    health:SetMaxHealth(value)
    health:SetPercent(percent)
end

local LevelSystem = require('components/levelsystem')
local player = { components = {}, currenthealthup = { value = function() return 2 end } }
function player:DoTaskInTime(_, fn) fn() end
local health = { _tbc_elixir_resource = 'health', _tbc_elixir_base = 100,
    maxhealth = 150, currenthealth = 90 }
health._tbc_elixir_last_max=150
function health:_tbc_elixir_capture()
    self._tbc_elixir_base=self._tbc_elixir_base+self.maxhealth-self._tbc_elixir_last_max
    self._tbc_elixir_last_max=self.maxhealth
end
function health:GetPercent() return self.currenthealth / self.maxhealth end
function health:SetPercent(value) self.currenthealth = self.maxhealth * value end
function health:SetMaxHealth(value)
    self._tbc_elixir_base = value
    self.maxhealth = value + 50 -- Tu Tien permanent health bonus
    self._tbc_elixir_last_max = self.maxhealth
end
player.components.health = health
local level = LevelSystem(player)
level.healthlevelamount = 2

level:loadHealth(player)
assert(health._tbc_elixir_base == 130, 'achievement must adjust native health base')
assert(health.maxhealth == 180, 'achievement and Tu Tien health must compose once')
health._tbc_elixir_base = 100 -- native player health on a fresh join
health.maxhealth = 175 -- Tu Tien adds another 25 directly before Achievement loads
health._tbc_elixir_last_max = 150
health.currenthealth = 90
local reloaded_level = LevelSystem(player)
reloaded_level.healthlevelamount = 2
reloaded_level:loadHealth(player)
assert(health.maxhealth == 205, 'fresh join restores Achievement and direct Tu Tien health')
reloaded_level:loadHealth(player)
assert(health.maxhealth == 205, 'subsequent refresh does not duplicate either bonus')
print('levelsystem_tutien_health_test: ok')
