require "behaviours/chaseandattack"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local Chasni_SpiderMonkeyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_SpiderMonkeyBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst),
        Wander(self.inst)
    }, 1)
    self.bt = BT(self.inst, root)
end

return Chasni_SpiderMonkeyBrain
