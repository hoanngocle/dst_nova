local Display = require("tbc_display")
local EquipmentDefs = require("tbc_equipment/solo_defs")
local Stone = require("tbc_affix/stone")

local M = {}
local SOLO_AFFIX_KEY = "hh_99_special_98"

function M.InstallSoloBuffRows(add_component_post_init)
    add_component_post_init("hh_equip", function(component)
        if component._tbc_buff_rows_wrapped or type(component.GetBuffDebugList) ~= "function" then
            return
        end
        component._tbc_buff_rows_wrapped = true
        local get_rows = component.GetBuffDebugList
        component.GetBuffDebugList = function(self, ...)
            local rows = get_rows(self, ...)
            if type(rows) ~= "table" then return rows end
            for _, row in ipairs(rows) do
                if type(row) == "table" then
                    if type(row.desc) == "string" and row.desc:sub(1, 1) ~= " " then
                        row.desc = " " .. row.desc
                    end
                    local colour = Stone.ColourForCode(row.name)
                    if colour ~= nil then row.desc_color = colour end
                end
            end
            return rows
        end
    end)
end

function M.FormatEquipmentState(raw)
    if type(raw) ~= "string" or raw == "" then return "" end
    local affixes = raw
    local _, _, old_affixes = raw:match("^(%d+);([^;]*);(.*)$")
    if old_affixes ~= nil then affixes = old_affixes end
    local lines = {}
    for entry in affixes:gmatch("[^|]+") do
        local id, value = entry:match("^([^:]+):(.+)$")
        if id ~= nil then
            local row = EquipmentDefs.Affixes[id]
            lines[#lines + 1] = "Thuộc tính: " .. (row ~= nil and row.name or id)
                .. (tonumber(value) ~= nil and " +" .. value or "")
        end
    end
    return table.concat(lines, "\n")
end

function M.SoloHoverRows(rows, item)
    if type(rows) ~= "table" then return rows end
    local state = item ~= nil and item._tbc_detail ~= nil
        and item._tbc_detail:value() or ""
    local equipment = item ~= nil and item._tbc_equip_state ~= nil
        and item._tbc_equip_state:value() or ""
    local detail = Display.Format(state, nil, item)
    local extra = M.FormatEquipmentState(equipment)
    if extra ~= "" then detail = detail ~= "" and detail .. "\n" .. extra or extra end
    local current = rows[SOLO_AFFIX_KEY]
    if detail == "" and (current == nil or current._tbc_attribute ~= true) then
        return rows
    end
    if detail ~= "" and current ~= nil and current._tbc_attribute == true
        and current.str == detail then return rows end
    local copy = {}
    for key, value in pairs(rows) do copy[key] = value end
    if detail == "" then
        copy[SOLO_AFFIX_KEY] = nil
    else
        copy[SOLO_AFFIX_KEY] = {
            bool = true, name = "Thuộc tính:", str = detail,
            format = "%s", str_color = {1, 1, 1, 1},
            _tbc_attribute = true,
        }
    end
    return copy
end

local function HoveredItem()
    local input = rawget(_G, "TheInput")
    if input == nil then return nil end
    local entity = input:GetHUDEntityUnderMouse()
    if entity ~= nil then
        local widget = entity.widget
        local item = widget ~= nil and widget.parent ~= nil and widget.parent.item or nil
        if item ~= nil then return item, true, input end
    end
    return input:GetWorldEntityUnderMouse(), false, input
end

local function HoverLevel()
    local item = HoveredItem()
    if item == nil or item._tbc_detail == nil or item.IsValid == nil
        or not item:IsValid() then return 0 end
    return Display.Level(item._tbc_detail:value())
end

function M.Attach(inst, net_string_fn)
    if inst.replica == nil
        or inst.replica.inventoryitem == nil or inst.replica.equippable == nil then return end
    if inst._tbc_detail == nil then
        inst._tbc_detail = net_string_fn(inst.GUID, "tbc_upgrade.detail", "tbc_upgrade_dirty")
    end
    if inst._tbc_equip_state == nil then
        inst._tbc_equip_state = net_string_fn(inst.GUID, "tbc_equipment.state", "tbc_equipment_dirty")
    end
    if inst._tbc_strengthen_stat == nil then
        inst._tbc_strengthen_stat = net_string_fn(inst.GUID,
            "tbc_upgrade.strengthen_stat", "tbc_upgrade_dirty")
    end
end

function M.AttachSpecial(inst, names)
    if inst._tbc_special_attached or inst.components == nil
        or inst.components.tbc_upgrade == nil then return end
    local slots = {}
    for index = 90, 99 do
        local key = "GetHHSpDesc" .. string.format("%02d", index)
        if inst[key] == nil then slots[#slots + 1] = key end
        if #slots == 2 then break end
    end
    if #slots < 2 then return end
    for index, key in ipairs(slots) do
        inst[key] = function(item)
            local upgrade = item.components ~= nil and item.components.tbc_upgrade or nil
            return Display.Sections(upgrade, names)[index]
        end
    end
    inst._tbc_special_attached = true
end

function M.Install(add_class_post_construct, names, solo_hover_enabled, utility_detail_enabled)
    add_class_post_construct("widgets/itemtile", function(tile)
        if tile.item ~= nil and tile.item.prefab == "hh_effect_stone"
            and tile.image ~= nil then
            tile.image:SetScale(.5, .5)
        end
        local get_description_string = tile.GetDescriptionString
        tile.GetDescriptionString = function(widget, ...)
            local description = get_description_string(widget, ...)
            local item = widget.item
            if item == nil or not item:IsValid() then
                return description
            end
            if item.prefab == "hh_effect_stone" and not utility_detail_enabled then
                local effect, stat = Stone.Detail(item)
                if effect ~= nil then
                    local title, actions = description:match("^([^\n]*)(.*)$")
                    description = title .. "\nMô tả: " .. effect .. "\n" .. stat .. actions
                end
            end
            if utility_detail_enabled then return description end
            if item._tbc_detail ~= nil then
                local state = item._tbc_detail:value()
                if solo_hover_enabled == false then
                    for _, section in ipairs(Display.SectionsFromState(state, item, names)) do
                        description = description .. "\n" .. section.title .. ": " .. section.desc
                    end
                else
                    local detail = Display.Format(state, names, item)
                    if detail ~= "" then description = description .. "\n" .. detail end
                end
            end
            local equipment = item._tbc_equip_state ~= nil
                and M.FormatEquipmentState(item._tbc_equip_state:value()) or ""
            if equipment ~= "" then description = description .. "\n" .. equipment end
            return description
        end
    end)

    if solo_hover_enabled == false then
        add_class_post_construct("widgets/hoverer", function(hover)
            local on_update = hover.OnUpdate
            hover.OnUpdate = function(widget, ...)
                local result = on_update(widget, ...)
                if widget.isFE or widget.shown == false or widget.text == nil
                    or type(widget.str) ~= "string" or widget.str == "" then
                    return result
                end

                local item, is_hud_item, input = HoveredItem()
                if item == nil or item.IsValid == nil or not item:IsValid() then
                    return result
                end
                if item.prefab == "hh_effect_stone" and not utility_detail_enabled then
                    local effect, stat = Stone.Detail(item)
                    if effect ~= nil then
                        local description = widget.str
                        if not is_hud_item then
                            description = description .. "\nMô tả: " .. effect .. "\n" .. stat
                        end
                        widget.text:SetString(description)
                        widget.text:SetColour(unpack(Stone.Colour(item)))
                        local position = input:GetScreenPosition()
                        widget:UpdatePosition(position.x, position.y)
                    end
                    return result
                end
                if utility_detail_enabled then return result end
                local state = item._tbc_detail ~= nil and item._tbc_detail:value() or ""
                local level = Display.Level(state)
                local sections = not is_hud_item
                    and Display.SectionsFromState(state, item, names) or {}
                local equipment = item._tbc_equip_state ~= nil
                    and M.FormatEquipmentState(item._tbc_equip_state:value()) or ""
                if level <= 0 and (is_hud_item or (#sections == 0 and equipment == "")) then
                    return result
                end

                local description = level > 0
                    and Display.HoverName(widget.str, level) or widget.str
                if not is_hud_item then
                    for _, section in ipairs(sections) do
                        description = description .. "\n" .. section.title .. ": " .. section.desc
                    end
                    if equipment ~= "" then description = description .. "\n" .. equipment end
                end
                widget.text:SetString(description)
                if level > 0 then
                    widget.text:SetColour(unpack(Display.NameColour(level)))
                end
                local position = input:GetScreenPosition()
                widget:UpdatePosition(position.x, position.y)
                return result
            end
        end)
        return
    end

    add_class_post_construct("widgets/hh_hoverer", function(hover)
        if utility_detail_enabled then return end
        local set_target_name = hover.SetTargetName
        hover.SetTargetName = function(widget, name, ...)
            return set_target_name(widget, Display.HoverName(name, HoverLevel()), ...)
        end

        local update_hoverer = hover.UpdateHoverer
        hover.UpdateHoverer = function(widget, ...)
            local stone = HoveredItem()
            if widget.owner ~= nil and type(widget.owner.hh_hoverer_list) == "table" then
                widget.owner.hh_hoverer_list = M.SoloHoverRows(
                    widget.owner.hh_hoverer_list, stone)
            end
            if stone ~= nil and stone.prefab == "hh_effect_stone"
                and widget.owner ~= nil and type(widget.owner.hh_hoverer_list) == "table" then
                local effect, stat = Stone.Detail(stone)
                if effect ~= nil then
                    -- Inventory hover text in Solo is built from this list, not
                    -- from itemtile:GetDescriptionString. Keep the RPC list intact.
                    local source = widget.owner.hh_hoverer_list
                    local rows = {}
                    for key, value in pairs(source) do rows[key] = value end
                    rows.hh_99_special_90 = {
                        bool = true, name = "Mô tả:", str = effect,
                    }
                    rows.hh_99_special_91 = {
                        bool = true, name = "", str = stat,
                    }
                    widget.owner.hh_hoverer_list = rows
                end
            end
            local result = update_hoverer(widget, ...)
            local level = HoverLevel()
            local row = widget.hh_main ~= nil and widget.hh_main.hh_body_hh_01_name or nil
            local text = row ~= nil and row.hh_str or nil
            if stone ~= nil and stone.prefab == "hh_effect_stone" and text ~= nil then
                text:SetColour(unpack(Stone.Colour(stone)))
            elseif level > 0 and text ~= nil then
                text:SetColour(unpack(Display.NameColour(level)))
            end
            return result
        end
    end)
end

return M
