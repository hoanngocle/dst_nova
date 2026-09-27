local easing = require("easing")

local assets =
{
	Asset("ANIM", "anim/dragoon_egg.zip"),
	Asset("ANIM", "anim/meteorshadow.zip"),
}

local prefabs =
{
	"groundpound_fx",
	"groundpoundring_fx",
	"chasni_ancientherald_lavapool",
	"chasni_ancientherald_firerainshadow",
	"chasni_ancientherald_firerainimpact"
}

local VOLCANO_FIRERAIN_WARNING = 2
local VOLCANO_FIRERAIN_DAMAGE = chasni_getmobconfig("chasni_ancientherald_firerain", "DMG") or 350 
local VOLCANO_FIRERAIN_LAVA_CHANCE = 0.3

local function SpawnWave(inst, onground, ground_prefab)
	local x, y, z = inst.Transform:GetLocalPosition()
	local ground = TheWorld.Map:GetTile(TheWorld.Map:GetTileCoordsAtPoint(x, y, z))

	if (ground == GROUND.OCEAN_COASTAL or
			ground == GROUND.OCEAN_COASTAL_SHORE or
			ground == GROUND.OCEAN_SWELL or
			ground == GROUND.OCEAN_ROUGH or
			ground == GROUND.OCEAN_BRINEPOOL or
			ground == GROUND.OCEAN_BRINEPOOL_SHORE or
			ground == GROUND.OCEAN_WATERLOG or
			ground == GROUND.OCEAN_HAZARDOUS)
	then
		chasni_spawnprefab("bombsplash", x, y, z)
		inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/large")
		SpawnAttackWaves(inst:GetPosition(), nil, (inst.Physics and inst.Physics:GetRadius()) or nil, 6, 360, 4, nil, 2, nil)
	elseif onground then
		local fx = chasni_spawnprefab(ground_prefab, x, y, z)
		if fx.components.timer then
			fx.components.timer:StartTimer("remove", TUNING.TOTAL_DAY_TIME * 2)
		end
	end
end

local function DoStep(inst)
	local x, _, z = inst.Transform:GetLocalPosition()

	local WALKABLE_PLATFORM_TAGS = {"walkableplatform"}
	local onground = true
	local entities = TheSim:FindEntities(x, 0, z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS, WALKABLE_PLATFORM_TAGS)
	for i, v in ipairs(entities) do
		local walkable_platform = v.components.walkableplatform
		if walkable_platform then
			local platform_x, _, platform_z = v.Transform:GetWorldPosition()
			local distance_sq = VecUtil_LengthSq(x - platform_x, z - platform_z)
			local radius = walkable_platform.radius or 4
			if distance_sq <= radius * radius then
				onground = false
			end
		end
	end

	local ground_prefab = "chasni_ancientherald_firerainimpact"
	if math.random() < VOLCANO_FIRERAIN_LAVA_CHANCE then
		ground_prefab = "chasni_ancientherald_lavapool"
	end
	SpawnWave(inst, onground, ground_prefab)

	inst.SoundEmitter:PlaySound("dontstarve/common/meteor_impact")
	inst.components.groundpounder.numRings = 2
	inst.components.groundpounder.burner = true
	inst.components.groundpounder:GroundPound()
	ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1.25, inst, 40)
end

local function StartStep(inst)
	local shadow = SpawnPrefab("chasni_ancientherald_firerainshadow")
	shadow.Transform:SetPosition(inst:GetPosition():Get())
	shadow.Transform:SetRotation(math.random(0, 360))
	inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/bomb_fall", nil, 0.8)
	inst:Hide()
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (5*FRAMES), function(inst) inst:DoStep() end)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (14*FRAMES), function(inst)
		inst:Show()
		inst.AnimState:PlayAnimation("idle")
		inst:ListenForEvent("animover", function(inst) inst:Remove() end)
	end)
end

local function firerainfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst:AddTag("FX")

	inst.AnimState:SetBank("meteor")
	inst.AnimState:SetBuild("draegg")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 2
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 1
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.burner = true
	inst.components.groundpounder.ring_fx_scale = 0.75

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(VOLCANO_FIRERAIN_DAMAGE)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()
	return inst
end

local function LerpIn(inst)
	inst:DoTaskInTime(64*FRAMES, inst.Remove)

	local s = easing.inExpo(inst:GetTimeAlive(), 1, 1 - inst.StartingScale, inst.TimeToImpact)
	inst.Transform:SetScale(s,s,s)
	if s >= inst.StartingScale then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function OnRemove(inst)
	if inst.sizeTask then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function shadowfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("meteor_shadow")
	inst.AnimState:SetBuild("meteorshadow1")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	local s = 2
	inst.StartingScale = s
	inst.Transform:SetScale(s,s,s)
	inst.TimeToImpact = VOLCANO_FIRERAIN_WARNING

	inst.OnRemoveEntity = OnRemove

	inst.sizeTask = inst:DoPeriodicTask(FRAMES, LerpIn)

	return inst
end

return Prefab("chasni_ancientherald_firerain", firerainfn, assets, prefabs),
Prefab("chasni_ancientherald_firerainshadow", shadowfn, assets)
