local assets =
{
	Asset("ANIM", "anim/upgraded_amulets.zip"),
	Asset("ANIM", "anim/torso_upgraded_amulets.zip"),
	Asset("ATLAS", "images/inventoryimages/upgraded_greenamulet.xml"),
}

local COOLDOWN = (chasni_getitemconfig("upgraded_greenamulet", "DUR") or 10) * TUNING.TOTAL_DAY_TIME

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "torso_upgraded_amulets", "greenamulet")

	inst._upgraded_greenamulet_consumeingredients = function()
		local _owner = inst.components.inventoryitem:GetGrandOwner()
		if not inst.components.rechargeable:IsCharged() then
			return
		end
		if _owner and _owner.prefab == "winona" then
			inst.components.rechargeable:Discharge(COOLDOWN)
		else
			inst:Remove()
		end
	end
	inst:ListenForEvent("consumeingredients", inst._upgraded_greenamulet_consumeingredients, owner)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	inst:RemoveEventCallback("consumeingredients", inst._upgraded_greenamulet_consumeingredients, owner)
end

local function green_init(inst)
	if not inst.components.rechargeable:IsCharged() then
		inst:RemoveTag("upgraded_greenamulet")
	end
end

local function OnCharged(inst)
	inst:AddTag("upgraded_greenamulet")
end

local function OnDischarged(inst)
	inst:RemoveTag("upgraded_greenamulet")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("upgraded_amulets")
	inst.AnimState:SetBank("upgraded_amulets")
	inst.AnimState:PlayAnimation("greenamulet")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.125, 0.65)

	inst.foleysound = "dontstarve/movement/foley/jewlery"

	inst:AddTag("upgraded_greenamulet")
	inst:AddTag("rechargeable")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "upgraded_greenamulet"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_greenamulet.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.AMULET or EQUIPSLOTS.AMULETS or EQUIPSLOTS.NECK or EQUIPSLOTS.NECKS or EQUIPSLOTS.BODY

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:DoTaskInTime(1, green_init)

	return inst
end

return Prefab("upgraded_greenamulet", fn, assets)
