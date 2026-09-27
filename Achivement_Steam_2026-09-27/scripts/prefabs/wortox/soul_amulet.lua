local assets =
{
	Asset("ANIM", "anim/upgraded_amulets.zip"),
	Asset("ANIM", "anim/torso_upgraded_amulets.zip"),
	Asset("ATLAS", "images/inventoryimages/upgraded_orangeamulet.xml"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "torso_upgraded_amulets", "orangeamulet")

	owner:AddTag("soulamulet")
	owner._soulamulet_spiritdamage = inst.spirit and inst.spirit:value() or 0
	inst._onkill = function(_, data)
		if data and data.victim and chasni_isValidVictim(data.victim) and data.victim:HasTag("epic") then
			local spirit = inst.spirit and inst.spirit:value() or 0
			inst.spirit:set(spirit + 1)
			owner._soulamulet_spiritdamage = spirit + 1
		end
	end
	owner:ListenForEvent("killed", inst._onkill)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")

	owner:RemoveTag("soulamulet")
	owner._soulamulet_spiritdamage = nil
	if inst._onkill then
		owner:RemoveEventCallback("killed", inst._onkill)
	end
end

local function SetSpirit(inst, spirit)
	if spirit then
		inst.spirit:set(spirit)
	else
		inst.spirit:set(0)
	end
end

local function OnSave(inst, data)
	data.spirit = inst.spirit:value()
end

local function OnLoad(inst, data)
	if data and data.spirit then
		SetSpirit(inst, data.spirit)
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
	inst.AnimState:PlayAnimation("orangeamulet")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.125, 0.65)

	inst.foleysound = "dontstarve/movement/foley/jewlery"

	inst.spirit = net_uint(inst.GUID, "soulamulet.spirit", "spiritdirty")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "upgraded_orangeamulet"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_orangeamulet.xml"

	-- >>>> This is hack so itemtiles shows... :(
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(10)
	inst.components.finiteuses:SetUses(10)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.AMULET or EQUIPSLOTS.AMULETS or EQUIPSLOTS.NECK or EQUIPSLOTS.NECKS or EQUIPSLOTS.BODY

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("soulamulet", fn, assets)
