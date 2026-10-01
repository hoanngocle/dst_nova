package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path
math.ldexp = math.ldexp or function(value, exponent) return value * 2 ^ exponent end
TUNING = { CHASNI_CONFIG = {}, TOTAL_DAY_TIME = 480 }
TheWorld = { state = { season = 'autumn', phase = 'day', cycles = 0 } }
ACTIONS = {}
package.loaded['functions/helperfunctions'] = true
package.loaded['functions/deconstructionhelperfunctions'] = true
function chasni_copylist(list)
    local copy = {}
    for key, value in pairs(list or {}) do copy[key] = value end
    return copy
end
ach_list_lists = {}
-- Simulate DST's Class setters so assertions inspect the actual replicated UI fields.
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

ach_lists = require('constants/achievementdata')
local Event = require('components/allachivevent')
local tracker = require('functions/novaachievementtracker')
local ui = require('constants/uidata')
local keys = {'power', 'health', 'mana', 'guard', 'speed', 'crit'}
local definitions = {}
for _, definition in ipairs(require('constants/novaachievements')) do
    definitions[definition.id] = definition
end

-- Missing registration, a wrong UI category, or using raw eat events must fail this test.
local food = ui.ach_tab[1]
for _, key in ipairs(keys) do
    local id = 'tbc_elixir_' .. key
    assert(ach_lists[id], id .. ': permanent potion achievement must be registered')
    assert(ach_lists[id].current == 10, id .. ': completes at ten doses')
    local found = false
    for index = food.start, food.start + food.count - 1 do
        if ui.ach_list[index] == id then found = true end
    end
    assert(found, id .. ': displayed on food tab')
    assert(definitions[id].strings.vi.name and definitions[id].strings.vi.description,
        id .. ': localized achievement description exists')
end

