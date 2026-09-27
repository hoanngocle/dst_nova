local assets =
{
	Asset("ANIM", "anim/upgraded_amulets.zip"),
	Asset("ANIM", "anim/torso_upgraded_amulets.zip"),
	Asset("ATLAS", "images/inventoryimages/upgraded_redamulet.xml"),
}

local FUEL = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("upgraded_redamulet", "PSPN") or 3)

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "torso_upgraded_amulets", "redamulet")
	owner:AddTag("chasni_heathealing")

	inst.components.fueled:StartConsuming()
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	owner:RemoveTag("chasni_heathealing")

	inst.components.fueled:StopConsuming()
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("upgraded_amulets")
	inst.AnimState:SetBank("upgraded_amulets")
	inst.AnimState:PlayAnimation("redamulet")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.125, 0.65)

	inst.foleysound = "dontstarve/movement/foley/jewlery"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "upgraded_redamulet"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_redamulet.xml"

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.MAGIC
	inst.components.fueled:InitializeFuelLevel(FUEL)
	inst.components.fueled:SetDepletedFn(inst.Remove)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.AMULET or EQUIPSLOTS.AMULETS or EQUIPSLOTS.NECK or EQUIPSLOTS.NECKS or EQUIPSLOTS.BODY

	return inst
end

return Prefab("upgraded_amulet", fn, assets)
