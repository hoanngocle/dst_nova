require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/useshield"

local MAX_CHASE_TIME = 40
local DAMAGE_UNTIL_SHIELD = 100
local SHIELD_TIME = 3
local AVOID_PROJECTILE_ATTACKS = false

local Chasni_WeevoleBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_WeevoleBrain:OnStart()
    local root = PriorityNode({
        UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
    }, 1)

    self.bt = BT(self.inst, root)
end

return Chasni_WeevoleBrain
