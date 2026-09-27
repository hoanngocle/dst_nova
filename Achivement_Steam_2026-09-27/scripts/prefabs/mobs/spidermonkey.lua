local brain = require "brains/chasni_spidermonkeybrain"

local assets =
{
    Asset("ANIM", "anim/spiderape_basics.zip"),
    Asset("ANIM", "anim/spiderape_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "spidergland",
    "beardhair",
    "silk",
}

SetSharedLootTable("chasni_spidermonkey", {
    {"monstermeat",              1.00},
    {"monstermeat",              1.00},
    {"monstermeat",              1.00},
    {"spidergland",              1.00},
    {"spidergland",              0.75},
    {"beardhair",                1.00},
    {"beardhair",                0.75},
    {"beardhair",                0.75},
    {"silk",                     0.75},
    {"chasni_cocoontreeseed",    1.00},

    {"jellybean_green",      0.10},
    {"jellybean_red",        0.20},
})

local HEALTH = chasni_getmobconfig("chasni_spidermonkey", "HP") or 2800
local DAMAGE = chasni_getmobconfig("chasni_spidermonkey", "DMG") or 85
local ATTACK_PERIOD = 6
local ATTACK_RANGE = 4.5
local SPEED = 4
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 15
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "spider", "monkey", "spiderwhisperer"}
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 15
local SHARETARGET_MAX = 5
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "spider", SHARETARGET_MAX, "monkey")
end

local function OnAttackOther(inst, data)
    if data.target and data.target:IsValid() and data.target:HasTag("player") then
        data.target:PushEvent("knockback", { knocker = inst, radius = 4 })
    end
end

local function CalcSanityAura(inst, observer)
    if observer:HasTag("spiderwhisperer") then
        return 0
    end
    return -TUNING.SANITYAURA_LARGE
end

local function onnear(inst)
    inst:AddTag("agitated")
    inst:PushEvent("agitated")
end

local function onfar(inst)
    inst:RemoveTag("agitated")
end

local function SpawnFx(inst, fx_prefab)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab(fx_prefab)
    fx.Transform:SetNoFaced()
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(1.5, 1.5, 1.5)
end

local function SlowingAttack(inst)
    SpawnFx(inst, "spider_heal_ground_fx")
    local x, _, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 10, {"structure"}, {"spidermonkey_creeped"})
    for i, v in ipairs(ents) do
        if v:IsValid() then
            local x1, _, z1 = v.Transform:GetWorldPosition()
            local creep = chasni_spawnprefab("spidermonkey_creep", x1, 0, z1)
            creep.InitCreep(creep, v)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(3, 1.5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 40, 1.5)

    inst:AddTag("spidermonkey")
    inst:AddTag("monkey")
    inst:AddTag("spider")
    inst:AddTag("animal")
    inst:AddTag("epic")

    inst.AnimState:SetBank("spiderape")
    inst.AnimState:SetBuild("SpiderApe_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 3

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_spidermonkey")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(6)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("inspectable")
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(20, 23)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    MakeMediumBurnableCharacter(inst)
    MakeMediumFreezableCharacter(inst)

    inst.curious = true
    inst.SlowingAttack = SlowingAttack

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onhitother", OnAttackOther)

    inst:SetStateGraph("SGCZspidermonkey")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_spidermonkey", fn, assets, prefabs)
