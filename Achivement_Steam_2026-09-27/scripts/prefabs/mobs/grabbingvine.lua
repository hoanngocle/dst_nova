local brain = require "brains/generic_staticbrain"

local assets =
{
	Asset("ANIM", "anim/cave_exit_rope.zip"),
	Asset("ANIM", "anim/copycreep_build.zip"),
	Asset("SOUND", "sound/frog.fsb"),
}

local HEALTH = chasni_getmobconfig("chasni_grabbingvine", "HP") or 300
local DAMAGE = chasni_getmobconfig("chasni_grabbingvine", "DMG") or 20
local RETARGET_PERIOD = 1
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 4
local ATTACK_DIST = 4
local STOPATTACK_DIST = 6

local function retargetfn(inst)
	return FindEntity(inst, ATTACK_DIST, function(guy)
		if guy.components.combat and guy.components.health and not guy.components.health:IsDead() then
			return (guy.components.combat.target == inst or guy:HasTag("character") or guy:HasTag("monster") or guy:HasTag("animal")) and not guy:HasTag("flytrap") and not guy:HasTag("grabbingvine") and not (guy.prefab == inst.prefab) and not guy:HasTag("plantkin")
		end
	end)
end

local function KeepTarget(inst, target)
	if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
		local distsq = target:GetDistanceSqToInst(inst)
		return distsq < STOPATTACK_DIST * STOPATTACK_DIST
	else
		return false
	end
end

local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(1.5, .75)
	MakeObstaclePhysics(inst, .25)

	inst.AnimState:SetBank("exitrope")
	inst.AnimState:SetBuild("copycreep_build")
	inst.AnimState:PlayAnimation("idle_loop")

	inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	inst.Physics:CollidesWith(COLLISION.FLYERS)

	inst:AddTag("flying")
	inst:AddTag("grabbingvine")
	inst:AddTag("animal")
	inst:AddTag("hostile")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(DAMAGE)
	inst.components.combat:SetRange(ATTACK_RANGE)
	inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, retargetfn)
	inst.components.combat.onhitotherfn = function(inst, target) inst.components.thief:StealItem(target, nil, nil, true) end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(HEALTH)

	inst:AddComponent("inspectable")
	inst:AddComponent("thief")

	inst:SetStateGraph("SGCZgrabbingvine")
	inst:SetBrain(brain)

	MakeSmallBurnableCharacter(inst)
	MakeLargeFreezableCharacter(inst)

	return inst
end

return Prefab("chasni_grabbingvine", commonfn, assets, prefabs)
