require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "behaviours/chaseandram"

local Chasni_AncientHulkBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_AncientHulkBrain:OnStart()


    local root =
        PriorityNode(
        {
            ChaseAndAttack(self.inst, 60, 120, nil, nil, true),
            Wander(self.inst, function() return self.inst:GetPosition() end, 20),
        }, .25)
    
    self.bt = BT(self.inst, root)
end

return Chasni_AncientHulkBrain