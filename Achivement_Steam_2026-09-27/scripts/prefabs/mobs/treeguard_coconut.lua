local assets =
{
	Asset("ANIM", "anim/coconut_cannon.zip"),
}

local prefabs =
{
	"warningshadow",
}

local DAMAGE = chasni_getmobconfig("chasni_treeguard", "CDMG") or 110
local function ReticuleTargetFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	for r = 6.5, 3.5, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function OnHitSnow(inst, attacker)
	SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 3, nil, { "shadow", "INLIMBO" })
	if #ents > 0 then
		for i, v in ipairs(ents) do
			if v:IsValid() and not v:IsInLimbo() then
				if v.components.sleeper and v.components.sleeper:IsAsleep() then
					v.components.sleeper:WakeUp()
				end

				if v.components.combat and v ~= inst and v.prefab ~= "chasni_treeguard" then
					v.components.combat:GetAttacked(attacker, 100)
				end
			end
		end
	end

	inst.components.groundpounder:GroundPound()
	inst:Remove()
end

local function onthrown(inst)
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst.AnimState:PlayAnimation("throw", true)

	inst.Physics:SetMass(1)
	inst.Physics:SetCapsule(0.2, 0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function onremove(inst)
	if inst.TrackHeight then
		inst.TrackHeight:Cancel()
		inst.TrackHeight = nil
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("coconut_cannon")
	inst.AnimState:SetBuild("coconut_cannon")
	inst.AnimState:PlayAnimation("throw", true)

	inst:AddTag("thrown")
	inst:AddTag("projectile")

	inst:AddComponent("reticule")
	inst.components.reticule.targetfn = ReticuleTargetFn
	inst.components.reticule.ease = true

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end
	inst.persists = false

	inst:AddComponent("locomotor")

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(15)
	inst.components.complexprojectile:SetGravity(-35)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 0, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrown)
	inst.components.complexprojectile:SetOnHit(OnHitSnow)

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 2
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 1
	inst.components.groundpounder.ring_fx_scale = 0.15
	inst.components.groundpounder.groundpoundfx = "explode_small"
	inst.components.groundpounder.groundpoundringfx = "explode_small"

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(DAMAGE)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DAMAGE)
	inst.components.weapon:SetRange(20, 10)

	inst.OnRemoveEntity = onremove

	return inst
end

return Prefab("chasni_treeguard_coconut", fn, assets, prefabs)
