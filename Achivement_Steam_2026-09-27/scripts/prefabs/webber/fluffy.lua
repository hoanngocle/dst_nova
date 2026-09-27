local brain = require "brains/chasni_fluffybrain"

local assets =
{
    Asset("ANIM", "anim/fluffy.zip"),
}

local prefabs =
{
    "monstermeat",
    "silk",
    "spidergland",
}

SetSharedLootTable("chasni_fluffy", {
    {"monstermeat",     1.00},
    {"monstermeat",     1.00},
    {"monstermeat",     0.50},
    {"spidergland",     1.00},
    {"spidergland",     0.50},
    {"silk",            0.50},
})

local HEALTH = chasni_getmobconfig("chasni_fluffy", "HP") or 850
local DAMAGE = chasni_getmobconfig("chasni_fluffy", "DMG") or 50
local ATTACK_PERIOD = 1
local ATTACK_RANGE = 4.5
local SPEED = 3.5
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 15
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "spider", "spiderwhisperer"}
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 5
local DIET = { FOODTYPE.MEAT }
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "fluffy", SHARETARGET_MAX)
end

local function CalcSanityAura(inst, observer)
    if observer:HasTag("spiderwhisperer") or chasni_friendpet(inst, "spiderwhisperer") then
        return TUNING.SANITYAURA_SMALL
    end

    return -TUNING.SANITYAURA_SMALL
end

local function ShouldAcceptItem(inst, item, giver)
    return (giver:HasTag("spiderwhisperer") and inst.components.eater:CanEat(item))
end

local SPIDER_TAGS = { "spider" }
local function GetOtherSpiders(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spiders = TheSim:FindEntities(x, y, z, radius, nil, chasni_TAG_NOTARGET, SPIDER_TAGS)
    local valid_spiders = {}

    for _, spider in ipairs(spiders) do
        if spider:IsValid() and not spider.components.health:IsDead() and not spider:HasTag("playerghost") then
            table.insert(valid_spiders, spider)
        end
    end

    return valid_spiders
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.eater:CanEat(item) then
        inst.components.eater:Eat(item)
        inst.sg:GoToState("eat", true)

        local playedfriendsfx = false
        if inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        elseif giver.components.leader and
                inst.components.follower then
            if giver.components.minigame_participator == nil then
                giver:PushEvent("makefriend")
                giver.components.leader:AddFollower(inst)
                playedfriendsfx = true
            end
        end

        if giver.components.leader then
            local spiders = GetOtherSpiders(inst, 15)
            local maxSpiders = TUNING.SPIDER_FOLLOWER_COUNT
            for i, v in ipairs(spiders) do
                if v ~= inst then
                    if maxSpiders <= 0 then
                        break
                    end
                    local effectdone = true
                    if v.components.combat.target == giver then
                        v.components.combat:SetTarget(nil)
                    elseif giver.components.leader and v.components.follower and v.components.follower.leader == nil then
                        if not playedfriendsfx then
                            giver:PushEvent("makefriend")
                            playedfriendsfx = true
                        end
                        giver.components.leader:AddFollower(v)
                    else
                        effectdone = false
                    end

                    if effectdone then
                        maxSpiders = maxSpiders - 1
                        if v.components.sleeper:IsAsleep() then
                            v.components.sleeper:WakeUp()
                        end
                    end
                end
            end
        end
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("taunt")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function MakeWeapon(inst)
    if inst.components.inventory then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()

        MakeInventoryPhysics(weapon)

        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(TUNING.SPIDER_SPITTER_DAMAGE_RANGED)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange + 4)
        weapon.components.weapon:SetProjectile("spider_web_spit")
        --weapon.components.weapon:SetOnAttack(OnAttack)

        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)

        weapon:AddComponent("equippable")
        weapon:AddTag("nosteal")
        inst.weapon = weapon
        inst.components.inventory:Equip(inst.weapon)
        inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
    end
end

local function OnDeath(inst, data)
    if inst.House and inst.House.fluffystate == 0 and data.cause ~= "NOLEADER" then
        inst.House.fluffystate = -1
        inst.House.AnimState:PlayAnimation("fluffy_died")
        inst.House.AnimState:PushAnimation("idle_dead", true)
        inst.House.ReSpawnFluffy(inst.House)
    end
end

local function ReturnHome(inst)
    if inst.House and inst.House.fluffystate == 0 then
        inst.House.fluffystate = 1
        inst.House.AnimState:PlayAnimation("fluffy_respawn")
        inst.House.AnimState:PushAnimation("idle_inside", true)
    end
    if inst.components.health then
        inst:RemoveComponent("lootdropper")
        inst.components.health._ignore_maxdamagetakenperhit = true
        inst.components.health:DoDelta(-inst.components.health.currenthealth, nil, "NOLEADER", nil, nil, true)
        inst.components.health._ignore_maxdamagetakenperhit = nil
    end
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
    MakeCharacterPhysics(inst, 100, .5)

    inst.AnimState:SetBank("fluffy")
    inst.AnimState:SetBuild("fluffy")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("spider")
    inst:AddTag("fluffy")

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
    --inst.components.health:SetMaxDamageTakenPerHit(10)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_fluffy")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventory")
    inst:AddComponent("follower")
    inst.components.follower:CancelLoyaltyTask()
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetAbleToAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("eater")
    inst.components.eater:SetDiet(DIET, DIET)
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true)
    inst.components.eater:SetCanEatRawMeat(true)

    --MakeWeapon(inst)

    MakeMediumBurnableCharacter(inst, "", Vector3(0, 0, 0))
    --MakeMediumFreezableCharacter(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst.House = nil
    inst.ReturnHome = ReturnHome
    inst:SetStateGraph("SGCZfluffy")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_fluffy", fn, assets, prefabs) 
