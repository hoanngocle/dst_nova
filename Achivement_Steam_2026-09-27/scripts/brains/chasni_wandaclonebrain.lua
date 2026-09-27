require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"

local BrainCommon = require "brains/braincommon"

local MAX_CHASE_TIME      = 25
local MAX_CHASE_DIST      = 40
local SEE_PLAYER_DIST     = 5

local FACETIME_BASE = 2
local FACETIME_RAND = 2

local MIN_FOLLOW_DIST     = 0
local TARGET_FOLLOW_DIST  = 6
local MAX_FOLLOW_DIST     = 9

local Chasni_WandaCloneBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
	if inst.components.timer:TimerExists("dontfacetime") then
		return nil
	end
	local shouldface = inst.components.follower.leader or FindClosestPlayerToInst(inst, SEE_PLAYER_DIST, true)
	if shouldface and not inst.components.timer:TimerExists("facetime") then
		inst.components.timer:StartTimer("facetime", FACETIME_BASE + math.random()*FACETIME_RAND)
	end
	return shouldface
end

local function KeepFaceTargetFn(inst, target)
	if inst.components.timer:TimerExists("dontfacetime") then
		return nil
	end
	local keepface = (inst.components.follower.leader and inst.components.follower.leader == target) or (target:IsValid() and inst:IsNear(target, SEE_PLAYER_DIST))
	if not keepface then
		inst.components.timer:StopTimer("facetime")
	end
	return keepface
end

function Chasni_WandaCloneBrain:OnStart()
	local root = PriorityNode({
		WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))),
		IfNode(function() return self.inst:HasTag("clone_chopper") or self.inst:HasTag("clone_worker") end, "Is Chopper", BrainCommon.NodeAssistLeaderDoAction(self, { action = "CHOP", })),
		IfNode(function() return self.inst:HasTag("clone_miner") or self.inst:HasTag("clone_worker") end, "Is Miner", BrainCommon.NodeAssistLeaderDoAction(self, { action = "MINE", })),
		Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, nil, true),
		IfNode(function() return self.inst.components.follower.leader end, "HasLeader",	FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
	}, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_WandaCloneBrain
