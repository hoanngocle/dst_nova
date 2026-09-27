local Defs = require("tbc_affix/defs")
local AffixCombat = require("tbc_affix/combat")
local M = {}

local function Time()
    return GetTime ~= nil and GetTime() or 0
end

local function Alive(target)
    if target == nil or target.IsValid ~= nil and not target:IsValid() then return false end
    local health = target.components ~= nil and target.components.health or nil
    return health ~= nil and (health.IsDead == nil or not health:IsDead())
end

local function Immune(target, status)
    local flags = target._tbc_affix_immunity
    if flags ~= nil and flags[status] then return true end
    local components = target.components or {}
    local effects = components.hh_monster or components.hh_player
    local key = status == "poison" and "immunePoison"
        or status == "freeze" and "immuneFreeze" or nil
    return key ~= nil and effects ~= nil and effects.HasSpecialEffect ~= nil
        and effects:HasSpecialEffect(key) or false
end

local function Cancel(state)
    if state ~= nil and state.task ~= nil then state.task:Cancel() end
end

function M.RemoveTarget(target)
    if target == nil then return end
    Cancel(target._tbc_affix_burn)
    Cancel(target._tbc_affix_poison)
    target._tbc_affix_burn = nil
    target._tbc_affix_poison = nil
    local task = target._tbc_affix_freeze_task
    if task ~= nil then task:Cancel() end
    target._tbc_affix_freeze_task = nil
    local locomotor = target.components ~= nil and target.components.locomotor or nil
    if locomotor ~= nil and locomotor.RemoveExternalSpeedMultiplier ~= nil then
        locomotor:RemoveExternalSpeedMultiplier(target, "tbc_affix_freeze")
    end
end

function M.ApplyBurn(attacker, target, percent)
    if not Alive(target) or percent <= 0 then return end
    local state = target._tbc_affix_burn
    if state == nil then
        state = {}
        target._tbc_affix_burn = state
        state.task = target:DoPeriodicTask(1, function()
            if not Alive(target) or Time() > state.expires_at then
                Cancel(state)
                if target._tbc_affix_burn == state then target._tbc_affix_burn = nil end
                return
            end
            local health = target.components.health
            local combat = target.components.combat
            if combat ~= nil and combat.GetAttacked ~= nil then
                combat:GetAttacked(state.attacker,
                    (health.maxhealth or 0) * state.percent / 100,
                    nil, "tbc_affix_burn")
            end
            if Time() >= state.expires_at then
                Cancel(state)
                if target._tbc_affix_burn == state then target._tbc_affix_burn = nil end
            end
        end)
    end
    state.attacker = attacker
    state.percent = percent
    state.expires_at = Time() + 3
end

function M.ApplyPoison(attacker, target, base_damage)
    if not Alive(target) or Immune(target, "poison") or base_damage <= 0 then return end
    local state = target._tbc_affix_poison
    if state ~= nil and Time() > state.expires_at then
        Cancel(state)
        state = nil
    end
    if state == nil then
        state = {stacks=0, damage_per_stack={}}
        target._tbc_affix_poison = state
        state.task = target:DoPeriodicTask(2, function()
            if not Alive(target) or Immune(target, "poison") or Time() > state.expires_at then
                Cancel(state)
                if target._tbc_affix_poison == state then target._tbc_affix_poison = nil end
                return
            end
            local total = 0
            for _, amount in ipairs(state.damage_per_stack) do total = total + amount end
            local combat = target.components.combat
            if combat ~= nil and combat.GetAttacked ~= nil then
                combat:GetAttacked(state.attacker, 0, nil, "tbc_affix_poison",
                    {tbc_affix_poison=total})
            end
            if Time() >= state.expires_at then
                Cancel(state)
                if target._tbc_affix_poison == state then target._tbc_affix_poison = nil end
            end
        end)
    end
    if state.stacks < 5 then
        state.stacks = state.stacks + 1
        state.damage_per_stack[state.stacks] = base_damage * .2
    end
    state.attacker = attacker
    state.expires_at = Time() + 10
end

local function Boss(target)
    return target.HasTag ~= nil and (target:HasTag("epic")
        or target:HasTag("boss") or target:HasTag("endgameboss_monster"))
        or target.components ~= nil and target.components.hh_monster ~= nil
        and target.components.hh_monster.GetMonsterType ~= nil
        and (target.components.hh_monster:GetMonsterType() == "boss_monster"
            or target.components.hh_monster:GetMonsterType() == "endgameboss_monster")
end

function M.ApplyFreezeOrSlow(target)
    if not Alive(target) or Immune(target, "freeze")
        or (target._tbc_affix_freeze_ready_at or 0) > Time() then return end
    if Boss(target) then
        local locomotor = target.components.locomotor
        if locomotor == nil or locomotor.SetExternalSpeedMultiplier == nil then return end
        locomotor:SetExternalSpeedMultiplier(target, "tbc_affix_freeze", .8)
        target._tbc_affix_freeze_task = target:DoTaskInTime(2, function()
            if target.IsValid == nil or target:IsValid() then
                local live = target.components ~= nil and target.components.locomotor or nil
                if live ~= nil and live.RemoveExternalSpeedMultiplier ~= nil then
                    live:RemoveExternalSpeedMultiplier(target, "tbc_affix_freeze")
                end
            end
            target._tbc_affix_freeze_task = nil
        end)
    else
        local freezable = target.components.freezable
        if freezable == nil or freezable.Freeze == nil then return end
        freezable:Freeze(2)
    end
    target._tbc_affix_freeze_ready_at = Time() + 5
end

local function Proc(percent, rng)
    percent = math.max(0, math.min(100, percent))
    return percent > 0 and (rng or math.random)(10000) <= percent * 100
end

function M.OnLandedHit(attacker, target, weapon, base_damage, rng)
    if not Alive(target) or type(base_damage) ~= "number" or base_damage <= 0 then return end
    local burn, poison, freeze = 0, 0, 0
    for _, affix in ipairs(AffixCombat.ForWeapon(attacker, weapon) or {}) do
        local row = Defs.by_code[affix.id]
        if row ~= nil then
            if row.effect_key == "burnMaxHealthPercent" then
                burn = math.max(burn, affix.value / row.scale)
            elseif row.effect_key == "atkAddPoisonChance" then
                poison = poison + affix.value / row.scale
            elseif row.effect_key == "atkChanceAddFreeze" then
                freeze = freeze + affix.value / row.scale
            end
        end
    end
    if burn > 0 then M.ApplyBurn(attacker, target, burn) end
    if Proc(math.min(poison, 80), rng) then M.ApplyPoison(attacker, target, base_damage) end
    if Proc(math.min(freeze, 40), rng) then M.ApplyFreezeOrSlow(target) end
end

return M
