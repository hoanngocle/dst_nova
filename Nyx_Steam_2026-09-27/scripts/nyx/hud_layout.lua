local Widget = require "widgets/widget"
local SkillPanel = require "nyx/input"

local Layout = {}

-- Toggle artwork includes a pendant and extra padding; enlarge its canvas
-- so the circular face matches the visible diameter of the skill icons.
local TOGGLE_SIZE = 96
local SKILL_ICON_SIZE = 58.08 * 1.2
local ICON_GAP = 64 * 1.2
local SKILL_ROW_Y = 8
local UTILITY_ROW_Y = SKILL_ROW_Y - 94
local BADGE_X = -110
local BADGE_Y = -150
local PANEL_X = 75
local ROW_Y = 190

local function Pack(...)
    return {n = select("#", ...), ...}
end

local function UpdateHUDScale(controls)
    local root = controls.nyx_bottomleft_hud_root
    if root == nil then return end
    local scale = TheFrontEnd ~= nil and TheFrontEnd.GetHUDScale ~= nil
        and TheFrontEnd:GetHUDScale() or 1
    root:SetScale(scale)
end

local function TrackHUDScale(controls)
    if controls._nyx_hud_layout_tracks_scale then return end
    controls._nyx_hud_layout_tracks_scale = true
    local SetHUDSize = controls.SetHUDSize
    if SetHUDSize == nil then return end
    controls.SetHUDSize = function(self, ...)
        local results = Pack(SetHUDSize(self, ...))
        UpdateHUDScale(self)
        return unpack(results, 1, results.n)
    end
end

local function ConfigureButton(button, size)
    if button == nil then return end
    -- Native ImageButton focus handling calls Image:SetScale for equal normal
    -- and focus textures, which otherwise discards ForceImageSize.
    button.scale_on_focus = false
    button:ForceImageSize(size, size)
end

function Layout.ConfigurePanel(panel)
    if panel == nil then return end

    ConfigureButton(panel.collapse, TOGGLE_SIZE)
    if panel.collapse ~= nil then panel.collapse:SetPosition(0, -2, 0) end

    for index, skill in ipairs(require('nyx/skilldefs').Order()) do
        local button = panel.icons ~= nil and panel.icons[skill] or nil
        ConfigureButton(button, SKILL_ICON_SIZE)
        if button ~= nil then
            local d=require('nyx/skilldefs').Get(skill)
            button:SetPosition(d.slot * ICON_GAP, d.row==1 and SKILL_ROW_Y or UTILITY_ROW_Y, 0)
            if button.label then button.label:SetPosition(0, -46, 0) end
        end
    end

    ConfigureButton(panel.appearance_button, SKILL_ICON_SIZE)
    if panel.appearance_button then panel.appearance_button:SetPosition(0, UTILITY_ROW_Y, 0) end

    local tooltip = panel.skill_tooltip_text or panel.tooltip
    if tooltip ~= nil then tooltip:SetPosition(190, 66, 0) end
end

local function GetOrCreateRoot(controls)
    if controls.nyx_bottomleft_root == nil then
        controls.nyx_bottomleft_root = controls:AddChild(Widget("NyxBottomLeftRoot"))
        controls.nyx_bottomleft_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
        controls.nyx_bottomleft_root:SetMaxPropUpscale(MAX_HUD_SCALE)
        controls.nyx_bottomleft_root:SetHAnchor(ANCHOR_LEFT)
        controls.nyx_bottomleft_root:SetVAnchor(ANCHOR_BOTTOM)
        controls.nyx_bottomleft_root:SetPosition(0, 0, 0)
    end
    if controls.nyx_bottomleft_hud_root == nil then
        controls.nyx_bottomleft_hud_root = controls.nyx_bottomleft_root:AddChild(
            Widget("NyxBottomLeftHUDRoot"))
    end
    TrackHUDScale(controls)
    UpdateHUDScale(controls)
    return controls.nyx_bottomleft_hud_root
end

function Layout.Apply(controls)
    local owner = controls ~= nil and controls.owner or nil
    if owner == nil or owner.prefab ~= "nyx" then return false end

    local status = controls.status or controls.statusdisplays
    local badge = owner.nyx_resourcehud or (status ~= nil and status.nyx_resourcehud or nil)
    local panel = controls.nyx_skillpanel
    if status == nil or badge == nil or panel == nil then return false end

    local root = GetOrCreateRoot(controls)
    status:AddChild(badge)
    badge:SetPosition(BADGE_X, BADGE_Y, 0)
    root:AddChild(panel)
    panel:SetPosition(PANEL_X, ROW_Y, 0)
    Layout.ConfigurePanel(panel)
    return true
end

function Layout.Install(add_class_post_construct)
    add_class_post_construct("widgets/controls", function(controls)
        local owner = controls.owner
        if owner == nil or owner.prefab ~= "nyx" or controls.inst == nil then return end
        controls.inst:DoTaskInTime(0, function()
            if controls.inst == nil or controls.inst.IsValid == nil
                or controls.inst:IsValid() then
                Layout.Apply(controls)
            end
        end)
    end)
end

return Layout
