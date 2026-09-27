local brain = require "brains/chasni_pangoldenbrain"

local assets =
{
    Asset("ANIM", "anim/pango_basic.zip"),
    Asset("ANIM", "anim/pango_action.zip"),
}

local prefabs =
{
    "meat",
    "goldnugget",
}

SetSharedLootTable("chasni_pangolden", {
    {"chasni_pangolden_scale",      1.00},
    {"chasni_pangolden_scale",      1.00},
    {"chasni_pangolden_scale",      0.90},
    {"chasni_pangolden_scale",      0.70},
    {"chasni_pangolden_scale",      0.50},
    {"chasni_pangolden_scale",      0.30},
    {"chasni_pangolden_scale",      0.10},
    {"goldnugget",                  1.00},
    {"goldnugget",                  1.00},
    {"goldnugget",                  1.00},
    {"goldnugget",                  0.90},
    {"goldnugget",                  0.80},
    {"goldnugget",                  0.70},
    {"goldnugget",                  0.60},
    {"meat",                        1.00},
    {"meat",                        0.70},

    {"jellybean_yellow",            0.05},
})

local HEALTH = chasni_getmobconfig("chasni_pangolden", "HP") or 2600
local DAMAGE = chasni_getmobconfig("chasni_pangolden", "DMG") or 40
local ATTACK_PERIOD = 2
local ATTACK_RANGE = 3.5
local SPEED = 3
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 5
local function KeepTarget(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "pangolden", SHARETARGET_MAX)
end

local function IncreaseGold(inst)
    local nextime = 20 + 100 * math.random()
    inst:DoTaskInTime(nextime, IncreaseGold)
    inst.goldlevel = inst.goldlevel + 1
end

local function LaunchItem(inst, target, item)
    if item.Physics and item.Physics:IsActive() then
        local x, y, z = item.Transform:GetWorldPosition()
        item.Physics:Teleport(x, .1, z)

        x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = math.atan2(z1 - z, x1 - x) + (math.random() * 20 - 10) * DEGREES
        local speed = 5 + math.random() * 2
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end

local function OnHitOther(inst, data)
    if data.target and data.target.components.inventory then
        if not data.target:HasTag("stronggrip") then
            local item = data.target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item and not item:HasTag("nosteal") then
                data.target.components.inventory:DropItem(item)
                LaunchItem(inst, data.target, item)
            end
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

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 100, .5)

    inst.AnimState:SetBank("pango")
    inst.AnimState:SetBuild("pango_action")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("animal")
    inst:AddTag("pangolden")
    inst:AddTag("largecreature")
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
    inst.components.locomotor.runspeed = SPEED + 4

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_pangolden")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")
    inst:AddComponent("timer")

    MakeMediumBurnableCharacter(inst, "pang_bod")
    MakeMediumFreezableCharacter(inst, "pang_bod")

    inst.goldlevel = 0

    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:DoTaskInTime(120, IncreaseGold)

    inst:SetStateGraph("SGCZpangolden")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_pangolden", fn, assets, prefabs) 
