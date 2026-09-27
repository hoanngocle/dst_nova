local assets =
{
	Asset("ANIM", "anim/chasni_repairkit.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_repairkit.xml"),
	Asset("IMAGE", "images/inventoryimages/chasni_repairkit.tex"),
}

local COOLDOWN = (chasni_getitemconfig("chasni_repairkit", "CD") or 3) * TUNING.TOTAL_DAY_TIME
local function onsewn(inst, target, doer)
	doer:PushEvent("repair")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("chasni_repairkit")
	inst.AnimState:SetBuild("chasni_repairkit")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst:AddTag("rechargeable")
	inst:AddTag("sew_any")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("inspectable")
	inst:AddComponent("rechargeable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "chasni_repairkit"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_repairkit.xml"

	inst:AddComponent("sewing")
	inst.components.sewing.repair_value = 1
	inst.components.sewing.onsewn = onsewn
	inst.components.sewing.rechargeablecooldown = COOLDOWN

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("chasni_repairkit", fn, assets) 
