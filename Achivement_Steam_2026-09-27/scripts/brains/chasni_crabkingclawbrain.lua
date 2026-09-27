require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "behaviours/leash"

local WAMDER_DIST = 2
local LEASH_DIST = 10

local Chasni_CrabKingClawBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_CrabKingClawBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.sg:HasStateTag("clampped") end, "not clamping", PriorityNode({
            Leash(self.inst, function() return self.inst.components.knownlocations:GetLocation("spawnpoint") end, LEASH_DIST, 5, false),
            Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("spawnpoint") end, WAMDER_DIST, {
                minwalktime=0.5,
                randwalktime=0.5,
                minwaittime=1,
                randwaittime=5,
            })
        }, 0.2)),
    }, 0.2)
    self.bt = BT(self.inst, root)
end

return Chasni_CrabKingClawBrain
