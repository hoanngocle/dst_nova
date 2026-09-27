-- Adapter for Hàn Lập's xd_htz_lq; deliberately never touches hh_mana.
local M = {}

local function Component(player)
    return player ~= nil and player.components ~= nil
        and player.components.xd_htz_lq or nil
end

local function StopTask(state)
    if state ~= nil and state.task ~= nil then
        state.task:Cancel()
        state.task = nil
    end
end

local function UpdateMax(component, delta)
    if type(component.max) ~= "number" or delta == 0 then return false end
    component.max = math.max(1, component.max + delta)
    if type(component.current) == "number" then
        component.current = math.max(0, math.min(component.current, component.max))
    end
    if type(component.Sync) == "function" then component:Sync() end
    return true
end

function M.Remove(player)
    if player == nil then return end
    local state = player._tbc_affix_mana
    if state == nil then return end
    StopTask(state)
    if state.component ~= nil then UpdateMax(state.component, -(state.max_bonus or 0)) end
    player._tbc_affix_mana = nil
end

function M.Tick(player, seconds)
    local state = player ~= nil and player._tbc_affix_mana or nil
    if state == nil or state.regen <= 0 or state.component ~= Component(player)
        or player.IsValid ~= nil and not player:IsValid()
        or player.HasTag ~= nil and player:HasTag("playerghost") then return end
    local health = player.components ~= nil and player.components.health or nil
    if health ~= nil and health.IsDead ~= nil and health:IsDead() then return end
    local component = state.component
    if component.IsPaused ~= nil and component:IsPaused() then return end
    if type(component.DoDelta) ~= "function" then return end
    local elapsed = tonumber(seconds) or 0
    if elapsed <= 0 then return end
    state.carry = state.carry + state.regen * elapsed
    local whole = math.floor(state.carry + 1e-9)
    if whole > 0 then
        state.carry = state.carry - whole
        component:DoDelta(whole)
    end
end

function M.Reconcile(player, max_bonus, regen_per_second)
    if player == nil then return end
    local component = Component(player)
    local state = player._tbc_affix_mana
    if state ~= nil and state.component ~= component then
        M.Remove(player)
        state = nil
    end
    if component == nil or type(component.max) ~= "number" then return end
    max_bonus = math.max(0, math.min(300, tonumber(max_bonus) or 0))
    regen_per_second = math.max(0, math.min(3, tonumber(regen_per_second) or 0))
    if state == nil then
        state = {component=component,max_bonus=0,regen=0,carry=0}
        player._tbc_affix_mana = state
    end
    local delta = max_bonus - state.max_bonus
    if UpdateMax(component, delta) then state.max_bonus = max_bonus end
    state.regen = regen_per_second
    if regen_per_second > 0 and state.task == nil and player.DoPeriodicTask ~= nil then
        state.task = player:DoPeriodicTask(1, function() M.Tick(player, 1) end)
    elseif regen_per_second == 0 then
        StopTask(state)
        state.carry = 0
    end
end

return M
