local assets =
{
	Asset("ANIM", "anim/medicalkit.zip"),
	Asset("ATLAS", "images/inventoryimages/medicalkit.xml"),
	Asset("IMAGE", "images/inventoryimages/medicalkit.tex"),
}

local COOLDOWN = (chasni_getitemconfig("medicalkit", "CD") or 1) * TUNING.TOTAL_DAY_TIME
local HEAL = chasni_getitemconfig("medicalkit", "HEAL") or 20
local function SpawnFx(inst, fx_prefab)
	local x,y,z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab(fx_prefab)
	fx.Transform:SetNoFaced()
	fx.Transform:SetPosition(x,y,z)
end

local function OnHealFn(inst, target)
	SpawnFx(target, "sparklefx")
	if target.components.playerpoisonable then
		target.components.playerpoisonable:WearOff()
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("medicalkit")
	inst.AnimState:SetBuild("medicalkit")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst:AddTag("rechargeable")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("inspectable")
	inst:AddComponent("rechargeable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "medicalkit"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/medicalkit.xml"

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(HEAL)
	inst.components.healer.onhealfn = OnHealFn
	inst.components.healer.rechargeablecooldown = COOLDOWN

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("medicalkit", fn, assets) 
