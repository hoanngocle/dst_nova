local assets =
{
	Asset("ANIM", "anim/arm_lower_cuff_pearl.zip"),
	Asset("ANIM", "anim/swap_pearl_arm_lower_cuff.zip"),

	Asset("ATLAS", "images/inventoryimages/arm_lower_cuff_pearl.xml"),
	Asset("IMAGE", "images/inventoryimages/arm_lower_cuff_pearl.tex"),
}

local assets_proj = {
	Asset("ANIM", "anim/chasni_projectile.zip"),
}

local USES = chasni_getitemconfig("chasni_pearl_bracelet", "USE") or 100
local RANGE = chasni_getitemconfig("chasni_pearl_bracelet", "RNG") or 8
local CD_REDUCTION = chasni_getitemconfig("chasni_pearl_bracelet", "CDR") or 0.2

-- Handle wolfgang and woodie
local function onnewstate_gloves(inst)
	local handslot = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if handslot:HasTag("gloves") and inst.sg:HasStateTag("nomorph") and handslot.RefreshLook then
		handslot.RefreshLook(handslot, inst)
	end
end

local function onequippedskinitem_gloves(owner)
	local handslot = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if handslot and (handslot:HasTag("gloves") or handslot:HasTag("bracelet")) and owner.components.skinner and handslot.RefreshLook then
		if owner.components.skinner.clothing["hand"] and owner.components.skinner.clothing["hand"] ~= "" then
			handslot._originalhandskin = owner.components.skinner.clothing["hand"]
		end

		owner:DoTaskInTime(0.5, function() handslot.RefreshLook(handslot, owner) end)
	end
end

local function RefreshLook(inst, owner)
	if owner.components.skinner.clothing["hand"] and owner.components.skinner.clothing["hand"] ~= "" then
		inst._originalhandskin = owner.components.skinner.clothing["hand"]
		owner.components.skinner.clothing["hand"] = ""
		owner.components.skinner:ClearClothing("hand")
	end

	if inst._originalhandskin == nil then
		if owner.components.skinner.clothing["body"] ~= "" then
			inst._originalbodyskin = owner.components.skinner.clothing["body"]
		else
			inst._originalbodyskin = nil
		end
	end

	owner.AnimState:ShowSymbol("arm_lower_cuff")
	owner.AnimState:OverrideSymbol("arm_lower_cuff", "swap_pearl_arm_lower_cuff", "arm_lower_cuff")

	owner:ListenForEvent("equipskinneditem", onequippedskinitem_gloves)
	owner:ListenForEvent("unequipskinneditem", onequippedskinitem_gloves)
	owner:ListenForEvent("newstate", onnewstate_gloves)
end

local function onequip(inst, owner)
	RefreshLook(inst, owner)

	owner.AnimState:ClearOverrideSymbol("swap_object")

	if inst.hideARMCarry == nil then
		inst.hideARMCarry = inst:DoPeriodicTask(FRAMES, function()
			owner.AnimState:Hide("ARM_carry")
			owner.AnimState:Show("ARM_normal")
		end)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("arm_lower_cuff")

	if inst._originalhandskin then
		owner.components.skinner.clothing["hand"] = inst._originalhandskin
		owner.components.skinner:SetSkinMode()
		inst._originalhandskin = nil
	else
		if inst._originalbodyskin then
			owner.components.skinner.clothing["body"] = inst._originalbodyskin
			owner.components.skinner:SetSkinMode()
			inst._originalbodyskin = nil
		end
	end

	if inst.hideARMCarry then
		inst.hideARMCarry:Cancel()
		inst.hideARMCarry = nil
	end

	owner:RemoveEventCallback("equipskinneditem", onequippedskinitem_gloves)
	owner:RemoveEventCallback("unequipskinneditem", onequippedskinitem_gloves)
	owner:RemoveEventCallback("newstate", onnewstate_gloves)
end

local function getDamage(inst, attacker, target)
	return attacker and attacker.components.levelsystem and attacker.components.levelsystem.petdamagelevelmax and (attacker.components.levelsystem.petdamagelevelmax * 0.5) or 0
end

local function onattack(weapon, attacker, target)
	local pet = attacker and attacker.components.petleash and attacker.components.petleash:GetChasniCritter()
	if pet and pet.attack_cd and pet.attack_cd > 0 then
		pet.attack_cd = pet.attack_cd - CD_REDUCTION
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.AnimState:SetBank("arm_lower_cuff_pearl")
	inst.AnimState:SetBuild("arm_lower_cuff_pearl")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("punch")
	inst:AddTag("bracelet")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(getDamage)
	inst.components.weapon:SetOnAttack(onattack)
	inst.components.weapon:SetRange(RANGE, RANGE+5)
	inst.components.weapon:SetProjectile("chasni_pearl_bracelet_proj")

	inst:AddComponent("inspectable")
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "arm_lower_cuff_pearl"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/arm_lower_cuff_pearl.xml"

	MakeHauntableLaunch(inst)

	inst:DoTaskInTime(0, function()
		if inst.components.inventoryitem and inst.components.inventoryitem.owner and inst.components.equippable:IsEquipped() then
			local owner = inst.components.inventoryitem.owner
			RefreshLook(inst, owner)
		end
	end)

	inst._originalhandskin = nil
	inst._originalbodyskin = nil

	inst.RefreshLook = RefreshLook

	return inst
end

local function proj_fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("chasni_projectile")
	inst.AnimState:SetBuild("chasni_projectile")
	inst.AnimState:PlayAnimation("pearl", true)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("projectile")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(8)
	inst.components.projectile:SetHitDist(0.3)
	inst.components.projectile:SetOnHitFn(inst.Remove)
	inst.components.projectile:SetOnMissFn(inst.Remove)
	inst.components.projectile:SetLaunchOffset({x=0,y=1,z=0})

	inst.persists = false

	return inst
end

return 
Prefab("chasni_pearl_bracelet", fn, assets),
Prefab("chasni_pearl_bracelet_proj", proj_fn, assets_proj)
