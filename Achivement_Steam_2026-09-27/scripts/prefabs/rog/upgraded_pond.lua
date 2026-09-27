local assets =
{
    Asset("ANIM", "anim/upgraded_pond.zip"),
    Asset("ANIM", "anim/splash.zip"),
}
local prefabs =
{
    "pondflower_winter",
    "pondflower_autumn",
    "pondfish",
}

local fish_prefab_spring =
{
    common = {
        pondfish = 0.3,    pondeel = 0.3,   wetpouch = 0.25,
        oceanfish_small_3_inv = 0.05,    oceanfish_small_7_inv = 0.05,    oceanfish_medium_9_inv = 0.05,
    },
    rare = {
        pondfish = 0.1,    pondeel = 0.15,   wetpouch = 0.15,
        oceanfish_small_3_inv = 0.2,    oceanfish_small_7_inv = 0.2,    oceanfish_medium_9_inv = 0.2,
    },
}
local fish_prefab_summer =
{
    common = {
        pondfish = 0.3,    pondeel = 0.3,   wetpouch = 0.25,
        oceanfish_small_2_inv = 0.05,    oceanfish_small_8_inv = 0.05,    oceanfish_medium_6_inv = 0.025,    oceanfish_medium_7_inv = 0.025,
    },
    rare = {
        pondfish = 0.1,    pondeel = 0.15,   wetpouch = 0.15,
        oceanfish_small_2_inv = 0.2,    oceanfish_small_8_inv = 0.2,    oceanfish_medium_6_inv = 0.1,    oceanfish_medium_7_inv = 0.1,
    },
}
local fish_prefab_autumn =
{
    common = {
        pondfish = 0.3,    pondeel = 0.3,   wetpouch = 0.25,
        oceanfish_small_1_inv = 0.05,    oceanfish_small_6_inv = 0.05,    oceanfish_medium_1_inv = 0.05,
    },
    rare = {
        pondfish = 0.1,    pondeel = 0.15,   wetpouch = 0.15,
        oceanfish_small_1_inv = 0.2,    oceanfish_small_6_inv = 0.2,    oceanfish_medium_1_inv = 0.2,
    },
}
local fish_prefab_winter =
{
    common = {
        pondfish = 0.3,    pondeel = 0.3,   wetpouch = 0.25,
        oceanfish_small_4_inv = 0.05,    oceanfish_small_5_inv = 0.05,    oceanfish_medium_8_inv = 0.05,
    },
    rare = {
        pondfish = 0.1,    pondeel = 0.15,   wetpouch = 0.15,
        oceanfish_small_4_inv = 0.2,    oceanfish_small_5_inv = 0.2,    oceanfish_medium_8_inv = 0.2,
    },
}
local PLANT_SPAWN_DURATION = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("upgraded_pond", "PDUR") or 1)
local PLANT_RESPAWN_TIME = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("upgraded_pond", "PSPN") or 5)
local MAX_FISH = chasni_getitemconfig("upgraded_pond", "FMAX") or 10
local FISH_RESPAWN_TIME = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("upgraded_pond", "FSPN") or 0.25)
local function updateAnim(inst)
    local animation = (TheWorld.state.isspring and "idle_spring") or (TheWorld.state.iswinter and "idle_winter") or (TheWorld.state.issummer and "idle_summer") or (TheWorld.state.isautumn and "idle_autumn")
    inst.AnimState:PlayAnimation(animation, true)
end
local function ondug(inst, worker)
    if inst.originalpond then
        ReplacePrefab(inst, inst.originalpond)
    else
        inst:Remove()
    end
end

local function getFishRarity(inst, pool)
    return (inst.plant_ents == nil and pool.common and weighted_random_choice(pool.common)) or 
            (pool.rare and weighted_random_choice(pool.rare)) or 
            "pondfish"
end

local function GetFish(inst)
    local retval = (TheWorld.state.isspring and getFishRarity(inst, fish_prefab_spring)) or
            (TheWorld.state.iswinter and getFishRarity(inst, fish_prefab_winter)) or
            (TheWorld.state.issummer and getFishRarity(inst, fish_prefab_summer)) or
            (TheWorld.state.isautumn and getFishRarity(inst, fish_prefab_autumn)) or
            "pondfish"
    return retval
end

local function OnSave(inst, data)
    data.plants = inst.plants
    data.originalpond = inst.originalpond
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst.originalpond = data.originalpond
        if inst.task ~= nil and inst.plants == nil then
            inst.plants = data.plants
        end
    end
end

local function SpawnPlants(inst)
    inst.task = nil
    if inst.plant_ents ~= nil then
        return
    end

    if inst.plants == nil then
        inst.plants = {}
        for _ = 1, math.random(2, 4) do
            local theta = math.random() * TWOPI
            table.insert(inst.plants, { offset = { math.sin(theta) * 1.9 + math.random() * .3, 0, math.cos(theta) * 2.1 + math.random() * .3, }, })
        end
    end

    inst.plant_ents = {}
    for i, v in pairs(inst.plants) do
        if type(v.offset) == "table" and #v.offset == 3 then
            local plant = SpawnPrefab(inst.planttype)
            if plant ~= nil then
                plant.AnimState:PlayAnimation("grow")
                plant.AnimState:PushAnimation("grow_pst")
                plant.AnimState:PushAnimation("idle_full", true)
                plant.entity:SetParent(inst.entity)
                plant.Transform:SetPosition(unpack(v.offset))
                plant.persists = false
                table.insert(inst.plant_ents, plant)
            end
        end
    end

    inst.components.timer:StopTimer("spawn")
    inst.components.timer:StartTimer("despawn", PLANT_SPAWN_DURATION)
end

local function DespawnPlants(inst)
    if inst.plant_ents ~= nil then
        for i, v in ipairs(inst.plant_ents) do
            if v:IsValid() then
                v.AnimState:PlayAnimation("harvest")
                v:ListenForEvent("animover", inst.Remove)
            end
        end

        inst.plant_ents = nil
    end

    inst.plants = nil

    inst.components.timer:StopTimer("despawn")
    inst.components.timer:StartTimer("spawn", PLANT_RESPAWN_TIME)
end

local function OnTimerDone(inst, data)
    if data.name == "spawn" then
        SpawnPlants(inst)
    elseif data.name == "despawn" then
        DespawnPlants(inst)
    end
end

local function OnInit(inst)
    if inst.plant_ents == nil then
        inst.components.timer:StartTimer("spawn", PLANT_RESPAWN_TIME)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	MakePondPhysics(inst, 1.95)

    inst.AnimState:SetBuild("upgraded_pond")
    inst.AnimState:SetBank("upgraded_pond")
    updateAnim(inst)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("watersource")
    inst:AddTag("pond")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("watersource")

    inst:AddComponent("fishable")
    inst.components.fishable.maxfish = MAX_FISH
    inst.components.fishable:SetRespawnTime(FISH_RESPAWN_TIME)
    inst.components.fishable:SetGetFishFn(GetFish)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(ondug)

    inst.planttype = "pondflower_winter"

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst.task = inst:DoTaskInTime(1, OnInit)
    inst:WatchWorldState("season", function() inst:DoTaskInTime(1, updateAnim) end)

    return inst
end

local function fnempty()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("upgraded_pond")
    inst.AnimState:SetBank("upgraded_pond")
    inst.AnimState:PlayAnimation("empty")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false

    return inst
end

return 
Prefab("upgraded_pond", fn, assets, prefabs),
Prefab("upgraded_pond_empty", fnempty, assets)
