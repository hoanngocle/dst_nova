package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
package.preload['widgets/widget'] = function()
    return function(name)
        local widget = {name = name}
        function widget:AddChild(child) child.parent = self; return child end
        function widget:SetScaleMode(value) self.scale_mode = value end
        function widget:SetMaxPropUpscale(value) self.max_scale = value end
        function widget:SetHAnchor(value) self.hanchor = value end
        function widget:SetVAnchor(value) self.vanchor = value end
        function widget:SetPosition(x, y, z) self.pos = {x = x, y = y, z = z} end
        function widget:SetScale(value) self.scale = value end
        function widget:Hide() self.hidden = true end
        return widget
    end
end
package.preload['nyx/input'] = function() return {} end

_G.SCALEMODE_PROPORTIONAL = 1
_G.MAX_HUD_SCALE = 2
_G.ANCHOR_LEFT = 10
_G.ANCHOR_MIDDLE = 11
_G.ANCHOR_BOTTOM = 12
_G.TheFrontEnd = {GetHUDScale = function() return 1 end}

local Widget = require('widgets/widget')
local panel = Widget('panel')
panel.icons = {}
local function button()
    local result = Widget('button')
    function result:ForceImageSize(width, height) self.size = {width, height} end
    return result
end
panel.collapse = button()
panel.appearance_button = button()
panel.gem_storage_button = button()
for _, id in ipairs(require('nyx/skilldefs').Order()) do
    panel.icons[id] = button()
    panel.icons[id].label = Widget('label')
end

local badge = Widget('badge')
local controls = Widget('controls')
controls.owner = {prefab = 'nyx', nyx_resourcehud = badge}
controls.status = Widget('status')
controls.nyx_skillpanel = panel
local layout = require('nyx/hud_layout')
assert(layout.Apply(controls), 'Nyx HUD layout must attach')
assert(panel.parent.parent.hanchor == ANCHOR_MIDDLE, 'skill bar must follow inventory at screen center')
assert(panel.parent.parent.vanchor == ANCHOR_BOTTOM, 'skill bar must follow inventory at screen bottom')
assert(panel.pos.y == 175, 'the skill row must sit closer to the inventory')
assert(panel.collapse.hidden, 'the crossed-out collapse icon must be hidden')

local first, last
for index, id in ipairs(require('nyx/skilldefs').Order()) do
    local icon = panel.icons[id]
    assert(icon.pos.y == 0, 'all eight skills must share one row')
    if index > 1 then assert(icon.pos.x > last, 'skills must follow their displayed order') end
    first = first or icon.pos.x
    last = icon.pos.x
end
assert(math.abs(first + last) < 0.01, 'eight skills must be centered over inventory')
assert(panel.appearance_button.parent.hanchor == ANCHOR_LEFT
    and panel.appearance_button.parent.vanchor == ANCHOR_BOTTOM,
    'Skin icon must be anchored to the lower-left corner')
assert(panel.appearance_button.parent.pos.x == 85
    and panel.appearance_button.parent.pos.y == 85,
    'Skin icon must sit just inside the lower-left corner')
assert(badge.parent == controls.status, 'resource badge must remain on the status HUD')
assert(panel.gem_storage_button.parent == panel.appearance_button.parent,
    'gem storage icon must share the Skin HUD anchor')
assert(panel.gem_storage_button.pos.x > panel.appearance_button.pos.x + 69,
    'gem storage icon must sit next to Skin without overlap')
assert(panel.gem_storage_button.size[1] == panel.appearance_button.size[1],
    'storage and Skin icons must have the same size')

print('hud_layout_test: ok')
