local brain = require "brains/chasni_snapdragonbrain"

local assets =
{
    Asset("ANIM", "anim/snapdragon.zip"),
    Asset("ANIM", "anim/snapdragon_build.zip"),
    Asset("SOUND", "sound/beefalo.fsb"),
}

local prefabs =
{
    "dragonfruit_seeds",
    "flower",
    "plantmeat",
}

SetSharedLootTable("chasni_snapdragon", {
    {"dragonfruit_seeds",               0.50},
    {"flower",                          1.00},
    {"plantmeat",                       1.00},
    {"plantmeat",                       0.50},
    {"chasni_snapdragon_petal",         1.00},
    {"chasni_snapdragon_petal",         0.60},
    {"chasni_snapdragon_petal",         0.30},
    {"chasni_snapdragon_seed",          0.90},
    {"chasni_snapdragon_seed",          0.40},

    {"jellybean_green",        0.1},
})

local periodictable = { {"flower", 0.90}, }

local HEALTH = chasni_getmobconfig("chasni_snapdragon", "HP") or 1800
local DAMAGE = chasni_getmobconfig("chasni_snapdragon", "DMG") or 45
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 5
local SPEED = 4
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 5
local function KeepTarget(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "snapdragon", SHARETARGET_MAX)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.22, 1.22, 1.22)
    MakeCharacterPhysics(inst, 100, .5)

    inst.AnimState:SetBank("snapdragon")
    inst.AnimState:SetBuild("snapdragon_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("animal")
    inst:AddTag("largecreature")
    inst:AddTag("snapdragon")
    inst:AddTag("epic")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 3

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_snapdragon")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner.chancetable = periodictable
    inst.components.periodicspawner:SetRandomTimes(40, 60)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(8)
    inst.components.periodicspawner:Start()

    MakeHauntablePanic(inst)
    MakeMediumBurnableCharacter(inst, "body")
    --MakeMediumFreezableCharacter(inst) -- [BAD] no animation

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZSnapdragon")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_snapdragon", fn, assets, prefabs) 
