local nyx_root = os.getenv('NYX_TEST_MOD_ROOT') or 'Nyx_Steam_2026-09-27'
package.path = nyx_root .. '/scripts/?.lua;' .. package.path
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
_G.unpack = table.unpack or unpack

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
controls.SetHUDSize = function() return 'original', nil, 3 end
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
assert(math.abs(first + last) < 0.01, 'all skills must be centered over inventory')
assert(panel.appearance_button.parent.hanchor == ANCHOR_LEFT
    and panel.appearance_button.parent.vanchor == ANCHOR_BOTTOM,
    'Skin icon must be anchored to the lower-left corner')
assert(panel.appearance_button.parent.pos.x == 85
    and panel.appearance_button.parent.pos.y == 85,
    'Skin icon must sit just inside the lower-left corner')
assert(badge.parent == controls.status, 'resource badge must remain on the status HUD')
assert(panel.gem_storage_button.parent == panel.appearance_button.parent,
    'gem storage icon must share the Skin HUD anchor')
assert(panel.gem_storage_button.pos.x > panel.appearance_button.pos.x + 48,
    'gem storage icon must sit next to Skin without overlap')
assert(panel.gem_storage_button.size[1] == panel.appearance_button.size[1],
    'storage and Skin icons must have the same size')

-- Test the composed corner group at different HUD scales and hook orders.
local ttk_root = os.getenv('TTK_TEST_MOD_ROOT') or 'TienIchTuTien_Steam_2026-09-27'
package.path = ttk_root .. '/scripts/?.lua;' .. package.path
package.preload.json = function() return {} end
package.preload.ttk_character_stats = function() return {} end
package.preload['widgets/imagebutton'] = function()
    return function()
        local result = button()
        function result:SetHoverText() end
        function result:SetOnClick(fn) self.click = fn end
        return result
    end
end
local hud_scale = 1
TheFrontEnd.GetHUDScale = function() return hud_scale end
local build_info
require('ttk_character_info').Install({
    GLOBAL = setmetatable({TheNet = {IsDedicated = function() return false end}}, {__index = _G}),
    modname = 'test',
    AddModRPCHandler = function() end,
    AddClientModRPCHandler = function() end,
    AddClassPostConstruct = function(_, fn) build_info = fn end,
})
build_info(controls)
local info = controls.ttk_character_info_button
local info_root = controls.ttk_character_info_root
local skin_root = controls.nyx_skin_root
assert(info_root == skin_root and info.parent == skin_root,
    'all three icons must belong to one shared corner group')
local function center(root, icon)
    return root.pos.x + icon.pos.x * root.scale, root.pos.y + icon.pos.y * root.scale
end
for _, scale in ipairs({.75, 1, 1.25, 1.5}) do
    hud_scale = scale
    layout.Apply(controls)
    local a, b, c = controls:SetHUDSize()
    assert(a == 'original' and b == nil and c == 3, 'scale hooks preserve returns')
    local skin_x, skin_y = center(skin_root, panel.appearance_button)
    local gem_x, gem_y = center(skin_root, panel.gem_storage_button)
    local info_x, info_y = center(info_root, info)
    assert(math.abs((gem_x - skin_x) - (info_x - gem_x)) < .01,
        'all three icons must have equal center spacing at every HUD scale')
    assert(skin_y == gem_y and gem_y == info_y, 'all three icons must share a baseline')
    assert(info_x - gem_x > (info.size[1] + panel.gem_storage_button.size[1]) / 2 * scale,
        'info and gem canvases must not overlap')
    assert(info.size[1] == 48, 'info canvas must match the compact corner icons')
end
local info_first = Widget('controls')
info_first.owner = {prefab = 'nyx', nyx_resourcehud = Widget('badge')}
info_first.status = Widget('status')
info_first.nyx_skillpanel = Widget('panel')
info_first.nyx_skillpanel.appearance_button = button()
info_first.nyx_skillpanel.gem_storage_button = button()
info_first.SetHUDSize = function() return 'original', nil, 3 end
build_info(info_first)
local shared_root = info_first.ttk_character_info_root
assert(layout.Apply(info_first))
assert(info_first.nyx_skin_root == shared_root,
    'Nyx must reuse the group created by the info hook')
assert(info_first.nyx_skillpanel.appearance_button.parent == shared_root
    and info_first.nyx_skillpanel.gem_storage_button.parent == shared_root,
    'skin and gem buttons must join the existing info group')
hud_scale = .75
info_first:SetHUDSize()
assert(shared_root.scale == .75, 'the shared group must follow HUD resizing')
print('hud_layout_test: ok')
