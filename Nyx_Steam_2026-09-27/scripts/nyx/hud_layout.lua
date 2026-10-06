local Widget = require "widgets/widget"
local SkillPanel = require "nyx/input"

local Layout = {}

-- Toggle artwork includes a pendant and extra padding; enlarge its canvas
-- so the circular face matches the visible diameter of the skill icons.
local TOGGLE_SIZE = 96
local SKILL_ICON_SIZE = 58.08 * 1.2
local CORNER_ICON_SIZE = 48
local CORNER_ICON_GAP = 64
local ICON_GAP = 64 * 1.2
local SKILL_ROW_Y = 0
local BADGE_X = -110
local BADGE_Y = -150
local PANEL_X = 0
local ROW_Y = 175
local SKIN_X = 85
local SKIN_Y = 85

local function Pack(...)
    return {n = select("#", ...), ...}
end

local function UpdateHUDScale(controls)
    local root = controls.nyx_skill_hud_root
    local scale = TheFrontEnd ~= nil and TheFrontEnd.GetHUDScale ~= nil
        and TheFrontEnd:GetHUDScale() or 1
    if root ~= nil then root:SetScale(scale) end
    if controls.nyx_skin_root ~= nil then controls.nyx_skin_root:SetScale(scale) end
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
    if panel.collapse ~= nil then panel.collapse:Hide() end

    local skills = require('nyx/skilldefs').Order()
    for index, skill in ipairs(skills) do
        local button = panel.icons ~= nil and panel.icons[skill] or nil
        ConfigureButton(button, SKILL_ICON_SIZE)
        if button ~= nil then
            button:SetPosition((index - (#skills + 1) / 2) * ICON_GAP, SKILL_ROW_Y, 0)
            if button.label then button.label:SetPosition(0, -46, 0) end
        end
    end

    ConfigureButton(panel.appearance_button, CORNER_ICON_SIZE)
    ConfigureButton(panel.gem_storage_button, CORNER_ICON_SIZE)

    local tooltip = panel.skill_tooltip_text or panel.tooltip
    if tooltip ~= nil then tooltip:SetPosition(0, 105, 0) end
end

local function PlaceAppearanceButton(controls, button)
    if button == nil then return end
    if controls.nyx_skin_root == nil then
        local root = controls:AddChild(Widget("NyxCornerButtonsRoot"))
        root:SetScaleMode(SCALEMODE_PROPORTIONAL)
        root:SetMaxPropUpscale(MAX_HUD_SCALE)
        root:SetHAnchor(ANCHOR_LEFT)
        root:SetVAnchor(ANCHOR_BOTTOM)
        root:SetPosition(SKIN_X, SKIN_Y, 0)
        controls.nyx_skin_root = root
    end
    controls.nyx_skin_root:AddChild(button)
    button:SetPosition(0, 0, 0)
    UpdateHUDScale(controls)
end

local function GetOrCreateRoot(controls)
    if controls.nyx_skill_root == nil then
        controls.nyx_skill_root = controls:AddChild(Widget("NyxSkillRoot"))
        controls.nyx_skill_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
        controls.nyx_skill_root:SetMaxPropUpscale(MAX_HUD_SCALE)
        controls.nyx_skill_root:SetHAnchor(ANCHOR_MIDDLE)
        controls.nyx_skill_root:SetVAnchor(ANCHOR_BOTTOM)
        controls.nyx_skill_root:SetPosition(0, 0, 0)
    end
    if controls.nyx_skill_hud_root == nil then
        controls.nyx_skill_hud_root = controls.nyx_skill_root:AddChild(
            Widget("NyxSkillHUDRoot"))
    end
    TrackHUDScale(controls)
    UpdateHUDScale(controls)
    return controls.nyx_skill_hud_root
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
    PlaceAppearanceButton(controls, panel.appearance_button)
    if panel.gem_storage_button ~= nil and controls.nyx_skin_root ~= nil then
        controls.nyx_skin_root:AddChild(panel.gem_storage_button)
        panel.gem_storage_button:SetPosition(CORNER_ICON_GAP, 0, 0)
    end
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
