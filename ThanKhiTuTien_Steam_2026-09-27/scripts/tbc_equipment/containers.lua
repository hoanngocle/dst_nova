local M = {}

local function IsEquipment(item)
    if item == nil then return false end
    local components = item.components or {}
    local replica = item.replica or {}
    return components.tbc_equipment ~= nil
        or components.equippable ~= nil and components.stackable == nil
        or replica.equippable ~= nil and replica.stackable == nil
end

function M.RegisterParams(containers, vector3)
    local positions = {
        vector3(-140, 65, 0), vector3(100, 65, 0),
        vector3(100, 65, 0),
    }
    containers.params.tbc_equipment_box = {
        widget = {slotpos = positions, pos = vector3(0, 0, 0),
            animbank = "ui_bundle_2x2", animbuild = "ui_bundle_2x2"},
        openlimit = 1,
        usespecificslotsforitems = true,
        type = "chest",
        itemtestfn = function(_, item, slot)
            if item == nil then return false end
            if slot == 1 then return IsEquipment(item) end
            if slot == 2 then return item.prefab == "hh_effect_stone"
                or item.prefab == "hh_effect_tally" end
            if slot == 3 then return item.prefab == "hh_remove_stone" end
            return false
        end,
    }
    containers.params.tbc_suit_build = {
        widget = {slotpos = {
            vector3(-265, 73, 0), vector3(-125, 73, 0),
            vector3(15, 73, 0), vector3(152, 73, 0),
            vector3(286, 73, 0),
        }, pos = vector3(0, 0, 0),
            animbank = "ui_bundle_2x2", animbuild = "ui_bundle_2x2"},
        openlimit = 1,
        usespecificslotsforitems = true,
        type = "chest",
        itemtestfn = function(_, item, slot)
            if item == nil then return false end
            if slot == 1 then return IsEquipment(item) end
            if slot == 2 then return IsEquipment(item)
                or item.prefab == "hh_effect_stone"
                or item.prefab == "hh_effect_tally" end
            if slot == 3 then return IsEquipment(item)
                or item.prefab == "hh_remove_stone" end
            if slot == 4 then return item.prefab == "hh_essence" end
            if slot == 5 then return item.prefab == "nightmarefuel" end
            return false
        end,
    }
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 5)
end

function M.CanUse(player, box)
    if player == nil or box == nil or box.tbc_owner ~= player then return false end
    if player.HasTag ~= nil and player:HasTag("playerghost") then return false end
    local container = box.components ~= nil and box.components.container or nil
    if container ~= nil then
        local opened = container.openlist ~= nil and container.openlist[player]
            or container.IsOpenedBy ~= nil and container:IsOpenedBy(player)
        if not opened then return false end
    elseif not box.tbc_open then return false end
    local station = box.tbc_station
    if station ~= nil then
        if station.IsValid ~= nil and not station:IsValid() then return false end
        if player.GetDistanceSqToInst ~= nil and player:GetDistanceSqToInst(station) > 36 then
            return false
        end
    end
    return true
end

function M.GetSlot(box, index)
    if type(index) ~= "number" or index % 1 ~= 0 then return nil end
    local container = box.components ~= nil and box.components.container or nil
    return container ~= nil and container:GetItemInSlot(index)
        or box.slots ~= nil and box.slots[index] or nil
end

return M
