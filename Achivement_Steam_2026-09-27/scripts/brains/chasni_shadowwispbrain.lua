require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local TARGET_FOLLOW_DIST = 2.5
local MAX_FOLLOW_DIST = 4
local MIN_FOLLOW_DIST = 1

local function GetOwner(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target and not target:HasTag("notarget") and target or nil
end
local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local Chasni_ShadowWispBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_ShadowWispBrain:OnStop()
    if self.onepicscarefn then
        self.inst:RemoveEventCallback("epicscare", self.onepicscarefn)
        self.onepicscarefn = nil
        self.scareendtime = nil
    end
end

function Chasni_ShadowWispBrain:OnStart()
    local root = PriorityNode({
        Follow(self.inst, GetOwner, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        StandStill(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_ShadowWispBrain
