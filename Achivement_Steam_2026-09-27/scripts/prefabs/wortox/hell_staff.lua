local assets =
{
	Asset("ANIM", "anim/hell_staff.zip"),
	Asset("ANIM", "anim/swap_hell_staff.zip"),
	Asset("ATLAS", "images/inventoryimages/hell_staff.xml"),
}

local assets_proj = {
	Asset("ANIM", "anim/staff_projectile.zip"),
}

local prefabs =
{
	"hell_staff_proj",
}

local USES = chasni_getitemconfig("hell_staff", "USE") or 100
local DAMAGE = chasni_getitemconfig("hell_staff", "DMG") or 17
local COMBO_DAMAGE = chasni_getitemconfig("hell_staff", "SDM") or 51
local MAX_REPAIR = chasni_getitemconfig("hell_staff", "REP") or 5
local RANGE = chasni_getitemconfig("hell_staff", "RNG") or 8
local function getDamage(inst, attacker, target)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	local mult = 1
	if owner and owner.components.inventory:EquipHasTag("hell_armor") and owner.components.inventory:EquipHasTag("hell_hat") then
		return COMBO_DAMAGE
	end
	return DAMAGE * mult
end

local function recoverDurability(inst)
	if inst and inst.components.finiteuses then
		inst.components.finiteuses:Repair(math.random(1, MAX_REPAIR))
	end
end

local function OnEquip(inst, owner)
	chasni_unquiprestrictedtag(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_hell_staff", "swap_hell_staff")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	inst._recover_durability = function() recoverDurability(inst) end

	owner:ListenForEvent("chasni_docriticalhit", inst._recover_durability)
	owner:ListenForEvent("chasni_dododge", inst._recover_durability)
end

local function OnUnequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	if inst._recover_durability then
		owner:RemoveEventCallback("chasni_docriticalhit", inst._recover_durability)
		owner:RemoveEventCallback("chasni_dododge", inst._recover_durability)
		inst._recover_durability = nil
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("hell_staff")
	inst.AnimState:SetBuild("hell_staff")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst._restrictedtag = "expertwortox3"

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst.entity:SetPristine()

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(getDamage)
	inst.components.weapon:SetRange(RANGE, RANGE+5)
	inst.components.weapon:SetProjectile("hell_staff_proj")
	inst.components.weapon:SetProjectileOffset(1)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "hell_staff"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/hell_staff.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst.castsound = "dontstarve/common/lava_arena/spell/fossilized"

	return inst
end

local function proj_fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("staff_projectile")
	inst.AnimState:PlayAnimation("ice_spin_loop", true)
	inst.AnimState:SetMultColour(0.5, 0.1, 0.1, 1)
	inst.Transform:SetScale(1.5, 1.5, 1.5)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("projectile")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(25)
	inst.components.projectile:SetOnHitFn(inst.Remove)
	inst.components.projectile:SetOnMissFn(inst.Remove)

	inst.persists = false

	return inst
end

return Prefab("hell_staff", fn, assets, prefabs),
Prefab("hell_staff_proj", proj_fn, assets_proj)
