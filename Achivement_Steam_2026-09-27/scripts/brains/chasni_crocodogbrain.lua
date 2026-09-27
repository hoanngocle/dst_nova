require "behaviours/wander"
require "behaviours/panic"
require "behaviours/doaction"
require "behaviours/standstill"

local BrainCommon = require("brains/braincommon")

local Chasni_CrocodogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local SEE_DIST = 30

local function HarvestAction(inst)
    local target = FindEntity(inst, SEE_DIST, function(item) return item.components.breeder and item.components.breeder.volume > 0 end)
    if target then
        return BufferedAction(inst, target, ACTIONS.HARVEST)
    end
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

function Chasni_CrocodogBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst),
        DoAction(self.inst, EatFoodAction, "eat food", true),
        DoAction(self.inst, HarvestAction, "harvest", true),
        Wander(self.inst)
    }, .25)
    self.bt = BT(self.inst, root)
end

return Chasni_CrocodogBrain
