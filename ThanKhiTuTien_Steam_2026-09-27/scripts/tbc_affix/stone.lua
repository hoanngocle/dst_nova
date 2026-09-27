local Defs = require("tbc_affix/defs")
local Roll = require("tbc_affix/roll")

local M = {}
local DEFAULT_ATLAS = "images/hh_icon/hh_items.xml"
local DEFAULT_IMAGE = "hh_effect_stone"
local TIER_COLOURS = {
    I = { .93, .96, 1, 1 },
    II = { .68, .95, .74, 1 },
    III = { .65, .82, 1, 1 },
    IV = { .86, .70, .98, 1 },
    V = { 1, .91, .55, 1 },
    UTILITY = { .86, .70, .98, 1 },
}
local DETAILS = {
    ["Nhanh Nhẹn"] = { "Tăng tốc độ di chuyển khi trang bị", "Tốc độ di chuyển", "+" },
    ["Bền Bỉ"] = { "Tăng độ bền tối đa của trang bị", "Độ bền tối đa", "+" },
    ["Xạ Kích"] = { "Tăng tốc độ tấn công", "Tốc đánh", "+" },
    ["Gia Trì"] = { "Giúp trang bị hồi hoặc giữ độ bền", "Hiệu ứng", "" },
    ["Hộ Giáp"] = { "Tăng độ bền của giáp", "Độ bền giáp", "+" },
    ["Xuyên Giáp"] = { "Đòn đánh bỏ qua một phần giáp của mục tiêu", "Xuyên giáp", "" },
    ["Nghịch Cảnh"] = { "Phát huy sức mạnh khi lâm vào nghịch cảnh", "Hiệu ứng", "" },
    ["Huyền Vũ"] = { "Giúp chống lại các trạng thái bất lợi", "Hiệu ứng", "" },
    ["Phần Thiên"] = { "Tấn công có khả năng thiêu đốt kẻ địch", "Sát thương", "" },
    ["Vạn Độc"] = { "Tấn công có khả năng khiến kẻ địch trúng độc", "Xác suất trúng độc", "" },
    ["Huyền Băng"] = { "Tấn công có khả năng đóng băng kẻ địch", "Xác suất đóng băng", "" },
    ["Sinh Mệnh"] = { "Tăng máu tối đa khi trang bị", "Máu tối đa", "+" },
    ["Sinh Cơ"] = { "Tự hồi máu khi trang bị", "Hồi máu", "" },
    ["Linh Hải"] = { "Tăng Linh Lực tối đa khi trang bị", "Linh Lực tối đa", "+" },
    ["Tụ Linh"] = { "Hồi Linh Lực khi trang bị", "Hồi Linh Lực", "+" },
}

function M.Description(code)
    local row = Defs.by_code[code]
    local detail = row ~= nil and DETAILS[row.family] or nil
    return detail ~= nil and detail[1] or nil
end

function M.Icon(code)
    local row = Defs.by_code[code]
    if row == nil then return DEFAULT_ATLAS, DEFAULT_IMAGE end
    return "images/tbc_affixes/" .. row.image_id .. ".xml", row.image_id
end

local function ApplyIcon(inst, code)
    local inventoryitem = inst.components ~= nil and inst.components.inventoryitem or nil
    if inventoryitem == nil then return end
    local atlas, image = M.Icon(code)
    inventoryitem.atlasname = atlas
    inventoryitem:ChangeImageName(image)
end

function M.Read(inst)
    if inst._tbc_stone_invalid then return nil, nil end
    local code = inst._tbc_code ~= nil and inst._tbc_code:value() or ""
    local value = inst._tbc_value ~= nil and inst._tbc_value:value() or nil
    if not Defs.IsValidValue(code, value) then return nil, nil end
    return code, value
end

function M.Set(inst, code, value)
    if inst._tbc_stone_invalid or not Defs.IsValidValue(code, value) then return false end
    local old_code = inst._tbc_code:value()
    if old_code ~= "" then return old_code == code and inst._tbc_value:value() == value end
    inst._tbc_code:set(code)
    inst._tbc_value:set(value)
    ApplyIcon(inst, code)
    return true
end

function M.OnReceived(inst, owner, rng)
    if inst._tbc_stone_invalid or inst._tbc_code:value() ~= "" then return false end
    if owner == nil or type(owner.HasTag) ~= "function" or not owner:HasTag("player") then return false end
    local level = owner.components ~= nil
        and owner.components.xd_level ~= nil and owner.components.xd_level.level or nil
    local code, value = Roll.Choose(level, rng)
    return code ~= nil and M.Set(inst, code, value) or false
end

function M.OnSave(inst, data)
    if inst._tbc_stone_invalid then
        data.tbc_invalid = true
        return
    end
    local code, value = M.Read(inst)
    if code == nil then return end
    data.tbc_code = code
    data.tbc_value = value
end

function M.OnLoad(inst, data)
    if data == nil or next(data) == nil then return end
    if data.tbc_invalid or data.tbc_value ~= nil and data.tbc_code == nil
        or data.tbc_code ~= nil and not Defs.IsValidValue(data.tbc_code, data.tbc_value) then
        inst._tbc_stone_invalid = true
        print("[ThanKhiTuTien] Invalid attribute stone save; preserving as unusable stone.")
        return
    end
    if data.tbc_code ~= nil then M.Set(inst, data.tbc_code, data.tbc_value) end
end

function M.Display(inst, base)
    local code = M.Read(inst)
    local row = code ~= nil and Defs.by_code[code] or nil
    return row ~= nil and ("Đá " .. row.name) or base
end

function M.Detail(inst)
    local code, value = M.Read(inst)
    local row = code ~= nil and Defs.by_code[code] or nil
    local info = row ~= nil and DETAILS[row.family] or nil
    local amount = code ~= nil and Defs.ValueText(code, value) or nil
    if info == nil or amount == nil then return nil, nil end
    if row.family == "Phần Thiên" then amount = amount .. " máu tối đa/s" end
    return info[1], info[2] .. ": " .. info[3] .. amount
end

function M.ColourForCode(code)
    local row = code ~= nil and Defs.by_code[code] or nil
    return row ~= nil and TIER_COLOURS[row.tier] or nil
end

function M.Colour(inst)
    return M.ColourForCode(M.Read(inst)) or TIER_COLOURS.I
end

function M.Init(inst)
    inst._tbc_code = net_string(inst.GUID, "tbc_stone.code", "tbc_stone_dirty")
    inst._tbc_value = net_int(inst.GUID, "tbc_stone.value", "tbc_stone_dirty")
    local old_name = inst.GetDisplayName
    inst.GetDisplayName = function(self, ...)
        local base = old_name ~= nil and old_name(self, ...) or "Đá Thuộc Tính"
        return M.Display(self, base)
    end
    inst.GetHHSpDesc90 = function(stone)
        local description = M.Detail(stone)
        return description ~= nil and { title = "Mô tả", desc = description } or nil
    end
    inst.GetHHSpDesc91 = function(stone)
        local _, stat = M.Detail(stone)
        if stat == nil then return nil end
        local title, value = stat:match("^(.-): (.+)$")
        return title ~= nil and { title = title, desc = value } or nil
    end
end

function M.AttachServer(inst)
    local item = inst.components.inventoryitem
    if item ~= nil then
        item:SetOnPutInInventoryFn(function(stone, owner)
            M.OnReceived(stone, owner)
        end)
    end
    inst.OnSave = M.OnSave
    inst.OnLoad = M.OnLoad
end

return M
