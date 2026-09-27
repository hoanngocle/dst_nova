require "behaviours/chaseandattack"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local Chasni_SlipstorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_SlipstorBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst),
        Wander(self.inst)
    }, 1)
    self.bt = BT(self.inst, root)
end

return Chasni_SlipstorBrain