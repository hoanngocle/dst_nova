package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

package.preload['util/nyx_domain_common'] = function()
    return {CanRemainActive = function() return true end}
end

local gather = require('util/nyx_gather_common')
local owner = {}

local function tree(action, tags)
    local inst = {components = {}, valid = true, tags = tags or {}}
    function inst:IsValid() return self.valid end
    function inst:HasTag(tag) return self.tags[tag] == true end
    inst.components.workable = {
        CanBeWorked = function() return true end,
        GetWorkAction = function() return {id = action} end,
        WorkedBy = function(self) self.worked = true end,
    }
    return inst
end

local selected = tree('CHOP')
selected.noleif = true
selected.leifscale = 1
selected.chopper = owner
selected.TransformIntoLeif = function() end
assert(not gather.WorkEntity(owner, selected),
    'gather must leave a selected evergreen alive until TreeGuard appears')
assert(not selected.components.workable.worked,
    'gather must not chop a tree waiting to become TreeGuard')

local petrifying = tree('CHOP')
petrifying.noleif = true
assert(gather.WorkEntity(owner, petrifying),
    'an unrelated noleif tree must remain harvestable')

local ordinary = tree('CHOP')
assert(gather.WorkEntity(owner, ordinary),
    'ordinary trees must still be chopped')

local stump = tree('DIG', {stump = true})
assert(gather.WorkEntity(owner, stump),
    'ordinary stumps must still be dug')

print('gather_treeguard_test: ok')
