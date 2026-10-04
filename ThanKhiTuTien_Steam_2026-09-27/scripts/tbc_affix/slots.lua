local Defs = require("tbc_affix/defs")
local M = {}

local function Slot(name)
    return EQUIPSLOTS ~= nil and EQUIPSLOTS[name] or name
end

function M.Accept(item, row)
    if item == nil or row == nil then return false end
    local components = item.components or {}
    local equippable = components.equippable
    if equippable == nil then return false end
    if row.slot == "Mọi trang bị" then return true end
    if row.slot == "Vũ khí" then return components.weapon ~= nil end
    if row.slot == "Giáp" then return components.armor ~= nil end
    if row.slot == "Trang bị có độ bền" then
        return components.finiteuses ~= nil or components.armor ~= nil
    end
    if row.slot == "Mũ hoặc phụ kiện" then
        return equippable.equipslot == Slot("HEAD")
            or equippable.equipslot == Slot("NECK")
    end
    if row.slot == "Giáp hoặc phụ kiện" then
        return components.armor ~= nil or equippable.equipslot == Slot("NECK")
    end
    return false
end

function M.CanAdd(item, affixes, row)
    if row == nil then return false, "Dữ liệu Đá Thuộc Tính không hợp lệ." end
    if not M.Accept(item, row) then return false, "Đá này không hợp vị trí trang bị." end
    if type(affixes) ~= "table" then return false, "Dữ liệu thuộc tính trang bị không hợp lệ." end
    if #affixes >= Defs.MAX_SLOTS then return false, "Trang bị đã đủ 5 dòng thuộc tính." end
    for _, affix in ipairs(affixes) do
        local existing = Defs.by_code[affix.id]
        if existing ~= nil and (
            existing.code == row.code
            or (row.family == "Hộ Giáp" or row.family == "Bền Bỉ"
                or row.family == "Gia Trì") and existing.family == row.family
            or row.exclusive_group ~= "" and existing.exclusive_group == row.exclusive_group
        ) then return false, "Trang bị đã có thuộc tính cùng nhóm." end
    end
    return true
end

return M
