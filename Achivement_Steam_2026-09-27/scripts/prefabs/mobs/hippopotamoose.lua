local brain = require "brains/chasni_hippopotamoosebrain"

local assets =
{
    Asset("ANIM", "anim/hippo_basic.zip"),
    Asset("ANIM", "anim/hippo_attacks.zip"),
    Asset("ANIM", "anim/hippo_water.zip"),
    Asset("ANIM", "anim/hippo_water_attacks.zip"),
    Asset("ANIM", "anim/hippo_build.zip"),
}

local prefabs =
{
    "meat",
}

SetSharedLootTable("chasni_hippopotamoose", {
    {"meat",                 1.00},
    {"meat",                 1.00},
    {"meat",                 1.00},
    {"meat",                 1.00},
    {"meat",                 0.50},
    {"meat",                 0.50},
    {"chasni_hippo_skin",    1.00},
    {"chasni_hippo_skin",    0.50},
    {"chasni_hippo_antler",  1.00},
    {"chasni_hippo_antler",  0.50},

    {"jellybean_red",        0.1},
})

local HEALTH = chasni_getmobconfig("chasni_hippopotamoose", "HP") or 1800
local DAMAGE = chasni_getmobconfig("chasni_hippopotamoose", "DMG") or 55
local ATTACK_PERIOD = 5
local ATTACK_RANGE = 4.5
local SPEED = 6
local KEEPTARGET_RANGE = 50
local SHARETARGET_RANGE = 15
local SHARETARGET_MAX = 5
local SLEEP_DIST_FROMTHREAT = 20
local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "hippo", SHARETARGET_MAX)
end

local function ShouldSleep(inst)
    if (inst.components.combat and inst.components.combat.target)
            or (inst.components.burnable and inst.components.burnable:IsBurning())
            or (inst.components.freezable and inst.components.freezable:IsFrozen()) then
        return false
    end
    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt == nil
end

local function ShouldWake(inst)
    if (inst.components.combat and inst.components.combat.target)
            or (inst.components.burnable and inst.components.burnable:IsBurning())
            or (inst.components.freezable and inst.components.freezable:IsFrozen()) then
        return true
    end
    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt
end

local function DoChargeDamage(inst, target)
    if not inst.recentlycharged then
        inst.recentlycharged = {}
    end
    for k,v in pairs(inst.recentlycharged) do
        if v == target then
            return
        end
    end
    inst.recentlycharged[target] = target
    inst:DoTaskInTime(3, function() inst.recentlycharged[target] = nil end)
    inst.components.combat:DoAttack(target, inst.weapon)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/explo")
end

local function oncollide(inst, other)
    local v1 = Vector3(inst.Physics:GetVelocity())
    if other and other:HasTag("player") then
        return
    end
    if v1:LengthSq() < 42 then return end

    TheCamera:Shake("SIDE", 0.5, 0.05, 0.1)
    inst:DoTaskInTime(2*FRAMES, function()
        if  (other and other:HasTag("smashable")) then
            other.components.health:Kill()
        elseif other and other.components.workable and other.components.workable.workleft > 0 then
            SpawnPrefab("collapse_small").Transform:SetPosition(other:GetPosition():Get())
            other.components.workable:Destroy(inst)
        elseif other and other.components.health and other.components.health:GetPercent() >= 0 then
            DoChargeDamage(inst, other)
        end
    end)

end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(3, 1.25)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 50, 1)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst:AddTag("animal")
    inst:AddTag("hippopotamoose")
    inst:AddTag("lightshake")
    inst:AddTag("aquatic")
    inst:AddTag("amphibious")
    inst:AddTag("epic")

    inst.AnimState:SetBank("hippo")
    inst.AnimState:SetBuild("hippo_build")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(oncollide)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spring"
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed =  SPEED + 2
    inst.components.locomotor:CanPathfindOnWater()
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_hippopotamoose")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("inventory")
    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2

    inst:AddComponent("embarker")
    inst.components.embarker.embark_speed = inst.components.locomotor.runspeed

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("hippo", "hippo_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
        chasni_amphibiousEnterWaterfn(inst, "turnoftides/common/together/water/splash/medium", "frogsplash", nil, 4)
    end)
    inst.components.amphibiouscreature:SetExitWaterFn(function(inst)
        chasni_amphibiousExitWaterfn(inst, "turnoftides/common/together/water/submerge/medium", "frogsplash")
    end)

    MakeMediumFreezableCharacter(inst)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZhippopotamoose")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_hippopotamoose", fn, assets, prefabs)