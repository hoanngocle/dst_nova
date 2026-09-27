require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/chattynode"

local BrainCommon = require "brains/braincommon"

local MAX_CHASE_TIME      = 25
local MAX_CHASE_DIST      = 40
local SEE_PLAYER_DIST     = 5
local RUN_AWAY_DIST       = 5
local STOP_RUN_AWAY_DIST  = 8

local FACETIME_BASE = 2
local FACETIME_RAND = 2

local MIN_FOLLOW_DIST     = 1
local MAX_FOLLOW_DIST     = 9

local Chasni_MermProtectorBrain = Class(Brain, function(self, inst)
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

local function TargetFollowDistFn(inst)
	local loyalty = inst.components.follower and inst.components.follower:GetLoyaltyPercent() or 0.5
	local boatmod = inst:GetCurrentPlatform() and 0.2 or 1.0
	return (MAX_FOLLOW_DIST - MIN_FOLLOW_DIST) * (1.0 - loyalty) * boatmod * math.random() + MIN_FOLLOW_DIST
end

function Chasni_MermProtectorBrain:OnStart()
	local root = PriorityNode({
		WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "Attack Momentarily",
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))),
		WhileNode(function() return self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown() end, "Dodge",
				RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),

		BrainCommon.NodeAssistLeaderDoAction(self, {
			action = "CHOP",
			chatterstring = "MERM_TALK_HELP_CHOP_WOOD",
		}),
		BrainCommon.NodeAssistLeaderDoAction(self, {
			action = "MINE",
			chatterstring = "MERM_TALK_HELP_MINE_ROCK",
		}),
		ChattyNode(self.inst, "MERM_TALK_FOLLOWWILSON",
				Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TargetFollowDistFn, MAX_FOLLOW_DIST, nil, true)),
		IfNode(function() return self.inst.components.follower.leader end, "HasLeader",
				ChattyNode(self.inst, "MERM_TALK_FOLLOWWILSON",
						FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn))),
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
	}, .25)

    self.bt = BT(self.inst, root)
end

return Chasni_MermProtectorBrain
