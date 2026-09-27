local brain = require "brains/chasni_crocodogbrain"

local assets =
{
    normal = {
        Asset("ANIM", "anim/crocodog_basic.zip"),
        Asset("ANIM", "anim/crocodog_basic_water.zip"),
        Asset("ANIM", "anim/crocodog.zip"),
        Asset("ANIM", "anim/watercrocodog.zip"),
    },
    water = {
        Asset("ANIM", "anim/crocodog_basic.zip"),
        Asset("ANIM", "anim/crocodog_basic_water.zip"),
        Asset("ANIM", "anim/crocodog_water.zip"),
        Asset("ANIM", "anim/watercrocodog_water.zip"),
    },
    poison = {
        Asset("ANIM", "anim/crocodog_basic.zip"),
        Asset("ANIM", "anim/crocodog_basic_water.zip"),
        Asset("ANIM", "anim/crocodog_poison.zip"),
        Asset("ANIM", "anim/watercrocodog_poison.zip"),
    },
}

local prefabs =
{
    "houndstooth",
    "monstermeat",
}

local summoner_prefabs =
{
    "chasni_crocodog",
    "chasni_watercrocodog",
    "chasni_poisoncrocodog",
}

SetSharedLootTable("chasni_crocodog", {
    {"chasni_crocodog_skin",  1.00},
    {"chasni_crocodog_skin",  0.25},
    {"chasni_crocodog_skin",  0.25},
    {"monstermeat",           1.00},
    {"monstermeat",           0.25},
    {"houndstooth",           1.00},
    {"houndstooth",           0.25},
    {"chasni_poison_gland",          0.15},
    {"chasni_poison_gland",          0.15},
})

SetSharedLootTable("chasni_crocodog_poison", {
    {"chasni_crocodog_skin",  1.00},
    {"chasni_crocodog_skin",  0.50},
    {"monstermeat",           1.00},
    {"monstermeat",           0.25},
    {"houndstooth",           1.00},
    {"houndstooth",           0.25},
    {"chasni_poison_gland",          1.00},
    {"chasni_poison_gland",          0.75},
})

local HEALTH = chasni_getmobconfig("chasni_crocodog", "HP") or 560
local DAMAGE = chasni_getmobconfig("chasni_crocodog", "DMG") or 38
local ATTACK_PERIOD = 3
local ATTACK_RANGE = 3.5
local SPEED = 4
local SPEED_RUN = 6
local SPEED_SWIM = 8
local RETARGET_PERIOD = 2
local RETARGET_RANGE = 35
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "crocodog" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 10
local SHARETARGET_MAX = 40
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "crocodog", SHARETARGET_MAX)
end

local function OnAttackOther(inst, data)
    if data.target then
        if inst.Type == "water" then
            if data.target.components.moisture then
                data.target.components.moisture:DoDelta(10)
            end
        end
        if inst.Type == "poison" then
            if data.target.components.playerpoisonable then
                data.target.components.playerpoisonable:Poison()
            end
        end
    end
end

local function fn(type)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(3, 1.5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 10, .5)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("aquatic")
    inst:AddTag("amphibious")
    inst:AddTag("crocodog")
    inst:AddTag("epic")

    inst.waterbuild = type == "water" and "watercrocodog_water"
            or type == "poison" and "watercrocodog_poison"
            or "watercrocodog"
    inst.normalbuild = type == "water" and "crocodog_water"
            or type == "poison" and "crocodog_poison"
            or "crocodog"
    inst.AnimState:SetBank("crocodog")
    inst.AnimState:SetBuild(inst.normalbuild)
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
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("DLChasni/DLChasni/chasni_crocodog/hit", nil, 0.8)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED_RUN
    inst.components.locomotor:CanPathfindOnWater()
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.pathcaps = { allowocean = true }

    local lootdrop = type == "poison" and "chasni_crocodog_poison" or "chasni_crocodog"
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable(lootdrop)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("crocodog", "crocodog_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
        chasni_amphibiousEnterWaterfn(inst, "turnoftides/common/together/water/submerge/medium", "frogsplash", SPEED_SWIM, 4)
        inst.AnimState:SetBuild(inst.waterbuild)
    end)
    inst.components.amphibiouscreature:SetExitWaterFn(function(inst)
        chasni_amphibiousExitWaterfn(inst, "turnoftides/common/together/water/submerge/medium", "frogsplash")
        inst.AnimState:SetBuild(inst.normalbuild)
    end)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true)

    MakeHauntablePanic(inst)
    MakeMediumFreezableCharacter(inst, "Crocodog_Body")
    MakeMediumBurnableCharacter(inst, "Crocodog_Body")

    inst.Type = type

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onhitother", OnAttackOther)

    inst:SetStateGraph("SGCZcrocodog")
    inst:SetBrain(brain)

    return inst
end

local function fnsummoner()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("notraptrigger")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(.1,function()
        local crocodogs = summoner_prefabs
        for i = 1, 3 do
            local x, y, z = inst.Transform:GetWorldPosition()
            local theta = (inst.Transform:GetRotation() + (i * 120))* DEGREES
            local xoffs = 3 * math.sin(theta)
            local zoffs = 3 * math.cos(theta)
            x = x + xoffs
            z = z + zoffs
            chasni_spawnprefab(crocodogs[i], x, y, z)
        end
        inst:Remove()
    end)

    inst.persists = false
    inst.OnLoad = inst.Remove

    return inst
end

local function normal_fn() return fn("normal") end
local function water_fn() return fn("water") end
local function poison_fn() return fn("poison") end

return Prefab("chasni_crocodog", normal_fn, assets.normal, prefabs),
Prefab("chasni_watercrocodog", water_fn, assets.water, prefabs),
Prefab("chasni_poisoncrocodog", poison_fn, assets.poison, prefabs),
Prefab("chasni_crocodogspawner", fnsummoner, {}, summoner_prefabs)
