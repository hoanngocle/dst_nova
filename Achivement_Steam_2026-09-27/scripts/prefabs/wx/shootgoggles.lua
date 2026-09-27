local assets =
{
	Asset("ANIM", "anim/hat_gogglesshoot.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_gogglesshoot.xml"),
	Asset("IMAGE", "images/inventoryimages/chasni_gogglesshoot.tex"),
}
local assets_charge =
{
	Asset("ANIM", "anim/bishop_projectile_yellow.zip"),
	Asset("SOUND", "sound/chess.fsb"),
}

local prefabs = {
	"chasni_gogglesshoot_charge",
}

local BASE_DAMAGE = chasni_getitemconfig("gogglesshoot", "DMG") or 17
local USES = chasni_getitemconfig("gogglesshoot", "DMG") or 40
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", "hat_gogglesshoot", "swap_hat")
	owner.AnimState:Show("HAT")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD_HAIR")
	end

	if owner and owner.components.upgrademoduleowner then
		SpawnPrefab("electrichitsparks"):AlignToTarget(inst, owner, true)
		owner.components.upgrademoduleowner:AddCharge(-3)
	end
	owner:ListenForEvent("attacked", inst._onattacked)
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("HAT")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAIR")
	end

	owner:RemoveEventCallback("attacked", inst._onattacked)
end

local function getdamage(inst, attacker, target)
	if attacker and attacker.prefab == "wx78" and attacker.components.upgrademoduleowner then
		return attacker.components.upgrademoduleowner:GetModuleTypeCount("taser") * 10 +
				attacker.components.upgrademoduleowner:GetModuleTypeCount("heat") * 7 +
				attacker.components.upgrademoduleowner:GetModuleTypeCount("light") * 5 +
				attacker:GetEnergyLevel() * 3 +
				BASE_DAMAGE
	end
	return 1
end

local function onattack_shoot(inst, attacker, target)
	if inst and attacker and attacker.components.upgrademoduleowner and inst.components.finiteuses and inst.components.finiteuses:GetPercent() == 0 then
		attacker.components.upgrademoduleowner:AddCharge(-1)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small")

	inst.AnimState:SetBank("gogglesshoothat")
	inst.AnimState:SetBuild("hat_gogglesshoot")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("hat")
	inst:AddTag("goggles")
	inst:AddTag("headweapon")
	inst:AddTag("googleweapon")
	inst:AddTag("charges_percentage")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_gogglesshoot.xml"
	inst.components.inventoryitem.imagename = "chasni_gogglesshoot"

	inst:AddComponent("equippable")
	inst.components.equippable.restrictedtag = "soulless"
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(getdamage)
	inst.components.weapon:SetRange(12, 14)
	inst.components.weapon:SetProjectile("chasni_gogglesshoot_charge")
	inst.components.weapon:SetOnAttack(onattack_shoot)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(0)

	inst._onattacked = function(owner, data)
		if owner.components.inventory and owner.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) == inst then
			inst:DoTaskInTime(0, function()
				SpawnPrefab("electrichitsparks"):AlignToTarget(owner, data.attacker or owner, true)
				owner.components.inventory:DropItem(owner.components.inventory:Unequip(inst.components.equippable.equipslot), true, true)
			end)
		end
	end

	MakeHauntableLaunch(inst)

	return inst
end

local function OnHit(inst, owner, target)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")
	inst.AnimState:PlayAnimation("impact")
	inst.Physics:Stop()
	inst:ListenForEvent("animover", inst.Remove)
end

local function fn_charge()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("bishop_projectile_yellow")
	inst.AnimState:SetBuild("bishop_projectile_yellow")
	inst.AnimState:PlayAnimation("idle", true)
	inst.Transform:SetScale(0.6,0.6,0.6)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("projectile")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(30)
	inst.components.projectile:SetHoming(false)
	inst.components.projectile:SetHitDist(2)
	inst.components.projectile:SetOnHitFn(OnHit)
	inst.components.projectile:SetOnMissFn(OnHit)
	inst.components.projectile:SetLaunchOffset({x=1,y=2,z=0})

	inst.persists = false

	return inst
end

return 
Prefab("chasni_gogglesshoot", fn, assets, prefabs),
Prefab("chasni_gogglesshoot_charge", fn_charge, assets_charge) 
