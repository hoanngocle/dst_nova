local clockwork_common = require "prefabs/clockwork_common"
local brain = require "brains/chasni_waterbishopbrain"

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/clockwork_common.lua"),

    Asset("ANIM", "anim/bishopboat.zip"),
    Asset("ANIM", "anim/bishopboat_build.zip"),
    Asset("ANIM", "anim/bishopboat_death.zip"),
}

local prefabs =
{
    "chasni_gas",
    "gears",
    "bishop_charge",
    "purplegem",
    "jellybean_yellow",
}

SetSharedLootTable('chasni_waterbishop',
        {
            {'gears',        1.0},
            {'gears',        1.0},
            {'gears',        0.7},
            {'gears',        0.3},
            {'purplegem',    1.0},
            {'purplegem',    0.5},
            {'chasni_gas',   1.0},

            {"jellybean_yellow",        0.10},
        })

local HEALTH = chasni_getmobconfig("chasni_waterbishop", "HP") or 1024
local DAMAGE = chasni_getmobconfig("chasni_waterbishop", "DMG") or 32
local ATTACK_PERIOD = 1
local ATTACK_PERIOD_SLOW = 4
local ATTACK_PERIOD_SLOW_MIN_COUNT = 4
local ATTACK_PERIOD_SLOW_MAX_COUNT = 7
local ATTACK_RANGE = 10
local SPEED = 7
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 10
local function Retarget(inst)
    return clockwork_common.Retarget(inst, RETARGET_RANGE)
end

local function KeepTarget(inst, target)
    return clockwork_common.KeepTarget(inst, target)
end

local function OnAttacked(inst, data)
    clockwork_common.OnAttacked(inst, data)
end

local function OnAttack(inst, data)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    inst.rapidfirecount = (inst.rapidfirecount or 1) - 1
    if inst.rapidfirecount <= 0 then
        inst.components.combat:SetAttackPeriod(ATTACK_PERIOD_SLOW)
        inst:DoTaskInTime(ATTACK_PERIOD_SLOW - 0.1, function(_inst)
            _inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
        end)
        inst.rapidfirecount = math.random(ATTACK_PERIOD_SLOW_MIN_COUNT, ATTACK_PERIOD_SLOW_MAX_COUNT)
    end
end

local function EquipWeapon(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
        weapon.components.weapon:SetProjectile("bishop_charge_fix")
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        weapon:AddComponent("equippable")
        weapon:AddTag("nosteal")

        inst.components.inventory:Equip(weapon)
    end
end

local function RememberKnownLocation(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("bishopboat")
    inst.AnimState:SetBuild("bishopboat_build")

    inst:AddTag("bishop")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("chess")
    inst:AddTag("epic")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 1

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_waterbishop")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(clockwork_common.ShouldWake)
    inst.components.sleeper:SetSleepTest(clockwork_common.ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("follower")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventory")
    inst:AddComponent("knownlocations")

    MakeMediumBurnableCharacter(inst, "waist")
    MakeMediumFreezableCharacter(inst, "waist")

    inst.soundpath = "dontstarve/creatures/bishop/"
    inst.effortsound = "dontstarve/creatures/bishop/idle"
    inst.rapidfirecount = math.random(ATTACK_PERIOD_SLOW_MIN_COUNT, ATTACK_PERIOD_SLOW_MAX_COUNT)

    EquipWeapon(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("doattack", OnAttack)
    inst:DoTaskInTime(0, RememberKnownLocation)

    inst:SetStateGraph("SGCZwaterbishop")
    inst:SetBrain(brain)

    return inst
end


local function OnHit(inst, owner, target)
    SpawnPrefab("bishop_charge_hit_fix").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function OnAnimOver(inst)
    inst:DoTaskInTime(.5, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animover", OnAnimOver)
end

local function fnproj()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("bishop_attack")
    inst.AnimState:SetBuild("bishop_attack")
    inst.AnimState:PlayAnimation("idle")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(40)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(0.8)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetStimuli("electric")

    return inst
end

local function PlayHitSound(proxy)
    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")

    inst:Remove()
end

local function hit_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame in case we are about to be removed
        inst:DoTaskInTime(0, PlayHitSound)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(.5, inst.Remove)

    return inst
end

return 
Prefab("chasni_waterbishop", fn, assets, prefabs),
Prefab("bishop_charge_fix", fnproj, assets),
Prefab("bishop_charge_hit_fix", hit_fn)
