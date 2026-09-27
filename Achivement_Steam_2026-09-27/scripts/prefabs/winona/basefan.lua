local assets =
{
	Asset("IMAGE", "images/prefabs/basefan.tex"),
	Asset("ATLAS", "images/prefabs/basefan.xml"),
	Asset("IMAGE", "images/minimap/basefan.tex"),
	Asset("ATLAS", "images/minimap/basefan.xml"),
	Asset("SOUNDPACKAGE", "sound/basefan.fev"),
	Asset("SOUND", "sound/basefan_bank00.fsb"),
	Asset("ANIM", "anim/basefan.zip"),
	Asset("ANIM", "anim/firefighter_placement.zip"),
	Asset("INV_IMAGE", "basefan"),
}

local function ontimerdone(inst, data)
	if data.name == "Reload" then
		inst.canFire = true
	end
end

local function TurnOff(inst, instant)
	inst.on = false
	inst:RemoveTag("blows_air")
	if instant then
		inst.sg:GoToState("idle_off")
	else
		inst.sg:GoToState("turn_off")
	end
end

local function TurnOn(inst, instant)
	inst.on = true
	inst:AddTag("blows_air")

	if instant then
		inst.sg:GoToState("idle_on")
	else
		inst.sg:GoToState("turn_on")
	end
end

local function onhammered(inst)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end

	inst.SoundEmitter:KillSound("idleloop")
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")

	inst:Remove()
end

local function onhit(inst)
	if not inst:HasTag("burnt") then
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("hit")
		end
	end
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("firesuppressor_idle")
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

local function CanInteract()
	return true
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.MiniMapEntity:SetPriority(5)
	inst.MiniMapEntity:SetIcon("basefan.tex")

	inst.AnimState:SetBank("basefan")
	inst.AnimState:SetBuild("basefan")
	inst.AnimState:PlayAnimation("off")

	MakeObstaclePhysics(inst, 1)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst.on = false

	inst:AddComponent("inspectable")
	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine.caninteractfn = CanInteract
	inst.components.machine.cooldowntime = 0.5

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:SetStateGraph("SGCZbasefan")

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.OnEntitySleep = OnEntitySleep

	return inst
end

local PLACER_SCALE = 1.55

local function placer_postinit_fn(inst)
	local placer2 = CreateEntity()
	placer2.entity:SetCanSleep(false)
	placer2.persists = false

	placer2.entity:AddTransform()
	placer2.entity:AddAnimState()

	placer2:AddTag("CLASSIFIED")
	placer2:AddTag("NOCLICK")
	placer2:AddTag("placer")

	local s = 1 / PLACER_SCALE
	placer2.Transform:SetScale(s, s, s)

	placer2.AnimState:SetBank("basefan")
	placer2.AnimState:SetBuild("basefan")
	placer2.AnimState:PlayAnimation("off")
	placer2.AnimState:SetLightOverride(1)

	placer2.entity:SetParent(inst.entity)

	inst.components.placer:LinkEntity(placer2)
end

return Prefab("chasni_basefan", fn, assets),
MakePlacer("chasni_basefan_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, PLACER_SCALE, nil, nil, placer_postinit_fn)