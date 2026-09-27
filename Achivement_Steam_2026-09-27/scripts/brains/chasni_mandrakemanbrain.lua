require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 1
local KEEP_FACE_DIST = 2
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 10
local Chasni_MandrakemanBrain = Class(Brain, function(self, inst)
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

function Chasni_MandrakemanBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_MandrakemanBrain