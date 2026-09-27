require "behaviours/chaseandattack"
local BrainCommon = require "brains/braincommon"

local MAX_CHASE_TIME = 8

local Chasni_SlipBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_SlipBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME)),
    }, 1)
    self.bt = BT(self.inst, root)
end

return Chasni_SlipBrain
