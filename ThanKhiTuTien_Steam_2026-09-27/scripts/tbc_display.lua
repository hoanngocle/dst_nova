local Catalog = require("tbc_catalog")
local Defs = require("tbc_affix/defs")

local M = {}
local WHITE = { .93, .96, 1, 1 }
local GREEN = { .68, .95, .74, 1 }
local PALE_BLUE = { .65, .82, 1, 1 }
local PURPLE = { .86, .70, .98, 1 }
local YELLOW = { 1, .91, .55, 1 }
local RED = { 1, .16, .16, 1 }

function M.NameColour(level)
    level = tonumber(level) or 0
    if level >= 16 then return RED end
    if level >= 12 then return YELLOW end
    if level >= 9 then return PURPLE end
    if level >= 6 then return PALE_BLUE end
    if level >= 3 then return GREEN end
    return WHITE
end

function M.Level(state)
    local level = type(state) == "string" and state:match("^(%d+);") or nil
    return tonumber(level) or 0
end

function M.HoverName(name, level)
    if type(name) ~= "string" or level <= 0 then return name end
    local break_at = name:find("\n", 1, true)
    if break_at == nil then return name .. " +" .. level end
    return name:sub(1, break_at - 1) .. " +" .. level .. name:sub(break_at)
end

function M.Encode(upgrade)
    if upgrade.level == 0 and #upgrade.affixes == 0 then return "" end
    local affixes = {}
    for _, row in ipairs(upgrade.affixes) do
        affixes[#affixes + 1] = row.id .. ":" .. row.value
    end
    return tostring(upgrade.level) .. ";" .. table.concat(affixes, "|")
end

function M.Format(state, names)
    if state == nil or state == "" then return "" end
    local level, affix_ids = state:match("^(%d+);(.*)$")
    if level == nil then return "" end
    local lines = tonumber(level) > 0 and { "Cường hóa: +" .. level } or {}
    local affix_count = 0
    for id, value in affix_ids:gmatch("([^:|]+):(%d+)") do
        local row = Catalog.affixes[id]
        if row ~= nil then
            if affix_count >= Defs.MAX_SLOTS then break end
            lines[#lines + 1] = Defs.Format(id, tonumber(value))
            affix_count = affix_count + 1
        end
    end
    return table.concat(lines, "\n")
end

-- Solo's hoverer reads GetHHSpDesc callbacks on the server and sizes its
-- frame to the returned rows. Keep these sections separate from the plain
-- itemtile description so Tu Tien's own details remain intact.
function M.Sections(upgrade, names)
    if upgrade == nil then return {} end
    local level = tonumber(upgrade.level) or 0
    local affixes = upgrade.affixes or {}
    if level == 0 and #affixes == 0 then return {} end

    local kind = upgrade.GetKind ~= nil and upgrade:GetKind() or nil
    local bonus = level > 0 and (kind == "weapon" and ("Sát thương +" .. string.format("%g%%", level * 5))
        or kind == "armor" and ("Giảm sát thương +" .. string.format("%g%%", level * 1.5)))
        or nil
    local sections = {}

    local lines = {"Cấp +" .. level .. "/16"
        .. (bonus ~= nil and (" | " .. bonus) or "")}
    if kind == "weapon" then
        if level >= 3 then lines[#lines + 1] = "Bộc Liệt: sát thương lan" end
        if level >= 5 then lines[#lines + 1] = "Bạo Vũ: thêm sát thương khi đánh" end
        if level >= 9 then lines[#lines + 1] = "Ngự Lôi: miễn nhiễm sát thương điện" end
        if level >= 11 then lines[#lines + 1] = "Địa Chấn: có cơ hội giữ chân mục tiêu" end
        if level >= 13 then
            lines[#lines + 1] = "Ảnh Tập: bóng đánh thêm; Vĩnh Cửu: không hao độ bền"
        end
        if level >= 16 then
            lines[#lines + 1] = "+500 sát thương xuyên giáp mỗi đòn"
            lines[#lines + 1] = "+50% sát thương bạo kích"
        end
    end
    if #affixes > 0 then
        lines[#lines + 1] = math.min(#affixes, Defs.MAX_SLOTS) .. "/" .. Defs.MAX_SLOTS .. " dòng thuộc tính"
        for index = 1, math.min(#affixes, Defs.MAX_SLOTS) do
            local affix = affixes[index]
            local row = Catalog.affixes[affix.id]
            if row ~= nil then
                lines[#lines + 1] = Defs.Format(affix.id, affix.value)
            end
        end
    end
    sections[#sections + 1] = {title = "Cường hóa",
        desc = table.concat(lines, "\n"), color = YELLOW}
    return sections
end

function M.SectionsFromState(state, item, names)
    if type(state) ~= "string" then return {} end
    local level, affix_ids = state:match("^(%d+);(.*)$")
    if level == nil then return {} end

    local upgrade = {level = tonumber(level), affixes = {}}
    local kind = nil
    if item ~= nil and item.HasTag ~= nil then
        if item:HasTag("weapon") then kind = "weapon"
        elseif item:HasTag("armor") then kind = "armor" end
    end
    for id, value in affix_ids:gmatch("([^:|]+):(%d+)") do
        if Catalog.affixes[id] ~= nil then
            upgrade.affixes[#upgrade.affixes + 1] = {id = id, value = tonumber(value)}
        end
    end
    function upgrade:GetKind() return kind end
    return M.Sections(upgrade, names)
end

return M
