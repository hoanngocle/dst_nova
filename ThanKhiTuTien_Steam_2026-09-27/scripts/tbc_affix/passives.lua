local Defs = require("tbc_affix/defs")

local M = {}
local SPEED_KEY = "tbc_affix"
local HEAD_ABSORB_KEY = "tbc_strengthen_head16"

function M.Sum(entries)
    local result = {speed=0, attack_speed=0, health_percent=0, health_regen=0}
    for _, entry in ipairs(entries or {}) do
        local row = Defs.by_code[entry.code or entry.id]
        if row ~= nil then
            local value = row.fixed and row.fixed_value or (entry.value or 0) / row.scale
            if row.effect_key == "addSpeedPercent" then
                result.speed = result.speed + value
            elseif row.effect_key == "atk_speed" then
                result.attack_speed = result.attack_speed + value
            elseif row.effect_key == "equipMaxHealthPercent" then
                result.health_percent = result.health_percent + value
            elseif row.effect_key == "equipHealthRegen" then
                result.health_regen = result.health_regen + value
            end
        end
    end
    result.speed = math.min(60, result.speed)
    result.attack_speed = math.min(160, result.attack_speed)
    result.health_percent = math.min(80, result.health_percent)
    result.health_regen = math.min(2, result.health_regen)
    return result
end

function M.Tick(player, seconds)
    if player == nil or seconds == nil or seconds <= 0 then return end
    local state = player._tbc_passive_state
    local health = player.components ~= nil and player.components.health or nil
    if state == nil or state.health_regen <= 0 or health == nil
        or type(health.DoDelta) ~= "function"
        or player.HasTag ~= nil and player:HasTag("playerghost")
        or health.IsDead ~= nil and health:IsDead() then return end
    health:DoDelta(state.health_regen * seconds)
end

function M.Reconcile(player, entries, strengthen)
    if player == nil then return end
    local stats = M.Sum(entries)
    strengthen = strengthen or {}
    local body_health = strengthen.body_health or 0
    local head_absorb = strengthen.head_absorb or 0
    local components = player.components or {}
    local locomotor = components.locomotor
    local combat = components.combat
    local health = components.health
    local state = player._tbc_passive_state
    if state == nil then
        state = {speed=0, attack_speed=0, health_percent=0, body_health=0, head_absorb=0,
            health_bonus=0, health_regen=0}
        player._tbc_passive_state = state
    end
    if locomotor ~= nil and state.speed ~= stats.speed then
        if stats.speed > 0 and locomotor.SetExternalSpeedMultiplier ~= nil then
            locomotor:SetExternalSpeedMultiplier(player, SPEED_KEY, 1 + stats.speed / 100)
        elseif stats.speed == 0 and locomotor.RemoveExternalSpeedMultiplier ~= nil then
            locomotor:RemoveExternalSpeedMultiplier(player, SPEED_KEY)
        end
    end
    if combat ~= nil and type(combat.min_attack_period) == "number"
        and combat.SetAttackPeriod ~= nil and state.attack_speed ~= stats.attack_speed then
        local base = combat.min_attack_period * (1 + state.attack_speed / 100)
        combat:SetAttackPeriod(math.max(0.1, base / (1 + stats.attack_speed / 100)))
    end
    if health ~= nil and type(health.maxhealth) == "number"
        and health.SetMaxHealth ~= nil
        and (state.health_percent ~= stats.health_percent or state.body_health ~= body_health) then
        local managed = health._tbc_elixir_resource == 'health'
        local base = math.max(1, managed and health._tbc_elixir_base
            or health.maxhealth - state.health_bonus)
        local bonus = base * stats.health_percent / 100 + body_health
        local percent = health.GetPercent ~= nil and health:GetPercent() or nil
        if managed then
            state.health_percent = stats.health_percent
            state.body_health = body_health
            health:SetMaxHealth(base)
        else
            health:SetMaxHealth(math.max(1, base + bonus))
        end
        if percent ~= nil and health.SetPercent ~= nil then health:SetPercent(percent) end
        state.health_bonus = bonus
    end
    if health ~= nil and health.externalabsorbmodifiers ~= nil
        and state.head_absorb ~= head_absorb then
        if head_absorb > 0 then
            health.externalabsorbmodifiers:SetModifier(player, head_absorb, HEAD_ABSORB_KEY)
        else
            health.externalabsorbmodifiers:RemoveModifier(player, HEAD_ABSORB_KEY)
        end
    end
    state.speed = stats.speed
    state.attack_speed = stats.attack_speed
    state.health_percent = stats.health_percent
    state.body_health = body_health
    state.head_absorb = head_absorb
    state.health_regen = stats.health_regen
    if stats.health_regen > 0 and state.task == nil and player.DoPeriodicTask ~= nil then
        state.task = player:DoPeriodicTask(1, function() M.Tick(player, 1) end)
    elseif stats.health_regen == 0 and state.task ~= nil then
        state.task:Cancel()
        state.task = nil
    end
end

function M.Remove(player)
    M.Reconcile(player, {})
end

return M
