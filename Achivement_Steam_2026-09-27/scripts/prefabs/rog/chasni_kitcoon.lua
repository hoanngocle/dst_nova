local brain = require("brains/chasni_kitcoonbrain")

local prefabs = {}

local SLEEP_NEAR_LEADER_DISTANCE = 2.5
local KITTEN_SCALE = 1
local MAX_CAST_DIST = 10
local CAST_COOLDOWN = 10
local HEALING = 10

-------------------------------------------------------------------------------

local function ShouldWakeUp(inst)
	return DefaultWakeTest(inst) or (inst.components.follower.leader and not inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local function ShouldSleep(inst)
	return DefaultSleepTest(inst) and (inst.components.follower.leader == nil or inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
end

local function ownerincombat(owner)
	local timeout_time = GetTime() - 10
	local owner_combat = owner.components.combat
	local attack_time = math.max(owner_combat.laststartattacktime or 0, owner_combat.lastdoattacktime or 0)
	if attack_time > timeout_time then
		return true
	end

	if owner_combat:GetLastAttackedTime() > timeout_time then
		if owner_combat.lastattacker and owner_combat.lastattacker.components.combat == nil then
			return false
		end
		return true
	end

	return false
end

local function CanCastSpell(inst)
	local owner = inst.components.follower and inst.components.follower.leader or nil
	return owner and ownerincombat(owner) and owner:IsNear(inst, MAX_CAST_DIST) and GetTime() - (inst.sg and inst.sg.mem.prevcasttime or 0) > CAST_COOLDOWN
end

local function CastSpell(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = 10
	local ents = FindPlayersInRange(x, y, z, range, true)
	for _, v in ipairs(ents) do
		v.components.health:DoDelta(HEALING)
		local fx = SpawnPrefab("brilliance_projectile_blast_fx")
		fx.entity:SetParent(v.entity)
	end

	local leader = inst.components.follower and inst.components.follower.leader and inst.components.follower.leader.components.leader or nil
	if leader and leader:CountFollowers() > 0 then
		for v, _ in pairs(leader.followers) do
			if v.components.health and not v.components.health:IsDead() then
				v.components.health:DoDelta(HEALING)
				local fx = SpawnPrefab("brilliance_projectile_blast_fx")
				fx.entity:SetParent(v.entity)
			end
		end
	end
end

local function MakeKitcoon(name, build)
	local assets =
	{
		Asset("ANIM", "anim/"..build.."_build.zip"),
		Asset("ANIM", "anim/kitcoon_basic.zip"),
		Asset("ANIM", "anim/kitcoon_emotes.zip"),
		Asset("ANIM", "anim/kitcoon_traits.zip"),
		Asset("ANIM", "anim/kitcoon_jump.zip"),
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddDynamicShadow()
		inst.entity:AddNetwork()

		inst.Transform:SetSixFaced()
		inst.Transform:SetScale(KITTEN_SCALE, KITTEN_SCALE, KITTEN_SCALE)

		inst.AnimState:SetBank("kitcoon")
		inst.AnimState:SetBuild(build.."_build")
		inst.AnimState:PlayAnimation("idle_loop")

		inst.DynamicShadow:SetSize(1, .33)

		MakeCharacterPhysics(inst, 1, .5)

		inst.Physics:SetDontRemoveOnSleep(true)

		inst:AddTag("companion")
		inst:AddTag("notraptrigger")
		inst:AddTag("noauradamage")
		inst:AddTag("NOBLOCK")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("follower")
		inst.components.follower.keepleaderduringminigame = true

		inst:AddComponent("sleeper")
		inst.components.sleeper:SetResistance(3)
		inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
		inst.components.sleeper:SetSleepTest(ShouldSleep)
		inst.components.sleeper:SetWakeTest(ShouldWakeUp)

		inst:AddComponent("locomotor")
		inst.components.locomotor:SetTriggersCreep(false)
		inst.components.locomotor.softstop = true
		inst.components.locomotor.walkspeed = TUNING.KITCOON_WALK_SPEED / KITTEN_SCALE
		inst.components.locomotor.runspeed = TUNING.KITCOON_RUN_SPEED / KITTEN_SCALE
		inst.components.locomotor:SetAllowPlatformHopping(true)

		inst:AddComponent("inspectable")
		inst:AddComponent("drownable")
		inst:AddComponent("embarker")
		inst.components.embarker.embark_speed = inst.components.locomotor.walkspeed + 2

		inst.CanCastSpell = CanCastSpell
		inst.CastSpell = CastSpell

		inst.persists = false

		inst:SetBrain(brain)
		inst:SetStateGraph("SGCZkitcoon")

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

-------------------------------------------------------------------------------
return 
MakeKitcoon("chasni_kitcoon_healer", "chasni_kitcoon_mage")
