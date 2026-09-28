local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local AffixDefs = require("tbc_affix/defs")

local SKIN = "images/ttk_forge/controls.xml"
local FONT = BODYTEXTFONT
local BLUE = { .54, .84, 1, 1 }
local TAB_ORDER = { "clean", "inherit", "reroll", "equipment" }
local SLOT_LAYOUT = {
    clean = { [1] = { -190, 16 } },
    inherit = {
        [2] = { -150, 40 }, [3] = { 150, 40 },
        [4] = { -150, -60 }, [5] = { 150, -60 },
    },
    reroll = { [2] = { 0, 54 }, [4] = { 0, -60 } },
}

local function Label(parent, value, x, y, size, colour)
    local label = parent:AddChild(Text(FONT, size or 19, value,
        colour or { .91, .94, 1, 1 }))
    label:SetPosition(x, y)
    label:SetClickable(false)
    return label
end

local function Button(parent, name, art, x, y, on_click)
    local atlas = art ~= nil and "images/ttk_forge/suit_buttons/" .. art .. ".xml" or SKIN
    local texture = art ~= nil and art .. ".tex" or "primary.tex"
    local button = parent:AddChild(ImageButton(atlas, texture))
    button.ignore_standard_scaling = true
    button:SetPosition(x, y)
    button:SetNormalScale(1, 1)
    button:SetFocusScale(1.03, 1.03)
    button:ForceImageSize(170, 43)
    if art == nil then
        button:SetFont(FONT)
        button:SetTextSize(18)
        button:SetText(name)
    end
    button:SetOnClick(on_click)
    return button
end

local UI = Class(Widget, function(self, owner, container, container_widget, rpc_namespace)
    Widget._ctor(self, "Hợp Thành Đài")
    self.owner, self.container = owner, container
    self.container_widget = container_widget
    self.rpc_namespace = rpc_namespace
    self.frame = self:AddChild(Image("images/ttk_forge/frame.xml", "frame.tex"))
    self.frame:SetSize(720, 480)
    Label(self, "HỢP THÀNH ĐÀI", 0, 184, 27)

    self.tabs = {}
    for index, data in ipairs({
        { "clean", "TẨY LUYỆN" },
        { "inherit", "KẾ THỪA" },
        { "reroll", "NGẪU LUYỆN ĐÁ" },
        { "equipment", "TRANG BỊ" },
    }) do
        local tab = self:AddChild(ImageButton(SKIN, "tab_idle.tex", nil, nil, nil,
            "tab_active.tex"))
        tab.ignore_standard_scaling = true
        tab:SetPosition(-252 + (index - 1) * 168, 130)
        tab:SetNormalScale(1, 1)
        tab:SetFocusScale(1.03, 1.03)
        tab:ForceImageSize(160, 32)
        tab:SetFont(FONT)
        tab:SetTextSize(16)
        tab:SetText(data[2])
        tab:SetTextColour(1, 1, 1, 1)
        tab:SetTextFocusColour(1, 1, 1, 1)
        tab:SetTextSelectedColour(1, 1, 1, 1)
        tab:SetOnClick(function() self:SwitchTab(data[1]) end)
        self.tabs[data[1]] = tab
    end

    self.pages = {
        clean = self:AddChild(Widget("Tẩy luyện")),
        inherit = self:AddChild(Widget("Kế thừa")),
        reroll = self:AddChild(Widget("Ngẫu luyện đá")),
        equipment = self:AddChild(Widget("Trang bị")),
    }

    Label(self.pages.clean, "Trang bị cần tẩy", -190, 66, 19, BLUE)
    for index = 1, AffixDefs.MAX_SLOTS do
        Button(self.pages.clean, "Dòng " .. index,
            "line" .. index, 110, 80 - (index - 1) * 50,
            function() self:ConfirmClean(index) end)
    end
    Label(self.pages.clean,
        "Đặt trang bị vào ô; chọn Dòng 1–5 rồi xác nhận tẩy bằng Đá Tẩy.",
        0, -170, 16)

    Label(self.pages.inherit, "Trang bị nguồn", -150, 88, 19, BLUE)
    Label(self.pages.inherit, "Trang bị nhận", 150, 88, 19, BLUE)
    Label(self.pages.inherit, "Linh Thạch ×20", -150, -111, 19, BLUE)
    Label(self.pages.inherit, "Nhiên liệu ác mộng ×20", 150, -111, 19, BLUE)
    Label(self.pages.inherit, "→", 0, 40, 38)
    Button(self.pages.inherit, "Kế thừa", "inherit", 0, -150,
        function() self:Submit("inherit") end)
    Label(self.pages.inherit,
        "Trên: nguồn → nhận. Dưới: 20 Linh Thạch + 20 Nhiên liệu ác mộng.",
        0, -190, 16)

    Label(self.pages.reroll, "Đá Thuộc Tính", 0, 100, 19, BLUE)
    Label(self.pages.reroll, "Linh Thạch ×5", 0, -111, 19, BLUE)
    Button(self.pages.reroll, "Ngẫu luyện đá", "reroll", 0, -150,
        function() self:Submit("stone_reroll") end)
    Label(self.pages.reroll,
        "Đá Thuộc Tính ở ô trên, 5 Linh Thạch ở ô dưới.", 0, -190, 16)

    self.equipment_ui = self.pages.equipment:AddChild(
        require("widgets/tbc_equipment_ui")(owner, container, container_widget, true, rpc_namespace))
    self.rpc_notice = Label(self, "", 0, -218, 16)

    self.close = self:AddChild(ImageButton("images/ttk_forge/close_icon.xml", "close_icon.tex"))
    self.close.ignore_standard_scaling = true
    self.close:SetPosition(309, 185)
    self.close:SetNormalScale(1, 1)
    self.close:SetFocusScale(1.05, 1.05)
    self.close:ForceImageSize(40, 40)
    self.close:SetOnClick(function()
        if container.replica ~= nil and container.replica.container ~= nil then
            container.replica.container:Close()
        end
    end)
    self:SwitchTab("clean")
end)

