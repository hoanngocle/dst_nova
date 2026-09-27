local assets =
{
	Asset("ANIM", "anim/chasni_heater.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_heater.xml"),
}

local prefabs =
{
	"collapse_small",
	"willow_ember",
}

local MAX_EMBER = 10
local SPAWNING_TICK = 10
local BASE_COOKING_COOLDOWN = 50
local MULTIPLIER_COOKING_COOLDOWN = 5
local FOOD_TYPE =
{
	GENERIC = "GENERIC",
	MEAT = "MEAT",
	VEGGIE = "VEGGIE",
	SEEDS = "SEEDS",
	BERRY = "BERRY",
	GOODIES = "GOODIES",
}
local function HeatFn(inst, observer)
	return inst._machinestate == 1 and 150 or 0
end

local function abletoaccepttest(inst, item)
	if item.components.edible and item.components.perishable then
		for k, v in pairs(FOOD_TYPE) do
			if item:HasTag("edible_"..v) then
				return true
			end
		end
	end
end

local function ongivenitem(inst, giver, item)
	if item.components.perishable then
		item.components.perishable:SetPercent(1)
		giver.components.inventory:GiveItem(item)
		if inst.components.machine then
			inst.components.machine:TurnOff()
			inst._machinestate = -1
			inst:AddTag("fueldepleted")

			inst:DoTaskInTime(0.5, function()
				inst._machinestate = -1
				inst.AnimState:PushAnimation("off", true)
			end)

			local cooldowntime = item.components.stackable and item.components.stackable:StackSize() * MULTIPLIER_COOKING_COOLDOWN or BASE_COOKING_COOLDOWN
			inst:DoTaskInTime(cooldowntime, function()
				inst._machinestate = 0
				inst.AnimState:PushAnimation("on", true)
				inst:RemoveTag("fueldepleted")
			end)
		end
	end
end

local function GetStatus(inst, viewer)
	return (inst:HasTag("playerghost") and "GHOST") or nil
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	inst:Remove()
end
-- 0 : off, 1 : on, -1 : recharge
local function onsave(inst, data)
	data._machinestate = inst._machinestate
end

local function onload(inst, data)
	inst._machinestate = data._machinestate and data._machinestate or 0
	if inst._machinestate == -1 then
		inst:AddTag("fueldepleted")
		inst.AnimState:PushAnimation("off", true)
	elseif inst._machinestate == 0 then
		inst.AnimState:PlayAnimation("working_pst")
		inst.AnimState:PushAnimation("on", true)
	elseif inst._machinestate == 1 then
		inst.AnimState:PlayAnimation("working_pre")
		inst.AnimState:PushAnimation("working_loop", true)
	end
end

local function emberspawntask(inst)
	local pos = Vector3(inst.Transform:GetWorldPosition())
	local embers = TheSim:FindEntities(pos.x,pos.y,pos.z, 3, {"willow_ember"})
	if #embers < MAX_EMBER then
		local ember = SpawnPrefab("willow_ember")
		inst.components.lootdropper:FlingItem(ember)
	end
end

local function TurnOff(inst, instant)
	inst._machinestate = 0
	if not inst.AnimState:IsCurrentAnimation("on") then
		inst.AnimState:PlayAnimation("working_pst")
		inst.AnimState:PushAnimation("on", true)
	end
	if inst._emberspawntask then
		inst._emberspawntask:Cancel()
		inst._emberspawntask = nil
	end
	if inst.components.trader then
		inst.components.trader:Disable()
	end
end

local function TurnOn(inst, instant)
	inst._machinestate = 1
	inst.AnimState:PlayAnimation("working_pre")
	inst.AnimState:PushAnimation("working_loop", true)
	inst._emberspawntask = inst:DoPeriodicTask(SPAWNING_TICK, emberspawntask)
	if inst.components.trader then
		inst.components.trader:Enable()
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.Transform:SetScale(2,2,2)
	inst.AnimState:SetBank("chasni_heater")
	inst.AnimState:SetBuild("chasni_heater")
	inst.AnimState:PlayAnimation("on", true)

	inst.Light:Enable(true)
	inst.Light:SetRadius(1.0)
	inst.Light:SetFalloff(.9)
	inst.Light:SetIntensity(0.5)
	inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

	inst:AddTag("structure")
	inst:AddTag("trader")
	inst:AddTag("HASHEATER")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine.cooldowntime = 0.5

	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(abletoaccepttest)
	inst.components.trader:SetAcceptStacks()
	inst.components.trader.acceptnontradable = true
	inst.components.trader.onaccept = ongivenitem
	inst.components.trader.deleteitemonaccept = false
	inst.components.trader:Disable()

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst:AddComponent("heater")
	inst.components.heater.heatfn = HeatFn

	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end

return Prefab("chasni_heater", fn, assets, prefabs),
MakePlacer("chasni_heater_placer", "chasni_heater", "chasni_heater", "on")