local function player(counts, saved)
    local visible, listeners, tasks, periodic = {}, {}, {}, {}
    local inst = {
        components = {}, entity = {},
        sg = { GoToState = function() end, AddStateTag = function() end },
        Transform = { GetWorldPosition = function() return 0, 0, 0 end },
    }
    for name, achievement in pairs(ach_lists) do
        for _, prefix in ipairs({'check', 'current'}) do
            local field = prefix .. name
            inst[field] = { set = function(_, value) visible[field] = value end }
        end
        if achievement.list then inst['current' .. name .. 'list'] = { set = function() end } end
    end
    function inst:ListenForEvent(event, fn)
        listeners[event] = listeners[event] or {}
        table.insert(listeners[event], fn)
    end
    function inst:PushEvent(event, data)
        for _, fn in ipairs(listeners[event] or {}) do fn(self, data) end
    end
    function inst:DoTaskInTime(delay, fn) tasks[#tasks + 1] = { delay = delay, fn = fn } end
    function inst:DoPeriodicTask(delay, fn) periodic[#periodic + 1] = fn end
    function inst:WatchWorldState() end
    function inst:HasTag() return false end
    function inst:HasDebuff() return false end
    function inst:GetDebuff() return nil end
    function inst:GetDisplayName() return 'Player' end
    inst.components.health = { IsDead = function() return false end }
    inst.components.locomotor = { wantstomoveforward = false }
    inst.components.age = { GetAge = function() return 480 end }
    local coins = 0
    inst.components.allachivcoin = { starsspent = 0, coinDoDelta = function(_, value) coins = coins + value end }
    inst.components.talker = { Say = function() end }
    local progress = { counts = counts or {} }
    function progress:GetCount(key) return self.counts[key] or 0 end
    if counts then inst.components.tbc_elixir_progress = progress end
    local component = Event(inst)
    inst.components.allachivevent = component
    component:OnLoad(saved or {})
    tracker.attach(inst, component)
    local function run_tasks(max_delay)
        local current = tasks
        tasks = {}
        for _, task in ipairs(current) do
            if task.delay <= max_delay then task.fn() else tasks[#tasks + 1] = task end
        end
    end
    return inst, component, visible, progress, run_tasks, function() return coins end, periodic
end

STRINGS = { ACHIEVEMENTS = {}, GUI = {br1='',br2='',obt='',points=''} }
for id, definition in pairs(definitions) do STRINGS.ACHIEVEMENTS[id] = definition.strings.vi end
STRINGS.ACHIEVEMENTS.complete = {name='Complete',info='Complete'}
SpawnPrefab = function() return { entity = { SetParent = function() end } } end

local inst, component, visible, progress, run, coins = player({power=3, health=4, mana=5, guard=6, speed=7, crit=9})
run(0)
local initial_counts = {power=3, health=4, mana=5, guard=6, speed=7, crit=9}
for _, key in ipairs(keys) do
    local id = 'tbc_elixir_' .. key
    assert(component[id .. 'amount'] == initial_counts[key], id .. ': initial authoritative snapshot')
    assert(visible['current' .. id] == initial_counts[key], id .. ': real net setter reflects exact count')
end
inst:PushEvent('oneat', { food = {prefab='tbc_elixir_power'} })
assert(component.tbc_elixir_poweramount == 3, 'eat event alone cannot award permanent progress')
progress.counts.power = 4
inst:PushEvent('tbc_elixir_progress', {counts=progress.counts})
inst:PushEvent('tbc_elixir_progress', {counts=progress.counts})
assert(component.tbc_elixir_poweramount == 4, 'duplicate snapshots do not double count')
assert(coins() == 0, 'no achievement reward before ten')
progress.counts.crit = 10
inst:PushEvent('tbc_elixir_progress', {counts=progress.counts})
assert(component.tbc_elixir_crit == true and visible.checktbc_elixir_crit == 1, 'completion replicated')
assert(coins() == 2, 'ordinary achievement reward exactly once')
inst:PushEvent('tbc_elixir_progress', {counts=progress.counts})
inst:PushEvent('oneat', {food={prefab='tbc_elixir_health'}})
assert(coins() == 2 and component.tbc_elixir_healthamount == 4, 'extra consumptions cannot inflate achievements')

local saved = component:OnSave()
assert(saved.tbc_elixir_poweramount == 4 and saved.tbc_elixir_crit == true, 'registered component save includes potions')
local restored, loaded, net, source, load_tasks, load_coins = player({power=4, crit=10}, saved)
load_tasks(4)
assert(load_coins() == 0, 'completed save does not grant reward again')
restored:PushEvent('death')
restored:PushEvent('respawnfromghost')
local after_revive = load_coins()
restored:PushEvent('tbc_elixir_progress', {counts=source.counts})
assert(loaded.tbc_elixir_poweramount == 4 and loaded.tbc_elixir_critamount == 10, 'save/load and death retain counts')
assert(load_coins() == after_revive, 'post-revive snapshot does not reward completed potion again')

-- Component attachment may happen after achievement tracking; its event still synchronizes.
local late, late_component, late_net, late_source, late_tasks = player(nil)
late_tasks(0)
late:PushEvent('tbc_elixir_progress', {counts={power=2}})
assert(late_component.tbc_elixir_poweramount == 2, 'event snapshot works before component is available')
late:PushEvent('tbc_elixir_progress', {counts={power=-3, mana='bad'}})
assert(late_component.tbc_elixir_poweramount == 0 and late_component.tbc_elixir_manaamount == 0,
    'negative counts clamp and malformed counts are ignored')
late.components.tbc_elixir_progress = late_source
late_source.counts = {power=8, health=10, mana=10, guard=10, speed=10, crit=10}
late:PushEvent('tbc_elixir_progress', {counts=late_source.counts})
assert(late_component.tbc_elixir_poweramount == 8 and late_net.currenttbc_elixir_power == 8, 'late component attachment')
late_source.counts.power = 15
late:PushEvent('tbc_elixir_progress', {counts=late_source.counts})
for _, key in ipairs(keys) do
    local id = 'tbc_elixir_' .. key
    assert(late_component[id] == true and late_component[id .. 'amount'] == 10,
        id .. ': completion at potion limit')
end
late_source.counts.power = 0
late:PushEvent('tbc_elixir_progress', {counts=late_source.counts})
assert(late_component.tbc_elixir_poweramount == 10 and late_component.tbc_elixir_power, 'completed counters never regress')

-- Fresh join imports achievement/reroll data after three seconds; re-read potion authority after that.
local delayed, delayed_component, _, delayed_source, delayed_tasks = player({power=9})
delayed_tasks(0)
delayed_component:OnLoad({tbc_elixir_poweramount=1})
delayed_tasks(4)
assert(delayed_component.tbc_elixir_poweramount == 9, 'late achievement load cannot replace permanent source')

-- Never leave a stale queued CheckAchievement that completes before the latest snapshot reaches ten.
local waiting, waiting_component, _, waiting_source, waiting_tasks, waiting_coins = player({power=10})
waiting_component.isready = false
waiting_tasks(0)
assert(not waiting_component.tbc_elixir_power, 'completion waits for achievement data readiness')
waiting_source.counts.power = 9
waiting_component.isready = true
waiting_tasks(4)
assert(not waiting_component.tbc_elixir_power and waiting_component.tbc_elixir_poweramount == 9,
    'deferred completion rechecks authority')
assert(waiting_coins() == 0, 'stale deferred snapshot cannot grant reward')

-- Repeat-all-achievements reset must not clear permanent counters or award them again.
local reset_inst, reset_component, _, reset_source, reset_tasks, reset_coins, periodic = player({power=10})
reset_tasks(0)
for id in pairs(ach_lists) do reset_component[id] = true end
reset_component.complete = false
PLAYS_CONFIG = 2
reset_component:allget(reset_inst)
periodic[#periodic]()
reset_tasks(3)
assert(reset_component.tbc_elixir_power == true and reset_component.tbc_elixir_poweramount == 10,
    'repeat achievement reset preserves permanent potion completion')
print('elixir achievements: catalog/UI, authority, duplicate events, net sync, reward, save/load, death, late load, reset passed')
