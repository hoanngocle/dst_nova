local assets =
{
	Asset("ANIM", "anim/upgraded_amulets.zip"),
	Asset("ANIM", "anim/torso_upgraded_amulets.zip"),
	Asset("ATLAS", "images/inventoryimages/upgraded_yellowamulet.xml"),
}

local USES = chasni_getitemconfig("water_crabamulet", "USES") or 100
local HEAL = chasni_getitemconfig("water_crabamulet", "HEAL") or 1
local TICK = chasni_getitemconfig("water_crabamulet", "TICK") or 1
local WET = chasni_getitemconfig("water_crabamulet", "WET") or 5
local REPAIR = chasni_getitemconfig("water_crabamulet", "REP") or 1

local function healowner(inst, owner)
	if owner.components.health and owner.components.health:IsHurt() and inst.components.finiteuses and inst.components.finiteuses:GetPercent() > 0 then
		owner.components.health:DoDelta(HEAL, false, "redamulet")
		inst.components.finiteuses:Use(1)
	end
	if owner.components.moisture and owner.components.moisture:GetMoisturePercent() > 0 and inst.components.finiteuses and inst.components.finiteuses:GetPercent() < 1 then
		if owner.components.moisture:GetMoisture() >= WET then
			inst.components.finiteuses:Repair(REPAIR)
			owner.components.moisture:DoDelta(-WET, true)
		end
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "torso_upgraded_amulets", "yellowamulet")
	inst._healingtask = inst:DoPeriodicTask(TICK, healowner, nil, owner)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	if inst._healingtask ~= nil then
		inst._healingtask:Cancel()
		inst._healingtask = nil
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("upgraded_amulets")
	inst.AnimState:SetBank("upgraded_amulets")
	inst.AnimState:PlayAnimation("yellowamulet")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.125, 0.65)

	inst.foleysound = "dontstarve/movement/foley/jewlery"

	inst:AddTag("charges_percentage")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "upgraded_yellowamulet"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_yellowamulet.xml"

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.AMULET or EQUIPSLOTS.AMULETS or EQUIPSLOTS.NECK or EQUIPSLOTS.NECKS or EQUIPSLOTS.BODY

	return inst
end

return Prefab("water_crabamulet", fn, assets)
