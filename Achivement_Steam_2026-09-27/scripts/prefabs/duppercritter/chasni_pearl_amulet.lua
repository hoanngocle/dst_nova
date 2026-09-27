local assets =
{
	Asset("ANIM", "anim/upgraded_b_amulets.zip"),
	Asset("ANIM", "anim/torso_upgraded_b_amulets.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_pearl_amulet.xml"),
}

local CD_REDUCTION = chasni_getitemconfig("chasni_pearlamulet", "CDR") or 1
local EPIC_CD_REDUCTION = chasni_getitemconfig("chasni_pearlamulet", "ECDR") or 10
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "torso_upgraded_b_amulets", "orangeamulet")

	inst._onkill = function(_, data)
		if data and data.victim and chasni_isValidVictim(data.victim) then
			local pet = owner and owner.components.petleash and owner.components.petleash:GetChasniCritter()
			local reduction = data.victim:HasTag("epic") and EPIC_CD_REDUCTION or CD_REDUCTION
			if pet then
				if pet._castdelaytime and pet._castdelaytime > 0 then
					pet._castdelaytime = pet._castdelaytime - reduction
				end
				if pet.spell_cd and pet.spell_cd > 0 then
					pet.spell_cd = pet.spell_cd - reduction
				end
			end
		end
	end
	owner:ListenForEvent("killed", inst._onkill)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")

	if inst._onkill then
		owner:RemoveEventCallback("killed", inst._onkill)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("upgraded_b_amulets")
	inst.AnimState:SetBank("upgraded_b_amulets")
	inst.AnimState:PlayAnimation("orangeamulet")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.125, 0.65)

	inst.foleysound = "dontstarve/movement/foley/jewlery"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "chasni_pearl_amulet"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_pearl_amulet.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.AMULET or EQUIPSLOTS.AMULETS or EQUIPSLOTS.NECK or EQUIPSLOTS.NECKS or EQUIPSLOTS.BODY

	return inst
end

return Prefab("chasni_pearlamulet", fn, assets)
