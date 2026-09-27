local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local Display = require("tbc_display")
local DetailHooks = require("tbc_detail_hooks")

local SKIN = "images/ttk_forge/controls.xml"
local FONT = BODYTEXTFONT

local function Label(parent, value, x, y, size)
    local text = parent:AddChild(Text(FONT, size or 20, value, { .9, .94, 1, 1 }))
    text:SetPosition(x, y)
    text:SetClickable(false)
    return text
end

local function Button(parent, title, x, y, width, action, art)
    local atlas = art ~= nil and "images/ttk_forge/equipment_buttons/" .. art .. ".xml" or SKIN
    local texture = art ~= nil and art .. ".tex" or "primary.tex"
    local button = parent:AddChild(ImageButton(atlas, texture))
    button.ignore_standard_scaling = true
    button:SetPosition(x, y)
    button:SetNormalScale(1, 1)
    button:SetFocusScale(1.02, 1.02)
    button:ForceImageSize(width or 144, art ~= nil and 45 or 40)
    if art == nil then
        button:SetFont(FONT)
        button:SetTextSize(17)
        button:SetText(title)
    end
    button:SetOnClick(action)
    return button
end

local UI = Class(Widget, function(self, owner, container, container_widget, embedded)
    Widget._ctor(self, "Thuộc tính trang bị")
    self.owner, self.container = owner, container
    self.container_widget = container_widget
    self.embedded = embedded == true
    if not self.embedded then
        self.frame = self:AddChild(Image("images/ttk_forge/frame.xml", "frame.tex"))
        self.frame:SetSize(660, 500)
        Label(self, "THUỘC TÍNH TRANG BỊ", 0, 205, 26)
    end
    self.tabs = {}
    for index, data in ipairs({{"add", "THÊM THUỘC TÍNH"}, {"edit", "CHỈNH THUỘC TÍNH"}}) do
        local tab = self:AddChild(ImageButton(SKIN, "tab_idle.tex", nil, nil, nil,
            "tab_active.tex"))
        tab.ignore_standard_scaling = true
        tab:SetPosition(-105 + (index - 1) * 210, self.embedded and 88 or 155)
        tab:SetNormalScale(1, 1)
        tab:SetFocusScale(1.03, 1.03)
        tab:ForceImageSize(200, 32)
        tab:SetFont(FONT)
        tab:SetTextSize(17)
        tab:SetText(data[2])
        tab:SetTextColour(1, 1, 1, 1)
        tab:SetTextSelectedColour(1, 1, 1, 1)
        tab:SetOnClick(function() self:SwitchTab(data[1]) end)
        self.tabs[data[1]] = tab
    end
    self.pages = {
        add = self:AddChild(Widget("Thêm thuộc tính")),
        edit = self:AddChild(Widget("Chỉnh thuộc tính")),
    }
    local slot_label_y = self.embedded and 48 or 105
    self.slot_y = self.embedded and 8 or 65
    Label(self, "Ô trang bị", -140, slot_label_y, 18)
    Label(self.pages.add, "Đá / Giấy thuộc tính", 100, slot_label_y, 18)
    Label(self.pages.edit, "Đá tẩy", 100, slot_label_y, 18)
    self.affix_info = Label(self, "Đặt trang bị vào ô", 0,
        self.embedded and -42 or 8, 17)
    self.affix_detail = Label(self, "", 0,
        self.embedded and -95 or -65, 16)

    Button(self.pages.add, "Thêm thuộc tính", 0, -165, 180,
        function() self:Submit("affix_add") end, "add")
    Button(self.pages.edit, "Tẩy ngẫu nhiên", -100, -165, 180,
        function() self:Submit("affix_remove") end)
    Button(self.pages.edit, "Đổi giá trị", 100, -165, 180,
        function() self:Submit("affix_reroll") end)
    self.notice = Label(self, "Đặt trang bị và đá/giấy vào hai ô.", 0,
        -210, 16)

    if not self.embedded then
        self.close = self:AddChild(ImageButton("images/ttk_forge/close_icon.xml", "close_icon.tex"))
        self.close.ignore_standard_scaling = true
        self.close:SetPosition(285, 210)
        self.close:SetNormalScale(1, 1)
        self.close:SetFocusScale(1.05, 1.05)
        self.close:ForceImageSize(40, 40)
        self.close:SetOnClick(function()
            if container.replica ~= nil and container.replica.container ~= nil then
                container.replica.container:Close()
            end
        end)
    end
    self:SwitchTab("add")
    self:StartUpdating()
end)

