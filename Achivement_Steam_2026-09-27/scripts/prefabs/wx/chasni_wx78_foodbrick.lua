local baseprefab = require("prefabs/wx78_foodbrick")

local function UpdateValues(inst)
	if inst.components.inventoryitem:IsWet() then
		inst.components.edible.healthvalue = 25
		inst.components.edible.hungervalue = 75
		inst.components.edible.sanityvalue = 50
	else
		inst.components.inventoryitem:ChangeImageName("wx78_foodbrick")
	end
end

local function top_hidefx(inst)
	if inst.fx ~= nil then
		inst.fx:Remove()
		inst.fx = nil
	end
end

local function top_showfx_onground(inst)
	if inst.fx == nil then
		inst.fx = SpawnPrefab("tophat_shadow_fx")
	else
		inst.fx.Follower:StopFollowing()
		inst.fx.Transform:SetPosition(0, 0, 0)
	end
	inst.fx.entity:SetParent(inst.entity)
end

local function top_enterlimbo(inst, owner)
	top_hidefx(inst)
end

local function top_exitlimbo(inst)
	top_showfx_onground(inst)
end

local function PostInit(inst)
	inst:AddTag("magiciantool")

	if not TheWorld.ismastersim then
		return
	end
	local old_onmoisturedeltacallback = inst.components.inventoryitemmoisture.onmoisturedeltacallback

	inst:ListenForEvent("enterlimbo", top_enterlimbo)
	inst:ListenForEvent("exitlimbo", top_exitlimbo)

	inst.components.inventoryitem:ChangeImageName("wx78_foodbrick")
	inst.components.inventoryitemmoisture:SetOnMoistureDeltaCallback(function(_inst, ...)
		old_onmoisturedeltacallback(_inst, ...)
		UpdateValues(_inst)
	end)
	if not inst:IsInLimbo() then
		top_showfx_onground(inst)
	end
	inst:DoTaskInTime(0, UpdateValues)
end

local function fn()
	local inst = baseprefab.fn()

	PostInit(inst)
	return inst
end

return Prefab("chasni_wx78_foodbrick", fn, baseprefab.assets)