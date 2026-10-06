package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path
math.ldexp = math.ldexp or function(value, exponent) return value * 2 ^ exponent end
package.loaded['functions/helperfunctions'] = true
function Class(ctor, _, setters)
    local c = {}
    c.__index = c
    return setmetatable(c, { __call = function(_, inst)
        local values = {}
        if setters then
            setmetatable(inst, { __index = function(t, key)
                if key == 'components' then return nil end
                local field = { set = function(self, value) self.current = value end,
                    value = function(self) return self.current end }
                rawset(t, key, field)
                return field
            end })
        end
        local self = setmetatable({}, { __index = function(_, key)
            if values[key] ~= nil then return values[key] end
            return c[key]
        end, __newindex = function(object, key, value)
            values[key] = value
            if setters and setters[key] then setters[key](object, value) end
        end })
        ctor(self, inst)
        return self
    end })
end
local function copy(t)
    local result = {}
    for k, v in pairs(t) do result[k] = v end
    return result
end
json = { encode = copy, decode = function(data)
    if type(data) ~= 'table' then error('invalid JSON') end
    return copy(data)
end }
perk_lists = require('constants/perkdata')
toggleableglobalperk = { riftcontroller = true }
TUNING = { ACH = {} }
for name, perk in pairs(perk_lists) do if perk.global then TUNING.ACH[name] = 0 end end
local written
TheSim = { SetPersistentString = function(_, _, data) written = copy(data) end }
local Coin = require('components/allachivcoin')
local coin = Coin({})
coin.coinamount = 100
coin.ongetcoin = function() end
coin.cantgetcoin = function() end
coin.eternalcagefn = false
coin:pickperk5(coin.inst, 'eternalcage')
assert(written and written.eternalcage == 1, 'purchase must persist before the next player save')
assert(coin.coinamount == 85, 'purchase charges stars once')

GLOBAL = _G
env = {}
local postinit
function AddPrefabPostInit(name, fn) assert(name == 'world'); postinit = fn end
local pending, reads, lastRead = nil, 0, nil
TheSim.GetPersistentString = function(_, _, callback)
    reads = reads + 1; pending = callback; lastRead = 'current'
end
local legacyPath, slot, dedicated = true, 1, false
-- ShardIndex() constructs an unloaded index; it is not the active save index.
function ShardIndex() return { GetSlot = function() return nil end,
    GetServerData = function() return {} end } end
ShardGameIndex = { GetSlot = function() return slot end,
    GetServerData = function() return { use_legacy_session_path = legacyPath } end }
TheSim.GetPersistentStringInClusterSlot = function(_, slot, shard, key, callback)
    assert(slot == 1 and shard == 'Master' and key == 'chasni_perk_global.json')
    reads = reads + 1; pending = callback; lastRead = 'cluster'
end
TheNet = { IsDedicated = function() return dedicated end }
local function world()
    TUNING.ACH = nil
    dofile('Achivement_Steam_2026-09-27/main_initialize.lua')
    local inst = { ismastersim = true, components = {} }
    function inst:AddComponent(name)
        self.components[name] = require('components/' .. name)(self)
    end
    TheWorld = inst
    postinit(inst)
    return inst.components.chasni_globalperks
end
local w = world()
assert(lastRead == 'current', 'legacy host reads current persistence path')
pending(false, nil)
local recovered = Coin({})
recovered:OnLoad({coinamount = 33, eternalcage = true, riftcontroller = -1, stackinfinite = true})
assert(TUNING.ACH.eternalcage == 1, 'missing JSON recovers unlock from player save')
assert(TUNING.ACH.riftcontroller == -1, 'recovery keeps purchased but disabled state')
assert(TUNING.ACH.stackinfinite == 0, 'retired global Perks stay removed')
assert(recovered.coinamount == 33, 'migration does not spend or grant stars')
local snapshot = w:OnSave()
local playerdata = recovered:OnSave()
assert(playerdata.riftcontroller == -1, 'player backup stores numeric disabled state')

