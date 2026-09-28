local Durability = require("tbc_affix/durability")
local Passives = require("tbc_affix/passives")
local Immunity = require("tbc_affix/immunity")
local Mana = require("tbc_affix/mana")
local StrengthenArmor = require("tbc_strengthen_armor")
local Defs = require("tbc_affix/defs")

local M = {}

local function EquippedItems(player)
    local inventory = player ~= nil and player.components ~= nil
        and player.components.inventory or nil
    local items = {}
    if inventory == nil or type(inventory.GetEquippedItem) ~= "function"
        or type(EQUIPSLOTS) ~= "table" then return items end
    local seen = {}
    for _, slot in pairs(EQUIPSLOTS) do
        local item = inventory:GetEquippedItem(slot)
        if item ~= nil and not seen[item] then
            items[#items + 1] = item
            seen[item] = true
        end
    end
    return items
end

function M.Reconcile(player)
    if player == nil then return {} end
    local equipped = player.HasTag ~= nil and player:HasTag("playerghost")
        and {} or EquippedItems(player)
    local current = {}
    local entries = {}
    local strengthen = {body_health = 0, head_absorb = 0}
    for _, item in ipairs(equipped) do
        current[item] = true
        local own = {}
        local upgrade = item.components ~= nil and item.components.tbc_upgrade or nil
        local slot = item.components ~= nil and item.components.equippable ~= nil
            and item.components.equippable.equipslot or nil
        local level = upgrade ~= nil and upgrade.level or 0
        if slot == EQUIPSLOTS.BODY and level >= 16 then
            strengthen.body_health = 500
        elseif slot == EQUIPSLOTS.HEAD and level >= 16 then
            strengthen.head_absorb = .5
        end
        for _, affix in ipairs(upgrade ~= nil and upgrade.affixes or {}) do
            local entry = {source=item, code=affix.id, value=affix.value}
            own[#own + 1] = entry
            entries[#entries + 1] = entry
        end
        Durability.Reconcile(item, own, level >= 13
            and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY))
    end
    for item in pairs(player._tbc_affix_equipped or {}) do
        if not current[item] then Durability.Reconcile(item, {}) end
    end
    player._tbc_affix_equipped = current
    Passives.Reconcile(player, entries, strengthen)
    StrengthenArmor.Reconcile(player, equipped)
    Immunity.Reconcile(player, entries)
    local max_mana, mana_regen = 0, 0
    for _, entry in ipairs(entries) do
        local row = Defs.by_code[entry.code]
        if row ~= nil and type(entry.value) == "number" then
            if row.effect_key == "equipMaxMana" then
                max_mana = max_mana + entry.value / row.scale
            elseif row.effect_key == "equipManaRegen" then
                mana_regen = mana_regen + entry.value / row.scale
            end
        end
    end
    Mana.Reconcile(player, math.min(max_mana, 300), math.min(mana_regen, 3))
    return entries
end

function M.Clear(player)
    if player == nil then return end
    StrengthenArmor.Reconcile(player, {})
    for item in pairs(player._tbc_affix_equipped or {}) do
        Durability.Reconcile(item, {})
    end
    player._tbc_affix_equipped = {}
    Passives.Remove(player)
    Immunity.Remove(player)
    Mana.Remove(player)
end

function M.OnItemChanged(item)
    local inventoryitem = item ~= nil and item.components ~= nil
        and item.components.inventoryitem or nil
    local owner = inventoryitem ~= nil and inventoryitem.owner or nil
    if owner == nil or owner.components == nil or owner.components.inventory == nil then return end
    local equippable = item.components.equippable
    local slot = equippable ~= nil and equippable.equipslot or nil
    if slot ~= nil and owner.components.inventory.GetEquippedItem ~= nil
        and owner.components.inventory:GetEquippedItem(slot) == item then
        M.Reconcile(owner)
    end
end

function M.WatchPlayer(player)
    if player == nil or player._tbc_affix_watched then return end
    player._tbc_affix_watched = true
    if player.ListenForEvent ~= nil then
        player:ListenForEvent("equip", function() M.Reconcile(player) end)
        player:ListenForEvent("unequip", function() M.Reconcile(player) end)
        player:ListenForEvent("death", function() M.Clear(player) end)
        player:ListenForEvent("respawnfromghost", function() M.Reconcile(player) end)
    end
    if player.DoTaskInTime ~= nil then
        player:DoTaskInTime(0, function() M.Reconcile(player) end)
        -- Other mods can add their player components after our post-init callback.
        player:DoTaskInTime(1, function() M.Reconcile(player) end)
    else
        M.Reconcile(player)
    end
end

return M
