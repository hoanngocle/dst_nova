local assets =
{
	Asset("ANIM", "anim/hand_lens.zip"),
	Asset("ANIM", "anim/swap_hand_lens.zip"),
	Asset("ATLAS", "images/inventoryimages/hand_lens.xml"),
}
local assetspaper =
{
	Asset("ANIM", "anim/wetpaper.zip"),
	Asset("ATLAS", "images/inventoryimages/wetpaper.xml"),
}

local prefabs = investigateablelist

local DAMAGE = 1
local RESEARCH_COOLDOWN = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("magnifying_glass", "CD") or 4) -- 4 days
local function ResultThings(inst, target, pos)
	if pos and inst.savedprefab then
		local spawnedentity = chasni_spawnprefab(inst.savedprefab, pos.x, pos.y, pos.z)
		if spawnedentity.components.researchables then
			spawnedentity.components.researchables.spawned = true
			spawnedentity:AddTag("chasni_researchproduct")
		end
		inst:Remove()
	end
end

local function ResearchThings(inst, obj)
	if obj then
		local researchable = obj.components.researchables
		local owner = inst.components.inventoryitem:GetGrandOwner()
		if researchable and researchable.spawned == false then
			if researchable.researchtimer <= 0 then
				inst.savedprefab = obj.prefab or nil
				if inst.savedprefab then
					inst.components.spellcaster:SetSpellFn(ResultThings)
					if obj.components.researchables then
						obj.components.researchables.researchtimer = RESEARCH_COOLDOWN
						obj:StartUpdatingComponent(obj.components.researchables)

						inst.iswater = obj.components.researchables.iswater
						inst.components.spellcaster.canuseonpoint_water = inst.iswater
						inst.components.spellcaster.canuseonpoint = not inst.iswater
					end
				end
			else
				owner.components.talker:Say(GetString(owner, "CHASNI_MAGNIFYING_GLASS_FAIL_1"))
			end
		else
			owner.components.talker:Say(GetString(owner, "CHASNI_MAGNIFYING_GLASS_FAIL_2"))
		end
	end
end

local function onequip(inst, owner)
	chasni_unquiprestrictedtag(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_hand_lens", "swap_hand_lens")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function onsave(inst, data)
	data.savedprefab = inst.savedprefab or nil
	data.iswater = inst.iswater or nil
end

local function onload(inst, data)
	inst.savedprefab = data and data.savedprefab or nil
	if inst.savedprefab then
		inst.components.spellcaster:SetSpellFn(ResultThings)
	end
	if inst.iswater ~= nil then
		inst.components.spellcaster.canuseonpoint_water = inst.iswater
		inst.components.spellcaster.canuseonpoint = not inst.iswater
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("hand_lens")
	inst.AnimState:SetBuild("hand_lens")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("allow_action_on_impassable")
	inst:AddTag("chasni_magnifying_glass")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.2, 0.5)

	inst._restrictedtag = "expertwalter3"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DAMAGE)

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "hand_lens"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/hand_lens.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint_water = false
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster.canuseontargets = false
	inst.components.spellcaster:SetSpellFn(nil)

	inst.ResearchThings = ResearchThings
	inst.Implem = nil
	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end

local function fnpaper()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("wetpaper")
	inst.AnimState:SetBuild("wetpaper")
	inst.AnimState:PlayAnimation("idle", false)

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.2, 0.8)

	inst:AddTag("wetpaper")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "wetpaper"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/wetpaper.xml"

	return inst
end

return 
Prefab("chasni_magnifying_glass", fn, assets, prefabs),
Prefab("wetpaper", fnpaper, assetspaper)