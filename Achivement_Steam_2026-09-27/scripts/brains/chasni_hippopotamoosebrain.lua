require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/chaseandattack"
require "behaviours/wander"

local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 14
local KEEP_FACE_DIST = 16
local MAX_CHASE_TIME = 30
local MAX_JUMP_ATTACK_RANGE = 9
local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 12

local Chasni_HippopotamooseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST) and not target:HasTag("notarget")
end

local function ShouldRunAway(guy)
    return guy:HasTag("character") and not guy:HasTag("notarget") and not guy:HasTag("cz_animallover")
end

local function ShouldJumpAttack(inst)
    if inst.sg:HasStateTag("leapattack") then
        return true
    end
    if inst.components.combat.target then
        local target = inst.components.combat.target
        if target then
            if target:IsValid() then
                local combatrange = inst.components.combat:CalcAttackRangeSq(target)
                local distsq = inst:GetDistanceSqToInst(target)
                if distsq > combatrange and distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
                    return true
                end
            else
                inst.components.combat.target = nil
            end
        end
    end
    return false
end

local function DoJumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        inst:PushEvent("doleapattack", {target=target})
        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

function Chasni_HippopotamooseBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return ShouldJumpAttack(self.inst) end, "jumpattack",
                DoAction(self.inst, function() return DoJumpAttack(self.inst) end, "jump", true)
        ),
        IfNode(function() return self.inst.components.combat.target end, "hastarget", AttackWall(self.inst)),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        SequenceNode{
            RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.5),
        },
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst)
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_HippopotamooseBrain
