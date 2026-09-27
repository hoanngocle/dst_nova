local assets =
{
	Asset("ANIM", "anim/chasni_solar_panel.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_solar_panel.xml"),
}

local prefabs =
{
	"collapse_small",
}

local BATTERY_CAPACITY = 100
local CHARGING_TICK = 5
local CHARGE_COST = 10
local function abletoaccepttest(inst, item, giver)
	if inst._charges then
		if (item:HasTag("charges_percentage") and item.components.finiteuses and inst._charges > 0) or ((item.prefab == "gears" or item.prefab == "moonglass") and inst._charges >= CHARGE_COST) then
			return true
		end
	else
		chasni_retalk(giver, "ANNOUNCE_CHASNI_NO_SOLAR")
		return false, "NO_SOLAR"
	end
	return false
end

local function ongivenitem(inst, giver, item)
	if item:HasTag("charges_percentage") and item.components.finiteuses and inst._charges > 0 then
		local total = item.components.finiteuses.total
		local current = item.components.finiteuses.current
		if current < total then
			local percentages = (inst._charges or 1) / BATTERY_CAPACITY
			local increment = math.ceil(total * percentages)
			item.components.finiteuses:SetUses(math.min(current + increment, total))
			inst._charges = 0
		end
		giver.components.inventory:GiveItem(item)
	elseif inst._charges >= CHARGE_COST and (item.prefab == "gears" or item.prefab == "moonglass") then
		local stacksize = math.min(item.components.stackable:StackSize(), math.floor(inst._charges / CHARGE_COST))
		if stacksize > 0 then
			local prefabname = item.prefab == "gears" and "chasni_gears_charged" or "moonglass_charged"
			local x, y, z = giver.Transform:GetWorldPosition()
			local chargeditem = chasni_spawnprefab(prefabname, x, y, z)
			if chargeditem.components.stackable then
				chargeditem.components.stackable:SetStackSize(stacksize)
			end
			giver.components.inventory:GiveItem(chargeditem)
			item.components.stackable:Get(stacksize):Remove()
			inst._charges = math.max(0, inst._charges - (stacksize * CHARGE_COST))
		end
		giver.components.inventory:GiveItem(item)
	end
end

local function getdesc(inst)
	if not inst._charges then
		inst._charges = 0
	end
	return subfmt(STRINGS.CHASNI_SOLAR_PANEL_DESC, {charge = inst._charges.."%"})
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	inst:Remove()
end

local function onsave(inst, data)
	data._charges = inst._charges or 0
end

local function onload(inst, data)
	inst._charges = data and data._charges or 0
end

local function chargingtask(inst)
	inst._charges = inst._charges or 0
	if inst._charges < BATTERY_CAPACITY then
		local energygain = TheWorld.state.issummer and 3 or 1
		inst._charges = inst._charges + energygain
	end
end

local function RefreshLook(inst, phase)
	if phase == "day" and not TheWorld.state.iswinter then
		inst.AnimState:PlayAnimation("working_pre")
		inst.AnimState:PushAnimation("working_loop", true)
		inst._chargingtask = inst:DoPeriodicTask(CHARGING_TICK, chargingtask)
		return
	end
	if not inst.AnimState:IsCurrentAnimation("off") then
		inst.AnimState:PlayAnimation("working_pst")
		inst.AnimState:PushAnimation("off", true)
	end
	if inst._chargingtask then
		inst._chargingtask:Cancel()
		inst._chargingtask = nil
	end
end
 

local function OnInit(inst)
	inst:WatchWorldState("phase", RefreshLook)
	RefreshLook(inst, TheWorld.state.isday and "day")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.Transform:SetScale(0.7,0.7,0.7)
	inst.AnimState:SetBank("chasni_solar_panel")
	inst.AnimState:SetBuild("chasni_solar_panel")
	inst.AnimState:PlayAnimation("off", true)

	inst:AddTag("structure")
	inst:AddTag("trader")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = getdesc

	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(abletoaccepttest)
	inst.components.trader:SetAcceptStacks()
	inst.components.trader.acceptnontradable = true
	inst.components.trader.onaccept = ongivenitem
	inst.components.trader.deleteitemonaccept = false

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst.OnSave = onsave
	inst.OnLoad = onload

	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("chasni_solar_panel", fn, assets, prefabs),
MakePlacer("chasni_solar_panel_placer", "chasni_solar_panel", "chasni_solar_panel", "off")