-- Client-only presentation of Thần Khí Tu Tiên equipment data.
local M = { MAX_AFFIXES = 5 }
local COLOURS = {
    { .93, .96, 1, 1 },
    { .68, .95, .74, 1 },
    { .65, .82, 1, 1 },
    { .86, .70, .98, 1 },
    { 1, .91, .55, 1 },
}
local STONE_TIERS = { I = 1, II = 2, III = 3, IV = 4, V = 5, UTILITY = 4 }
M.HEADER_COLOUR = {.45, .88, 1, 1}
M.ACTIVE_COLOUR = {.68, .90, .58, 1}
M.LOCKED_COLOUR = {.50, .50, .50, 1}
local WEAPON_MILESTONES = {
    {3, "Bộc Liệt: Tấn công gây sát thương lan."},
    {5, "Bạo Vũ: Gây thêm sát thương khi tấn công."},
    {9, "Ngự Lôi: Miễn nhiễm sát thương từ sét."},
    {11, "Địa Chấn: Có cơ hội giữ chân mục tiêu."},
    {13, "Ảnh Tập: Có cơ hội tạo phân thân tấn công."},
    {13, "Vĩnh Cửu: Không tiêu hao độ bền.", true},
    {16, "Thiên Kiếp: +500 xuyên giáp, +50% sát thương bạo kích."},
}
local HEAD_MILESTONES = {
    {3, "Nhập Định: Giảm tiêu hao độ đói theo cấp."},
    {5, "Hoá Thần: Đảo ngược hào quang tinh thần tiêu cực."},
    {9, "Kim Quang: Phát sáng phạm vi lớn."},
    {11, "Huyết Chú: Hồi đầy máu khi dưới 30% máu, có hồi chiêu."},
    {13, "Bất Diệt: Không hao độ bền; có cơ hội hồi máu khi giáp đỡ đòn."},
    {16, "Giảm 50% sát thương nhận vào khi đội."},
}
local BODY_MILESTONES = {
    {3, "Lưu Vân: Tăng tốc độ di chuyển theo cấp."},
    {5, "Hồi Phong: Có cơ hội đẩy lùi mục tiêu khi bị đánh."},
    {7, "Phản Chấn: Phản sát thương giáp hấp thụ."},
    {9, "Ngạo Tuyết: Kháng lửa và miễn nhiễm mưa axit."},
    {11, "Vô Ngã: Chống hất ngã."},
    {13, "Bất Diệt: Không hao độ bền; có cơ hội hồi máu khi giáp đỡ đòn."},
    {16, "+500 máu tối đa khi mặc."},
}

local function EquipSlot(item)
    local components = item.components or {}
    local equipped = components.equippable
    if equipped ~= nil and equipped.equipslot ~= nil then return equipped.equipslot end
    equipped = item.replica ~= nil and item.replica.equippable or nil
    if equipped ~= nil and equipped.EquipSlot ~= nil then return equipped:EquipSlot() end
    if item.HasTag ~= nil and EQUIPSLOTS ~= nil then
        if item:HasTag("equippable-head") then return EQUIPSLOTS.HEAD end
        if item:HasTag("equippable-body") then return EQUIPSLOTS.BODY end
        if item:HasTag("equippable-hands") then return EQUIPSLOTS.HANDS end
    end
end

function M.StrengthenRows(detail)
    local rows = {}
    local milestones = detail.slot == (EQUIPSLOTS ~= nil and EQUIPSLOTS.HEAD) and HEAD_MILESTONES
        or detail.slot == (EQUIPSLOTS ~= nil and EQUIPSLOTS.BODY) and BODY_MILESTONES
        or detail.kind == "weapon" and WEAPON_MILESTONES or nil
    if milestones == nil then return rows end
    for _, entry in ipairs(milestones) do
        local active = detail.level >= entry[1]
        rows[#rows + 1] = {label = entry[3] and "" or "(+" .. entry[1] .. ")",
            text = entry[2], active = active,
            colour = active and M.ACTIVE_COLOUR or M.LOCKED_COLOUR}
    end
    return rows
end

function M.Colour(level)
    level = tonumber(level) or 0
    return COLOURS[level >= 12 and 5 or level >= 9 and 4
        or level >= 6 and 3 or level >= 3 and 2 or 1]
end

