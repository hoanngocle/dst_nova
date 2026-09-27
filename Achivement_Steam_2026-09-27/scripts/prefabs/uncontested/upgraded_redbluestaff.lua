local USES = 100
local CAST_USES = 10

local function red_onequip(inst, owner, _fn, ...)
	_fn(inst, owner, ...)
	owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_red_staff")
end

local function blue_onequip(inst, owner, _fn, ...)
	_fn(inst, owner, ...)
	owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_blue_staff")
end

local function red_spellfn(inst, target, position)
	local px, py, pz = chasni_getPos(position, target)
	local fx = SpawnPrefab("deer_fire_circle")
	fx.Transform:SetPosition(px, py, pz)
	fx:DoTaskInTime(4, fx.KillFX)
	inst.components.finiteuses:Use(CAST_USES)
end

local function blue_spellfn(inst, target, position)
	local px, py, pz = chasni_getPos(position, target)
	local fx = SpawnPrefab("deer_ice_circle")
	fx.Transform:SetPosition(px, py, pz)
	fx:DoTaskInTime(6, fx.KillFX)
	inst.components.finiteuses:Use(CAST_USES)
end

local function MakeAmulet(name, atlas, anim, spellfn, equipfn)
	local assets =
	{
		Asset("ANIM", "anim/staffs.zip"),
		Asset("ANIM", "anim/swap_staffs.zip"),
		Asset("ATLAS", "images/inventoryimages/"..atlas..".xml"),
	}

	local prefabs =
	{
		name,
	}

	local function reticule_target_function(inst)
		return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
	end

	local function fn()
		local inst = Prefabs[name].fn()
		inst.AnimState:SetBuild("staffs")
		inst.AnimState:PlayAnimation(anim)

		inst:AddComponent("reticule")
		inst.components.reticule.targetfn = reticule_target_function
		inst.components.reticule.ease = true
		inst.components.reticule.ispassableatallpoints = true

		if not TheWorld.ismastersim then
			return inst
		end

		if inst.components.inventoryitem then
			inst.components.inventoryitem.imagename = atlas
			inst.components.inventoryitem.atlasname = "images/inventoryimages/"..atlas..".xml"
		end

		if inst.components.equippable then
			local _onequipfn = inst.components.equippable.onequipfn
			inst.components.equippable:SetOnEquip(function(inst, owner, ...)
				equipfn(inst, owner, _onequipfn, ...)
			end)
		end

		if inst.components.finiteuses then
			inst.components.finiteuses:SetMaxUses(USES)
			inst.components.finiteuses:SetUses(USES)
		end

		inst:AddComponent("spellcaster")
		inst.components.spellcaster.canuseonpoint = true
		inst.components.spellcaster.canuseontargets = true
		inst.components.spellcaster:SetSpellFn(spellfn)

		return inst
	end

	return Prefab("upgraded_" .. name, fn, assets, prefabs)
end


return
MakeAmulet("firestaff", "hell_staff", "redstaff", red_spellfn, red_onequip),
MakeAmulet("icestaff", "hell_staff", "bluestaff", blue_spellfn, blue_onequip)
