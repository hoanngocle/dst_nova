local Screen = require("widgets/screen")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")
local catalog = require("nyx/appearance")

local SKIN_ATLAS = "images/nyx_skin_ui/controls.xml"
local CLOSE_ATLAS = "images/nyx_skin_ui/close_icon.xml"
local WHITE = { .93, .96, 1, 1 }
local MUTED = { .68, .74, .82, 1 }
local ACTIVE = { 1, 1, 1, 1 }
local INACTIVE = { .78, .80, .87, 1 }
local TAB_X = { -288, -144, 0, 144, 288 }

local NyxSkinScreen = Class(Screen, function(self, on_select)
    Screen._ctor(self, "NyxSkinScreen")
    self.on_select = on_select

    -- A full-screen backing button consumes clicks outside the selector.
    self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetTint(0, 0, 0, .75)
    self.black:SetOnClick(function() end)

    self.root = self:AddChild(Widget("selector"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local panel = self.root:AddChild(Image("images/nyx_skin_ui/frame.xml", "frame.tex"))
    panel:SetSize(860, 574)
    panel:SetClickable(false)

    local title = self.root:AddChild(Text(BODYTEXTFONT, 32, "NGOẠI HÌNH NYX"))
    title:SetPosition(0, 233)
    title:SetColour(unpack(WHITE))
    title:SetClickable(false)

    self.close_button = self.root:AddChild(ImageButton(CLOSE_ATLAS, "close_icon.tex"))
    self.close_button.ignore_standard_scaling = true
    self.close_button:SetPosition(374, 234)
    self.close_button:SetNormalScale(1, 1)
    self.close_button:SetFocusScale(1.05, 1.05)
    self.close_button:ForceImageSize(39, 39)
    self.close_button:SetOnClick(function() self:Close() end)

    self.tabs = {}
    for i, group in ipairs(catalog.groups) do
        local col = (i - 1) % 5
        local row = math.floor((i - 1) / 5)
        local tab = self.root:AddChild(ImageButton(SKIN_ATLAS, "tab_idle.tex", "tab_active.tex"))
        tab.ignore_standard_scaling = true
        tab:SetPosition(TAB_X[col + 1], 169 - row * 39)
        tab:SetNormalScale(1, 1)
        tab:SetFocusScale(1.02, 1.02)
        tab:ForceImageSize(135, 34)
        tab:SetFont(BODYTEXTFONT)
        tab:SetDisabledFont(BODYTEXTFONT)
        tab:SetTextSize(17)
        tab:SetText(group.name)
        tab.text:SetPosition(0, 2)
        tab:SetTextColour(unpack(INACTIVE))
        tab:SetTextFocusColour(unpack(ACTIVE))
        tab:SetOnClick(function() self:ShowGroup(i) end)
        self.tabs[i] = tab
    end

    self.group_title = self.root:AddChild(Text(BODYTEXTFONT, 23, ""))
    self.group_title:SetPosition(0, 85)
    self.group_title:SetColour(unpack(WHITE))
    self.group_title:SetClickable(false)

    local note = self.root:AddChild(Text(BODYTEXTFONT, 16,
        "Chọn hình để đổi ngoại hình. Kỹ năng và chỉ số vẫn là Nyx."))
    note:SetPosition(0, -208)
    note:SetColour(unpack(MUTED))
    note:SetClickable(false)

    self.reset = self.root:AddChild(ImageButton(SKIN_ATLAS, "primary.tex"))
    self.reset.ignore_standard_scaling = true
    self.reset:SetPosition(0, -244)
    self.reset:SetNormalScale(1, 1)
    self.reset:SetFocusScale(1.02, 1.02)
    self.reset:ForceImageSize(180, 42)
    self.reset:SetFont(BODYTEXTFONT)
    self.reset:SetDisabledFont(BODYTEXTFONT)
    self.reset:SetTextSize(18)
    self.reset:SetText("VỀ SKIN GỐC")
    self.reset:SetTextColour(unpack(WHITE))
    self.reset:SetTextFocusColour(unpack(ACTIVE))
    self.reset.text:SetPosition(0, 2)
    self.reset:SetOnClick(function() self:Select("") end)

    self.default_focus = self.tabs[5]
    self:ShowGroup(5)
end)

function NyxSkinScreen:ShowGroup(index)
    local group = catalog.groups[index]
    if group == nil then
        return
    end
    for i, tab in ipairs(self.tabs) do
        local selected = i == index
        tab:SetTextures(SKIN_ATLAS, selected and "tab_active.tex" or "tab_idle.tex",
            "tab_active.tex", "tab_idle.tex", "tab_active.tex")
        tab:ForceImageSize(135, 34)
        tab:SetTextColour(unpack(selected and ACTIVE or INACTIVE))
    end
    self.group_title:SetString(group.name .. "  ·  " .. #group.builds .. " ngoại hình")

    if self.gallery ~= nil then
        self.gallery:Kill()
    end
    self.gallery = self.root:AddChild(Widget("previews"))

    for i, build in ipairs(group.builds) do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local row_count = math.min(3, #group.builds - row * 3)
        local card = self.gallery:AddChild(ImageButton(SKIN_ATLAS, "slot.tex"))
        card.ignore_standard_scaling = true
        card:SetNormalScale(1, 1)
        card:SetFocusScale(1.04, 1.04)
        card:ForceImageSize(124, 124)
        card:SetPosition((col - (row_count - 1) / 2) * 170,
            #group.builds <= 3 and -61 or 4 - row * 130)
        card:SetOnClick(function() self:Select(build) end)

        local preview = card:AddChild(UIAnim())
        local anim = preview:GetAnimState()
        anim:SetBank("wilson")
        anim:SetBuild(build)
        anim:AddOverrideBuild("player_emote_extra")
        anim:PlayAnimation("idle_loop", true)
        anim:Hide("ARM_carry")
        anim:Hide("HAIR_HAT")
        anim:Hide("HEAD_HAT")
        preview:SetFacing(FACING_DOWN)
        preview:SetScale(.15)
        preview:SetPosition(0, -30)

        local label = card:AddChild(Text(BODYTEXTFONT, 17,
            i == 1 and "Mặc định" or ("Skin " .. (i - 1))))
        label:SetPosition(0, -47)
        label:SetColour(unpack(WHITE))
        label:SetClickable(false)
    end
end

function NyxSkinScreen:Select(build)
    self.on_select(build)
    self:Close()
end

function NyxSkinScreen:Close()
    TheFrontEnd:PopScreen(self)
end

function NyxSkinScreen:OnControl(control, down)
    if NyxSkinScreen._base.OnControl(self, control, down) then
        return true
    end
    if control == CONTROL_CANCEL and not down then
        self:Close()
        return true
    end
end

return NyxSkinScreen
