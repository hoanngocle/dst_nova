local brain = require "brains/chasni_plasmablobbrain"

local assets =
{
    Asset("ANIM", "anim/plasmablob.zip"),
}

local prefabs =
{
    "chasni_plasmablob_blob",
}

SetSharedLootTable("chasni_plasmablob", { {"chasni_plasmablob_blob", 0.8}, })

local HEALTH = chasni_getmobconfig("chasni_plasmablob", "HP") or 82
local DAMAGE = chasni_getmobconfig("chasni_plasmablob", "DMG") or 10
local ATTACK_PERIOD = 8
local ATTACK_RANGE = 10
local SPEED = 4
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 10
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "plasmablob" }
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
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "plasmablob", SHARETARGET_MAX)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(.8, .5)
    inst.Transform:SetTwoFaced()
    MakeFlyingCharacterPhysics(inst, 1, 0.5)
    inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("plasmablob")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("electricdamageimmune")

    inst.AnimState:SetBank("plasmablob")
    inst.AnimState:SetBuild("plasmablob")
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

    inst:AddComponent("electricattacks")
    inst.components.electricattacks:AddSource(inst)

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
    inst.components.lootdropper:SetChanceLootTable("chasni_plasmablob")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")

    MakeHauntablePanic(inst)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZplasmablob")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_plasmablob", fn, assets, prefabs)
