local brain = require "brains/chasni_blackflybrain"

local assets =
{
    Asset("ANIM", "anim/quagmire_blackfly.zip"),
    Asset("ATLAS", "images/inventoryimages/quagmire_blackfly.xml"),
}

local prefabs =
{
    "mosquitosack",
}

SetSharedLootTable("chasni_blackfly", { {"mosquitosack", 0.15}, })

local HEALTH = chasni_getmobconfig("chasni_blackfly", "HP") or 35
local DAMAGE = chasni_getmobconfig("chasni_blackfly", "DMG") or 5
local ATTACK_PERIOD = 1
local ATTACK_RANGE = 3
local SPEED = 7
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 10
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "blackfly" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 100
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function keeptargetfn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "blackfly", SHARETARGET_MAX)
end

local function OnWorked(inst, worker)
    if worker.components.inventory then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function OnDropped(inst)
    inst.sg:GoToState("idle")
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.brain then
        inst.brain:Start()
    end
    if inst.sg then
        inst.sg:Start()
    end
    if inst.components.stackable and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack()do
            local item = inst.components.stackable:Get()
            if item then
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local function StartBuzz(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/mosquito/mosquito_fly_LP", "buzz")
end

local function StopBuzz(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(.8, .5)
    inst.Transform:SetFourFaced()
    MakeTinyFlyingCharacterPhysics(inst, 1, 0.5)
    MakeInventoryFloatable(inst)
    MakeFeedableSmallLivestockPristine(inst)

    inst:AddTag("smallcreature")
    inst:AddTag("blackfly")
    inst:AddTag("insect")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("cattoyairborne")

    inst.AnimState:SetBank("quagmire_blackfly")
    inst.AnimState:SetBuild("quagmire_blackfly")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2
    inst.components.locomotor:CanPathfindOnWater()
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_blackfly")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(1)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")
    inst:AddComponent("stackable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "quagmire_blackfly"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/quagmire_blackfly.xml"
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.pushlandedevents = false

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    MakeHauntablePanic(inst)
    MakeMediumBurnableCharacter(inst, "body")
    MakeSmallFreezableCharacter(inst, "body")
    MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME * 2, OnPickedUp, OnDropped)

    inst:ListenForEvent("attacked", OnAttacked)
    inst.OnEntityWake = StartBuzz
    inst.OnEntitySleep = StopBuzz

    inst:SetStateGraph("SGCZblackfly")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_blackfly", fn, assets, prefabs)
