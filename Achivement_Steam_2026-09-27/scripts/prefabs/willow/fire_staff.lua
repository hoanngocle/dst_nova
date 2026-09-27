local assets =
{
	Asset("ANIM", "anim/fire_staff.zip"),
	Asset("ATLAS", "images/inventoryimages/fire_staff.xml"),
}

local prefabs =
{
	"fire_staff_meteor",
	"fire_perk_light",
}

local USES = chasni_getitemconfig("fire_staff", "USE") or 100
local DAMAGE = chasni_getitemconfig("fire_staff", "DMG") or 17
local METEOR_DAMAGE = chasni_getitemconfig("fire_staff", "MDM") or 11
local HEAT = chasni_getitemconfig("fire_staff", "HEAT") or 100
local COOLDOWN_METEOR = chasni_getitemconfig("fire_staff", "CDME") or 0
local COOLDOWN_EXTINGUISH = chasni_getitemconfig("fire_staff", "CDEX") or 0
local EXTINGUISH_RADIUS = chasni_getitemconfig("fire_staff", "EXRAD") or 16
local CHARGE_MULT = chasni_getitemconfig("fire_staff", "CRG") or 1
local FIRE_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "lighter" }
local FIRE_ONEOF_TAGS = { "fire", "smolder" }

local CANT_HAVE_SPELL_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR"}
local function reticule_target_function(inst)
	return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function createFireStorm(inst, target, pos)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if pos then
		if owner and chasni_hastag(inst, owner) then
			local uses = inst.components.finiteuses and inst.components.finiteuses:GetUses() or 0
			if uses > 0 then
				if not TheNet:GetPVPEnabled() then
					table.insert(CANT_HAVE_SPELL_TAGS, "player")
					table.insert(CANT_HAVE_SPELL_TAGS, "companion")
					table.insert(CANT_HAVE_SPELL_TAGS, "ally")
				end
				SpawnPrefab("fire_staff_meteor"):InitState(owner, inst, pos, nil, CANT_HAVE_SPELL_TAGS, uses * METEOR_DAMAGE)
				inst.components.rechargeable:Discharge(COOLDOWN_METEOR)
				inst.components.finiteuses:Use(uses)
			else
				owner.components.talker:Say(GetString(owner, "FIRE_STAFF_FAIL_1"))
			end
		else
			owner.components.talker:Say(GetString(owner, "FIRE_STAFF_FAIL_2"))
		end
	else  -- casted from inventory
		local x, y, z = owner.Transform:GetWorldPosition()
		local fires = TheSim:FindEntities(x, y, z, EXTINGUISH_RADIUS, nil, FIRE_CANT_TAGS, FIRE_ONEOF_TAGS)
		if #fires > 0 then
			local fire_count = 0
			for i, fire in ipairs(fires) do
				if fire.components.burnable then
					fire_count = fire_count + 1
					fire.components.burnable:Extinguish(true, 0)
				end
			end
			inst.components.finiteuses:Repair(fire_count * CHARGE_MULT)
			inst.components.rechargeable:Discharge(COOLDOWN_EXTINGUISH)
		end
	end
end

local function OnEquip(inst, owner)
	chasni_unquiprestrictedtag(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_fire_staff", "swap_sword_lunarplant")
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

local function OnCharged(inst)
	inst.components.spellcaster:SetSpellFn(createFireStorm)
end

local function OnDischarged(inst)
	inst.components.spellcaster:SetSpellFn(nil)
end

local function OnSave(inst, data)
	data.uses = inst.components.finiteuses.current
end

local function OnLoad(inst, data)
	if data and data.uses then
		inst.components.finiteuses:SetUses(data.uses)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddLight()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.AnimState:SetBank("fire_staff")
	inst.AnimState:SetBuild("fire_staff")
	inst.AnimState:PlayAnimation("idle", true)

	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(0.75)

	inst:AddTag("allow_action_on_impassable")
	inst:AddTag("charges_percentage")
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
	inst._fxswap = SpawnPrefab("fire_staff_fx")
	inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
	inst._fxswap.AnimState:SetFrame(frame)
	chasni_equipanimatedswaphand(inst, nil)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DAMAGE)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(0)
	inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "fire_staff"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/fire_staff.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint_water = true
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster.canusefrominventory = true
	inst.components.spellcaster:SetSpellFn(createFireStorm)

	inst.castsound = "dontstarve/common/lava_arena/spell/meteor"

	inst:AddComponent("heater")
	inst.components.heater.equippedheat = HEAT

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

local function fxfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("fire_staff")
	inst.AnimState:SetBuild("fire_staff")
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

return Prefab("fire_staff", fn, assets, prefabs),
Prefab("fire_staff_fx", fxfn, assets)
