package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path

-- Compatibility for the original attribute data when testing with Lua 5.4.
math.ldexp = math.ldexp or function(value, exponent) return value * 2 ^ exponent end
package.loaded['functions/helperfunctions'] = true
perk_lists = require('constants/perks/attributes')
TUNING = { ACH = {} }
json = { encode = function() return '{}' end }
TheSim = { SetPersistentString = function() end }

-- Reproduce DST component property callbacks so we also check client prices.
function Class(ctor, _, setters)
    local class = {}
    return setmetatable(class, { __call = function(_, inst)
        local values = {}
        local self = setmetatable({}, {
            __index = function(_, key)
                if values[key] ~= nil then return values[key] end
                return class[key]
            end,
            __newindex = function(object, key, value)
                values[key] = value
                if setters[key] then setters[key](object, value) end
            end,
        })
        ctor(self, inst)
        return self
    end })
end

local Coin = require('components/allachivcoin')
local removed = require('constants/removedperks')
local caps = require('constants/attributecaps')
local function player()
    local visible = {}
    local inst = setmetatable({
        SoundEmitter = { PlaySound = function() end },
        components = { allachivevent = {}, health = { currenthealth = 0 } },
        Transform = { GetWorldPosition = function() return 0, 0, 0 end },
    }, {
        __index = function(_, key)
            return { set = function(_, value) visible[key] = value end }
        end,
    })
    local coin = Coin(inst)
    -- Stat effects require the game engine; charging and persistence run unchanged.
    for name in pairs(perk_lists) do coin[name .. 'fn'] = false end
    return coin, inst, visible
end

SpawnPrefab = function()
    return { Transform = { SetPosition = function() end } }
end

-- All active attributes, including those whose original starting price exceeds 5.
for name, perk in pairs(perk_lists) do
    if not removed.isRemoved(name) then
        local coin, inst, visible = player()
        local initial = math.min(5, perk.cost)
        assert(coin[name .. 'cost'] == initial, name .. ': starting price capped at 5')
        coin.coinamount = initial
        assert(coin:pickperk1(inst, name))
        assert(coin.coinamount == 0, name .. ': first purchase charged correctly')
        coin:OnLoad(coin:OnSave())
        assert(coin[name .. 'cost'] <= 5, name .. ': loaded price capped at 5')
        coin.resetbuff = function() end
        coin:removecoin(inst, true)
        assert(coin[name .. 'amount'] == 0)
        assert(coin[name .. 'cost'] == initial, name .. ': reset price capped at 5')
        assert(visible[name .. 'cost'] == initial, name .. ': reset client price matches')
        assert(coin.coinamount == initial, name .. ': reset refunds actual spending')
    end
end

for name, perk in pairs(perk_lists) do
    if not removed.isRemoved(name) and not caps[name] then
        local coin, inst, visible = player()
        local threshold = math.max(0, (5 - perk.cost) * perk.multi)
        local start = math.max(0, threshold - 1)
        coin:OnLoad({ coinamount = 10000, [name .. 'amount'] = start })
        local previous = math.min(5, perk.cost + math.floor(start / perk.multi))
        local maximum = 5
        assert(coin[name .. 'cost'] == previous, name .. ': unchanged below cap')
        assert(coin:pickperk1(inst, name))
        assert(coin.coinamount == 10000 - previous, name .. ': charge before cap')
        assert(coin[name .. 'cost'] == maximum, name .. ': price at threshold')
        for _ = 1, 25 do
            local before = coin.coinamount
            assert(coin:pickperk1(inst, name), name .. ': can upgrade beyond price cap')
            assert(coin.coinamount == before - maximum, name .. ': fixed charge beyond cap')
            assert(coin[name .. 'cost'] == maximum, name .. ': price must stop increasing')
            assert(visible[name .. 'cost'] == maximum, name .. ': client price matches')
        end
        assert(coin[name .. 'amount'] == start + 26)
        assert(coin.starsspent == previous + 25 * maximum, name .. ': track actual spending')
        local saved = coin:OnSave()
        local loaded = player()
        loaded:OnLoad(saved)
        assert(loaded[name .. 'cost'] == maximum, name .. ': reload capped price')
        assert(loaded.starsspent == coin.starsspent, name .. ': retain refund accounting')

        coin:OnLoad({ coinamount = maximum, starsspent = 12345, [name .. 'amount'] = 10000 })
        assert(coin[name .. 'cost'] == maximum, name .. ': old high-level save uses price cap')
        assert(coin.starsspent == 12345, name .. ': retain historical spending')
        assert(coin:pickperk1(inst, name), name .. ': exact funds accepted')
        assert(coin.coinamount == 0)
        assert(not coin:pickperk1(inst, name), name .. ': insufficient funds rejected')
        assert(coin[name .. 'amount'] == 10001)
    end
end

for name, cap in pairs(caps) do
    local coin, inst = player()
    coin:OnLoad({ coinamount = 10000, [name .. 'amount'] = cap })
    assert(not coin:pickperk1(inst, name), name .. ': existing stat limit preserved')
    assert(coin.coinamount == 10000)
end
print('attribute prices: boundary, continued upgrades, spending, client sync, save/load and stat limits passed')
