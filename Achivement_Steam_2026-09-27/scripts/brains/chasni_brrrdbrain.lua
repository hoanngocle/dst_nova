require "behaviours/chaseandattack"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 20
local MAX_CHASE_DIST = 25
local SKILL_PERIOD = chasni_getmobconfig("chasni_brrrd", "CD") or 15
local PECK_PERIOD = 10
local Chasni_BrrrdBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function CanSkill(inst)
    return inst:GetTimeAlive() > 5 and inst.components.combat:HasTarget()
end

local function CanFlyAway(inst)
    return inst.components.health:GetPercent() <= 0.5
end

local function FlyAway(inst)
    return inst.components.combat.target == nil
            and BufferedAction(inst, nil, ACTIONS.GOHOME)
            or nil
end

local function CanPeck(inst)
    return not inst.components.combat:HasTarget()
end

function Chasni_BrrrdBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return self.inst.sg:HasStateTag("flight") end, "do nothing",
                ActionNode(function()
                    if not IsEntityDead(self.inst) then
                        return SUCCESS
                    end
                    return FAILED
                end, "doing nothing")
        ),
        BrainCommon.PanicTrigger(self.inst),
        IfNode(function() return CanFlyAway(self.inst) end, "want to fly away",
                DoAction(self.inst, FlyAway)),
        MinPeriod(self.inst, SKILL_PERIOD, true,
                IfNode(function() return CanSkill(self.inst) end, "want to skill",
                        ActionNode(function()
                            if not IsEntityDead(self.inst) then
                                self.inst.sg:GoToState("skill")
                                return SUCCESS
                            end
                            return FAILED
                        end, "Skilling"))),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
        MinPeriod(self.inst, PECK_PERIOD, true,
                IfNode(function() return CanPeck(self.inst) end, "want to peck",
                        ActionNode(function()
                            if not IsEntityDead(self.inst) then
                                self.inst.sg:GoToState("peck")
                                return SUCCESS
                            end
                            return FAILED
                        end, "Pecking"))),
        Wander(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_BrrrdBrain