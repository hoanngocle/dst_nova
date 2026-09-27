local Runtime = require("tbc_equipment/effect_runtime")
local M = {}

function M.AttachItem(inst)
    local components = inst ~= nil and inst.components or nil
    if components == nil or components.equippable == nil
        or components.inventoryitem == nil or components.stackable ~= nil
        or inst.AddComponent == nil then return false end
    if components.tbc_equipment == nil then inst:AddComponent("tbc_equipment") end
    inst:AddTag("tbc_equipment")
    if inst._tbc_equipment_wrapped then return true end
    inst._tbc_equipment_wrapped = true
    local equippable = components.equippable
    local old_equip = equippable.onequipfn
    local old_unequip = equippable.onunequipfn
    equippable.onequipfn = function(item, owner, ...)
        if old_equip ~= nil then old_equip(item, owner, ...) end
        if owner ~= nil and owner.HasTag ~= nil and owner:HasTag("player") then
            local ok, reason = Runtime.Attach(item, owner)
            if not ok then print("[ThanKhiTuTien] Equipment effect attach failed: " .. tostring(reason)) end
        end
    end
    equippable.onunequipfn = function(item, owner, ...)
        Runtime.Detach(item, owner)
        if old_unequip ~= nil then old_unequip(item, owner, ...) end
    end
    if inst.ListenForEvent ~= nil then
        inst:ListenForEvent("onremove", function(item)
            Runtime.Detach(item)
        end)
    end
    if inst.DoTaskInTime ~= nil then
        inst:DoTaskInTime(0, function(item)
            local equipped = item.components ~= nil and item.components.equippable or nil
            local inventory = item.components ~= nil and item.components.inventoryitem or nil
            local owner = inventory ~= nil and inventory.owner or nil
            if equipped ~= nil and equipped.IsEquipped ~= nil and equipped:IsEquipped()
                and owner ~= nil and owner.HasTag ~= nil and owner:HasTag("player") then
                Runtime.Attach(item, owner)
            end
        end)
    end
    return true
end

return M
