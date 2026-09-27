require "behaviours/chaseandattack"
require "behaviours/standstill"
require "behaviours/wander"
require "behaviours/follow"
require "behaviours/standandattack"
local BrainCommon = require "brains/braincommon"

local MAX_CHASE_TIME = 30

local Chasni_PlasmablobBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_PlasmablobBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        Wander(self.inst),
    }, 1)
    self.bt = BT(self.inst, root)
end

return Chasni_PlasmablobBrain
