local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local Display = require("tbc_display")

local FONT = BODYTEXTFONT
local SKIN = "images/ttk_forge/controls.xml"
local CLOSE_SKIN = "images/ttk_forge/close_icon.xml"
local WHITE = { .93, .96, 1, 1 }
local BLUE = { .54, .84, 1, 1 }
local MUTED = { .68, .74, .82, 1 }

local function Label(parent, value, x, y, size, colour)
    local label = parent:AddChild(Text(FONT, size, value, colour or WHITE))
    label:SetPosition(x, y)
    label:SetClickable(false)
    return label
end

local function Button(parent, controller, label, x, y, operation, width, size)
    local button = parent:AddChild(ImageButton(SKIN, "primary.tex"))
    button.ignore_standard_scaling = true
    button:SetPosition(x, y)
    button:SetNormalScale(1, 1)
    button:SetFocusScale(1.02, 1.02)
    -- Scale setters write directly to image:SetScale, so the forced atlas
    -- region size must be applied last or the button expands on first draw.
    button:ForceImageSize(width or 175, 48)
    button:SetFont(FONT)
    button:SetDisabledFont(FONT)
    button:SetTextSize(size or 21)
    button:SetText(label)
    button:SetTextColour(unpack(WHITE))
    button:SetTextFocusColour(1, 1, 1, 1)
    button.text:SetPosition(0, 3)
    button:SetOnClick(function() controller:Submit(operation) end)
    return button
end

local ForgeUI = Class(Widget, function(self, owner, container, _, rpc_namespace)
    Widget._ctor(self, "Lò Rèn Trang Bị")
    self.owner, self.container = owner, container
    self.rpc_namespace = rpc_namespace
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.frame = self.root:AddChild(Image("images/ttk_forge/frame.xml", "frame.tex"))
    self.frame:SetSize(700, 467)
    Label(self.root, "LÒ RÈN TRANG BỊ", 0, 181, 29)
    self.place_hint = Label(self.root, "Đặt vũ khí hoặc giáp vào ô", -198, 113, 19, BLUE)
    self.equipment_slot = self.root:AddChild(Image(SKIN, "slot.tex"))
    self.equipment_slot:SetPosition(-198, 50)
    self.equipment_slot:SetSize(82, 82)
    self.equipment_slot:SetClickable(false)
    self.name = Label(self.root, "Chưa có trang bị", -198, -20, 19)
    local magic_slot = self.root:AddChild(Image(SKIN, "slot.tex"))
    magic_slot:SetPosition(-250, -95)
    magic_slot:SetSize(66, 66)
    magic_slot:SetClickable(false)
    local protect_slot = self.root:AddChild(Image(SKIN, "slot.tex"))
    protect_slot:SetPosition(-145, -95)
    protect_slot:SetSize(66, 66)
    protect_slot:SetClickable(false)
    self.stone_slot = self.root:AddChild(Image(SKIN, "slot.tex"))
    self.stone_slot:SetPosition(-40, -95)
    self.stone_slot:SetSize(66, 66)
    self.stone_slot:SetClickable(false)
    self.magic_label = Label(self.root, "Bùa Giữ Cấp", -250, -152, 19, BLUE)
    self.protect_label = Label(self.root, "Bùa Bảo Vệ", -145, -152, 19, BLUE)
    self.stone_label = Label(self.root, "Huyền Tinh\nCực Phẩm", -40, -148, 15, BLUE)

    self.level_label = Label(self.root, "Cấp", -2, 68, 19)
    self.level_current = Label(self.root, "—", 124, 68, 22)
    self.level_next = Label(self.root, "—", 256, 68, 22)
    self.stat_label = Label(self.root, "Chỉ số", -2, 30, 19)
    self.stat_current = Label(self.root, "—", 124, 30, 19)
    self.stat_next = Label(self.root, "—", 256, 30, 19)
    Label(self.root, "CHỈ SỐ", -2, 111, 19, BLUE)
    Label(self.root, "HIỆN TẠI", 124, 111, 19, BLUE)
    Label(self.root, "SAU CƯỜNG HÓA", 256, 111, 19, BLUE)
    self.material = Label(self.root, "Huyền Tinh Cực Phẩm: —", 126, -12, 19, BLUE)
    self.luck = Label(self.root, "Phúc Lạc Dược: không dùng", 126, -43, 19, BLUE)
    self.chance = Label(self.root, "Tỷ lệ thành công: —", 126, -74, 19)
    self.risk = Label(self.root, "", 126, -102, 15, MUTED)
    self.strengthen = Button(self.root, self, "CƯỜNG HÓA", 126, -143, "strengthen", 220, 16)
    self.footer = Label(self.root,
        "Đá và bùa dùng từ các ô; lấy trang bị ra khi xong.",
        0, -185, 20, MUTED)

    self.close = self.root:AddChild(ImageButton(CLOSE_SKIN, "close_icon.tex"))
    self.close.ignore_standard_scaling = true
    self.close:SetPosition(302, 183)
    self.close:SetNormalScale(1, 1)
    self.close:SetFocusScale(1.05, 1.05)
    self.close:ForceImageSize(42, 42)
    self.close:SetOnClick(function()
        if container.replica ~= nil and container.replica.container ~= nil then
            container.replica.container:Close()
        end
    end)
end)

