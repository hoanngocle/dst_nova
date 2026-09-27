require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
local BrainCommon = require("brains/braincommon")

local STOP_RUN_DIST = 12
local SEE_PLAYER_DIST = 7
local AVOID_PLAYER_DIST = 5
local AVOID_PLAYER_STOP = 10

local SEE_BAIT_DIST = 20

local Chasni_GronehogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_BAIT_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end)
    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function() return not (target.components.inventoryitem and target.components.inventoryitem:IsHeld()) end
        return act
    end
end

function Chasni_GronehogBrain:OnStart()
    local root = PriorityNode(
            {
                BrainCommon.PanicTrigger(self.inst),
                RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
                RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true),
                DoAction(self.inst, EatFoodAction),
                Wander(self.inst),
            }, .25)
    self.bt = BT(self.inst, root)
end

return Chasni_GronehogBrain