function M.Read(item, source)
    if item == nil or source == nil or item._tbc_detail == nil
        or item.IsValid == nil or not item:IsValid() then return nil end
    local state = item._tbc_detail:value()
    local level, encoded
    if type(state) == "string" then
        level, encoded = state:match("^(%d+);(.*)$")
    end
    if level == nil then
        if item.HasTag == nil or not item:HasTag("tbc_upgradeable") then return nil end
        level, encoded = 0, ""
    else
        level = tonumber(level) or 0
    end
    local stat = item._tbc_strengthen_stat ~= nil
        and item._tbc_strengthen_stat:value() or ""
    local detail = { level = level, affixes = {}, other_affixes = {}, stat = stat,
        max_affixes = source.max_affixes or M.MAX_AFFIXES }
    detail.slot = EquipSlot(item)
    local components = item.components or {}
    if components.weapon ~= nil or stat:find("Sát thương", 1, true) == 1
        or (item.HasTag ~= nil and item:HasTag("weapon")) then
        detail.kind = "weapon"
    elseif components.armor ~= nil or stat:find("Giảm sát thương", 1, true) == 1 then
        detail.kind = "armor"
    elseif detail.slot == (EQUIPSLOTS ~= nil and EQUIPSLOTS.HEAD)
        or detail.slot == (EQUIPSLOTS ~= nil and EQUIPSLOTS.BODY) then
        detail.kind = "equipment"
    end
    detail.damage_bonus = tonumber(stat:match("%(%+([%d%.]+) từ cường hóa%)"))
    -- A hosted world can read the authoritative component immediately.
    local upgrade = components.tbc_upgrade
    if detail.damage_bonus == nil and upgrade ~= nil
        and type(upgrade.base_damage) == "number" and type(upgrade.last_damage) == "number" then
        detail.damage_bonus = math.max(0, upgrade.last_damage - upgrade.base_damage)
    end
    for id, value in (encoded or ""):gmatch("([^:|]+):(%d+)") do
        local row = source.by_code ~= nil and source.by_code[id] or nil
        local number = tonumber(value)
        local amount = row ~= nil and source.value_text ~= nil
            and source.value_text(id, number) or nil
        if row ~= nil and amount ~= nil and #detail.affixes < detail.max_affixes then
            detail.affixes[#detail.affixes + 1] = {
                name = row.name, value = amount,
                description = source.description ~= nil and source.description(id) or "",
                atlas = "images/tbc_affixes/" .. row.image_id .. ".xml",
                image = row.image_id .. ".tex",
                colour = COLOURS[STONE_TIERS[row.tier] or 1],
            }
        end
    end
    local other_state = item._tbc_equip_state ~= nil
        and item._tbc_equip_state:value() or ""
    local _, _, old_entries = other_state:match("^(%d+);([^;]*);(.*)$")
    if old_entries ~= nil then other_state = old_entries end
    for entry in other_state:gmatch("[^|]+") do
        local id, value = entry:match("^([^:]+):(.+)$")
        local row = id ~= nil and source.solo_by_code ~= nil
            and source.solo_by_code[id] or nil
        if row ~= nil then
            detail.other_affixes[#detail.other_affixes + 1] =
                row.name .. (tonumber(value) ~= nil and " +" .. value or "")
        end
    end
    return detail
end

function M.ReadStone(item, source)
    if item == nil or item.prefab ~= "hh_effect_stone" or source == nil
        or source.stone_detail == nil or item.IsValid == nil or not item:IsValid()
        or item._tbc_code == nil or item._tbc_value == nil then return nil end
    local code = item._tbc_code:value()
    local row = source.by_code ~= nil and source.by_code[code] or nil
    if row == nil then return nil end
    local description, stat = source.stone_detail(item)
    if description == nil or stat == nil then return nil end
    return {
        kind = "stone", name = item:GetDisplayName(),
        description = description, stat = stat, slot = row.slot,
        affix_name = row.name,
        atlas = "images/tbc_affixes/" .. row.image_id .. ".xml",
        image = row.image_id .. ".tex",
        colour = source.stone_colour ~= nil and source.stone_colour(item) or COLOURS[1],
    }
end

function M.Name(item, detail)
    local name = item:GetDisplayName() or ""
    name = name:match("^[^\n]*") or name
    name = name:gsub(" %+(%d+)$", "")
    return name .. (detail.level > 0 and " +" .. detail.level or "")
end

function M.Lines(detail, base)
    local lines = {"", "THUỘC TÍNH · " .. #detail.affixes .. "/" .. (detail.max_affixes or M.MAX_AFFIXES)}
    local icon_lines = {}
    if #detail.affixes == 0 then
        lines[#lines + 1] = "Chưa gắn Đá Thuộc Tính"
    else
        for _, affix in ipairs(detail.affixes) do
            lines[#lines + 1] = "     " .. affix.name .. " · " .. affix.value
            icon_lines[#icon_lines + 1] = {index = #lines, atlas = affix.atlas, image = affix.image}
            if affix.description ~= nil and affix.description ~= "" then
                lines[#lines + 1] = "     " .. affix.description
            end
        end
    end
    if #detail.other_affixes > 0 then
        lines[#lines + 1] = "DÒNG TRANG BỊ"
        for _, affix in ipairs(detail.other_affixes) do
            lines[#lines + 1] = affix
        end
    end
    local milestones = M.StrengthenRows(detail)
    if #milestones > 0 then
        lines[#lines + 1] = "CƯỜNG HÓA"
        for _, row in ipairs(milestones) do
            lines[#lines + 1] = row.label .. "   " .. row.text
        end
    end
    if base ~= nil and base ~= "" then
        lines[#lines + 1] = "THÔNG TIN VẬT PHẨM"
        lines[#lines + 1] = base
    end
    return table.concat(lines, "\n"), icon_lines
end

function M.StoneLines(stone, base)
    local lines = {
        "", "THUỘC TÍNH",
        "     " .. stone.affix_name .. " · " .. stone.stat,
        "     " .. stone.description,
        "Áp dụng: " .. stone.slot,
    }
    if base ~= nil and base ~= "" then
        lines[#lines + 1] = "THÔNG TIN VẬT PHẨM"
        lines[#lines + 1] = base
    end
    return table.concat(lines, "\n"), {{
        index = 3, atlas = stone.atlas, image = stone.image,
    }}
end

return M