w = world()
w:OnLoad(snapshot)
pending(true, { eternalcage = 0, riftcontroller = 1 })
assert(TUNING.ACH.eternalcage == 1 and TUNING.ACH.riftcontroller == -1,
    'late legacy JSON cannot replace native world save')
local reload = Coin({})
reload.ongetcoin = function() end
reload:OnLoad(playerdata)
assert(reload.eternalcage == 1 and reload.riftcontroller == -1, 'rejoin restores visible Perk states')
assert(reload.inst.currenteternalcage:value() == 1 and reload.inst.currentriftcontroller:value() == -1,
    'real property callbacks replicate restored Perk states to UI')
reload:pickperk5(reload.inst, 'riftcontroller')
assert(TUNING.ACH.riftcontroller == 1 and written.riftcontroller == 1, 'toggle persists without charging stars')
assert(reload.coinamount == 33)

w = world()
local buyer = Coin({}); buyer.coinamount = 100
buyer.ongetcoin = function() end; buyer.eternalcagefn = false
buyer:pickperk5(buyer.inst, 'eternalcage')
pending(true, { eternalcage = 0 })
assert(TUNING.ACH.eternalcage == 1, 'late legacy load cannot erase a new purchase')
w = world()
pending(true, 'corrupt')
assert(TUNING.ACH.eternalcage == 0, 'corrupt legacy JSON safely starts unknown defaults')
w:OnLoad({ eternalcage = 0, riftcontroller = -1 })
Coin({}):OnLoad({ eternalcage = true, riftcontroller = true })
assert(TUNING.ACH.eternalcage == 0 and TUNING.ACH.riftcontroller == -1,
    'authoritative world values override stale player backups')
w:LoadLegacy(true, { eternalcage = 1, riftcontroller = 1 })
assert(TUNING.ACH.eternalcage == 0 and TUNING.ACH.riftcontroller == -1,
    'native world locked/disabled values outrank late valid legacy unlocks')
w = world()
local latecoin = Coin({})
AllPlayers = {{ components = { allachivcoin = latecoin } }}
latecoin.eternalcagefn = false
pending(true, { eternalcage = 1, riftcontroller = -1 })
assert(TUNING.ACH.eternalcage == 1 and TUNING.ACH.riftcontroller == -1, 'legacy JSON migrates unlocks')
assert(latecoin.eternalcage == 1 and latecoin.riftcontroller == -1,
    'late legacy read refreshes Perk fields for players already loaded')
assert(latecoin.inst.currenteternalcage:value() == 1 and latecoin.inst.currentriftcontroller:value() == -1)
local before = reads
postinit({ ismastersim = false })
assert(reads == before, 'clients do not read or rewrite server global data')
w = world()
AllPlayers = nil
Coin({}):OnLoad({ riftcontroller = true })
pending(true, { riftcontroller = -1 })
assert(TUNING.ACH.riftcontroller == -1,
    'valid legacy shared state overrides a stale player backup when its read finishes late')
legacyPath = false
local previousReads = reads
w = world()
assert(reads == previousReads + 1, 'non-legacy self-host reads the Master slot exactly once')
assert(lastRead == 'cluster', 'host uses its active loaded ShardGameIndex')
pending(true, { eternalcage = 1 })
assert(TUNING.ACH.eternalcage == 1)
for _, invalid in ipairs({false, '1', 0, -1, 1.5, math.huge}) do
    slot = invalid ~= false and invalid or nil
    previousReads = reads
    w = world()
    assert(reads == previousReads + 1 and lastRead == 'current',
        'missing/invalid slot falls back without calling native cluster API')
    pending(false, nil)
    w:OnLoad(snapshot)
    assert(TUNING.ACH.eternalcage == 1 and TUNING.ACH.riftcontroller == -1,
        'missing legacy file must not erase saved Perks')
end
slot = 1; dedicated = true
w = world()
assert(lastRead == 'current', 'dedicated server uses current shard persistence')
dedicated = false; ShardGameIndex = nil
w = world()
assert(lastRead == 'current', 'absent active index safely uses current persistence')
print('global_perk_reload_test: ok (mock DST persistence and lifecycle)')
