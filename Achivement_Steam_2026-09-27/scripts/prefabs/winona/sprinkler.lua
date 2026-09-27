local assets =
{
	Asset("ANIM", "anim/sprinkler.zip"),
	Asset("ANIM", "anim/sprinkler_placement.zip"),
	Asset("ANIM", "anim/sprinkler_meter.zip"),
	Asset("IMAGE", "images/inventoryimages/sprinkler.tex"),
	Asset("ATLAS", "images/inventoryimages/sprinkler.xml"),
}

local prefabs =
{
	"water_spray",
	"water_pipe",
}

local function spawndrop(inst)
	local drop = SpawnPrefab("rain_drop")
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local angle = math.random()*2*PI
	local dist = math.random()*TUNING.SPRINKLER_RANGE
	local offset = Vector3(dist * math.cos(angle), 0, -dist * math.sin(angle))
	drop.Transform:SetPosition(pt.x+offset.x,0,pt.z+offset.z)
	drop.Transform:SetScale(0.5, 0.5, 0.5)
end

local function TurnOn(inst)
	inst.on = true

	inst.components.fueled:StartConsuming()

	if not inst.waterSpray then
		inst.waterSpray = SpawnPrefab("water_spray")
		local follower = inst.waterSpray.entity:AddFollower()
		follower:FollowSymbol(inst.GUID, "top", 0, -100, 0)
	end

	inst.droptask = inst:DoPeriodicTask(0.2,function() spawndrop(inst) spawndrop(inst) end)

	inst.spraytask = inst:DoPeriodicTask(0.2,function()
		if inst.components.machine:IsOn() then
			inst.UpdateSpray(inst)
		end
	end)

	local attractor = inst.components.birdattractor
	if attractor then
		attractor.spawnmodifier:SetModifier(inst, TUNING.BIRD_SPAWN_MAXDELTA_FEATHERHAT, "maxbirds")
		attractor.spawnmodifier:SetModifier(inst, TUNING.BIRD_SPAWN_DELAYDELTA_FEATHERHAT.MIN, "mindelay")
		attractor.spawnmodifier:SetModifier(inst, TUNING.BIRD_SPAWN_DELAYDELTA_FEATHERHAT.MAX, "maxdelay")
		local birdspawner = TheWorld.components.birdspawner
		if birdspawner then
			birdspawner:ToggleUpdate(true)
		end
	end

	inst.sg:GoToState("turn_on")
end

local function TurnOff(inst)
	--inst:RemoveTag("shelter")
	inst.on = false
	inst.components.fueled:StopConsuming()

	if inst.waterSpray then
		inst.waterSpray:Remove()
		inst.waterSpray = nil
	end

	if inst.droptask then
		inst.droptask:Cancel()
		inst.droptask = nil
	end

	if inst.spraytask then
		inst.spraytask:Cancel()
		inst.spraytask = nil
	end

	local attractor = inst.components.birdattractor
	if attractor then
		attractor.spawnmodifier:RemoveModifier(inst)
		local birdspawner = TheWorld.components.birdspawner
		if birdspawner then
			birdspawner:ToggleUpdate(true)
		end
	end

	inst.sg:GoToState("turn_off")
end

local function OnFuelEmpty(inst)
end

local function OnFuelSectionChange(old, new, inst)
	local fuelAnim = 0
	if inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.01 then fuelAnim = "0"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.1 then fuelAnim = "1"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.2 then fuelAnim = "2"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.3 then fuelAnim = "3"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.4 then fuelAnim = "4"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.5 then fuelAnim = "5"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.6 then fuelAnim = "6"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.7 then fuelAnim = "7"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.8 then fuelAnim = "8"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.9 then fuelAnim = "9"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 1 then fuelAnim = "10" end
	if inst then inst.AnimState:OverrideSymbol("swap_meter", "sprinkler_meter", fuelAnim) end
end

