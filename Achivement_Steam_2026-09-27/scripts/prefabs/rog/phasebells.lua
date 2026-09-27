local SHADOW_USES = chasni_getitemconfig("phasebell_shadow", "USES") or 100
local LUNAR_USES = chasni_getitemconfig("phasebell_lunar", "USES") or 100

local function MakeBell(element, uses, nightmarephase, moonphase)
	local assets = {
		Asset("ANIM", "anim/phasebell_"..element..".zip"),
		Asset("ATLAS", "images/inventoryimages/phasebell_"..element..".xml"),
	}

	local function shine(inst)
		inst.task = nil
		inst.AnimState:PlayAnimation("sparkle")
		inst.AnimState:PushAnimation("idle")
		inst.task = inst:DoTaskInTime(4 + math.random() * 5, function() shine(inst) end)
	end

	local function OnPlayed(inst, musician)
		if TheWorld:HasTag("cave") and inst.nightmarephase then
			TheWorld:PushEvent("ms_setnightmarephase", inst.nightmarephase)
		elseif TheWorld:HasTag("forest") and inst.moonphase then
			TheWorld:PushEvent("ms_setmoonphase", {moonphase = inst.moonphase, iswaxing = inst.moonphase == "new"})
		end
	end

	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		MakeInventoryFloatable(inst, "small", 0.2, 0.65)

		inst.AnimState:SetBank("phasebell_"..element)
		inst.AnimState:SetBuild("phasebell_"..element)
		inst.AnimState:PlayAnimation("idle")

		inst:AddTag("bell")
		inst:AddTag("molebait")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("finiteuses")
		inst.components.finiteuses:SetMaxUses(uses)
		inst.components.finiteuses:SetUses(uses)
		inst.components.finiteuses:SetOnFinished(inst.Remove)
		inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

		inst:AddComponent("inspectable")
		inst:AddComponent("instrument")
		inst.components.instrument.onplayed = OnPlayed

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = "phasebell_"..element
		inst.components.inventoryitem.atlasname = "images/inventoryimages/phasebell_"..element..".xml"

		inst:AddComponent("tool")
		inst.components.tool:SetAction(ACTIONS.PLAY)

		inst.nightmarephase = nightmarephase
		inst.moonphase = moonphase
		inst.bellbuild = "phasebell_"..element
		inst.bellsymbol = "bell01"
		shine(inst)

		return inst
	end

	return Prefab("phasebell_"..element, fn, assets)
end

return
MakeBell("shadow", SHADOW_USES, "wild", "new"),
MakeBell("lunar", LUNAR_USES, "calm", "full")
