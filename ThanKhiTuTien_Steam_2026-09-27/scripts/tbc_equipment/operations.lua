local Containers = require("tbc_equipment/containers")
local Defs = require("tbc_equipment/solo_defs")
local Stone = require("tbc_affix/stone")
local Roll = require("tbc_affix/roll")
local AffixDefs = require("tbc_affix/defs")
local M = {}

local function SpendOne(item)
    local stack = item.components ~= nil and item.components.stackable or nil
    if stack ~= nil then
        local one = stack:Get()
        if one ~= nil then one:Remove() end
    else
        item:Remove()
    end
end

local function RollAffix(item)
    local eligible = {}
    for id, row in pairs(Defs.Affixes) do
        local valid = true
        if row.check_equip_can_add ~= nil then
            local ok, allowed = pcall(row.check_equip_can_add, item)
            valid = ok and allowed
        end
        if row.can_add and row.value_range ~= nil and valid then
            eligible[#eligible + 1] = id
        end
    end
    if #eligible == 0 then return nil end
    table.sort(eligible)
    local id = eligible[math.random(1, #eligible)]
    local range = Defs.Affixes[id].value_range
    return id, math.random(range.min, range.max)
end

local function AffixAdd(_, box)
    local item = Containers.GetSlot(box, 1)
    local material = Containers.GetSlot(box, 2)
    local equip = item ~= nil and item.components ~= nil and item.components.tbc_equipment or nil
    if equip == nil or material == nil then return false, "MISSING_EQUIPMENT_OR_STONE" end
    local id, value
    if material.prefab == "hh_effect_stone" then
        local stone_code, stone_value = Stone.Read(material)
        if stone_code ~= nil then
            local upgrade = item.components.tbc_upgrade
            if upgrade == nil then return false, "MISSING_UPGRADE_COMPONENT" end
            local added = upgrade:AddAffix(stone_code, stone_value)
            if not added then return false, "AFFIX_ADD_FAILED" end
            SpendOne(material)
            return true
        end
        id = material.hh_effect
        if id == nil and material._tbc_affix ~= nil then id = material._tbc_affix:value() end
        if id == nil and material._tbc_code ~= nil then id = material._tbc_code:value() end
        value = material.hh_value
        if value == nil and material._tbc_value ~= nil then value = material._tbc_value:value() end
        if id == nil or Defs.Affixes[id] == nil then return false, "INVALID_AFFIX_STONE" end
        if value == nil then
            local range = Defs.Affixes[id].value_range
            value = range ~= nil and math.random(range.min, range.max) or nil
        end
    elseif material.prefab == "hh_effect_tally" then
        id, value = RollAffix(item)
    else
        return false, "INVALID_AFFIX_MATERIAL"
    end
    if id == nil then return false, "NO_ELIGIBLE_AFFIX" end
    local ok, reason = equip:AddAffix(id, value)
    if not ok then return false, reason end
    SpendOne(material)
    return true
end

local function AffixRemove(_, box)
    local item = Containers.GetSlot(box, 1)
    local material = Containers.GetSlot(box, 3)
    local equip = item ~= nil and item.components ~= nil and item.components.tbc_equipment or nil
    if equip == nil or material == nil or material.prefab ~= "hh_remove_stone" then
        return false, "MISSING_EQUIPMENT_OR_REMOVER"
    end
    local removed, reason
    if #equip.affixes > 0 then
        removed, reason = equip:RemoveAffix(math.random(1, #equip.affixes))
    else
        local upgrade = item.components.tbc_upgrade
        if upgrade == nil or upgrade.RemoveRandomAffix == nil
            or #upgrade.affixes == 0 then return false, "NO_AFFIX" end
        removed = upgrade:RemoveRandomAffix()
        reason = "NO_AFFIX"
    end
    if not removed then return false, reason end
    SpendOne(material)
    return true
end

local function AffixClean(player, box, index)
    local item = Containers.GetSlot(box, 1)
    local components = item ~= nil and item.components or nil
    if components == nil then return false, "Đặt trang bị vào ô trước" end
    local solo = components.hh_equip
    local upgrade = components.tbc_upgrade
    local equip = components.tbc_equipment
    local target, affixes, kind
    if solo ~= nil and type(solo.equip_buff_list) == "table"
        and #solo.equip_buff_list > 0
        and type(solo.ReduceEquipBuffByIndex) == "function" then
        target, affixes, kind = solo, solo.equip_buff_list, "solo"
    elseif upgrade ~= nil and type(upgrade.affixes) == "table"
        and #upgrade.affixes > 0
        and type(upgrade.RemoveAffixAt) == "function" then
        target, affixes, kind = upgrade, upgrade.affixes, "upgrade"
    elseif equip ~= nil and type(equip.affixes) == "table"
        and #equip.affixes > 0
        and type(equip.RemoveAffix) == "function" then
        target, affixes, kind = equip, equip.affixes, "equipment"
    end
    if affixes == nil then return false, "Trang bị chưa có dòng thuộc tính" end
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > (kind == "upgrade" and AffixDefs.MAX_SLOTS or 3) or index > #affixes then
        return false, "Dòng này chưa có thuộc tính"
    end

    local player_components = player.components or {}
    local solo_player = player_components.hh_player
    local inventory = player_components.inventory
    local wallet = player_components.tbc_equipment_wallet
    local currency = solo_player ~= nil and solo_player.GetItemsByKey ~= nil
        and solo_player.RemoveItemsByKey ~= nil
        and solo_player:GetItemsByKey("ad_cleanStone") >= 1 and "solo"
        or inventory ~= nil and inventory.Has ~= nil
        and inventory.ConsumeByName ~= nil
        and inventory:Has("ad_cleanstone", 1) and "item"
        or wallet ~= nil and wallet:Get("ad_cleanStone") >= 1 and "wallet" or nil
    if currency == nil then
        return false, "Cần 1 Đá Tẩy Thuộc Tính trong túi Solo hoặc túi đồ"
    end

    local removed, reason
    if kind == "solo" then
        removed, reason = target:ReduceEquipBuffByIndex(index)
    elseif kind == "upgrade" then
        removed = target:RemoveAffixAt(index)
    else
        removed, reason = target:RemoveAffix(index)
    end
    if not removed then return false, reason or "Không thể tẩy dòng thuộc tính" end
    if currency == "solo" then
        solo_player:RemoveItemsByKey("ad_cleanStone", 1)
    elseif currency == "item" then
        inventory:ConsumeByName("ad_cleanstone", 1)
    else
        wallet:Spend("ad_cleanStone", 1)
    end
    return true
end

local function AffixReroll(player, box)
    local wallet = player.components ~= nil and player.components.tbc_equipment_wallet or nil
    local item = Containers.GetSlot(box, 1)
    local equip = item ~= nil and item.components ~= nil and item.components.tbc_equipment or nil
    if wallet == nil or equip == nil then return false, "MISSING_EQUIPMENT" end
    if wallet:Get("ac_refreshStone") < 1 then return false, "MISSING_REFRESH_STONE" end
    local ok, reason
    if #equip.affixes > 0 then
        ok, reason = equip:RerollAffixValues()
    else
        local upgrade = item.components.tbc_upgrade
        if upgrade == nil or upgrade.RerollAffix == nil
            or #upgrade.affixes == 0 then return false, "NO_AFFIX" end
        ok = upgrade:RerollAffix()
        reason = "AFFIX_REROLL_FAILED"
    end
    if not ok then return false, reason end
    wallet:Spend("ac_refreshStone", 1)
    return true
end

local function Inherit(player, box)
    local container = box.components ~= nil and box.components.container or nil
    local source = Containers.GetSlot(box, 2)
    local target = Containers.GetSlot(box, 3)
    local from = source ~= nil and source.components ~= nil and source.components.tbc_equipment or nil
    local to = target ~= nil and target.components ~= nil and target.components.tbc_equipment or nil
    if container == nil or from == nil or to == nil then return false, "MISSING_EQUIPMENT" end
    if container.Has == nil or container.ConsumeByName == nil
        or not container:Has("hh_essence", 20) or not container:Has("nightmarefuel", 20) then
        return false, "MISSING_INHERIT_MATERIAL"
    end
    local ok, reason = from:TransferTo(to)
    if not ok then return false, reason end
    container:ConsumeByName("hh_essence", 20)
    container:ConsumeByName("nightmarefuel", 20)
    source:Remove()
    return true
end

local function StoneReroll(player, box)
    local container = box.components ~= nil and box.components.container or nil
    local old = Containers.GetSlot(box, 2)
    if container == nil or old == nil or old.prefab ~= "hh_effect_stone" then
        return false, "MISSING_AFFIX_STONE"
    end
    if container.Has == nil or container.ConsumeByName == nil
        or not container:Has("hh_essence", 5) then
        return false, "MISSING_ESSENCE"
    end
    local level = player.components ~= nil and player.components.xd_level ~= nil
        and player.components.xd_level.level or nil
    local code, value = Roll.Choose(level)
    if code == nil then return false, "NO_ELIGIBLE_STONE" end
    local fresh = SpawnPrefab("hh_effect_stone")
    if fresh == nil then return false, "STONE_SPAWN_FAILED" end
    if not Stone.Set(fresh, code, value) then
        fresh:Remove()
        return false, "STONE_INVALID"
    end
    old:Remove()
    container:ConsumeByName("hh_essence", 5)
    container:GiveItem(fresh, 2)
    return true
end

local HANDLERS = {
    inherit = Inherit,
    affix_add = AffixAdd,
    affix_remove = AffixRemove,
    affix_clean = AffixClean,
    affix_reroll = AffixReroll,
    stone_reroll = StoneReroll,
}
local STATION_OPERATIONS = {inherit = true, affix_clean = true, stone_reroll = true}

function M.Execute(player, box, operation, arg)
    if not Containers.CanUse(player, box) then return false, "NOT_OWNER_OR_TOO_FAR" end
    local handler = type(operation) == "string" and HANDLERS[operation] or nil
    if handler == nil then return false, "UNKNOWN_OPERATION" end
    if box.prefab == "tbc_equipment_box" and STATION_OPERATIONS[operation] then
        return false, "WRONG_EQUIPMENT_SCREEN"
    end
    return handler(player, box, arg)
end

return M
