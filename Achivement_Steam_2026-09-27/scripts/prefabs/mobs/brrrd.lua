local brain = require "brains/chasni_brrrdbrain"

local assets =
{
    summer = {
        Asset("ANIM", "anim/brrrd_free_actions.zip"),
        Asset("ANIM", "anim/brrrd_free_basic.zip"),
        Asset("ANIM", "anim/brrrd_warm.zip"),
    },
    winter = {
        Asset("ANIM", "anim/brrrd_free_actions.zip"),
        Asset("ANIM", "anim/brrrd_free_basic.zip"),
        Asset("ANIM", "anim/brrrd_cold.zip"),
    },
}

local prefabs =
{
    summer = {
        "drumstick",
        "bird_egg",
        "feather_robin",
    },
    winter = {
        "drumstick",
        "bird_egg",
        "feather_robin_winter",
    },
}

SetSharedLootTable("chasni_brrrd_summer", {
    {"drumstick",                1.00},
    {"drumstick",                1.00},
    {"bird_egg",                 1.00},
    {"bird_egg",                 0.50},
    {"chasni_exort_feather",     1.00},
    {"chasni_exort_feather",     1.00},
    {"chasni_exort_feather",     0.50},
    {"feather_robin",            1.00},
    {"feather_robin",            1.00},
    {"feather_canary",           1.00},
    {"feather_canary",           0.50},

    {"jellybean_red",        0.20},
})

SetSharedLootTable("chasni_brrrd_winter", {
    {"drumstick",               1.00},
    {"drumstick",               1.00},
    {"bird_egg",                1.00},
    {"bird_egg",                0.50},
    {"chasni_quas_feather",     1.00},
    {"chasni_quas_feather",     1.00},
    {"chasni_quas_feather",     0.50},
    {"feather_crow",            1.00},
    {"feather_crow",            1.00},
    {"feather_robin_winter",    1.00},
    {"feather_robin_winter",    0.50},

    {"jellybean_green",        0.10},
})

local HEALTH_SUMMER = chasni_getmobconfig("chasni_brrrd_summer", "HP") or 1000
local DAMAGE_SUMMER = chasni_getmobconfig("chasni_brrrd_summer", "DMG") or 120
local HEALTH_WINTER = chasni_getmobconfig("chasni_brrrd_winter", "HP") or 2000
local DAMAGE_WINTER = chasni_getmobconfig("chasni_brrrd_winter", "DMG") or 60
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 4
local SPEED = 3
local SPEED_RUN = 8
local KEEPTARGET_RANGE = 8
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 5
local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "brrrd", SHARETARGET_MAX)
end

local function spawnRandomDung()
    local px = 0
    local py = 0
    local maxpoop = 8
    for i, node in ipairs(TheWorld.topology.nodes) do
        local dx = px - node.x
        local dy = py - node.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 600 then
            local randx = math.random() * 100 * (math.random(1, 2) * 2 - 3)
            local randy = math.random() * 100 * (math.random(1, 2) * 2 - 3)
            if TheWorld.Map:IsPassableAtPoint(node.x + randx, 0, node.y + randy) and node.type ~= NODE_TYPE.SeparatedRoom then
                maxpoop = maxpoop - 1
                chasni_spawnprefab("chasni_dungpile", node.x + randx, 0, node.y + randy)
                px = node.x
                py = node.y
                if maxpoop < 0 then
                    return
                end
            end
        end
    end
end

local function DoDung(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    inst:DoTaskInTime(2, function()
        chasni_spawnprefab("chasni_dungpile", x, 0, z)
        spawnRandomDung()
        TheNet:Announce(STRINGS.CHASNI_DUNGPILE.SPAWN)
    end)
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.prefab == "chasni_robin_stone" and item.components.inventoryitem and item.components.inventoryitem.imagename == "robin_stone_death" then
        inst.sg:GoToState("nest")
    end
end

local function OnRefuseItem(inst, giver, item)
    inst.components.combat:SetTarget(giver)
    inst.sg:GoToState("skill")
end

local function AbleToAcceptTest(inst, item, giver)
    local attacktarget = inst.components.combat.target
    return attacktarget == nil
end

local function AcceptTest(inst, item, giver)
    local attacktarget = inst.components.combat.target
    return attacktarget == nil and item.prefab == "chasni_robin_stone" and item.components.inventoryitem and item.components.inventoryitem.imagename == "robin_stone_death"
end

local function fn(type)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 100, .5)

    inst:AddTag("trader")
    inst:AddTag("brrrd")
    inst:AddTag("animal")
    inst:AddTag("largecreature")
    inst:AddTag("epic")

    local build = type == "summer" and "brrrd_warm" or "brrrd_cold"
    inst.AnimState:SetBank("brrrd_free")
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    local brrrd_damage = type == "summer" and DAMAGE_SUMMER or DAMAGE_WINTER
    inst.components.combat:SetDefaultDamage(brrrd_damage)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    local brrrd_health = type == "summer" and HEALTH_SUMMER or HEALTH_WINTER
    inst.components.health:SetMaxHealth(brrrd_health)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED_RUN

    local lootname = "chasni_brrrd_" .. type
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable(lootname)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("lighttweener")
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    MakeHauntablePanic(inst)
    MakeLargeBurnableCharacter(inst, "brrrd_body")
    --MakeLargeFreezableCharacter(inst) -- [BAD] no animation

    inst.Type = type
    inst.DoDung = DoDung

    inst:ListenForEvent("attacked", OnAttacked)
    inst:DoTaskInTime(0,function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, 20, z)
        inst.sg:GoToState("glide")
    end)

    inst:SetStateGraph("SGCZBrrrd")
    inst:SetBrain(brain)

    return inst
end

local function summer_fn() return fn("summer") end
local function winter_fn() return fn("winter") end

return 
Prefab("chasni_brrrd_summer", summer_fn, assets.summer, prefabs.summer),
Prefab("chasni_brrrd_winter", winter_fn, assets.winter, prefabs.winter)
