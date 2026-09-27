local assets =
{
	Asset("ANIM", "anim/boat_propelomatic.zip"),
	Asset("ATLAS", "images/inventoryimages/propelomatic.xml"),
}

local prefabs =
{
	"collapse_small",
}

local SALTLICKER_MUST_TAGS = { "saltlicker" }
local SALTLICKER_CANT_TAGS = { "INLIMBO" }
local SALTLICK_CHECK_DIST = 30
local SALTLICK_USES = 1200
local function AlertNearbyCritters(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z, SALTLICK_CHECK_DIST, SALTLICKER_MUST_TAGS, SALTLICKER_CANT_TAGS)
	for i,ent in ipairs(ents) do
		ent:PushEvent("saltlick_placed", { inst = inst })
	end
end

local function OnFinished(inst)
	inst.components.machine:TurnOff()
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	inst:Remove()
end

local function onhit(inst)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle", true)
end

local function TurnOn(inst)
	inst.AnimState:PlayAnimation("on_pre")
	inst.AnimState:PushAnimation("on_loop", true)
	inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_propel/loop", "on_loop", 0.3)

	inst.components.finiteuses:SetUses(SALTLICK_USES)
	AlertNearbyCritters(inst)
end

local function TurnOff(inst)
	inst.AnimState:PlayAnimation("cooldown_pre")
	inst.AnimState:PushAnimation("idle", true)
	inst.SoundEmitter:KillSound("on_loop")

	inst.components.finiteuses:SetUses(0)
end

local function CanInteract(inst)
	if inst.components.machine.ison then
		return false
	end
	return true
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end

	data.on = inst.on
end

local function onload(inst, data)
	if data and data.burnt and inst.components.burnable and inst.components.burnable.onburnt then
		inst.components.burnable.onburnt(inst)
	end

	inst.on = data.on and data.on or false
	if data.on then
		inst.components.machine:TurnOn()
	else
		inst.components.machine:TurnOff()
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("propelomatic")
	inst.AnimState:SetBuild("boat_propelomatic")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("structure")
	inst:AddTag("saltlick")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	inst:AddComponent("inspectable")

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine.caninteractfn = CanInteract
	inst.components.machine.cooldowntime = 0.5

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(SALTLICK_USES)
	inst.components.finiteuses:SetUses(SALTLICK_USES)
	inst.components.finiteuses:SetOnFinished(OnFinished)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end

return Prefab("propelomatic", fn, assets, prefabs),
MakePlacer("propelomatic_placer", "propelomatic", "boat_propelomatic", "idle")