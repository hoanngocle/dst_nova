local Defs = require("tbc_equipment/solo_defs")
local M = {}

local function Ledger(owner)
    return owner ~= nil and owner.components ~= nil
        and owner.components.tbc_player_effects or nil
end

local function Source(item, kind, index)
    return kind .. ":" .. tostring(item.GUID or item) .. ":" .. tostring(index)
end

local function Visit(item, owner, equipping, snapshot)
    local equipment = snapshot or item.components ~= nil and item.components.tbc_equipment or nil
    local ledger = Ledger(owner)
    if equipment == nil or ledger == nil then return false, "MISSING_EQUIPMENT_OR_OWNER" end
    local touched = {}
    local function Fail(err)
        for index = #touched, 1, -1 do
            local entry = touched[index]
            ledger:SetSource(entry.source)
            if equipping and entry.undo ~= nil then
                pcall(entry.undo, item, owner, entry.value)
            end
            ledger:ClearSource(entry.source)
        end
        ledger:SetSource(nil)
        return false, err
    end

    for index, affix in ipairs(equipment.affixes or {}) do
        local row = Defs.Affixes[affix.id]
        local source = Source(item, "affix", index)
        ledger:SetSource(source)
        touched[#touched + 1] = {source = source,
            undo = row ~= nil and row.un_equip_fn or nil, value = affix.value}
        local callback = row ~= nil and (equipping and row.on_equip_fn or row.un_equip_fn) or nil
        if callback ~= nil then
            local ok, err = pcall(callback, item, owner, affix.value)
            if not ok then return Fail(err) end
        end
        if not equipping then ledger:ClearSource(source) end
    end
    ledger:SetSource(nil)
    return true
end

local function Snapshot(item)
    local equipment = item.components ~= nil and item.components.tbc_equipment or nil
    if equipment == nil then return nil end
    local snapshot = {affixes = {}}
    for _, row in ipairs(equipment.affixes or {}) do
        snapshot.affixes[#snapshot.affixes + 1] = {id = row.id, value = row.value}
    end
    return snapshot
end

function M.Detach(item, owner)
    owner = owner or item._tbc_effect_owner
    if owner == nil or item._tbc_effect_owner ~= owner then return false end
    local ok, reason = Visit(item, owner, false, item._tbc_effect_snapshot)
    item._tbc_effect_owner = nil
    item._tbc_effect_snapshot = nil
    return ok, reason
end

function M.Attach(item, owner)
    if item == nil or owner == nil then return false end
    if item._tbc_effect_owner == owner then return true end
    if item._tbc_effect_owner ~= nil then M.Detach(item, item._tbc_effect_owner) end
    local snapshot = Snapshot(item)
    local ok, reason = Visit(item, owner, true, snapshot)
    if not ok then return false, reason end
    item._tbc_effect_owner = owner
    item._tbc_effect_snapshot = snapshot
    return true
end

function M.Sync(item)
    local owner = item ~= nil and item._tbc_effect_owner or nil
    if owner == nil then return true end
    M.Detach(item, owner)
    return M.Attach(item, owner)
end

return M
