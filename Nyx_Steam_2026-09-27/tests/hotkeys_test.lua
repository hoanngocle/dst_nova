package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local keys = {KEY_1 = 49, KEY_2 = 50, KEY_3 = 51, KEY_4 = 52, KEY_5 = 53,
    KEY_G = 103, KEY_T = 116, KEY_H = 104, KEY_R = 114,
    KEY_F1 = 282, KEY_F2 = 283}
for name, value in pairs(keys) do _G[name] = value end

package.preload['nyx/skillnet'] = function()
    return {Read = function() return {ready = true, unlocked = {
        absolute_domain = true, triflame_fan = true, yellow_river = true,
        eternal_night = true, spirit_sword = true, purple_gather = true,
        purple_eye = true, moon_wings = true,
    }} end}
end

local activated = {}
local book = {components = {spellbook = {items = {}}}}
function book:IsValid() return true end
function book:GetNyxOwner() return _G.ThePlayer end
function book.components.spellbook:SelectSpell(index) self.selected = index; return true end
for index, id in ipairs(require('nyx/skilldefs').Order()) do
    book.components.spellbook.items[index] = {execute = function()
        activated[#activated + 1] = id
    end}
end

local player = {prefab = 'nyx', _nyx_skillbook = {value = function() return book end},
    HUD = {HasInputFocus = function() return false end}}
function player:HasTag() return false end
_G.ThePlayer = player

local handlers = {}
local input = {
    AddKeyDownHandler = function(_, key, callback) handlers[key] = callback end,
}
local frontend
require('nyx/hotkeys').Install(input, function() return frontend end,
    function() return _G.ThePlayer end)
frontend = {
    GetActiveScreen = function() return {name = 'HUD'} end,
    IsControlsDisabled = function() return false end,
}
local count_handlers = 0
for _ in pairs(handlers) do count_handlers = count_handlers + 1 end
assert(count_handlers == 6, 'only G, T, H, R, F1 and F2 should be registered')
for _, key in ipairs({KEY_1, KEY_2, KEY_3, KEY_4, KEY_5}) do
    assert(handlers[key] == nil, 'combat skills must not register number keys')
end
for _, binding in ipairs({{KEY_R, 'absolute_domain'}, {KEY_T, 'triflame_fan'},
    {KEY_H, 'yellow_river'}, {KEY_G, 'purple_gather'}, {KEY_F1, 'purple_eye'},
    {KEY_F2, 'moon_wings'}}) do
    handlers[binding[1]]()
    assert(activated[#activated] == binding[2], 'utility shortcut must activate the matching skill')
end

local count = #activated
player.HUD.HasInputFocus = function() return true end
handlers[KEY_R]()
assert(#activated == count, 'hotkeys must not fire while chat or HUD input has focus')
player.HUD.HasInputFocus = function() return false end
_G.ThePlayer = {prefab = 'wilson'}
handlers[KEY_R]()
assert(#activated == count, 'hotkeys must not activate for another character')

print('hotkeys_test: ok')
