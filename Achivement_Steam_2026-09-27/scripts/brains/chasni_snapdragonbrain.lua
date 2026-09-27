require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 3
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 20
local MAX_CHASE_DIST = 25
local SKILL_MINPERIOD = 20
local Chasni_SnapdragonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function CanTaunt(inst)
    return inst:GetTimeAlive() > 5 and inst.components.combat:HasTarget()
end

function Chasni_SnapdragonBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        MinPeriod(self.inst, SKILL_MINPERIOD, true,
                IfNode(function() return CanTaunt(self.inst) end, "want to taunt",
                        ActionNode(function()
                            if not IsEntityDead(self.inst) then
                                self.inst.sg:GoToState("taunt")
                                return SUCCESS
                            end
                            return FAILED
                        end, "Taunting"))),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
        Wander(self.inst),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_SnapdragonBrain