function UI:SwitchTab(name)
    if self.pages[name] == nil then return end
    self.active_tab = name
    for _, key in ipairs({"add", "edit"}) do
        if key == name then
            self.tabs[key]:Select()
            self.pages[key]:Show()
        else
            self.tabs[key]:Unselect()
            self.pages[key]:Hide()
        end
    end
    local slots = self.container_widget ~= nil and self.container_widget.inv or nil
    if slots ~= nil then
        for index = 1, 3 do
            local slot = slots[index]
            if slot ~= nil then
                if index == 1 or index == 2 and name == "add"
                    or index == 3 and name == "edit" then
                    slot:SetPosition(index == 1 and -140 or 100, self.slot_y, 0)
                    slot:Show()
                else
                    slot:Hide()
                end
            end
        end
    end
    self:Refresh()
end

function UI:Submit(operation, arg)
    local rpc = MOD_RPC.ThanKhiTuTien ~= nil and MOD_RPC.ThanKhiTuTien.tbc_equipment_use or nil
    if rpc ~= nil then SendModRPCToServer(rpc, self.container, operation, arg) end
end

function UI:Refresh()
    local replica = self.container.replica ~= nil and self.container.replica.container or nil
    local affix_item = replica ~= nil and replica:GetItemInSlot(1) or nil
    local add_stone = replica ~= nil and replica:GetItemInSlot(2) or nil
    local remove_stone = replica ~= nil and replica:GetItemInSlot(3) or nil
    local detail_state = affix_item ~= nil and affix_item._tbc_detail ~= nil
        and affix_item._tbc_detail:value() or ""
    local equipment_state = affix_item ~= nil and affix_item._tbc_equip_state ~= nil
        and affix_item._tbc_equip_state:value() or ""
    self.last_item = affix_item
    self.last_detail_state = detail_state
    self.last_equipment_state = equipment_state
    self.affix_info:SetString(affix_item ~= nil and affix_item:GetDisplayName()
        or "Đặt trang bị vào ô")
    local details = Display.Format(detail_state)
    local solo_details = DetailHooks.FormatEquipmentState(equipment_state)
    if solo_details ~= "" then
        details = details ~= "" and details .. "\n" .. solo_details or solo_details
    end
    self.affix_detail:SetString(affix_item == nil and ""
        or details ~= "" and details or "Chưa có thuộc tính")
    -- Five gem rows must fit above the action buttons in the embedded panel.
    local width, height = self.affix_detail:GetRegionSize()
    self.affix_detail:SetScale(math.min(1, 500 / math.max(width, 1),
        (self.embedded and 86 or 105) / math.max(height, 1)))
    if self.active_tab == "add" then
        self.notice:SetString(add_stone == nil and "Đặt đá/giấy vào ô bên phải."
            or "Vật liệu chỉ bị trừ khi thêm thành công.")
    else
        self.notice:SetString(remove_stone == nil
            and "Tẩy cần Đá Tẩy; đổi giá trị dùng Đá Đổi trong túi Solo."
            or "Vật liệu chỉ bị trừ khi thao tác thành công.")
    end
end

function UI:OnUpdate()
    local replica = self.container.replica ~= nil and self.container.replica.container or nil
    local item = replica ~= nil and replica:GetItemInSlot(1) or nil
    local detail = item ~= nil and item._tbc_detail ~= nil
        and item._tbc_detail:value() or ""
    local equipment = item ~= nil and item._tbc_equip_state ~= nil
        and item._tbc_equip_state:value() or ""
    if item ~= self.last_item or detail ~= self.last_detail_state
        or equipment ~= self.last_equipment_state then self:Refresh() end
end

return UI
