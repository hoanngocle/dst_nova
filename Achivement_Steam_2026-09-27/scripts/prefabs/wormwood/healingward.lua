local brain = require("brains/chasni_healingwardbrain")

local assets =
{
	Asset("ANIM", "anim/healingward.zip"),
	Asset("ATLAS", "images/inventoryimages/healingward.xml"),
}

local prefabs =
{
	"lighterfire_healingward"
}

local HEALTH = 1
local TICK = 1
local SPEED = chasni_getitemconfig("healingward", "SPD") or 4
local HEALING = chasni_getitemconfig("healingward", "HEAL") or 0.01
local RANGE = chasni_getitemconfig("healingward", "RNG") or 6
local XP_MULT = chasni_getitemconfig("healingward", "XP") or 1
local function ShouldKeepTarget()
	return false
end

local function setLeader(inst, leader)
	leader = leader or FindClosestPlayerToInst(inst, 3, true)
	if leader and inst.components.follower then
		if leader == inst.components.follower.leader then
			inst.components.follower:SetLeader(nil)
		else
			inst.components.follower:SetLeader(leader)
		end
	end
end

local function TurnOff(inst)
	setLeader(inst)

	inst:AddTag("fueldepleted")
	inst:DoTaskInTime(.1,function()
		inst.components.machine:TurnOn()
		inst:RemoveTag("fueldepleted")
	end)
end

local TAUNT_DIST = 10
local TAUNT_MUST_TAGS = { "_combat", "locomotor" }
local TAUNT_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player", "companion", "notaunt" }
local function IsTauntable(inst, target)
	return target.components.combat and not target.components.combat:TargetIs(inst) and target.components.combat:CanTarget(inst)
end
local function healingtask(inst)
	if not inst.components.health:IsDead() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = FindPlayersInRange(x, y, z, RANGE, true)
		local healedcount = 0
		for _, v in ipairs(ents) do
			if v and v.prefab ~= "wormwood" and v.components.health and not v.components.health:IsDead() then
				local heal = HEALING * v.components.health:GetMaxWithPenalty()
				v.components.health:DoDelta(heal)
				healedcount = healedcount + 1
			end
		end

		if healedcount > 0 then
			for i, v in ipairs(AllPlayers) do
				if v and v.prefab == "wormwood" then
					v.components.levelsystem:xpDoDelta(healedcount * XP_MULT, v)
				end
			end
		end

		local wards = TheSim:FindEntities(x, y, z, RANGE + RANGE, {"healingward"})
		for _, v in ipairs(wards) do
			if v ~= inst then
				if v._healtask then
					v._healtask:Cancel()
					v._healtask = nil
				end
				ErodeAway(v)
			end
		end

		if math.random() < 0.2 then
			for i, v in ipairs(TheSim:FindEntities(x, y, z, TAUNT_DIST, TAUNT_MUST_TAGS, TAUNT_CANT_TAGS)) do
				if IsTauntable(inst, v) then
					v.components.combat:SetTarget(inst)
				end
			end
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("healingward")
	inst.AnimState:SetBuild("healingward")
	inst.AnimState:PlayAnimation("walk_loop", true)
	inst.AnimState:SetScale(-1, 1)

	inst.DynamicShadow:SetSize(1, .5)
	inst.Transform:SetTwoFaced()
	MakeTinyFlyingCharacterPhysics(inst, 1, 0.5)

	inst:AddTag("companion")
	inst:AddTag("healingward")
	inst:AddTag("notraptrigger")
	inst:AddTag("noauradamage")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

	inst:AddComponent("machine")
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine:TurnOn()

	inst:AddComponent("inspectable")
	inst:AddComponent("follower")
	inst:AddComponent("locomotor")
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.softstop = true
	inst.components.locomotor.walkspeed = SPEED
	inst.components.locomotor.runspeed = SPEED
	inst.components.locomotor:CanPathfindOnWater()
	inst.components.locomotor:SetAllowPlatformHopping(true)
	inst.components.locomotor.pathcaps = { allowocean = true }

	if inst._fire == nil then
		local fx = SpawnPrefab("lighterfire_healingward")
		fx.entity:SetParent(inst.entity)
		fx.entity:AddFollower()
		fx.Follower:FollowSymbol(inst.GUID, "ward", fx.fx_offset_x, fx.fx_offset_y, 0)
		fx:AttachLightTo(inst)
		inst._fire = fx
		inst._healtask = inst:DoPeriodicTask(TICK, healingtask)
	end

	inst:SetBrain(brain)
	inst:SetStateGraph("SGCZhealingward")

	return inst
end

return Prefab("healingward", fn, assets, prefabs)
