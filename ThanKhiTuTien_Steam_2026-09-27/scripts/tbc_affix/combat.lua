local Defs = require("tbc_affix/defs")
local M = {}

function M.ForWeapon(attacker, weapon)
    local inventory = attacker ~= nil and attacker.components ~= nil
        and attacker.components.inventory or nil
    if inventory == nil or inventory.GetEquippedItem == nil or EQUIPSLOTS == nil then return nil end
    local equipped = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipped == nil then return nil end
    local source = weapon ~= nil and (weapon._tbc_source_item or weapon._source_weapon or weapon)
        or equipped
    if source ~= equipped then return nil end
    local upgrade = equipped.components ~= nil and equipped.components.tbc_upgrade or nil
    return upgrade ~= nil and upgrade.affixes or nil
end

local RESOURCE = {
    bloodOutburst = "health",
    spiritFade = "sanity",
    hungerAssault = "hunger",
}

function M.AdjustDamage(attacker, weapon, damage)
    if type(damage) ~= "number" or damage <= 0 then return damage end
    local bonus = 0
    for _, affix in ipairs(M.ForWeapon(attacker, weapon) or {}) do
        local row = Defs.by_code[affix.id]
        local component_name = row ~= nil and RESOURCE[row.effect_key] or nil
        local component = component_name ~= nil and attacker.components[component_name] or nil
        if component ~= nil and component.GetPercent ~= nil then
            bonus = bonus + math.max(0, math.min(1, 1 - component:GetPercent())) * 50
        end
    end
    return damage * (1 + bonus / 100)
end

function M.AugmentHit(attacker, victim, weapon, base_damage, spdamage)
    local packet = {}
    if type(spdamage) == "table" then
        for kind, amount in pairs(spdamage) do packet[kind] = amount end
    end
    if type(base_damage) ~= "number" or base_damage <= 0 then return packet end
    local percent = 0
    for _, affix in ipairs(M.ForWeapon(attacker, weapon) or {}) do
        local row = Defs.by_code[affix.id]
        if row ~= nil and row.effect_key == "trueDamageNum" then
            percent = percent + affix.value / row.scale
        end
    end
    if percent > 0 then
        packet.tbc_armor_pierce = (packet.tbc_armor_pierce or 0)
            + base_damage * percent / 100
    end
    return packet
end

return M