local function ontakefuelfn(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel", nil, 0.5)
	local fuelAnim = 0
	if inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.01 then fuelAnim = "0"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.1 then fuelAnim = "1"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.2 then fuelAnim = "2"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.3 then fuelAnim = "3"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.4 then fuelAnim = "4"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.5 then fuelAnim = "5"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.6 then fuelAnim = "6"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.7 then fuelAnim = "7"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.8 then fuelAnim = "8"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.9 then fuelAnim = "9"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 1 then fuelAnim = "10" end
	if inst then inst.AnimState:OverrideSymbol("swap_meter", "sprinkler_meter", fuelAnim) end
end

local function CanInteract(inst)
	return true
end

local function GetStatus(inst, viewer)
	if inst.on then
		return "ON"
	else
		return "OFF"
	end
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("firesuppressor_idle", nil, 0.5)
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end

	data.on = inst.on
end

local function onload(inst, data)
	if data and data.burnt and inst.components.burnable and inst.components.burnable.onburnt then
		inst.components.burnable.onburnt(inst)
	end

	inst.on = data.on and data.on or false
	if data.on then
		inst.components.machine:TurnOn()
	else
		inst.components.machine:TurnOff()
	end
end

local function OnLoadPostPass(inst, newents, data)
	if data and data.waterSpray then
		inst.waterSpray = newents[data.waterSpray].entity
	end
end

local function OnBuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle_off")
	inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_sprinkler/place", nil, 0.5)
end

local function UpdateSpray(inst)
	OnFuelSectionChange(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local GARDENING_CANT_TAGS = { "pickable", "stump", "withered", "barren", "INLIMBO" }
	local ents = TheSim:FindEntities(x, y, z, TUNING.SPRINKLER_RANGE, nil, GARDENING_CANT_TAGS)

	if not inst.moisture_targets then
		inst.moisture_targets = {}
	end
	inst.moisture_targets_old = {}
	for GUID,v in pairs(inst.moisture_targets) do
		inst.moisture_targets_old[GUID] = v
	end
	inst.moisture_targets = {}

	for k,v in pairs(ents) do

		inst.moisture_targets[v.GUID] = v
		if v.components.moisture then
			if not v.components.moisture.moisture_sources then
				v.components.moisture.moisture_sources = {}
			end
			v.components.moisture.moisture_sources[inst.GUID] = inst.moisturizing
		end

		if v.components.moisturelistener and not (v.components.inventoryitem and v.components.inventoryitem:GetGrandOwner()) then
			v.components.moisturelistener:AddMoisture(15)

			local moisture = v.components.moisturelistener:GetMoisture()
			moisture = math.min(100,moisture + (15 / 100))
			v.components.moisturelistener:Soak(moisture/100)
		end

		if v.components.moisture then
			v.components.moisture:DoDelta(0.1)
		end

		if v.components.burnable and not (v.components.inventoryitem and v.components.inventoryitem:GetGrandOwner()) then
			v.components.burnable:Extinguish()
		end

		if v.components.crop and v.components.crop.task then
			v.components.crop.growthpercent = v.components.crop.growthpercent + (0.001)
		end

		if v.components.growable then
			v.components.growable:ExtendGrowTime(-0.2)
		end

		if v then
			local a, b, c = v.Transform:GetWorldPosition()
			if inst.components.wateryprotection then
				inst.components.wateryprotection:SpreadProtectionAtPoint(a, b, c, 1)
			end
		end

		if v.components.witherable and v.components.witherable:IsWithered() then
			v.components.witherable:ForceRejuvenate()
		end
	end

	for GUID,v in pairs(inst.moisture_targets_old)do
		local still_affected = false
		for iGUID, i in pairs(inst.moisture_targets)do
			if GUID == iGUID then
				still_affected = true
				break
			end
		end
		if not still_affected then
			if v.components.moisture then
				v.components.moisture.moisture_sources[inst.GUID] = nil
			end
		end
	end
end

local function RetractPipes(inst)
	TheWorld[tostring(inst.GUID).."pipesound"] = 1
	if inst.pipes and inst.pipes[#inst.pipes] then
		inst.pipes[#inst.pipes].sg:GoToState("retract")
	end
end

local function OnHit(inst, worker)
	if not inst:HasTag("burnt") then
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("hit")
		end
	end
end

local function OnHammered(inst, worker)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end

	inst.SoundEmitter:KillSound("idleloop", nil, 0.5)
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood", nil, 0.5)
	TurnOff(inst, true)
	RetractPipes(inst)
	inst:Remove()
end

local function OnDeplete(inst)
end

local function SprinklerFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetPriority(5)
	inst.MiniMapEntity:SetIcon("sprinkler.tex")

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBank("sprinkler")
	inst.AnimState:SetBuild("sprinkler")
	inst.AnimState:PlayAnimation("idle_off")
	inst.AnimState:OverrideSymbol("sidepipe", "sprinkler", "sidepipe")
	inst.on = false

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine.caninteractfn = CanInteract
	inst.components.machine.cooldowntime = 0.5

	inst:AddComponent("fueled")
	inst.components.fueled:SetDepletedFn(OnFuelEmpty)
	inst.components.fueled.accepting = false
	inst.components.fueled:SetSections(10)
	inst.components.fueled.ontakefuelfn = ontakefuelfn
	inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
	inst.components.fueled:InitializeFuelLevel(TUNING.SPRINKLER_MAX_FUEL_TIME)
	inst.components.fueled.bonusmult = TUNING.SPRINKLER_FUEL_BONUS_MULTIPLIER
	inst.components.fueled.rate = 0

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

	inst:AddComponent("wateryprotection")
	inst.components.wateryprotection.extinguishheatpercent = TUNING.SPRINKLER_EXTINGUISH_HEAT_PERCENT
	inst.components.wateryprotection.temperaturereduction = TUNING.SPRINKLER_TEMP_REDUCTION
	inst.components.wateryprotection.witherprotectiontime = TUNING.SPRINKLER_PROTECTION_TIME
	inst.components.wateryprotection.addwetness = 0.01
	inst.components.wateryprotection.protection_dist = TUNING.SPRINKLER_PROTECTION_DIST
	inst.components.wateryprotection:AddIgnoreTag("player")
	inst.components.wateryprotection.onspreadprotectionfn = OnDeplete

	inst:SetStateGraph("SGCZsprinkler")

	inst.moisturizing = 2

	inst.UpdateSpray = UpdateSpray

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.OnLoadPostPass = OnLoadPostPass
	inst.OnEntitySleep = OnEntitySleep

	inst:ListenForEvent("onbuilt", OnBuilt)

	MakeSnowCovered(inst, .01)

	inst.waterSpray = nil

	return inst
end

return Prefab("chasni_sprinkler", SprinklerFn, assets, prefabs),
MakePlacer("chasni_sprinkler_placer", "sprinkler_placement", "sprinkler_placement", "idle", true, nil, nil, 1.4, nil, nil, nil, nil, nil, nil)