function UI:SwitchTab(name)
    if self.pages[name] == nil then return end
    self.active_tab = name
    for _, tab_name in ipairs(TAB_ORDER) do
        if tab_name == name then
            self.tabs[tab_name]:Select()
            self.pages[tab_name]:Show()
        else
            self.tabs[tab_name]:Unselect()
            self.pages[tab_name]:Hide()
        end
    end
    local slots = self.container_widget ~= nil and self.container_widget.inv or nil
    if slots ~= nil then
        for index = 1, 5 do
            local slot = slots[index]
            if slot ~= nil then
                local positions = SLOT_LAYOUT[name]
                local position = positions ~= nil and positions[index] or nil
                if position ~= nil then
                    slot:SetPosition(position[1], position[2], 0)
                    slot.side_align_tip = -position[1]
                    slot:Show()
                else
                    slot:Hide()
                end
            end
        end
        if name == "equipment" then
            self.equipment_ui:SwitchTab(self.equipment_ui.active_tab or "add")
        end
    end
end

function UI:Submit(operation, arg)
    local namespace = MOD_RPC ~= nil and MOD_RPC[self.rpc_namespace] or nil
    local rpc = namespace ~= nil and namespace.tbc_equipment_use or nil
    if rpc == nil then
        if self.rpc_notice ~= nil then
            self.rpc_notice:SetString("Không tìm thấy lệnh trang bị; hãy tải lại world")
        end
        return
    end
    if self.rpc_notice ~= nil then self.rpc_notice:SetString("") end
    if arg ~= nil then
        SendModRPCToServer(rpc, self.container, operation, arg)
    else
        SendModRPCToServer(rpc, self.container, operation)
    end
end

function UI:ConfirmClean(index)
    local replica = self.container.replica ~= nil and self.container.replica.container or nil
    local item = replica ~= nil and replica:GetItemInSlot(1) or nil
    if item == nil then
        self:Submit("affix_clean", index)
        return
    end
    local name = item.GetDisplayName ~= nil and item:GetDisplayName() or "trang bị"
    local popup
    popup = require("screens/popupdialog")(
        "XÁC NHẬN TẨY DÒNG",
        "Tẩy dòng " .. index .. " của " .. name
            .. "?\nNếu thành công sẽ tiêu hao 1 Đá Tẩy Thuộc Tính.",
        {
            { text = "Tẩy dòng", cb = function()
                TheFrontEnd:PopScreen(popup)
                if replica:GetItemInSlot(1) == item then
                    self:Submit("affix_clean", index)
                end
            end },
            { text = "Hủy", cb = function() TheFrontEnd:PopScreen(popup) end },
        }, nil, nil, "dark")
    TheFrontEnd:PushScreen(popup)
end

function UI:Refresh()
    if self.equipment_ui ~= nil then self.equipment_ui:Refresh() end
end

return UI
