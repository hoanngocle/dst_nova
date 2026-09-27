local assets =
{
	Asset("ANIM", "anim/hulk_gloves.zip"),
	Asset("ANIM", "anim/swap_hulk_gloves.zip"),

	Asset("ATLAS", "images/inventoryimages/hulk_gloves.xml"),
	Asset("IMAGE", "images/inventoryimages/hulk_gloves.tex"),
}

local USES = chasni_getitemconfig("hulkgloves", "USE") or 100
local DAMAGE = chasni_getitemconfig("hulkgloves", "DMG") or 17
-- Handle wolfgang and woodie
local function onnewstate_gloves(inst)
	local handslot = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if handslot:HasTag("gloves") and inst.sg:HasStateTag("nomorph") and handslot.RefreshLook then
		handslot.RefreshLook(handslot, inst)
	end
end

local function onequippedskinitem_gloves(owner)
	local handslot = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if handslot and (handslot:HasTag("gloves") or handslot:HasTag("bracelet")) and owner.components.skinner and handslot.RefreshLook then
		if owner.components.skinner.clothing["hand"] and owner.components.skinner.clothing["hand"] ~= "" then
			handslot._originalhandskin = owner.components.skinner.clothing["hand"]
		end

		owner:DoTaskInTime(0.5, function() handslot.RefreshLook(handslot, owner) end)
	end
end

local function RefreshLook(inst, owner)
	if owner.components.skinner.clothing["hand"] and owner.components.skinner.clothing["hand"] ~= "" then
		inst._originalhandskin = owner.components.skinner.clothing["hand"]
		owner.components.skinner.clothing["hand"] = ""
		owner.components.skinner:ClearClothing("hand")
	end

	if inst._originalhandskin == nil then
		if owner.components.skinner.clothing["body"] ~= "" then
			inst._originalbodyskin = owner.components.skinner.clothing["body"]
		else
			inst._originalbodyskin = nil
		end
	end

	owner.AnimState:OverrideSymbol("hand", "swap_hulk_gloves", "hand")

	owner:ListenForEvent("equipskinneditem", onequippedskinitem_gloves)
	owner:ListenForEvent("unequipskinneditem", onequippedskinitem_gloves)
	owner:ListenForEvent("newstate", onnewstate_gloves)
end

local function onequip(inst, owner)
	RefreshLook(inst, owner)

	owner.AnimState:ClearOverrideSymbol("swap_object")

	if inst.hideARMCarry == nil then
		inst.hideARMCarry = inst:DoPeriodicTask(FRAMES, function()
			owner.AnimState:Hide("ARM_carry")
			owner.AnimState:Show("ARM_normal")
		end)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("hand")

	if inst._originalhandskin then
		owner.components.skinner.clothing["hand"] = inst._originalhandskin
		owner.components.skinner:SetSkinMode()
		inst._originalhandskin = nil
	else
		if inst._originalbodyskin then
			owner.components.skinner.clothing["body"] = inst._originalbodyskin
			owner.components.skinner:SetSkinMode()
			inst._originalbodyskin = nil
		end
	end

	if inst.hideARMCarry then
		inst.hideARMCarry:Cancel()
		inst.hideARMCarry = nil
	end

	owner:RemoveEventCallback("equipskinneditem", onequippedskinitem_gloves)
	owner:RemoveEventCallback("unequipskinneditem", onequippedskinitem_gloves)
	owner:RemoveEventCallback("newstate", onnewstate_gloves)
end

local function SpawnLaser(inst)
	local numsteps = 10
	local x, y, z = inst.Transform:GetWorldPosition()
	local angle = (inst.Transform:GetRotation() + 90) * DEGREES
	local step = .75
	local offset = 2 - step
	local ground = TheWorld.Map
	local targets, skiptoss = {}, {}
	local i = -1
	local noground = false
	local fx, dist, delay, x1, z1

	x1 = x + offset * math.sin(angle)
	z1 = z + offset * math.cos(angle)
	local laserhand = chasni_spawnprefab("chasni_ancient_hulk_orb", x1, 1, z1)
	laserhand.AnimState:PlayAnimation("spin_loop",true)
	laserhand.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	laserhand.AnimState:SetLightOverride(1)
	laserhand.Transform:SetScale(0.75,0.75,0.75)
	local alpha = 1
	local delta = 0.1
	laserhand:DoPeriodicTask(0, function(i)
		alpha = math.max(0, alpha - delta)
		laserhand.AnimState:SetMultColour(1, 1, 1, alpha)
	end)

	while i < numsteps do
		i = i + 1
		dist = i * step + offset
		delay = math.max(0, i - 1)
		x1 = x + dist * math.sin(angle)
		z1 = z + dist * math.cos(angle)
		if not ground:IsPassableAtPoint(x1, 0, z1) then
			if i <= 0 then
				return
			end
			noground = true
		end
		fx = SpawnPrefab(i > 0 and "chasni_playerlaser" or "chasni_playerlaserempty")
		fx.caster = inst
		fx.Transform:SetPosition(x1, 0, z1)
		fx:Trigger(delay * FRAMES, targets, skiptoss, inst)
		if i == 0 then
			ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .6, fx, 30)
		end
		if noground then
			break
		end
	end

	if i < numsteps then
		dist = (i + .5) * step + offset
		x1 = x + dist * math.sin(angle)
		z1 = z + dist * math.cos(angle)
	end
	fx = SpawnPrefab("chasni_playerlaser")
	fx.Transform:SetPosition(x1, 0, z1)
	fx:Trigger((delay + 1) * FRAMES, targets, skiptoss, inst)

	fx = SpawnPrefab("chasni_playerlaser")
	fx.Transform:SetPosition(x1, 0, z1)
	fx:Trigger((delay + 2) * FRAMES, targets, skiptoss, inst)
end

local function onattack(inst, owner, target)
	if not inst:HasTag("StopLaser") then
		inst.components.finiteuses:Use(1)
		inst:AddTag("StopLaser")
		SpawnLaser(owner)
		inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/charge")
		inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
		inst:DoTaskInTime(0.7, function()
			inst:RemoveTag("StopLaser")
		end)
	end
end

local function init()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	inst.AnimState:SetBank("hulk_gloves")
	inst.AnimState:SetBuild("hulk_gloves")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("punch")
	inst:AddTag("gloves")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._originalhandskin = nil
	inst._originalbodyskin = nil

	inst.RefreshLook = RefreshLook

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DAMAGE)
	inst.components.weapon:SetRange(5)
	inst.components.weapon:SetOnAttack(onattack)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "hulk_gloves"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/hulk_gloves.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	MakeHauntableLaunch(inst)

	inst:DoTaskInTime(0, function()
		if inst.components.inventoryitem and inst.components.inventoryitem.owner and inst.components.equippable:IsEquipped() then
			local owner = inst.components.inventoryitem.owner
			RefreshLook(inst, owner)
		end
	end)

	return inst
end

return Prefab("hulkgloves", init, assets)
