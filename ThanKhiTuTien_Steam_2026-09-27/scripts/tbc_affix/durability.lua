local Defs = require("tbc_affix/defs")

local M = {}

local REGEN_PER_SECOND = {
    restore_use_10s_1use = 0.1,
    restore_use_5s_1use = 0.2,
    restore_use_1s_1use = 1,
}

local function SetBonus(component, maximum_field, old_bonus, new_bonus)
    if component == nil or component[maximum_field] == nil then return end
    local delta = new_bonus - old_bonus
    if delta == 0 then return end
    local percent = component.GetPercent ~= nil and component:GetPercent() or nil
    component[maximum_field] = math.max(1, component[maximum_field] + delta)
    if percent ~= nil and component.SetPercent ~= nil then component:SetPercent(percent) end
end

function M.Tick(item, seconds)
    local state = item._tbc_durability_state
    if state == nil or seconds == nil or seconds <= 0 then return end
    local components = item.components or {}
    local finite = components.finiteuses
    local armor = components.armor
    local rate = state.regen_flat
    if finite ~= nil then
        rate = rate + (finite.total or 0) * state.regen_percent
    elseif armor ~= nil then
        rate = rate + (armor.maxcondition or 0) * state.regen_percent
    end
    if rate <= 0 then return end
    state.carry = (state.carry or 0) + rate * seconds
    local whole = math.floor(state.carry + 0.0000001)
    state.carry = state.carry - whole
    if whole <= 0 then return end
    if finite ~= nil and finite.GetUses ~= nil and finite.SetUses ~= nil then
        finite:SetUses(math.min(finite.total, finite:GetUses() + whole))
    elseif armor ~= nil and armor.SetCondition ~= nil then
        armor:SetCondition(math.min(armor.maxcondition, armor.condition + whole))
    end
end

local function SetFiniteImmune(state, finite, wanted)
    if finite == nil then return end
    if wanted and state.use_wrapper == nil and type(finite.Use) == "function" then
        local original = finite.Use
        state.original_use = original
        state.use_wrapper = function(self, ...)
            if not state.finite_immune_active then return original(self, ...) end
        end
        finite.Use = state.use_wrapper
    end
    state.finite_immune_active = wanted
    if not wanted and state.use_wrapper ~= nil and finite.Use == state.use_wrapper then
        finite.Use = state.original_use
        state.original_use = nil
        state.use_wrapper = nil
    end
end

local function SetArmorImmune(state, armor, wanted)
    if armor == nil then return end
    -- DST subtracts armor condition in TakeDamage, not via the
    -- indestructible field. Keep the field untouched so saves stay clean.
    if wanted and state.armor_wrapper == nil and type(armor.TakeDamage) == "function" then
        local original = armor.TakeDamage
        state.original_armor_take_damage = original
        state.armor_wrapper = function(self, ...)
            if not state.armor_immune_active then return original(self, ...) end
        end
        armor.TakeDamage = state.armor_wrapper
    end
    state.armor_immune_active = wanted
    if not wanted and state.armor_wrapper ~= nil and armor.TakeDamage == state.armor_wrapper then
        armor.TakeDamage = state.original_armor_take_damage
        state.original_armor_take_damage = nil
        state.armor_wrapper = nil
    end
end

function M.Reconcile(item, entries)
    if item == nil then return end
    local components = item.components or {}
    local finite, armor = components.finiteuses, components.armor
    local state = item._tbc_durability_state
    if state == nil then
        state = { finite_bonus = 0, armor_bonus = 0, regen_flat = 0,
            regen_percent = 0, carry = 0 }
        item._tbc_durability_state = state
    end
    local finite_bonus, armor_bonus = 0, 0
    local regen_flat, regen_percent = 0, 0
    local finite_immune, armor_immune = false, false
    for _, entry in ipairs(entries or {}) do
        local row = Defs.by_code[entry.code or entry.id]
        if row ~= nil then
            if row.effect_key == "add_max_use" then
                if finite ~= nil then finite_bonus = finite_bonus + entry.value
                elseif armor ~= nil then armor_bonus = armor_bonus + entry.value end
            elseif row.effect_key == "armorDurability" then
                if row.fixed then armor_immune = true
                else armor_bonus = armor_bonus + entry.value end
            elseif row.effect_key == "durabilityImmune" then
                finite_immune = true
                armor_immune = true
            elseif row.code == "restore_use_1s_2_percent" then
                regen_percent = regen_percent + 0.02
            else
                regen_flat = regen_flat + (REGEN_PER_SECOND[row.code] or 0)
            end
        end
    end
    SetBonus(finite, "total", state.finite_bonus, finite_bonus)
    SetBonus(armor, "maxcondition", state.armor_bonus, armor_bonus)
    state.finite_bonus, state.armor_bonus = finite_bonus, armor_bonus
    SetFiniteImmune(state, finite, finite_immune)
    SetArmorImmune(state, armor, armor_immune)
    state.regen_flat, state.regen_percent = regen_flat, regen_percent
    if regen_flat + regen_percent > 0 and state.task == nil and item.DoPeriodicTask ~= nil then
        state.task = item:DoPeriodicTask(1, function() M.Tick(item, 1) end)
    elseif regen_flat + regen_percent == 0 and state.task ~= nil then
        state.task:Cancel()
        state.task = nil
        state.carry = 0
    end
end

return M
