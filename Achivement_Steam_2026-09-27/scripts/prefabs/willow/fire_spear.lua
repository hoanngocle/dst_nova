local assets =
{
	Asset("ANIM", "anim/fire_spear.zip"),
	Asset("ATLAS", "images/inventoryimages/fire_spear.xml"),
}

local USES = chasni_getitemconfig("fire_spear", "USE") or 300
local REPAIR = chasni_getitemconfig("fire_spear", "USE") or 3
local DAMAGE = chasni_getitemconfig("fire_spear", "BDM") or 34
local FIRE_DAMAGE = chasni_getitemconfig("fire_spear", "FDM") or 85
local HEAT = chasni_getitemconfig("fire_spear", "HEAT") or 100
local COOLDOWN = chasni_getitemconfig("fire_spear", "CD") or 8
local function setPos(position,target)
	if target then
		return Vector3(target.Transform:GetWorldPosition())
	else
		return position
	end
end

local function DoFireDash(inst, target, position)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner == nil then
		return
	end
	owner:PushEvent("combat_lunge", {targetpos = setPos(position, target), weapon = inst})
end

local function reticule_target_function(inst)
	return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function OnAttack(inst, attacker, target, projectile)
	if chasni_hastag2(attacker, "expertwillow3") then
		if target and target:IsValid() and attacker and attacker:IsValid() and target:HasTag("fire") then
			local pos = Vector3(target.Transform:GetWorldPosition())
			chasni_spawnprefab("halloween_firepuff_1", pos.x, pos.y, pos.z)
			if target.components.health then
				target.components.health:DoFireDamage(FIRE_DAMAGE, attacker)
				if inst.components.finiteuses then
					inst.components.finiteuses:Repair(REPAIR)
				end
			end
		end
	end
end

local function OnCharged(inst)
	inst.components.spellcaster:SetSpellFn(DoFireDash)
end

local function OnDischarged(inst)
	inst.components.spellcaster:SetSpellFn(nil)
end

local function OnEquip(inst, owner)
	chasni_unquiprestrictedtag(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_fire_spear", "swap_sword_lunarplant")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	chasni_equipanimatedswaphand(inst, owner)

	if chasni_hastag(inst, owner) then
		if inst._light == nil or not inst._light:IsValid() then
			inst._light = SpawnPrefab("fire_perk_light")
		end
		inst._light.entity:SetParent(owner.entity)
	else
		if inst._light then
			if inst._light:IsValid() then
				inst._light:Remove()
			end
			inst._light = nil
		end
	end
end

local function OnUnequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	chasni_equipanimatedswaphand(inst, nil)

	if inst._light then
		if inst._light:IsValid() then
			inst._light:Remove()
		end
		inst._light = nil
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddLight()
	inst.entity:AddSoundEmitter()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.AnimState:SetBank("fire_spear")
	inst.AnimState:SetBuild("fire_spear")
	inst.AnimState:PlayAnimation("idle")

	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(0.75)

	inst:AddTag("sharp")
	inst:AddTag("fire_spear")
	inst:AddTag("aoeweapon_lunge")
	inst:AddTag("HASHEATER")
	inst:AddTag("rechargeable")

	inst:AddComponent("reticule")
	inst.components.reticule.targetfn = reticule_target_function
	inst.components.reticule.ease = true
	inst.components.reticule.ispassableatallpoints = true

	inst._restrictedtag = "expertwillow3"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
	inst.AnimState:SetFrame(frame)
	inst._fxswap = SpawnPrefab("fire_spear_fx")
	inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
	inst._fxswap.AnimState:SetFrame(frame)
	chasni_equipanimatedswaphand(inst, nil)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DAMAGE)
	inst.components.weapon:SetOnAttack(OnAttack)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "fire_spear"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/fire_spear.xml"

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint_water = true
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster.canonlyuseoncombat = true
	inst.components.spellcaster:SetSpellFn(DoFireDash)

	inst:AddComponent("aoeweapon_lunge")
	inst.components.aoeweapon_lunge.chasni_lunge = true
	inst.components.aoeweapon_lunge.chasni_cooldown = COOLDOWN

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("heater")
	inst.components.heater.equippedheat = HEAT

	return inst
end

local function lightfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.Light:SetRadius(2)
	inst.Light:SetFalloff(.7)
	inst.Light:SetIntensity(.65)
	inst.Light:SetColour(223 / 255, 169 / 255, 69 / 255)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

local function fxfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("fire_spear")
	inst.AnimState:SetBuild("fire_spear")
	inst.AnimState:PlayAnimation("swap_energy", true)
	inst.AnimState:SetSymbolBloom("pb_energy_loop01")
	inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("colouradder")

	inst.persists = false

	return inst
end

return 
Prefab("fire_spear", fn, assets, { "fire_perk_light", "halloween_firepuff_1" }),
Prefab("fire_perk_light", lightfn),
Prefab("fire_spear_fx", fxfn, assets)

