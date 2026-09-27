-- The seven Huyền Vũ flags are owned by this mod. Native methods stay wrapped
-- once and delegate normally as soon as the last source is unequipped.
local M = {}

local MAP = {
    add_immune_cold = {"cold"},
    add_immune_hot = {"hot"},
    add_immune_poison = {"poison"},
    add_immune_freeze = {"freeze"},
    immunity_moisture = {"moisture"},
    immunity_reduce_speed = {"slow"},
    immune_sleep = {"sleep"},
    immune_debuff = {"hot", "cold", "moisture"},
    immune_debuff_2 = {"freeze", "poison", "slow", "sleep"},
    special_zqrf = {"cold", "hot", "poison", "freeze", "moisture", "slow", "sleep"},
}

function M.Flags(entries)
    local flags = {}
    for _, entry in ipairs(entries or {}) do
        for _, status in ipairs(MAP[entry.code or entry.id] or {}) do
            flags[status] = true
        end
    end
    return flags
end

function M.Has(player, status)
    return player ~= nil and player._tbc_affix_immunity ~= nil
        and player._tbc_affix_immunity[status] == true or false
end

local function Wrap(player, component_name, method, decorator)
    local component = player.components ~= nil and player.components[component_name] or nil
    if component == nil or type(component[method]) ~= "function" then return end
    local wrapped = player._tbc_affix_immunity_wrapped
    if wrapped == nil then
        wrapped = {}
        player._tbc_affix_immunity_wrapped = wrapped
    end
    if wrapped[component] == nil then wrapped[component] = {} end
    if wrapped[component][method] then return end
    local original = component[method]
    component[method] = decorator(original)
    wrapped[component][method] = true
end

local function Install(player)
    Wrap(player, "temperature", "SetTemperature", function(original)
        return function(self, value, ...)
            if type(value) == "number" then
                if M.Has(player, "cold") then
                    value = math.max(value, math.max(self.mintemp or 0, 10) + 1)
                end
                if M.Has(player, "hot") then
                    value = math.min(value,
                        math.min(self.maxtemp or math.huge,
                            (self.overheattemp or math.huge) - 10) - 1)
                end
            end
            return original(self, value, ...)
        end
    end)
    Wrap(player, "moisture", "DoDelta", function(original)
        return function(self, delta, ...)
            if M.Has(player, "moisture") and type(delta) == "number"
                and delta > 0 and player.prefab ~= "avava" and player.prefab ~= "wurt" then
                delta = 0
            end
            return original(self, delta, ...)
        end
    end)
    Wrap(player, "inventory", "GetWaterproofness", function(original)
        return function(self, ...)
            if M.Has(player, "moisture") then return 1 end
            return original(self, ...)
        end
    end)
    Wrap(player, "freezable", "Freeze", function(original)
        return function(self, ...)
            if M.Has(player, "freeze") then return end
            return original(self, ...)
        end
    end)
    Wrap(player, "grogginess", "AddGrogginess", function(original)
        return function(self, ...)
            if M.Has(player, "sleep") then return end
            return original(self, ...)
        end
    end)
    Wrap(player, "locomotor", "SetExternalSpeedMultiplier", function(original)
        return function(self, source, key, multiplier, ...)
            if M.Has(player, "slow") and type(multiplier) == "number"
                and multiplier < 1 then return end
            return original(self, source, key, multiplier, ...)
        end
    end)
    Wrap(player, "hh_buff", "AddBuff", function(original)
        return function(self, name, ...)
            if M.Has(player, "poison") and name == "poison" then return end
            return original(self, name, ...)
        end
    end)
end

function M.Reconcile(player, entries)
    if player == nil then return {} end
    local flags = M.Flags(entries)
    player._tbc_affix_immunity = flags
    Install(player)
    return flags
end

function M.Remove(player)
    if player ~= nil then player._tbc_affix_immunity = {} end
end

return M
