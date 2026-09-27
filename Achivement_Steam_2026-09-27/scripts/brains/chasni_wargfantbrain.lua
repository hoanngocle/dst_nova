require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local SKILL_MINPERIOD = 20
local Chasni_WargfantBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function CanSpawnChild(inst)
    return inst:GetTimeAlive() > 5 and inst:NumHoundsToSpawn() > 0 and inst.components.combat:HasTarget()
end

function Chasni_WargfantBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        MinPeriod(self.inst, SKILL_MINPERIOD, true,
                IfNode(function() return CanSpawnChild(self.inst) end, "needs follower",
                        ActionNode(function()
                            if not IsEntityDead(self.inst) then
                                self.inst.sg:GoToState("howl", {howl = true})
                                return SUCCESS
                            end
                            return FAILED
                        end, "Summon Hound"))),
        ChaseAndAttack(self.inst),
        StandStill(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_WargfantBrain
