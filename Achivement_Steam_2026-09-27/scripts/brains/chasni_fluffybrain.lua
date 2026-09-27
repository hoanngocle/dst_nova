require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/wander"
require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 20
local MAX_CHASE_DIST = 16

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local SEE_FOOD_DIST = 10
local EATFOOD_CANT_TAGS = { "outofreach" }
local function EatFoodAction(inst)
    local target = FindEntity(inst,
            SEE_FOOD_DIST,
            function(item)
                return inst.components.eater:CanEat(item)
                        and item:IsOnValidGround()
                        and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
            end,
            nil,
            EATFOOD_CANT_TAGS
    )
    return target and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local Chasni_FluffyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_FluffyBrain:OnStop()
    if self.onepicscarefn then
        self.inst:RemoveEventCallback("epicscare", self.onepicscarefn)
        self.onepicscarefn = nil
        self.scareendtime = nil
    end
end

local function NoLeader(self)
    return not (self.inst.components.follower and self.inst.components.follower.leader)
end

local function NoHome(self)
    return self.inst.House == nil
end

function Chasni_FluffyBrain:OnStart()
    if self.scareendtime == nil then
        self.scareendtime = 0
        self.onepicscarefn = function(inst, data)
            self.scareendtime = math.max(self.scareendtime, data.duration + GetTime() + math.random())
        end
        self.inst:ListenForEvent("epicscare", self.onepicscarefn)
    end

    local root = PriorityNode({
        IfNode(function() return NoLeader(self) end, "No Leader", ActionNode(function() self.inst.ReturnHome(self.inst) end)),
        IfNode(function() return NoHome(self) end, "No Home", ActionNode(function() self.inst.ReturnHome(self.inst) end)),
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
        DoAction(self.inst, EatFoodAction, "eat food", true),
        Follow(self.inst, function() return self.inst.components.follower.leader end,
                TUNING.SPIDER_DEFENSIVE_MIN_FOLLOW, TUNING.SPIDER_DEFENSIVE_MED_FOLLOW, TUNING.SPIDER_DEFENSIVE_MAX_FOLLOW),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst)
    }, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_FluffyBrain
