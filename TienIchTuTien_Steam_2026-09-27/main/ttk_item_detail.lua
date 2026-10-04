local G = GLOBAL
if G.TheNet:IsDedicated() then return end

local Detail = require("ttk_item_detail")
local Image = G.require("widgets/image")
local Text = G.require("widgets/text")
print("[TienIchTuTien] item detail hooks 3 loaded")
local reported_itemtile = false
local reported_hoverer = false

local function HoveredItem()
    local input = G.TheInput
    if input == nil then return nil end
    local entity = input:GetHUDEntityUnderMouse()
    if entity ~= nil then
        local widget = entity.widget
        while widget ~= nil do
            if widget.item ~= nil then return widget.item end
            widget = widget.parent
        end
    end
    return input:GetWorldEntityUnderMouse()
end

local function EquipmentData()
    local item = HoveredItem()
    local detail = Detail.Read(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
    return item, detail
end

local function Data()
    local item, detail = EquipmentData()
    if detail == nil then
        detail = Detail.ReadStone(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
    end
    return item, detail
end

-- All inventory, container and forge slots use ItemTile descriptions. Keep
-- the detail in that shared string for tooltip renderers that read it.
AddClassPostConstruct("widgets/itemtile", function(tile)
    local old_description = tile.GetDescriptionString
    tile.GetDescriptionString = function(widget, ...)
        local original = old_description(widget, ...)
        local item = widget.item
        local detail = Detail.Read(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
            or Detail.ReadStone(item, G.TTK_EQUIPMENT_DETAIL_SOURCE)
        if detail == nil or type(original) ~= "string" then return original end
        if not reported_itemtile then
            print("[TienIchTuTien] itemtile detail:", item.prefab)
            reported_itemtile = true
        end
        local title, rest = original:match("^([^\n]*)(.*)$")
        if title == nil then return original end
        local name = detail.kind == "stone" and detail.name or Detail.Name(item, detail)
        local body = detail.kind == "stone" and Detail.StoneLines(detail, "")
            or Detail.Lines(detail, "")
        return name .. rest .. body
    end
end)

AddClassPostConstruct("widgets/hoverer", function(hover)
    local old_update = hover.OnUpdate
    hover.OnUpdate = function(widget, ...)
        local result = old_update(widget, ...)
        local item, detail = Data()
        if widget.isFE or detail == nil or widget.text == nil or not widget.shown then
            if widget.ttk_title ~= nil then widget.ttk_title:Hide() end
            for _, icon in ipairs(widget.ttk_icons or {}) do icon:Hide() end
            return result
        end
        if not reported_hoverer then
            print("[TienIchTuTien] hoverer detail:", item.prefab)
            reported_hoverer = true
        end

        local original = widget.str or ""
        -- ItemTile has already appended our sections. Remove them before
        -- laying out icons and the coloured title in the normal hoverer.
        local marker = detail.kind == "stone" and "\nTHUỘC TÍNH\n"
            or detail.kind == "soul_banner" and "\nCƯỜNG HÓA\n"
            or "\nTHUỘC TÍNH · "
        local marker_at = original:find(marker, 1, true)
        if marker_at ~= nil then original = original:sub(1, marker_at - 1) end
        local first, remainder = original:match("^([^\n]*)\n(.*)$")
        local base = remainder or original
        local name = detail.kind == "stone" and detail.name or Detail.Name(item, detail)
        if first ~= nil and first ~= name and first ~= item:GetDisplayName() then
            base = first .. (base ~= "" and "\n" .. base or "")
        end
        local body, icon_lines
        if detail.kind == "stone" then
            body, icon_lines = Detail.StoneLines(detail, base)
        else
            body, icon_lines = Detail.Lines(detail, base)
        end
        widget.text:SetString(body)
        widget.text:SetColour(1, 1, 1, 1)
        widget.text:Show()

        if widget.ttk_title == nil then
            widget.ttk_title = widget:AddChild(Text(G.UIFONT, 30))
            widget.ttk_title:SetClickable(false)
        end
        local width, height = widget.text:GetRegionSize()
        local position = widget.text:GetPosition()
        widget.ttk_title:SetString(name)
        widget.ttk_title:SetColour(G.unpack(detail.kind == "stone"
            and detail.colour or Detail.Colour(detail.level)))
        widget.ttk_title:SetPosition(position.x, position.y + height / 2 - 15, 1)
        widget.ttk_title:Show()

        widget.ttk_icons = widget.ttk_icons or {}
        local line_count = select(2, body:gsub("\n", "")) + 1
        local line_height = height / math.max(1, line_count)
        for index, icon_info in ipairs(icon_lines) do
            local icon = widget.ttk_icons[index]
            if icon == nil then
                icon = widget:AddChild(Image())
                icon:SetClickable(false)
                widget.ttk_icons[index] = icon
            end
            icon:SetTexture(icon_info.atlas, icon_info.image)
            icon:SetSize(22, 22)
            icon:SetPosition(position.x - width / 2 + 13,
                position.y + height / 2 - (icon_info.index - .5) * line_height, 2)
            icon:Show()
        end
        for index = #icon_lines + 1, #widget.ttk_icons do widget.ttk_icons[index]:Hide() end
        local pointer = G.TheInput:GetScreenPosition()
        widget:UpdatePosition(pointer.x, pointer.y)
        return result
    end
end)

-- SetNew owns the real Tu Tien tooltip rows AND its frame measurements.
-- Its module is only available after all modmain files have loaded.
local xd_hover_hook_installed = false
AddSimPostInit(function()
    if xd_hover_hook_installed then return end
    local ok, err = G.pcall(function()
        local class = G.require("widgets/xd_showhoverui")
        require("ttk_xd_hover").Install(class, G, Detail, Image, require("ttk_player_detail"), Text)
    end)
    if ok then
        xd_hover_hook_installed = true
        print("[TienIchTuTien] xd_showhoverui SetNew integration ready")
    elseif tostring(err):find("module 'widgets/xd_showhoverui' not found", 1, true) then
        print("[TienIchTuTien] Tu Tien hover widget unavailable; using standard tooltip")
    else
        print("[TienIchTuTien] Tu Tien hover hook failed:", err)
    end
end)

local solo_enabled = G.KnownModIndex ~= nil
    and G.KnownModIndex:IsModEnabled("workshop-3780347550")
if solo_enabled then
AddClassPostConstruct("widgets/hh_hoverer", function(hover)
    local old_set_name = hover.SetTargetName
    hover.SetTargetName = function(widget, name, ...)
        local item, detail = EquipmentData()
        if detail ~= nil then name = Detail.Name(item, detail) end
        return old_set_name(widget, name, ...)
    end

    local old_update = hover.UpdateHoverer
    hover.UpdateHoverer = function(widget, ...)
        local owner = widget.owner
        local rows = owner ~= nil and owner.hh_hoverer_list or nil
        local item, detail = EquipmentData()
        if type(rows) == "table" then
            local copy = {}
            for key, value in pairs(rows) do
                if type(value) ~= "table" or value._ttk_detail ~= true then
                    copy[key] = value
                end
            end
            if detail ~= nil then
                local function Add(index, label, value, child, colour)
                    copy["hh_99_special_" .. index] = {
                        bool = true, name = label, str = value or "", format = "%s",
                        str_color = colour or {1, 1, 1, 1}, child_ui = child,
                        _ttk_detail = true,
                    }
                end
                Add(990, "THUỘC TÍNH", #detail.affixes .. "/" .. (detail.max_affixes or Detail.MAX_AFFIXES))
                for index, affix in ipairs(detail.affixes) do
                    Add(990 + index, "", "", {{
                        xml = affix.atlas, tex = affix.image,
                        desc = affix.name .. " · " .. affix.value .. "\n" .. (affix.description or ""),
                    }})
                end
                local milestones = Detail.StrengthenRows(detail)
                if #milestones > 0 then
                    Add(996, "CƯỜNG HÓA", "", nil, Detail.HEADER_COLOUR)
                    for index, row in ipairs(milestones) do
                        Add("996_" .. index, row.label, row.text, nil, row.colour)
                    end
                end
                for index, affix in ipairs(detail.other_affixes) do
                    Add(999 + index, "Dòng trang bị:", affix)
                end
            end
            owner.hh_hoverer_list = copy
        end
        local result = old_update(widget, ...)
        local row = widget.hh_main ~= nil and widget.hh_main.hh_body_hh_01_name or nil
        local title = row ~= nil and row.hh_str or nil
        if detail ~= nil and title ~= nil then
            title:SetColour(G.unpack(Detail.Colour(detail.level)))
        end
        return result
    end
end)
end
