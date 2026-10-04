-- Reapply the saved Tu Tien body realm after health and elixir load callbacks.
-- Tu Tien's SetLevel recalculates the body maximum; assigning maxhealth here
-- would bypass that calculation.
local M = {}

local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function M.Restore(inst, saved_health, saved_hunger, saved_sanity)
    local components = inst and inst.components
    local body = components and components.xd_dtlevel
    local health = components and components.health
    local body_level = body and body.level
    if body ~= nil and not Finite(body_level) and type(body.GetLevel) == "function" then
        local ok, level = pcall(body.GetLevel, body)
        if ok then body_level = level end
    end
    if body == nil or health == nil or not Finite(body_level) or body_level <= 0
        or type(body.SetLevel) ~= "function" then
        return false
    end

    local ok, err = pcall(body.SetLevel, body, body_level)
    if not ok then
        print("[Achievement] Tu Tien body health reload: " .. tostring(err))
        return false
    end
    if type(health._tbc_elixir_capture) == "function" then
        health:_tbc_elixir_capture()
    end

    if Finite(saved_health) and type(health.SetCurrentHealth) == "function" then
        local cap = type(health.GetMaxWithPenalty) == "function"
            and health:GetMaxWithPenalty() or health.maxhealth
        health:SetCurrentHealth(math.max(0, math.min(saved_health, cap)))
        if type(health.ForceUpdateHUD) == "function" then health:ForceUpdateHUD(true) end
    end

    local hunger = components.hunger
    if hunger ~= nil and type(hunger.SetCurrent) == "function" then
        local current = Finite(saved_hunger) and saved_hunger or hunger.max
        hunger:SetCurrent(math.max(0, math.min(current, hunger.max)))
    end
    local sanity = components.sanity
    if sanity ~= nil and Finite(saved_sanity) and type(sanity.SetCurrent) == "function" then
        local cap = type(sanity.GetMaxWithPenalty) == "function"
            and sanity:GetMaxWithPenalty() or sanity.max
        sanity:SetCurrent(math.max(0, math.min(saved_sanity, cap)))
    end

    local level = components.levelsystem
    if level ~= nil then
        level.healthlevelmax = health.maxhealth
        if hunger ~= nil then level.hungerlevelmax = hunger.max end
        if sanity ~= nil then level.sanitylevelmax = sanity.max end
    end
    return true
end

return M
