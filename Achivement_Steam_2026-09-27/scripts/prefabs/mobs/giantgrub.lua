local brain = require "brains/chasni_giantgrubbrain"

local assets =
{
	Asset("ANIM", "anim/giant_grub.zip"),
}

local prefabs =
{
	"monstermeat",
}

SetSharedLootTable("chasni_giantgrub", { 
	{"chasni_grub_skull", 	1.00},
	{"chasni_grub_jaw", 	1.00},
	{"chasni_grub_jaw", 	0.30},
	{"monstermeat", 		1.00},
	{"monstermeat", 		1.00},
	{"monstermeat", 		0.50},
	{"monstermeat", 		0.50},

	{"jellybean_yellow",        0.10},
})

local HEALTH = chasni_getmobconfig("chasni_giantgrub", "HP") or 4000
local DAMAGE = chasni_getmobconfig("chasni_giantgrub", "DMG") or 33
local ATTACK_PERIOD = 4
local ATTACK_RANGE = 1
local HIT_RANGE = 5
local GROUNDPOUND_RANGE = 12
local SPEED = 1
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 25
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "grubarmy", }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 40
local SHARETARGET_MAX = 40
local MAX_ARMY = chasni_getmobconfig("chasni_giantgrub", "MX_ARMY") or 4
local ARMY_CHOICES =
{
	chasni_weevole = 0.5,
	chasni_weevole = 0.5,
}
local function RetargetFn(inst)
	return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
	return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
	chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "grubarmy", SHARETARGET_MAX)
end

local function CanBeAttacked(inst)
	return not inst.IsDigging
end

local function DoGroundPound(inst, dig)
	if inst.components.combat and inst.components.groundpounder then
		inst.components.combat:SetRange(GROUNDPOUND_RANGE, GROUNDPOUND_RANGE)
		inst.components.groundpounder:GroundPound()
		inst:DoTaskInTime(0.2 * inst.components.groundpounder.numRings,function()
			inst.components.combat:SetRange(ATTACK_RANGE, HIT_RANGE)
		end)
	end
end

local function GoDigging(inst, dig)
	inst.IsDigging = dig
	if dig then
		inst:AddTag("INLIMBO")
		inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
		inst.Physics:ClearCollisionMask()
		inst.Physics:CollidesWith(COLLISION.WORLD)
		inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	else
		inst:RemoveTag("INLIMBO")
		ChangeToCharacterPhysics(inst)
	end
end

local function RemoveSound(inst)
	inst.SoundEmitter:KillAllSounds()
end

local function SpawnArmy(inst)
	local x, _, z = inst.Transform:GetWorldPosition()
	local map = TheWorld.Map
	local offset = FindValidPositionByFan(
			math.random() * 3 * PI,
			math.random() * 4,
			2,
			function(offset)
				local x1 = x + offset.x
				local z1 = z + offset.z
				return map:IsPassableAtPoint(x1, 0, z1) and map:IsDeployPointClear(Vector3(x1, 0, z1), nil, 1)
			end
	)

	if offset then
		local army = SpawnPrefab(weighted_random_choice(ARMY_CHOICES)).Transform:SetPosition(x + offset.x, 0, z + offset.z)
		if army then
			inst.components.leader:AddFollower(army)
		end
	end
end

local function SpawnArmies(inst)
	if inst.components.leader and inst.components.leader:CountFollowers() < MAX_ARMY then
		SpawnArmy(inst)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(3, 1.5)
	inst.Transform:SetFourFaced()
	inst.Transform:SetScale(4, 4, 4)
	MakeCharacterPhysics(inst, 100000, 0.5)

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("grubarmy")
	inst:AddTag("largecreature")
	inst:AddTag("epic")

	inst.AnimState:SetBank("giant_grub")
	inst.AnimState:SetBuild("giant_grub")
	inst.AnimState:PlayAnimation("idle", true)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(DAMAGE)
	inst.components.combat:SetRange(ATTACK_RANGE, HIT_RANGE)
	inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.canbeattackedfn = CanBeAttacked

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(HEALTH)

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = SPEED
	inst.components.locomotor.runspeed = SPEED
	inst.components.locomotor:SetShouldRun(true)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("chasni_giantgrub")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

	inst:AddComponent("leader")
	inst:AddComponent("groundpounder")
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 3
	inst.components.groundpounder.destructionRings = 2
	inst.components.groundpounder.platformPushingRings = 2
	inst.components.groundpounder.numRings = 3
	inst.components.groundpounder.noTags = { "FX", "NOCLICK", "DECOR", "INLIMBO", "grubarmy" }

	MakeTinyFreezableCharacter(inst)

	inst.OnEntitySleep = RemoveSound
	inst.OnRemoveEntity = RemoveSound
	inst.DoGroundPound = DoGroundPound
	inst.GoDigging = GoDigging

	inst:ListenForEvent("enterlimbo", RemoveSound)
	inst:ListenForEvent("attacked", OnAttacked)
	inst:DoPeriodicTask(7, SpawnArmies)

	inst:SetStateGraph("SGCZgiantgrub")
	inst:SetBrain(brain)

	return inst
end

return Prefab("chasni_giantgrub", fn, assets, prefabs)