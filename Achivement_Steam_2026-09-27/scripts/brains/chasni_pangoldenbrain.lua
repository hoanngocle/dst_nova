require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"

local START_FACE_DIST = 7
local KEEP_FACE_DIST = 12
local MAX_CHASE_TIME = 60
local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 9

local BrainCommon = require("brains/braincommon")

local Chasni_PangoldenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function poop(inst)
    if inst.goldlevel and inst.goldlevel >= 1 then
        inst.goldlevel = inst.goldlevel -1
        return BufferedAction(inst, nil, ACTIONS.PANGO_POOP)
    end
end

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

function Chasni_PangoldenBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.sg:HasStateTag("ball") end, "Balled up",
                PriorityNode{
                    BrainCommon.PanicTrigger(self.inst),
                    SequenceNode{
                        RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
                        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.5),
                    },

                    IfNode(function() return self.inst.components.combat.target end, "hastarget", AttackWall(self.inst)),
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME),

                    DoAction(self.inst, function() return poop(self.inst) end, "poop"),
                    Wander(self.inst)
                }),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_PangoldenBrain