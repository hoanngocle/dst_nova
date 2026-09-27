-- Adapter for Tu Tien widgets/xd_showhoverui:SetNew({str={{label,value},...}},...).
-- Add rows BEFORE the original renderer measures them and builds its frame.
local M = {}
local HEADER_COLOUR = {.45, .88, 1, 1}

local function Copy(t)
    local result = {}
    for k, v in pairs(t) do result[k] = v end
    return result
end

local function Wrapped(text, add, indent)
    local line = ""
    for word in tostring(text or ""):gmatch("%S+") do
        local next_line = line == "" and word or line .. " " .. word
        -- Count UTF-8 characters, not bytes, when wrapping Vietnamese text.
        if #next_line:gsub("[\128-\191]", "") > 42 and line ~= "" then
            add((indent or "") .. line)
            line = word
        else
            line = next_line
        end
    end
    if line ~= "" then add((indent or "") .. line) end
end

function M.Augment(data, item, detail, Detail)
    local result = Copy(data)
    result.str = {}
    for i, row in ipairs(data.str) do result.str[i] = Copy(row) end
    if detail.damage_bonus ~= nil then
        for _, row in ipairs(result.str) do
            if row[1] == "伤害" or row[1] == "Sát thương" then
                if row[2] ~= nil then
                    row[2] = tostring(row[2]) .. " (+" .. string.format("%g", detail.damage_bonus) .. " từ cường hóa)"
                end
                break
            end
        end
    end
    result.str[1][1] = detail.kind == "stone" and detail.name or Detail.Name(item, detail)
    local decor = {icons = {}, headers = {}, milestones = {}, colour = detail.kind == "stone"
        and detail.colour or Detail.Colour(detail.level)}
    local milestone_lines = {}
    if detail.kind ~= "stone" then
        for _, entry in ipairs(Detail.StrengthenRows(detail)) do
            local label = entry.label
            Wrapped(entry.text, function(line)
                milestone_lines[#milestone_lines + 1] = {
                    text = line, label = label, colour = entry.colour, active = entry.active}
                label = ""
            end)
        end
    end
    -- Reserve the final milestone rows before optional gem descriptions.
    local reserved = #milestone_lines > 0 and #milestone_lines + 1 or 0
    local function Add(text)
        -- The current Tu Tien widget preallocates 40 text rows.
        if #result.str >= 40 - reserved then return nil end
        result.str[#result.str + 1] = {text}
        return #result.str
    end
    local function Header(text)
        local index = Add(text)
        if index ~= nil then decor.headers[#decor.headers + 1] = index end
    end
    local function Affix(text, atlas, image, description, colour)
        local row = Add("      " .. text)
        if row ~= nil then
            decor.icons[#decor.icons + 1] = {row = row, atlas = atlas, image = image, colour = colour}
        end
        Wrapped(description, Add, "      ")
    end
    if detail.kind == "stone" then
        Header("THUỘC TÍNH")
        Affix(detail.affix_name, detail.atlas, detail.image, nil, detail.colour)
        Wrapped(detail.stat, Add)
        Wrapped(detail.description, Add)
        Wrapped("Áp dụng: " .. detail.slot, Add)
    else
        Header("THUỘC TÍNH · " .. #detail.affixes .. "/" .. (detail.max_affixes or Detail.MAX_AFFIXES or 5))
        if #detail.affixes == 0 then Add("Chưa gắn Đá Thuộc Tính") end
        for index, affix in ipairs(detail.affixes) do
            reserved = reserved + #detail.affixes - index
            Affix(affix.name .. " · " .. affix.value,
                affix.atlas, affix.image, affix.description, affix.colour)
            reserved = reserved - (#detail.affixes - index)
        end
        reserved = 0
        if #milestone_lines > 0 then
            Header("CƯỜNG HÓA")
            for _, entry in ipairs(milestone_lines) do
                entry.row = Add("            " .. entry.text)
                if entry.row ~= nil then decor.milestones[#decor.milestones + 1] = entry end
            end
        end
        if #detail.other_affixes > 0 then
            Header("DÒNG TRANG BỊ")
            for _, affix in ipairs(detail.other_affixes) do Wrapped(affix, Add) end
        end
    end
    return result, decor
end

local function HoveredItem(G)
    if G.TheInput == nil then return nil end
    local entity = G.TheInput:GetHUDEntityUnderMouse()
    if entity ~= nil then
        local widget = entity.widget
        while widget ~= nil do
            if widget.item ~= nil then return widget.item end
            widget = widget.parent
        end
        return nil
    end
    return G.TheInput:GetWorldEntityUnderMouse()
end

local function Resolve(data, G, Detail, ...)
    if type(data) ~= "table" or type(data.str) ~= "table"
        or type(data.str[1]) ~= "table" then return nil end
    local title = data.str[1][1]
    local function Check(item)
        if type(item) ~= "table" or item.GetDisplayName == nil then return nil end
        local detail = Detail.Read(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
            or Detail.ReadStone(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
        if detail == nil then return nil end
        local name = item:GetDisplayName()
        local enhanced = detail.kind == "stone" and detail.name or Detail.Name(item, detail)
        if title == name or title == enhanced then return item, detail end
    end
    -- Prefer the renderer's target when provided, then use the hovered slot
    -- or world entity. Matching the title keeps other tooltip instances intact.
    for i = 1, select("#", ...) do
        local item, detail = Check(select(i, ...))
        if item ~= nil then return item, detail end
    end
    return Check(HoveredItem(G))
end

local function ResetDecor(widget)
    for _, entry in ipairs(widget._ttk_xd_colours or {}) do
        entry.text:SetColour(unpack(entry.colour))
    end
    widget._ttk_xd_colours = {}
    for _, icon in ipairs(widget._ttk_xd_icons or {}) do icon:Hide() end
    for _, label in pairs(widget._ttk_xd_labels or {}) do label:Hide() end
end

local function Decorate(widget, decor, Image, Text, G)
    local rows = widget.strdata or {}
    local function Colour(index, colour)
        local text = rows[index]
        if text == nil then return end
        local original = text:GetColour()
        -- Text:GetColour returns an RGBA table in DST.
        widget._ttk_xd_colours[#widget._ttk_xd_colours + 1] =
            {text = text, colour = Copy(original)}
        text:SetColour(unpack(colour))
    end
    Colour(1, decor.colour)
    for _, index in ipairs(decor.headers) do Colour(index, HEADER_COLOUR) end
    widget._ttk_xd_labels = widget._ttk_xd_labels or {}
    for index, entry in ipairs(decor.milestones) do
        Colour(entry.row, entry.colour)
        local row = rows[entry.row]
        if row ~= nil and Text ~= nil and entry.label ~= "" then
            local label = widget._ttk_xd_labels[index]
            if label == nil then
                label = widget:AddChild(Text(row.font or G.BODYTEXTFONT, row:GetSize()))
                label:SetClickable(false)
                widget._ttk_xd_labels[index] = label
            end
            label:SetSize(row:GetSize())
            label:SetString(entry.label)
            label:SetColour(unpack(entry.colour))
            local width = label:GetRegionSize()
            local p = row:GetPosition()
            label:SetPosition(p.x - (widget.maxw or 0) / 2 + width / 2, p.y, 1)
            label:Show()
        end
    end
    widget._ttk_xd_icons = widget._ttk_xd_icons or {}
    for index, entry in ipairs(decor.icons) do
        if entry.colour ~= nil then Colour(entry.row, entry.colour) end
        local row = rows[entry.row]
        if row ~= nil then
            local icon = widget._ttk_xd_icons[index]
            if icon == nil then
                icon = widget:AddChild(Image())
                icon:SetClickable(false)
                widget._ttk_xd_icons[index] = icon
            end
            icon:SetTexture(entry.atlas, entry.image)
            icon:SetSize(18, 18)
            local p = row:GetPosition()
            icon:SetPosition(p.x - (widget.maxw or 0) / 2 + 10, p.y, 1)
            icon:Show()
        end
    end
end

function M.Install(class, G, Detail, Image, Player, Text)
    local original = class._ttk_xd_original_setnew or class.SetNew
    class._ttk_xd_original_setnew = original
    class.SetNew = function(widget, data, ...)
        ResetDecor(widget)
        local item, detail = Resolve(data, G, Detail, ...)
        local decor
        if detail ~= nil then data, decor = M.Augment(data, item, detail, Detail) end
        if detail == nil and Player ~= nil and Player.IsPlayerData(data) then
            local target = HoveredItem(G)
            if target ~= nil and target.HasTag ~= nil and target:HasTag("player") then
                local stats = Player.Read(target)
                if stats ~= nil then data = Player.Augment(data, stats) end
            end
        end
        local result = original(widget, data, ...)
        if decor ~= nil then Decorate(widget, decor, Image, Text, G) end
        return result
    end
end

return M
