require "behaviours/wander"
require "behaviours/chaseandattack"
local BrainCommon = require "brains/braincommon"

local MAX_CHASE_TIME = 8
local MAX_WANDER_DIST = 10

local Chasni_BlackflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_BlackflyBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME)),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
    }, 1)
    self.bt = BT(self.inst, root)
end

function Chasni_BlackflyBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return Chasni_BlackflyBrain
