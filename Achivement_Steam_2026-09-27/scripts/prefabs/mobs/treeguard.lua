local brain = require "brains/chasni_treeguardbrain"
local easing = require("easing")


local assets =
{
    Asset("ANIM", "anim/treeguard_walking.zip"),
    Asset("ANIM", "anim/treeguard_actions.zip"),
    Asset("ANIM", "anim/treeguard_attacks.zip"),
    Asset("ANIM", "anim/treeguard_idles.zip"),
    Asset("ANIM", "anim/treeguard_build.zip"),
}

local prefabs =
{
    "livinglog",
}

SetSharedLootTable("chasni_treeguard", {
    {"livinglog",                  1.0},
    {"livinglog",                  1.0},
    {"chasni_palmtreeguard_log",   1.0},
    {"chasni_palmtreeguard_log",   1.0},
    {"chasni_palmtreeguard_log",   1.0},
    {"chasni_palmtreeguard_log",   0.5},
    {"chasni_palmtreeguard_log",   0.5},
    {"chasni_palmtreeguard_log",   0.5},

    {"jellybean_green",        0.10},
})

local HEALTH = chasni_getmobconfig("chasni_treeguard", "HP") or 1800
local DAMAGE = chasni_getmobconfig("chasni_treeguard", "DMG") or 55
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 20
local ATTACK_RANGE_MELEE = 3.5
local ATTACK_RANGE_RANGED = 25
local SPEED = 2
local KEEPTARGET_RANGE = 40
local function KeepTarget(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    local x, _, z = inst.Transform:GetWorldPosition()
    local targetpos = inst:GetPosition()
    local projectile = SpawnPrefab("chasni_treeguard_coconut")
    projectile.Transform:SetPosition(x, 5.5, z)
    projectile:AddTag("canthit")
    projectile.components.complexprojectile:SetHorizontalSpeed(1)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end

local function OnLoad(inst, data)
    if data and data.hibernate then
        inst.components.sleeper.hibernate = true
    end
    if data and data.sleep_time then
        inst.components.sleeper.testtime = data.sleep_time
    end
    if data and data.sleeping then
        inst.components.sleeper:GoToSleep()
    end
end

local function OnSave(inst, data)
    if inst.components.sleeper:IsAsleep() then
        data.sleeping = true
        data.sleep_time = inst.components.sleeper.testtime
    end

    if inst.components.sleeper:IsHibernating() then
        data.hibernate = true
    end
end

local function CalcSanityAura(inst)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_LARGE
    end
    return 0
end

local function OnBurnt(inst)
    if inst.components.propagator and inst.components.health and not inst.components.health:IsDead() then
        inst.components.propagator.acceptsheat = true
    end
end

local function SetRangeMode(inst)
    if inst.combatmode == "RANGE" then
        return
    end

    inst.combatmode = "RANGE"
    inst.components.combat:SetDefaultDamage(0)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD + 1)
    inst.components.combat:SetRange(ATTACK_RANGE, ATTACK_RANGE_RANGED)
end

local function SetMeleeMode(inst)
    if inst.combatmode == "MELEE" then
        return
    end

    inst.combatmode = "MELEE"
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRange(ATTACK_RANGE, ATTACK_RANGE_MELEE)
end

local function ThrowCoconut(inst, target)
    if target then
        local x, _, z = inst.Transform:GetWorldPosition()
        local projectile = SpawnPrefab("chasni_treeguard_coconut")
        projectile.Transform:SetPosition(x, 6, z)
        local a, _, c = target.Transform:GetWorldPosition()
        local targetpos = target:GetPosition()
        targetpos.x = targetpos.x + math.random(-3,3)
        targetpos.z = targetpos.z + math.random(-3,3)
        local dx = a - x
        local dz = c - z
        local rangesq = dx * dx + dz * dz
        local maxrange = 25
        local bigNum = 10
        local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange)
        projectile:AddTag("canthit")
        projectile.components.complexprojectile:SetHorizontalSpeed(speed+math.random(2,7))
        projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    end
end

local function ThrowCoconuts(inst)
    for _ = 1, math.random(3,5) do
        if inst.components.combat.target then
            inst:DoTaskInTime(FRAMES+math.random()*0.1, ThrowCoconut, inst.components.combat.target)
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

    inst.DynamicShadow:SetSize(4, 1.5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 1000, .5)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("leif")
    inst:AddTag("tree")
    inst:AddTag("largecreature")
    inst:AddTag("epic")

    inst.AnimState:SetBank("treeguard")
    inst.AnimState:SetBuild("treeguard_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE, ATTACK_RANGE_RANGED)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.hiteffectsymbol = "marker"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 1

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_treeguard")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_treeguard")

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:SetStateGraph("SGCZtreeguard")
    inst:SetBrain(brain)

    MakeLargeBurnableCharacter(inst, "marker")
    MakeHugeFreezableCharacter(inst, "marker")
    inst.components.burnable.flammability = .333
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.propagator.acceptsheat = true

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    inst.SetRange = SetRangeMode
    inst.SetMelee = SetMeleeMode
    inst.ThrowCoconuts = ThrowCoconuts

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("chasni_treeguard", fn, assets, prefabs)
