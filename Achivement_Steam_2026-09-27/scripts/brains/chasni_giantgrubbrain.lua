require "behaviours/wander"
require "behaviours/chaseandattack"

local MAX_CHASE_TIME = 40

local Chasni_GiantgrubBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function Chasni_GiantgrubBrain:OnStart()
	local root = PriorityNode({
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst)
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return Chasni_GiantgrubBrain