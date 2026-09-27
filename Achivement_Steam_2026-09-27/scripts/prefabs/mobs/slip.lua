local brain = require "brains/chasni_slipbrain"

local assets =
{
    Asset("ANIM", "anim/slips_build.zip"),
    Asset("ANIM", "anim/slips_basic.zip"),
    Asset("ANIM", "anim/slips_actions.zip"),
}

local prefabs =
{
    "chasni_slipstor",
    "monstermeat",
}

SetSharedLootTable("chasni_slip", {
    {"monstermeat",         0.01},
    {"chasni_slipstor_fur", 0.01},
})

local HEALTH = chasni_getmobconfig("chasni_slip", "HP") or 160
local DAMAGE = chasni_getmobconfig("chasni_slip", "DMG") or 16
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 3
local SPEED = 6
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 4
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "slip", "slipstor" }
local KEEPTARGET_RANGE = 8
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
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 10, .5)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("smallcreature")
    inst:AddTag("slip")

    inst.AnimState:SetBank("slip")
    inst.AnimState:SetBuild("slips_build")
    inst.AnimState:PlayAnimation("eat_loop")

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
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_slip")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(1)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME

    MakeHauntablePanic(inst)
    MakeMediumBurnableCharacter(inst, "slip_body")
    MakeSmallFreezableCharacter(inst, "slip_body")

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZslip")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_slip", fn, assets, prefabs)
