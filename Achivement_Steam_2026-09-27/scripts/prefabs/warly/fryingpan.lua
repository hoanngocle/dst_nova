local assets =
{
	Asset("ANIM", "anim/pan.zip"),
	Asset("ANIM", "anim/swap_pan.zip"),
	Asset("ATLAS", "images/inventoryimages/fryingpan.xml"),
	Asset("SOUNDPACKAGE", "sound/fryingpan.fev"),
	Asset("SOUND", "sound/fryingpan1.fsb")
}

local USES = chasni_getitemconfig("fryingpan", "USE") or 5
local BOSS_KILL_REPAIR = chasni_getitemconfig("fryingpan", "REP") or 2
local DAMAGE = chasni_getitemconfig("fryingpan", "DMG") or 17
local DAMAGE_HUNGER_MULT = chasni_getitemconfig("fryingpan", "DMGH") or 0.05
local DISHES = require("preparedfoods")
local DISHES_INDEX = {}

for k, v in pairs(DISHES) do
	table.insert(DISHES_INDEX, k)
end

local function spawnDish(owner)
	local randomKey = DISHES_INDEX[math.random(#DISHES_INDEX)]
	local prefab = DISHES[randomKey].name
	local dish = SpawnPrefab(prefab)
	if dish then
		local p = Vector3(owner.Transform:GetWorldPosition()) + Vector3(0,2,0)
		dish.Transform:SetPosition(p:Get())
		local down = TheCamera:GetDownVec()
		local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
		local sp = 3 + math.random()
		dish.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
		return true
	end
	return false
end

local function castMagic(inst, target, pos)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	local dish = spawnDish(owner)
	if dish then
		inst.components.finiteuses:Use(1)
	end
end

local function getDamage(inst, attacker, target)
	local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
	local mult = owner and owner.components.inventory:EquipHasTag("chefhat") and owner.components.hunger and (math.max(owner.components.hunger.current, 0) * DAMAGE_HUNGER_MULT) or 1
	return DAMAGE * mult
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_pan", "swap_pan")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	inst._onkill = function(_, data)
		if owner.components.allachivcoin and owner.components.allachivcoin.expertwarly3 then
			if data.victim:HasTag("epic") then
				inst.components.finiteuses:Repair(BOSS_KILL_REPAIR)
			end
		end
	end
	owner:ListenForEvent("killed", inst._onkill)
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	if inst._onkill then
		owner:RemoveEventCallback("killed", inst._onkill)
	end
end

local function OnCharged(inst)
	inst.components.spellcaster:SetSpellFn(castMagic)
end

local function OnDischarged(inst)
	inst.components.spellcaster:SetSpellFn(nil)
end
local function onattack(inst, attacker, target)
	if target.SoundEmitter then
		target.SoundEmitter:PlaySound("fryingpan/fryingpan1/fryingpan")
	elseif inst.SoundEmitter then
		inst.SoundEmitter:PlaySound("fryingpan/fryingpan1/fryingpan")
	elseif attacker.SoundEmitter then
		attacker.SoundEmitter:PlaySound("fryingpan/fryingpan1/fryingpan")
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBank("pan")
	inst.AnimState:SetBuild("pan")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("rechargeable")
	inst:AddTag("castspell_fryingpan")

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(getDamage)
	inst.components.weapon:SetOnAttack(onattack)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("inspectable")
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "fryingpan"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/fryingpan.xml"

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canusefrominventory = true
	inst.components.spellcaster:SetSpellFn(castMagic)

	return inst
end

return Prefab("fryingpan", fn, assets)
