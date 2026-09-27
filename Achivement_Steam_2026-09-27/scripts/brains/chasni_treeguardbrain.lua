require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/doaction"

local BrainCommon = require "brains/braincommon"

local Chasni_TreeGuardBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_TreeGuardBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst),
        Wander(self.inst),
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return Chasni_TreeGuardBrain
