local brain = require("brains/chasni_healingwardbrain")

local prefabs =
{
	"shadowwisp_fire"
}

local SPEED = chasni_getitemconfig("shadowwisp", "SPD") or 9
local DURATION = chasni_getitemconfig("shadowwisp", "DUR") or 180
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.Transform:SetTwoFaced()
	MakeTinyFlyingCharacterPhysics(inst, 1, 0.5)

	inst:AddTag("companion")
	inst:AddTag("notraptrigger")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

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

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

	if inst._fire == nil then
		local fx = SpawnPrefab("shadowwisp_fire")
		fx.entity:SetParent(inst.entity)
		fx.entity:AddFollower()
		fx:AttachLightTo(inst)
		fx:SetLightRange(4)
		inst._fire = fx
	end

	inst:SetBrain(brain)
	inst:SetStateGraph("SGCZhealingward")
	inst:DoTaskInTime(DURATION, inst.Remove)

	inst.persists = false

	return inst
end

return Prefab("shadowwisp", fn, nil, prefabs)
