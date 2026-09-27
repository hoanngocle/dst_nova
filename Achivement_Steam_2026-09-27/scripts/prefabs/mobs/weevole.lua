local brain = require "brains/chasni_weevolebrain"

local assets =
{
    Asset("ANIM", "anim/weevole.zip"),
}

local prefabs =
{
    "mosquitosack",
}

SetSharedLootTable("chasni_weevole", { {"mosquitosack",        0.01}, })

local HEALTH = 55
local DAMAGE = 6
local ATTACK_PERIOD = 1
local ATTACK_RANGE = 3
local SPEED = 5
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 15
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "grubarmy" }
local KEEPTARGET_RANGE = 40
local function RetargetFn(inst)
    return chasni_followerretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function keeptargetfn(inst, target)
    return chasni_followerkeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_solosharetarget(inst, data)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 5, .5)

    inst:AddTag("monster")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("smallcreature")
    inst:AddTag("weevole")
    inst:AddTag("grubarmy")

    inst.AnimState:SetBank("weevole")
    inst.AnimState:SetBuild("weevole")
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

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 1

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_weevole")

    inst:AddComponent("inspectable")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME

    MakeHauntablePanic(inst)
    MakeSmallBurnableCharacter(inst, "body")
    MakeSmallFreezableCharacter(inst, "body")

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZweevole")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_weevole", fn, assets, prefabs)
