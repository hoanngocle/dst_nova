local assets =
{
	Asset("ANIM", "anim/wormwood_salve.zip"),
	Asset("ATLAS", "images/inventoryimages/wormwood_salve.xml"),
	Asset("IMAGE", "images/inventoryimages/wormwood_salve.tex"),
}

local HEAL = chasni_getitemconfig("wormwood_salve", "HEAL") or 40
local function SpawnFx(inst, fx_prefab)
	local x,y,z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab(fx_prefab)
	fx.Transform:SetNoFaced()
	fx.Transform:SetPosition(x,y,z)
end

local function OnHealFn(inst, target)
	if target.SoundEmitter then
		target.SoundEmitter:PlaySound("webber1/creatures/spider_cannonfodder/heal_fartcloud")
	end

	SpawnFx(target, "palmcone_leaf_fx_short")
	SpawnFx(target, "spider_heal_target_fx")
	if target.prefab == "wolfgang" and target.components.mightiness then
		target.components.mightiness:SetPercent(1, true, false)
		target.components.mightiness:DelayDrain(30 * 5)
	end
	if target.prefab == "wathgrithr" and target.components.singinginspiration then
		target.components.singinginspiration:SetPercent(1)
	elseif target.prefab == "wx78" and target.components.upgrademoduleowner then
		target.components.upgrademoduleowner:AddCharge(100)
	elseif target.prefab == "warly" and target.components.foodmemory then
		target.components.foodmemory.foods = {}
	elseif target.prefab == "wendy" and target.components.ghostlybond then
		target.components.ghostlybond:SetBondLevel(target.components.ghostlybond.maxbondlevel)
	elseif target.prefab == "wortox" and target.components.inventory then
		local headgear = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		if headgear and headgear.prefab == "hell_hat" and headgear.Evolve  then
			headgear:Evolve(420)
		end
		local bodygear = target.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
		if bodygear and bodygear.prefab == "hell_armor" and bodygear.Evolve  then
			bodygear:Evolve(420)
		end
	end
	if target.components.playerpoisonable then
		target.components.playerpoisonable:WearOff()
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.AnimState:SetBank("wormwood_salve")
	inst.AnimState:SetBuild("wormwood_salve")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "wormwood_salve"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/wormwood_salve.xml"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(HEAL)
	inst.components.healer.onhealfn = OnHealFn

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("wormwood_salve", fn, assets) 
