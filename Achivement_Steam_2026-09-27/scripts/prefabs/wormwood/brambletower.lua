local assets =
{
	Asset("ANIM", "anim/bramble.zip"),
	Asset("ANIM", "anim/bramble1_build.zip"),
	Asset("ANIM","anim/bramble_core.zip"),
	Asset("ATLAS", "images/inventoryimages/brambletower.xml"),
}

local prefabs =
{
	"bramblefx_new",
	"bramblefx_ring",
}

local TAUNT_DIST = 7
local DAMAGE = chasni_getitemconfig("brambletower", "DMG") or 51
local HEALTH = chasni_getitemconfig("brambletower", "HP") or 1000
local HEALTH_REGEN = chasni_getitemconfig("brambletower", "RGN") or 5
local HEALTH_REGEN_TIME = 1
local TAUNT_TIME = 5
local TAUNT_MUST_TAGS = { "_combat", "locomotor" }
local TAUNT_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player", "companion", "notaunt" }
local function OnDeath(inst)
	inst.AnimState:PlayAnimation("wither")
	inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_bramble/wither")
end

local function IsTauntable(inst, target)
	return not (target.components.health and target.components.health:IsDead()) and target.components.combat and not target.components.combat:TargetIs(inst) and target.components.combat:CanTarget(inst)
end

local function corefn()
	local inst = CreateEntity()
	inst.entity:AddNetwork()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	MakeObstaclePhysics(inst, .5)
	inst.Physics:SetDontRemoveOnSleep(true)

	inst.Transform:SetTwoFaced()
	inst.AnimState:SetBank("bramble_core")
	inst.AnimState:SetBuild("bramble_core")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("bramble_resistant")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("combat")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(HEALTH)
	inst.components.health:StartRegen(HEALTH_REGEN, HEALTH_REGEN_TIME)

	inst:DoPeriodicTask(TAUNT_TIME, function()
		if not inst.components.health:IsDead() then
			local x, y, z = inst.Transform:GetWorldPosition()
			chasni_spawnprefab("bramblefx_ring", x, y, z)
			for i, v in ipairs(TheSim:FindEntities(x, y, z, TAUNT_DIST, TAUNT_MUST_TAGS, TAUNT_CANT_TAGS)) do
				if IsTauntable(inst, v) then
					v.components.combat:SetTarget(inst)
				end
			end
		end
	end)

	inst:ListenForEvent("attacked", function(owner, data)
		inst.AnimState:PlayAnimation("hit",false)
		if inst.components.health:IsDead() then
			inst.AnimState:PushAnimation("wither",false)
			inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_bramble/attack")
		else
			inst.AnimState:PushAnimation("idle",false)
		end

		local p = inst:GetPosition()
		local bramble = chasni_spawnprefab("bramblefx_new", p.x, p.y, p.z)
		bramble.damage = DAMAGE
	end)

	inst:ListenForEvent("death", OnDeath)

	return inst
end

return Prefab("brambletower", corefn, assets, prefabs),
MakePlacer("brambletower_placer", "bramble_core", "bramble_core", "idle")
