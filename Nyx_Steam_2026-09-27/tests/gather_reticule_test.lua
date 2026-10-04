package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local level = 50
package.preload['nyx/skillnet'] = function()
    return {Read = function() return {level = level} end}
end
_G.TheWorld = {ismastersim = false}
_G.Prefab = function(name, fn) return {name = name, fn = fn} end

local prefab = dofile('Nyx_Steam_2026-09-27/scripts/prefabs/nyx_skillbook.lua')
local spells
for i = 1, 20 do
    local name, value = debug.getupvalue(prefab.fn, i)
    if name == 'SPELLS' then spells = value; break end
end
assert(spells ~= nil, 'skillbook should expose its spell definitions')

local owner = {prefab = 'nyx'}
local book = {
    _nyx_skill_owner = {value = function() return owner end},
    components = {
        spellbook = {
            SetSpellName = function() end,
            SetSpellAction = function() end,
        },
        aoetargeting = {
            reticule = {},
            SetRange = function(self, range) self.range = range end,
            SetAllowWater = function() end,
            SetAllowRiding = function() end,
            SetDeployRadius = function() end,
            SetShouldRepeatCastFn = function() end,
        },
    },
}
local targeting = book.components.aoetargeting

spells[6].onselect(book) -- Tử Phong Tụ Linh
assert(targeting.range == 12, 'cast distance remains 12')
assert(targeting.reticule.reticuleprefab == 'reticuleaoe_1_6',
    'gather should use a scalable area preview')
assert(targeting.reticule.pingprefab == nil,
    'gather ping must not draw a second uncalibrated range ring')
local fx_scale
local fx = {prefab = 'reticuleaoe_1_6', Transform = {
    SetPosition = function() end,
    SetScale = function(_, x) fx_scale = x end,
}}
targeting.reticule.updatepositionfn(book, {x = 1, z = 2}, fx)
assert(math.abs(fx_scale * 1.5 * 6 - require('nyx/progression').Radius(level)) < 0.001,
    'reticule outer edge must match the server gather radius at this level')

level = 100
spells[6].onselect(book)
targeting.reticule.updatepositionfn(book, {x = 1, z = 2}, fx)
assert(math.abs(fx_scale - 4 / 3) < 0.001,
    'maximum gather radius must compensate for the native 1.5 animation scale')

spells[4].onselect(book) -- Tàn Dạ
assert(targeting.reticule.reticuleprefab == 'reticuleaoesummontarget_1'
    and targeting.reticule.updatepositionfn == nil
    and targeting.reticule.pingprefab == 'reticuleaoeping',
    'other skills keep their original targeting marker')

print('gather_reticule_test: ok')