function ForgeUI:Refresh()
    local replica = self.container.replica ~= nil and self.container.replica.container or nil
    local item = replica ~= nil and replica:GetItemInSlot(1) or nil
    self.place_hint:SetString(item == nil and "Đặt vũ khí hoặc giáp vào ô" or "")
    local state = self.container._tbc_forge_state ~= nil and self.container._tbc_forge_state:value() or ""
    local level, kind, current, next_value, chance, cost, luck =
        state:match("^(%d+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(%d+)|([^|]+)$")
    local display_name = item ~= nil and item:GetDisplayName() or "Chưa có trang bị"
    local current_level = tonumber(level)
    local name = display_name:match("^[^\n]*")
    if current_level ~= nil and current_level > 0 then
        name = name .. " +" .. current_level
    end
    self.name:SetTruncatedString(name, 218, nil, true)
    self.name:SetColour(unpack(Display.NameColour(current_level or 0)))
    local next_level = tonumber(level) ~= nil and tonumber(level) + 1 or nil
    self.can_strengthen = next_level ~= nil and next_level <= 16 and tonumber(cost) ~= nil
        and tonumber(cost) > 0
    if level == nil then
        self.level_current:SetString("—")
        self.level_next:SetString("—")
    elseif self.can_strengthen then
        self.level_current:SetString("+" .. level)
        self.level_next:SetString("+" .. next_level)
    else
        self.level_current:SetString("+" .. level)
        self.level_next:SetString("tối đa")
    end
    local stat_name = kind == "weapon" and "Sát thương" or kind == "armor" and "Giảm sát thương"
        or kind == "weapon_bonus" and "Thưởng cường hóa" or "Chỉ số"
    local suffix = kind == "armor" and "%" or ""
    self.stat_label:SetString(stat_name)
    self.stat_current:SetString(tonumber(current) ~= nil
        and (string.format("%.1f", tonumber(current)) .. suffix) or "—")
    self.stat_next:SetString(tonumber(next_value) ~= nil
        and (string.format("%.1f", tonumber(next_value)) .. suffix) or "—")
    self.material:SetString(self.can_strengthen and ("Huyền Tinh Cực Phẩm cần: " .. cost)
        or "Huyền Tinh Cực Phẩm cần: —")
    local bonus = tonumber(luck) or 0
    local luck_name = bonus >= 24.5 and "III" or bonus >= 14.5 and "II"
        or bonus >= 4.5 and "I" or nil
    self.luck:SetString(luck_name ~= nil
        and ("Phúc Lạc Dược " .. luck_name .. " (chỉ số cộng: +" .. string.format("%.0f", bonus) .. "%)")
        or "Phúc Lạc Dược: không dùng")
    self.chance:SetString(self.can_strengthen and ("Tỷ lệ thành công: "
        .. string.format("%.1f%%", tonumber(chance) or 0)) or "Tỷ lệ thành công: —")
    self.risk:SetString(current_level == nil and ""
        or current_level >= 16 and "Đã đạt cấp cường hóa tối đa"
        or current_level >= 9 and "Thất bại: có thể mất trang bị"
        or current_level >= 5 and "Thất bại: có thể mất 1 cấp"
        or "Thất bại: không giảm cấp")
    self.strengthen:SetText(current_level ~= nil and current_level >= 16 and "ĐÃ TỐI ĐA" or "CƯỜNG HÓA")
end

function ForgeUI:Submit(operation)
    if operation ~= "strengthen" or not self.can_strengthen then return end
    local namespace = MOD_RPC ~= nil and MOD_RPC[self.rpc_namespace] or nil
    local rpc = namespace ~= nil and namespace.forge_use or nil
    if rpc ~= nil then
        SendModRPCToServer(rpc, self.container, operation)
    elseif self.risk ~= nil then
        self.risk:SetString("Không tìm thấy lệnh cường hóa; hãy tải lại world")
    end
end

return ForgeUI
