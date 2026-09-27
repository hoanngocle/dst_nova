local brain = require "brains/chesterbrain"

local assets =
{
    Asset("ANIM", "anim/ro_bin.zip"),
    Asset("ANIM", "anim/ro_bin_water.zip"),
    Asset("ANIM", "anim/ro_bin_build.zip"),
}

local prefabs =
{
    "chasni_robin_stone",
    "die_fx",
    "chesterlight",
}

local HEALTH = 600
local HEALTH_REGEN_AMOUNT = 10
local HEALTH_REGEN_PERIOD = 1
local SPEED = 5
local WAKE_TO_FOLLOW_DISTANCE = 14
local SLEEP_NEAR_LEADER_DISTANCE = 7
local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and not inst.sg:HasStateTag("open")
            and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
            and TheWorld.state.moonphase ~= "full"
end

local function ShouldKeepTarget()
    return false
end

local function OnOpen(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("open")
    end
end

local function OnClose(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("close")
    end
end

local function OnStopFollowing(inst)
    inst:RemoveTag("companion")
end

local function OnStartFollowing(inst)
    inst:AddTag("companion")
end

local function SetId(inst, id)
    inst._id = id
end

local function SetStone(inst, stone)
    inst._stone = stone
end

local function OnSave(inst, data)
    data._id = inst._id
end

local function OnPreLoad(inst, data)
    inst._id = data and data._id or nil
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    inst:AddTag("companion")
    inst:AddTag("scarytoprey")
    inst:AddTag("ro_bin")
    inst:AddTag("notraptrigger")
    inst:AddTag("amphibious")
    inst:AddTag("noauradamage")

    inst.DynamicShadow:SetSize(2, 1.5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 75, .5)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst.AnimState:SetBank("ro_bin")
    inst.AnimState:SetBuild("ro_bin_build")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("chester")
        end
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)
    inst.components.health:StartRegen(HEALTH_REGEN_AMOUNT, HEALTH_REGEN_PERIOD)

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 3
    inst.components.locomotor:CanPathfindOnWater()
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("follower")
    inst:AddComponent("knownlocations")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("chester")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:AddComponent("embarker")
    inst.components.embarker.embark_speed = inst.components.locomotor.runspeed

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("ro_bin", "ro_bin_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
        inst.hop_distance = inst.components.locomotor.hop_distance
        inst.components.locomotor.hop_distance = 4
        inst.onwater = true
        inst.altstep = nil
        inst.sg:GoToState("takeoff")
    end)
    inst.components.amphibiouscreature:SetExitWaterFn(function(inst)
        if inst.hop_distance then
            inst.components.locomotor.hop_distance = inst.hop_distance
        end
        inst.onwater = false
        inst.sg:GoToState("land")
    end)

    inst:DoTaskInTime(1.5, function(inst)
        if not inst._stone then
            inst:Remove()
        end
    end)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
    inst:ListenForEvent("startfollowing", OnStartFollowing)

    if TheWorld.components.robinregistry == nil then
        TheWorld:AddComponent("robinregistry")
    end
    TheWorld.components.robinregistry:Register(inst)

    MakeMediumBurnableCharacter(inst, "hound_body")

    inst.SetId = SetId
    inst.SetStone = SetStone
    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad

    inst:SetStateGraph("SGCZRo_Bin")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_ro_bin", fn, assets, prefabs) 